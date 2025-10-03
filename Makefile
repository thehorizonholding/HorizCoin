SHELL := /bin/bash
APP_DIR=app
.PHONY: install dev build migrate migrate-deploy lint typecheck test seed format
install: ; cd $(APP_DIR) && npm install
dev: ; cd $(APP_DIR) && npm run dev
build: ; cd $(APP_DIR) && npm run build
migrate: ; cd $(APP_DIR) && npx prisma migrate dev
migrate-deploy: ; cd $(APP_DIR) && npx prisma migrate deploy
lint: ; cd $(APP_DIR) && npm run lint
typecheck: ; cd $(APP_DIR) && npm run typecheck
test: ; cd $(APP_DIR) && npm test
seed: ; cd $(APP_DIR) && npm run seed
format: ; cd $(APP_DIR) && npx prettier --write .
