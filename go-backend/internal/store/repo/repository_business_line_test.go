package repo

import "testing"

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
