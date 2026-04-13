package main

import (
	"fmt"
	"os"

	"github.com/BurntSushi/toml"
)

type AIConfig struct {
	APIKey  string `toml:"api_key"`
	BaseURL string `toml:"base_url"`
	Model   string `toml:"model"`
}

type Config struct {
	AI         AIConfig        `toml:"ai"`
	Linear     LinearConfig    `toml:"linear"`
	ListenAddr string          `toml:"listen_addr"`
	Projects   []ProjectConfig `toml:"projects"`
	Sentry     SentryConfig    `toml:"sentry"`
}

type LinearConfig struct {
	APIKey        string `toml:"api_key"`
	TeamID        string `toml:"team_id"`
	WebhookSecret string `toml:"webhook_secret"`
}

type ProjectConfig struct {
	ID            string `toml:"id"`
	SentryProject string `toml:"sentry_project"`
	Workspace     string `toml:"workspace"`
}

type SentryConfig struct {
	WebhookSecret string `toml:"webhook_secret"`
}

func LoadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading config file: %w", err)
	}

	var cfg Config
	if err := toml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("parsing config file: %w", err)
	}

	if cfg.ListenAddr == "" {
		return nil, fmt.Errorf("listen_addr is required")
	}
	if cfg.Sentry.WebhookSecret == "" {
		return nil, fmt.Errorf("sentry.webhook_secret is required")
	}
	if cfg.Linear.APIKey == "" {
		return nil, fmt.Errorf("linear.api_key is required")
	}
	if cfg.Linear.TeamID == "" {
		return nil, fmt.Errorf("linear.team_id is required")
	}
	if cfg.Linear.WebhookSecret == "" {
		return nil, fmt.Errorf("linear.webhook_secret is required")
	}
	if cfg.AI.BaseURL == "" {
		return nil, fmt.Errorf("ai.base_url is required")
	}
	if cfg.AI.APIKey == "" {
		return nil, fmt.Errorf("ai.api_key is required")
	}
	if cfg.AI.Model == "" {
		return nil, fmt.Errorf("ai.model is required")
	}
	if len(cfg.Projects) == 0 {
		return nil, fmt.Errorf("at least one project is required")
	}
	for i, p := range cfg.Projects {
		if p.ID == "" {
			return nil, fmt.Errorf("project[%d]: id is required", i)
		}
		if p.Workspace == "" {
			return nil, fmt.Errorf("project[%d]: workspace is required", i)
		}
	}

	return &cfg, nil
}
