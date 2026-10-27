package handler

import (
	"errors"
	"testing"
)

func TestIsAddressAlreadyInUse(t *testing.T) {
	if !isAddressAlreadyInUse(errors.New("listen tcp 0.0.0.0:34702: bind: address already in use")) {
		t.Fatal("expected bind conflict to be recognized")
	}
	if isAddressAlreadyInUse(errors.New("node offline")) {
		t.Fatal("unrelated agent failures must not trigger a port retry")
	}
}
