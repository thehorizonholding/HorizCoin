package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"time"
)

// Simple placeholder oracle node exposing a mock epoch report endpoint.

type MockReport struct {
	Epoch      uint64 `json:"epoch"`
	Generated  int64  `json:"generated_at"`
	TotalNodes int    `json:"total_nodes"`
	MerkleRoot string `json:"merkle_root"`
	Note       string `json:"note"`
}

var currentEpoch uint64 = 1

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	mux.HandleFunc("/report", func(w http.ResponseWriter, _ *http.Request) {
		report := MockReport{
			Epoch:      currentEpoch,
			Generated:  time.Now().Unix(),
			TotalNodes: 100 + rand.Intn(20),
			MerkleRoot: "0xDEADBEEF",
			Note:       "Mock report - placeholder. Not cryptographically signed.",
		}
		_ = json.NewEncoder(w).Encode(report)
	})

	go func() {
		ticker := time.NewTicker(15 * time.Second)
		for range ticker.C {
			currentEpoch++
		}
	}()

	addr := ":8081"
	log.Printf("Oracle mock node listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
} 
