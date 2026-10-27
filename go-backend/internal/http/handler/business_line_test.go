package handler

import (
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"go-backend/internal/store/model"
)

func TestIsAddressAlreadyInUse(t *testing.T) {
	if !isAddressAlreadyInUse(errors.New("listen tcp 0.0.0.0:34702: bind: address already in use")) {
		t.Fatal("expected bind conflict to be recognized")
	}
	if isAddressAlreadyInUse(errors.New("node offline")) {
		t.Fatal("unrelated agent failures must not trigger a port retry")
	}
}

func TestConfiguredBusinessLineResource(t *testing.T) {
	t.Setenv(businessLineGZNodeEnv, " 12 ")
	id, err := configuredBusinessLineResource(businessLineGZNodeEnv)
	if err != nil || id != 12 {
		t.Fatalf("configuredBusinessLineResource() = %d, %v", id, err)
	}

	t.Setenv(businessLineGZNodeEnv, "invalid")
	if _, err := configuredBusinessLineResource(businessLineGZNodeEnv); err == nil {
		t.Fatal("expected invalid configured resource to fail")
	}
}

func TestBusinessLineValidationMessages(t *testing.T) {
	h := &Handler{}
	t.Setenv(businessLineGZNodeEnv, "1")
	t.Setenv(businessLineFrontseaNodeEnv, "2")
	t.Setenv(businessLineQIXTunnelEnv, "262")

	tests := []struct {
		name string
		req  businessLineCreateRequest
		want string
	}{
		{
			name: "invalid entry port",
			req:  businessLineCreateRequest{Name: "test", PathType: "frontsea", EntryPort: 0, TargetHost: "127.0.0.1", TargetPort: 80},
			want: "GZ入口端口必须是 1-65535",
		},
		{
			name: "empty target",
			req:  businessLineCreateRequest{Name: "test", PathType: "frontsea", EntryPort: 10001, TargetPort: 80},
			want: "落地 IP / Host 不能为空",
		},
		{
			name: "invalid target port",
			req:  businessLineCreateRequest{Name: "test", PathType: "qix", EntryPort: 10001, TargetHost: "127.0.0.1", TargetPort: 70000},
			want: "落地端口必须是 1-65535",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := h.createBusinessLine(tt.req, 0)
			if err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("error = %v, want %q", err, tt.want)
			}
		})
	}
}

func TestBusinessLineResponseSerializesNullableIDsAsNumbers(t *testing.T) {
	row := &model.BusinessLine{
		ID: 1, Name: "test", PathType: "frontsea",
		IXPort:   sql.NullInt64{Int64: 34705, Valid: true},
		TunnelID: sql.NullInt64{},
	}
	payload, err := json.Marshal(newBusinessLineResponse(row))
	if err != nil {
		t.Fatalf("marshal response: %v", err)
	}
	text := string(payload)
	if !strings.Contains(text, `"ixPort":34705`) {
		t.Fatalf("expected numeric ixPort, got %s", text)
	}
	if !strings.Contains(text, `"tunnelId":null`) {
		t.Fatalf("expected null tunnelId, got %s", text)
	}
	if strings.Contains(text, "Int64") || strings.Contains(text, "Valid") {
		t.Fatalf("response leaked sql.NullInt64 shape: %s", text)
	}
}
