APP=horizcoin
BIN_DIR=bin

.PHONY: all build clean run test

all: build

build:
	@mkdir -p $(BIN_DIR)
	go build -o $(BIN_DIR)/$(APP) ./cmd/horizcoin

run: build
	./$(BIN_DIR)/$(APP) demo

test:
	go test ./...

clean:
	rm -rf $(BIN_DIR)
