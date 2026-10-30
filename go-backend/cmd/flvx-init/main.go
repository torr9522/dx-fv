package main

import (
	"errors"
	"fmt"
	"os"
	"regexp"
	"strings"
	"time"

	"go-backend/internal/security"
	"go-backend/internal/store/model"
	"go-backend/internal/store/repo"
)

const schemaVersion = 8

var usernamePattern = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_-]{7,31}$`)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "initialize database: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	dbPath := strings.TrimSpace(os.Getenv("FLVX_INIT_DB_PATH"))
	username := strings.TrimSpace(os.Getenv("FLVX_INITIAL_ADMIN_USERNAME"))
	password := os.Getenv("FLVX_INITIAL_ADMIN_PASSWORD")

	if dbPath == "" {
		return errors.New("FLVX_INIT_DB_PATH is required")
	}
	if !usernamePattern.MatchString(username) {
		return errors.New("administrator username must be 8-32 characters and start with a letter")
	}
	if len(password) < 24 {
		return errors.New("administrator password must contain at least 24 characters")
	}
	if _, err := os.Stat(dbPath); err == nil {
		return fmt.Errorf("database already exists at %s", dbPath)
	} else if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("inspect database path: %w", err)
	}

	r, err := repo.Open(dbPath)
	if err != nil {
		return fmt.Errorf("create database: %w", err)
	}
	defer r.Close()

	hash, err := security.HashPassword(password)
	if err != nil {
		return fmt.Errorf("hash administrator password: %w", err)
	}
	if err := r.UpdateUserNameAndPassword(1, username, hash, time.Now().UnixMilli()); err != nil {
		return fmt.Errorf("set administrator credentials: %w", err)
	}

	var version model.SchemaVersion
	if err := r.DB().First(&version).Error; err != nil {
		return fmt.Errorf("read schema version: %w", err)
	}
	if version.Version != schemaVersion {
		return fmt.Errorf("unexpected schema version %d, require %d", version.Version, schemaVersion)
	}

	var integrity string
	if err := r.DB().Raw("PRAGMA integrity_check").Scan(&integrity).Error; err != nil {
		return fmt.Errorf("run SQLite integrity check: %w", err)
	}
	if integrity != "ok" {
		return fmt.Errorf("SQLite integrity check returned %q", integrity)
	}
	if err := os.Chmod(dbPath, 0o600); err != nil {
		return fmt.Errorf("protect database permissions: %w", err)
	}

	fmt.Printf("database initialized: schema=%d administrator=%s\n", version.Version, username)
	return nil
}
