package repo

import (
	"database/sql"
	"testing"

	"github.com/glebarez/sqlite"
	"go-backend/internal/store/model"
	"gorm.io/gorm"
)

func TestPickPortFromPoolSkipsReservedAndUsed(t *testing.T) {
	used := map[int]bool{34702: true, 34703: true}
	reserved := map[int]bool{34700: true, 34701: true, 34704: true}
	got, err := PickPortFromPool(used, reserved, 34700, 34705)
	if err != nil {
		t.Fatalf("PickPortFromPool: %v", err)
	}
	if got != 34705 {
		t.Fatalf("expected 34705, got %d", got)
	}
}

func TestPickPortFromPoolReportsExhaustion(t *testing.T) {
	_, err := PickPortFromPool(map[int]bool{10: true, 11: true}, nil, 10, 11)
	if err == nil {
		t.Fatal("expected exhaustion error")
	}
}

func TestNextIndexTxUsesOpenTransaction(t *testing.T) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("open database: %v", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatalf("database handle: %v", err)
	}
	sqlDB.SetMaxOpenConns(1)
	if err := db.AutoMigrate(&model.Tunnel{}); err != nil {
		t.Fatalf("migrate tunnel: %v", err)
	}

	r := &Repository{db: db}
	tx := db.Begin()
	if tx.Error != nil {
		t.Fatalf("begin transaction: %v", tx.Error)
	}
	defer tx.Rollback()
	if err := tx.Create(&model.Tunnel{Name: "first", Inx: 0}).Error; err != nil {
		t.Fatalf("create tunnel: %v", err)
	}
	if got := r.NextIndexTx(tx, "tunnel"); got != -1 {
		t.Fatalf("NextIndexTx() = %d, want -1", got)
	}
}

func TestBusinessLineTunnelReadsUseOpenTransaction(t *testing.T) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("open database: %v", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		t.Fatalf("database handle: %v", err)
	}
	sqlDB.SetMaxOpenConns(1)
	if err := db.AutoMigrate(&model.Tunnel{}, &model.ChainTunnel{}); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	tunnel := model.Tunnel{Name: "qix", Type: 2, Flow: 1, TrafficRatio: 1, Status: 1}
	if err := db.Create(&tunnel).Error; err != nil {
		t.Fatalf("create tunnel: %v", err)
	}
	if err := db.Create(&model.ChainTunnel{
		TunnelID: tunnel.ID, ChainType: "1", NodeID: 7,
		Inx: sql.NullInt64{Int64: 1, Valid: true},
	}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	r := &Repository{db: db}
	tx := db.Begin()
	if tx.Error != nil {
		t.Fatalf("begin transaction: %v", tx.Error)
	}
	defer tx.Rollback()
	if got, err := r.GetTunnelRecordTx(tx, tunnel.ID); err != nil || got == nil || got.ID != tunnel.ID {
		t.Fatalf("GetTunnelRecordTx() = %#v, %v", got, err)
	}
	ids, err := r.TunnelEntryNodeIDsTx(tx, tunnel.ID)
	if err != nil || len(ids) != 1 || ids[0] != 7 {
		t.Fatalf("TunnelEntryNodeIDsTx() = %v, %v", ids, err)
	}
}

func TestUpdateBusinessLineProtocolModeUsesExpectedState(t *testing.T) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("open database: %v", err)
	}
	if err := db.AutoMigrate(&model.BusinessLine{}); err != nil {
		t.Fatalf("migrate business line: %v", err)
	}
	line := model.BusinessLine{
		Name: "line", PathType: "qix", ProtocolMode: model.BusinessLineProtocolTCPUDP,
		Status: "active", CreatedTime: 1, UpdatedTime: 1,
	}
	if err := db.Create(&line).Error; err != nil {
		t.Fatalf("create business line: %v", err)
	}
	r := &Repository{db: db}
	if err := r.UpdateBusinessLineProtocolMode(line.ID, model.BusinessLineProtocolTCPUDP, model.BusinessLineProtocolTCP, 2); err != nil {
		t.Fatalf("update protocol: %v", err)
	}
	if err := r.UpdateBusinessLineProtocolMode(line.ID, model.BusinessLineProtocolTCPUDP, model.BusinessLineProtocolTCP, 3); err == nil {
		t.Fatal("expected stale protocol update to fail")
	}
	got, err := r.GetBusinessLine(line.ID)
	if err != nil {
		t.Fatalf("get business line: %v", err)
	}
	if got.ProtocolMode != model.BusinessLineProtocolTCP || got.UpdatedTime != 2 {
		t.Fatalf("unexpected line after update: %#v", got)
	}
}
