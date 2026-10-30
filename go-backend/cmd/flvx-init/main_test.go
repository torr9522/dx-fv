package main

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"

	"go-backend/internal/security"
	"go-backend/internal/store/repo"
)

func TestRunInitializesSchemaAndRandomAdministrator(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "flvx.db")
	username := "Admin_7f3a91"
	password := "unit-test-only-32-byte-password-value"
	t.Setenv("FLVX_INIT_DB_PATH", dbPath)
	t.Setenv("FLVX_INITIAL_ADMIN_USERNAME", username)
	t.Setenv("FLVX_INITIAL_ADMIN_PASSWORD", password)

	if err := run(); err != nil {
		t.Fatalf("run() error = %v", err)
	}

	r, err := repo.Open(dbPath)
	if err != nil {
		t.Fatalf("open initialized database: %v", err)
	}
	defer r.Close()
	user, err := r.GetUserByID(1)
	if err != nil {
		t.Fatalf("read administrator: %v", err)
	}
	if user == nil || user.User != username {
		t.Fatalf("administrator = %+v, want username %q", user, username)
	}
	matched, legacy := security.VerifyPassword(user.Pwd, password)
	if !matched || legacy {
		t.Fatalf("administrator password was not stored as a modern hash")
	}

	raw, err := os.ReadFile(dbPath)
	if err != nil {
		t.Fatalf("read database: %v", err)
	}
	if bytes.Contains(raw, []byte(password)) {
		t.Fatal("database contains the plaintext administrator password")
	}
	info, err := os.Stat(dbPath)
	if err != nil {
		t.Fatalf("stat database: %v", err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("database mode = %o, want 600", info.Mode().Perm())
	}
}

func TestRunRefusesExistingDatabase(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "flvx.db")
	if err := os.WriteFile(dbPath, []byte("existing"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FLVX_INIT_DB_PATH", dbPath)
	t.Setenv("FLVX_INITIAL_ADMIN_USERNAME", "Admin_7f3a91")
	t.Setenv("FLVX_INITIAL_ADMIN_PASSWORD", "unit-test-only-32-byte-password-value")

	if err := run(); err == nil {
		t.Fatal("run() accepted an existing database")
	}
	raw, err := os.ReadFile(dbPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(raw) != "existing" {
		t.Fatalf("existing database was modified: %q", raw)
	}
}

func TestRunRejectsWeakCredentials(t *testing.T) {
	tests := []struct {
		name     string
		username string
		password string
	}{
		{name: "short username", username: "admin", password: "unit-test-only-32-byte-password-value"},
		{name: "short password", username: "Admin_7f3a91", password: "too-short"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("FLVX_INIT_DB_PATH", filepath.Join(t.TempDir(), "flvx.db"))
			t.Setenv("FLVX_INITIAL_ADMIN_USERNAME", tc.username)
			t.Setenv("FLVX_INITIAL_ADMIN_PASSWORD", tc.password)
			if err := run(); err == nil {
				t.Fatal("run() accepted weak credentials")
			}
		})
	}
}
