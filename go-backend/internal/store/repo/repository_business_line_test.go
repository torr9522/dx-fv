package repo

import (
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
