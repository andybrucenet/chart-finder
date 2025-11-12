FRONTEND_DIR ?= src/frontend/chart-finder-mobile
NPM ?= npm

.PHONY: help setup-dev-env backend backend-build backend-test backend-clean backend-rebuild backend-all backend-deploy backend-swagger frontend frontend-clean \
	infra infra-build infra-stage infra-status infra-uri infra-publish infra-smoke infra-clean

log = @printf '\n***** %s\n' "$(1)"

help:
	@printf "%s\n" \
		"Available targets:" \
		"  setup-dev-env     Hydrate local environment via scripts/setup-dev-env.sh" \
		"  backend-build     Restore and build the backend solution (delegates to backend/Makefile)" \
		"  backend-all       Build + test backend projects" \
		"  backend-test      Run backend tests" \
		"  backend-clean     Clean backend build artifacts" \
		"  backend-rebuild   Clean then build backend projects" \
		"  backend-deploy    SAM preflight + deploy (delegates to backend/Makefile)" \
		"  backend-swagger   Build and export OpenAPI spec (delegates to backend/Makefile)" \
		"  infra-build       Run SAM preflight (delegates to infra/Makefile)" \
		"  infra-stage       Alias for infra-build" \
		"  infra-publish     Deploy SAM stack (delegates to infra/Makefile)" \
		"  infra-status      Status of SAM stack (delegates to infra/Makefile)" \
		"  infra-uri         Current URI endpoint of SAM stack (delegates to infra/Makefile)" \
		"  infra-smoke       Hit deployed utils endpoint to verify deployment" \
		"  frontend          Install frontend dependencies (Expo project)" \
		"  frontend-clean    Remove frontend node_modules cache"

setup-dev-env:
	$(call log,SETUP: dev-env)
	@./scripts/setup-dev-env.sh

backend backend-all:
	@$(MAKE) -C backend all

backend-build:
	@$(MAKE) -C backend build

backend-test:
	@$(MAKE) -C backend test

backend-clean:
	@$(MAKE) -C backend clean

backend-rebuild:
	@$(MAKE) -C backend rebuild

backend-deploy:
	@$(MAKE) -C backend deploy

backend-swagger:
	@$(MAKE) -C backend swagger

infra:
	@$(MAKE) -C infra build

infra-build:
	@$(MAKE) -C infra build

infra-stage:
	@$(MAKE) -C infra stage

infra-publish:
	@$(MAKE) -C infra publish

infra-status:
	@$(MAKE) -C infra status

infra-uri:
	@$(MAKE) -C infra uri

infra-smoke:
	@$(MAKE) -C infra smoke

infra-clean:
	@$(MAKE) -C infra clean

frontend:
	$(call log,FRONTEND: install)
	@echo "$(NPM) install --prefix $(FRONTEND_DIR)"
	@$(NPM) install --prefix $(FRONTEND_DIR)

frontend-clean:
	$(call log,FRONTEND: clean)
	@echo "rm -rf $(FRONTEND_DIR)/node_modules"
	@rm -rf $(FRONTEND_DIR)/node_modules
