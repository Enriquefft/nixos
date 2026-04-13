package main

import (
	"flag"
	"log"
	"net/http"
)

func main() {
	configPath := flag.String("config", "", "path to config.toml")
	flag.Parse()

	if *configPath == "" {
		log.Fatal("--config flag is required")
	}

	cfg, err := LoadConfig(*configPath)
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("POST /webhook/sentry", NewSentryHandler(cfg))
	mux.HandleFunc("POST /webhook/linear", NewWebhookHandler(cfg))

	log.Printf("sentry-linear-bridge listening on %s", cfg.ListenAddr)
	log.Fatal(http.ListenAndServe(cfg.ListenAddr, mux))
}
