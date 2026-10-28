package repo

import (
	"database/sql"
	"errors"
	"sort"

	"go-backend/internal/store/model"
	"gorm.io/gorm"
)

func (r *Repository) ListBusinessLines(userID int64) ([]model.BusinessLine, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("repository not initialized")
	}
	var rows []model.BusinessLine
	q := r.db.Order("id ASC")
	if userID > 0 {
		q = q.Where("user_id = ?", userID)
	}
	return rows, q.Find(&rows).Error
}

func (r *Repository) GetBusinessLine(id int64) (*model.BusinessLine, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("repository not initialized")
	}
	var row model.BusinessLine
	if err := r.db.First(&row, id).Error; err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *Repository) GetBusinessLineByForwardID(forwardID int64) (*model.BusinessLine, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("repository not initialized")
	}
	var row model.BusinessLine
	err := r.db.Where("gz_forward_id = ? OR ix_forward_id = ?", forwardID, forwardID).First(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *Repository) UpdateBusinessLineProtocolMode(id int64, expectedMode, nextMode string, updatedTime int64) error {
	if r == nil || r.db == nil {
		return errors.New("repository not initialized")
	}
	result := r.db.Model(&model.BusinessLine{}).
		Where("id = ? AND protocol_mode = ?", id, expectedMode).
		Updates(map[string]interface{}{"protocol_mode": nextMode, "updated_time": updatedTime})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected != 1 {
		return errors.New("business line protocol mode changed concurrently")
	}
	return nil
}

func (r *Repository) CreateBusinessLineTx(tx *gorm.DB, row *model.BusinessLine) error {
	if tx == nil || row == nil {
		return errors.New("database unavailable")
	}
	return tx.Create(row).Error
}

func (r *Repository) CreateForwardOnTx(tx *gorm.DB, f *model.Forward, nodeID int64, port int, inIP string) error {
	if tx == nil || f == nil || nodeID <= 0 || port <= 0 {
		return errors.New("invalid forward")
	}
	if err := tx.Create(f).Error; err != nil {
		return err
	}
	return tx.Create(&model.ForwardPort{ForwardID: f.ID, NodeID: nodeID, Port: port, InIP: sqlNullString(inIP)}).Error
}

func (r *Repository) DeleteBusinessLine(id int64) error {
	if r == nil || r.db == nil {
		return errors.New("repository not initialized")
	}
	return r.db.Delete(&model.BusinessLine{}, id).Error
}

// UsedPortsForNode returns ports referenced by any configured forward. The
// caller combines this with live listener checks and static reservations.
func (r *Repository) UsedPortsForNode(nodeID int64) (map[int]bool, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("repository not initialized")
	}
	var rows []model.ForwardPort
	if err := r.db.Where("node_id = ?", nodeID).Find(&rows).Error; err != nil {
		return nil, err
	}
	used := make(map[int]bool, len(rows))
	for _, row := range rows {
		if row.Port > 0 {
			used[row.Port] = true
		}
	}
	return used, nil
}

func (r *Repository) UsedPortsOnNodeTx(tx *gorm.DB, nodeID int64) (map[int]bool, error) {
	if tx == nil {
		return nil, errors.New("database unavailable")
	}
	var rows []model.ForwardPort
	if err := tx.Where("node_id = ?", nodeID).Find(&rows).Error; err != nil {
		return nil, err
	}
	used := make(map[int]bool, len(rows))
	for _, row := range rows {
		if row.Port > 0 {
			used[row.Port] = true
		}
	}
	return used, nil
}

func PickPortFromPool(used map[int]bool, reserved map[int]bool, start, end int) (int, error) {
	ports := make([]int, 0, end-start+1)
	for p := start; p <= end; p++ {
		ports = append(ports, p)
	}
	sort.Ints(ports)
	for _, p := range ports {
		if !used[p] && !reserved[p] {
			return p, nil
		}
	}
	return 0, errors.New("没有可用的端口池端口")
}

func sqlNullString(v string) (out sql.NullString) {
	if v != "" {
		out.String, out.Valid = v, true
	}
	return out
}
