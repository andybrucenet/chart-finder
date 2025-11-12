FRONTEND_DIR ?= src/frontend/chart-finder-mobile
NPM ?= npm

.PHONY: help setup-dev-env backend backend-build backend-test backend-clean backend-rebuild backend-all backend-deploy backend-swagger frontend frontend-clean

log = @printf '\n***** %s\n' "$(1)"

help:
	@printf "%s\n" \
		"Available targets:" \
		"  setup-dev-env     Hydrate local environment via scripts/setup-dev-env.sh" \
		"  backend-build     Restore and build the backend solution (delegates to src/backend/Makefile)" \
		"  backend-all       Build + test backend projects" \
		"  backend-test      Run backend tests" \
		"  backend-clean     Clean backend build artifacts" \
		"  backend-rebuild   Clean then build backend projects" \
		"  backend-deploy    SAM preflight + deploy (delegates to src/backend/Makefile)" \
		"  backend-swagger   Build and export OpenAPI spec (delegates to src/backend/Makefile)" \
		"  frontend          Install frontend dependencies (Expo project)" \
		"  frontend-clean    Remove frontend node_modules cache"

setup-dev-env:
	$(call log,SETUP: dev-env)
	@./scripts/setup-dev-env.sh

backend backend-all:
	@$(MAKE) -C src/backend all

backend-build:
	@$(MAKE) -C src/backend build

backend-test:
	@$(MAKE) -C src/backend test

backend-clean:
	@$(MAKE) -C src/backend clean

backend-rebuild:
	@$(MAKE) -C src/backend rebuild

backend-deploy:
	@$(MAKE) -C src/backend deploy

backend-swagger:
	@$(MAKE) -C src/backend swagger

frontend:
	$(call log,FRONTEND: install)
	@echo "$(NPM) install --prefix $(FRONTEND_DIR)"
	@$(NPM) install --prefix $(FRONTEND_DIR)

frontend-clean:
	$(call log,FRONTEND: clean)
	@echo "rm -rf $(FRONTEND_DIR)/node_modules"
	@rm -rf $(FRONTEND_DIR)/node_modules
