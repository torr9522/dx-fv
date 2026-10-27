package handler

import (
	"database/sql"
	"errors"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"go-backend/internal/http/response"
	"go-backend/internal/store/model"
	"go-backend/internal/store/repo"
	"gorm.io/gorm"
)

var (
	businessLinePortMu               sync.Mutex
	businessLineRuntimePortConflicts = make(map[int64]map[int]bool)
)

const (
	frontseaPortStart = 34700
	frontseaPortEnd   = 34799
)

type businessLineCreateRequest struct {
	Name        string `json:"name"`
	PathType    string `json:"pathType"`
	GZNodeID    int64  `json:"gzNodeId"`
	IXNodeID    int64  `json:"ixNodeId"`
	EntryPort   int    `json:"entryPort"`
	TargetHost  string `json:"targetHost"`
	TargetPort  int    `json:"targetPort"`
	QIXTunnelID int64  `json:"qixTunnelId"`
}

type frontseaPortConflictError struct {
	port int
	err  error
}

func (e *frontseaPortConflictError) Error() string {
	return e.err.Error()
}

func (e *frontseaPortConflictError) Unwrap() error {
	return e.err
}

func (h *Handler) businessLineList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteJSON(w, response.ErrDefault("请求失败"))
		return
	}
	userID, roleID, err := userRoleFromRequest(r)
	if err != nil {
		response.WriteJSON(w, response.Err(401, "未登录"))
		return
	}
	if roleID == 0 {
		userID = 0
	}
	rows, err := h.repo.ListBusinessLines(userID)
	if err != nil {
		response.WriteJSON(w, response.Err(-2, err.Error()))
		return
	}
	response.WriteJSON(w, response.OK(rows))
}

func (h *Handler) businessLineCreate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteJSON(w, response.ErrDefault("请求失败"))
		return
	}
	var req businessLineCreateRequest
	if err := decodeJSON(r.Body, &req); err != nil {
		response.WriteJSON(w, response.ErrDefault("请求参数错误"))
		return
	}
	userID, _, err := userRoleFromRequest(r)
	if err != nil {
		response.WriteJSON(w, response.Err(401, "未登录"))
		return
	}
	row, err := h.createBusinessLine(req, userID)
	if err != nil {
		response.WriteJSON(w, response.ErrDefault(err.Error()))
		return
	}
	response.WriteJSON(w, response.OK(row))
}

func (h *Handler) businessLineDelete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteJSON(w, response.ErrDefault("请求失败"))
		return
	}
	var req struct {
		ID int64 `json:"id"`
	}
	if err := decodeJSON(r.Body, &req); err != nil || req.ID <= 0 {
		response.WriteJSON(w, response.ErrDefault("线路ID不能为空"))
		return
	}
	row, err := h.repo.GetBusinessLine(req.ID)
	if err != nil {
		response.WriteJSON(w, response.ErrDefault("线路不存在"))
		return
	}
	actorID, roleID, actorErr := userRoleFromRequest(r)
	if actorErr != nil || (roleID != 0 && row.UserID != actorID) {
		response.WriteJSON(w, response.Err(403, "无权操作该线路"))
		return
	}
	for _, id := range []int64{row.GZForwardID, row.IXForwardID.Int64} {
		if id <= 0 {
			continue
		}
		if f, e := h.getForwardRecord(id); e == nil && f != nil {
			_ = h.deleteForwardServicesOnNodeBatch(f, row.GZNodeID)
			if row.IXNodeID.Valid {
				_ = h.deleteForwardServicesOnNodeBatch(f, row.IXNodeID.Int64)
			}
		}
		_ = h.repo.DeleteForwardCascade(id)
	}
	if row.PathType == "frontsea" {
		if row.IXTunnelID.Valid {
			_ = h.repo.DeleteTunnelCascade(row.IXTunnelID.Int64)
		}
		_ = h.repo.DeleteTunnelCascade(row.GZTunnelID)
	} else if row.TunnelID.Valid {
		// QIX tunnels are shared and are intentionally not deleted with a line.
		_, _ = h.repo.GetTunnelName(row.TunnelID.Int64)
	}
	if err := h.repo.DeleteBusinessLine(req.ID); err != nil {
		response.WriteJSON(w, response.Err(-2, err.Error()))
		return
	}
	response.WriteJSON(w, response.OKEmpty())
}

func (h *Handler) createBusinessLine(req businessLineCreateRequest, userID int64) (*model.BusinessLine, error) {
	req.Name = strings.TrimSpace(req.Name)
	req.PathType = strings.ToLower(strings.TrimSpace(req.PathType))
	req.TargetHost = strings.TrimSpace(req.TargetHost)
	if req.Name == "" || len(req.Name) > 150 {
		return nil, errors.New("线路名称不能为空且不能超过150个字符")
	}
	if req.PathType != "frontsea" && req.PathType != "qix" {
		return nil, errors.New("路径必须是前海IX或QIX")
	}
	if req.GZNodeID <= 0 || req.EntryPort < 1 || req.EntryPort > 65535 || req.TargetPort < 1 || req.TargetPort > 65535 || req.TargetHost == "" {
		return nil, errors.New("入口和目标参数无效")
	}
	if net.ParseIP(req.TargetHost) == nil && strings.ContainsAny(req.TargetHost, "/?# ") {
		return nil, errors.New("目标Host格式无效")
	}
	if req.PathType == "frontsea" && req.IXNodeID <= 0 {
		return nil, errors.New("前海IX节点不能为空")
	}
	if req.PathType == "qix" && req.QIXTunnelID <= 0 {
		return nil, errors.New("QIX必须选择既有Tunnel")
	}

	businessLinePortMu.Lock()
	defer businessLinePortMu.Unlock()
	now := time.Now().UnixMilli()
	userName := h.repo.GetUsernameByID(userID)
	if userName == "" {
		userName = "user"
	}
	if req.PathType == "frontsea" {
		runtimeConflicts := businessLineRuntimePortConflicts[req.IXNodeID]
		if runtimeConflicts == nil {
			runtimeConflicts = make(map[int]bool)
			businessLineRuntimePortConflicts[req.IXNodeID] = runtimeConflicts
		}
		for {
			tx := h.repo.BeginTx()
			if tx == nil || tx.Error != nil {
				return nil, errors.New("无法打开数据库事务")
			}
			row, err := h.createFrontseaLineTx(tx, req, userID, userName, now, runtimeConflicts)
			_ = tx.Rollback().Error
			if err == nil {
				return row, nil
			}
			var conflict *frontseaPortConflictError
			if !errors.As(err, &conflict) {
				return nil, err
			}
			runtimeConflicts[conflict.port] = true
		}
	}
	tx := h.repo.BeginTx()
	if tx == nil || tx.Error != nil {
		return nil, errors.New("无法打开数据库事务")
	}
	defer tx.Rollback()
	return h.createQIXLineTx(tx, req, userID, userName, now)
}

func (h *Handler) createFrontseaLineTx(tx *gorm.DB, req businessLineCreateRequest, userID int64, userName string, now int64, runtimeConflicts map[int]bool) (*model.BusinessLine, error) {
	ix, err := h.repo.GetNodeRecordTx(tx, req.IXNodeID)
	if err != nil || ix == nil {
		return nil, errors.New("前海IX节点不存在")
	}
	if _, err := h.repo.GetNodeRecordTx(tx, req.GZNodeID); err != nil {
		return nil, errors.New("GZ节点不存在")
	}
	gzUsed, err := h.repo.UsedPortsOnNodeTx(tx, req.GZNodeID)
	if err != nil {
		return nil, err
	}
	if gzUsed[req.EntryPort] {
		return nil, errors.New("GZ入口端口已被占用")
	}
	used, err := h.repo.UsedPortsOnNodeTx(tx, req.IXNodeID)
	if err != nil {
		return nil, err
	}
	reserved := map[int]bool{34700: true, 34701: true, 34720: true, 34721: true, 34722: true, 34723: true, 34724: true, 34725: true}
	for port := range runtimeConflicts {
		reserved[port] = true
	}
	ixPort, err := repo.PickPortFromPool(used, reserved, frontseaPortStart, frontseaPortEnd)
	if err != nil {
		return nil, err
	}
	ixAddr := net.JoinHostPort(strings.TrimSpace(ix.ServerIP), strconv.Itoa(ixPort))
	if strings.TrimSpace(ix.ServerIP) == "" {
		return nil, errors.New("前海IX节点地址为空")
	}

	gzTunnelID, err := h.repo.CreateTunnelTx(tx, req.Name+" / GZ入口", 1, 1, 1, now, 1, nil, h.repo.NextIndexTx(tx, "tunnel"), "", "", 0)
	if err != nil {
		return nil, err
	}
	if err := h.repo.CreateChainTunnelTx(tx, gzTunnelID, "1", req.GZNodeID, sql.NullInt64{}, "round", 1, "tcp", ""); err != nil {
		return nil, err
	}
	ixTunnelID, err := h.repo.CreateTunnelTx(tx, req.Name+" / 前海IX出口", 1, 1, 1, now, 1, nil, h.repo.NextIndexTx(tx, "tunnel"), "", "", 0)
	if err != nil {
		return nil, err
	}
	if err := h.repo.CreateChainTunnelTx(tx, ixTunnelID, "1", req.IXNodeID, sql.NullInt64{}, "round", 1, "tcp", ""); err != nil {
		return nil, err
	}

	gzForward := &model.Forward{UserID: userID, UserName: userName, Name: req.Name + " / GZ入口", TunnelID: gzTunnelID, RemoteAddr: ixAddr, Strategy: "fifo", CreatedTime: now, UpdatedTime: now, Status: 1}
	if err := h.repo.CreateForwardOnTx(tx, gzForward, req.GZNodeID, req.EntryPort, ""); err != nil {
		return nil, err
	}
	ixForward := &model.Forward{UserID: userID, UserName: userName, Name: req.Name + " / 前海IX出口", TunnelID: ixTunnelID, RemoteAddr: net.JoinHostPort(req.TargetHost, strconv.Itoa(req.TargetPort)), Strategy: "fifo", CreatedTime: now, UpdatedTime: now, Status: 1}
	if err := h.repo.CreateForwardOnTx(tx, ixForward, req.IXNodeID, ixPort, ""); err != nil {
		return nil, err
	}
	row := &model.BusinessLine{UserID: userID, Name: req.Name, PathType: "frontsea", GZNodeID: req.GZNodeID, GZForwardID: gzForward.ID, GZTunnelID: gzTunnelID, IXNodeID: sql.NullInt64{Int64: req.IXNodeID, Valid: true}, IXForwardID: sql.NullInt64{Int64: ixForward.ID, Valid: true}, IXTunnelID: sql.NullInt64{Int64: ixTunnelID, Valid: true}, IXPort: sql.NullInt64{Int64: int64(ixPort), Valid: true}, EntryPort: req.EntryPort, TargetHost: req.TargetHost, TargetPort: req.TargetPort, Status: "active", CreatedTime: now, UpdatedTime: now}
	if err := h.repo.CreateBusinessLineTx(tx, row); err != nil {
		return nil, err
	}
	if err := tx.Commit().Error; err != nil {
		return nil, err
	}
	if err := h.syncForwardByID(gzForward.ID); err != nil {
		_ = h.cleanupBusinessLineRows(row)
		return nil, err
	}
	if err := h.syncForwardByID(ixForward.ID); err != nil {
		_ = h.cleanupBusinessLineRows(row)
		if isAddressAlreadyInUse(err) {
			return nil, &frontseaPortConflictError{port: ixPort, err: err}
		}
		return nil, err
	}
	return row, nil
}

func isAddressAlreadyInUse(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "address already in use")
}

func (h *Handler) createQIXLineTx(tx *gorm.DB, req businessLineCreateRequest, userID int64, userName string, now int64) (*model.BusinessLine, error) {
	tun, err := h.repo.GetTunnelRecord(req.QIXTunnelID)
	if err != nil || tun == nil {
		return nil, errors.New("QIX Tunnel不存在")
	}
	entry, err := h.repo.TunnelEntryNodeIDs(req.QIXTunnelID)
	if err != nil || len(entry) == 0 || entry[0] != req.GZNodeID {
		return nil, errors.New("QIX Tunnel入口不是指定GZ节点")
	}
	used, err := h.repo.UsedPortsOnNodeTx(tx, req.GZNodeID)
	if err != nil {
		return nil, err
	}
	if used[req.EntryPort] {
		return nil, errors.New("GZ入口端口已被占用")
	}
	f := &model.Forward{UserID: userID, UserName: userName, Name: req.Name, TunnelID: req.QIXTunnelID, RemoteAddr: net.JoinHostPort(req.TargetHost, strconv.Itoa(req.TargetPort)), Strategy: "fifo", CreatedTime: now, UpdatedTime: now, Status: 1}
	if err := h.repo.CreateForwardOnTx(tx, f, req.GZNodeID, req.EntryPort, ""); err != nil {
		return nil, err
	}
	row := &model.BusinessLine{UserID: userID, Name: req.Name, PathType: "qix", GZNodeID: req.GZNodeID, GZForwardID: f.ID, TunnelID: sql.NullInt64{Int64: req.QIXTunnelID, Valid: true}, EntryPort: req.EntryPort, TargetHost: req.TargetHost, TargetPort: req.TargetPort, Status: "active", CreatedTime: now, UpdatedTime: now}
	if err := h.repo.CreateBusinessLineTx(tx, row); err != nil {
		return nil, err
	}
	if err := tx.Commit().Error; err != nil {
		return nil, err
	}
	if err := h.syncForwardByID(f.ID); err != nil {
		_ = h.cleanupBusinessLineRows(row)
		return nil, err
	}
	return row, nil
}

func (h *Handler) syncForwardByID(id int64) error {
	f, err := h.getForwardRecord(id)
	if err != nil {
		return err
	}
	return h.syncForwardServices(f, "UpdateService", true)
}

func (h *Handler) cleanupBusinessLineRows(row *model.BusinessLine) error {
	if row == nil {
		return nil
	}
	for _, id := range []int64{row.GZForwardID, row.IXForwardID.Int64} {
		if id > 0 {
			if f, err := h.getForwardRecord(id); err == nil && f != nil {
				_ = h.deleteForwardServicesOnNodeBatch(f, row.GZNodeID)
				if row.IXNodeID.Valid {
					_ = h.deleteForwardServicesOnNodeBatch(f, row.IXNodeID.Int64)
				}
			}
			_ = h.repo.DeleteForwardCascade(id)
		}
	}
	if row.PathType == "frontsea" {
		_ = h.repo.DeleteTunnelCascade(row.GZTunnelID)
		if row.IXTunnelID.Valid {
			_ = h.repo.DeleteTunnelCascade(row.IXTunnelID.Int64)
		}
	}
	return h.repo.DeleteBusinessLine(row.ID)
}
