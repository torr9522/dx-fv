package handler

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
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

func TestFrontseaReservedPortsProtectsInfrastructureRange(t *testing.T) {
	reserved := frontseaReservedPorts()
	for port := frontseaPortStart; port <= frontseaReservedPortEnd; port++ {
		if !reserved[port] {
			t.Fatalf("expected port %d to be reserved", port)
		}
	}
	if reserved[frontseaReservedPortEnd+1] {
		t.Fatalf("port %d must remain available to the DX pool", frontseaReservedPortEnd+1)
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
		ID: 1, Name: "test", PathType: "frontsea", ProtocolMode: model.BusinessLineProtocolTCP,
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
	if !strings.Contains(text, `"protocolMode":"tcp"`) {
		t.Fatalf("expected protocol mode, got %s", text)
	}
}

func TestBusinessLineProtocolModeValidation(t *testing.T) {
	if got := normalizeBusinessLineProtocolMode(""); got != model.BusinessLineProtocolTCPUDP {
		t.Fatalf("empty mode default = %q", got)
	}
	for _, mode := range []string{model.BusinessLineProtocolTCPUDP, model.BusinessLineProtocolTCP} {
		if !validBusinessLineProtocolMode(mode) {
			t.Fatalf("expected %q to be valid", mode)
		}
	}
	for _, mode := range []string{"udp", "tcp+udp", "both"} {
		if validBusinessLineProtocolMode(mode) {
			t.Fatalf("expected %q to be invalid", mode)
		}
	}
}

func TestRunForwardProtocolTransitionsRollsBackCompletedHopsInReverse(t *testing.T) {
	forwards := []*forwardRecord{{ID: 1}, {ID: 2}}
	calls := make([]string, 0)
	err := runForwardProtocolTransitions(forwards, model.BusinessLineProtocolTCPUDP, model.BusinessLineProtocolTCP, func(forward *forwardRecord, mode string) error {
		calls = append(calls, fmt.Sprintf("%d:%s", forward.ID, mode))
		if forward.ID == 2 && mode == model.BusinessLineProtocolTCP {
			return errors.New("injected second-hop failure")
		}
		return nil
	})
	if err == nil {
		t.Fatal("expected transition failure")
	}
	want := []string{"1:tcp", "2:tcp", "1:tcp_udp"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("calls = %v, want %v", calls, want)
	}
}
