# Makefile, ABr
#
# chart-finder: Backend client tooling

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
$(eval $(shell $(ROOT)/scripts/cf-env-vars-to-make.sh))
CLIENTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
STATE_DIR := $(ROOT)/.local/state
API_SPEC := $(ROOT)/docs/api/chart-finder-openapi-v1.json
CACHED_API_SPEC := $(STATE_DIR)/chart-finder-openapi-v1.json
NPM ?= npm

.PHONY: all setup build rebuild clean veryclean api-contract-status api-contract-update build-impl summary test

log = @printf '\n***** %s\n' "$(1)"

all: build

setup:
	$(call log,CLIENTS: setup tooling)
	@"$(CLIENTS_DIR)/scripts/npm-login.sh"
	@cd "$(CLIENTS_DIR)" && $(NPM) install
	@mkdir -p "$(STATE_DIR)"

define run_if_changed
	@spec_changed=1; \
	if [ -f "$(CACHED_API_SPEC)" ] && cmp -s "$(API_SPEC)" "$(CACHED_API_SPEC)"; then \
		spec_changed=0; \
	fi; \
	if [ $$spec_changed -eq 0 ] && [ -z "$${CLIENTS_FORCE:-}" ]; then \
		echo "[clients] CMD_SKIP (OpenAPI spec unchanged; use CLIENTS_FORCE=1 to override)"; \
		$(2); \
	else \
		if [ $$spec_changed -eq 0 ]; then \
			echo "[clients] CMD_RUN (CLIENTS_FORCE set)"; \
		else \
			echo "[clients] CMD_RUN (OpenAPI spec changed)"; \
		fi; \
		$(1); \
	fi
endef

build: setup
	$(call run_if_changed,$(MAKE) build-impl,echo "[clients] OpenAPI spec unchanged; skipping build.")

test:
	$(call log,CLIENTS: test)
	@echo "[clients] No automated tests defined; skipping."

rebuild: clean build

build-impl:
	$(call log,CLIENTS: generate all)
	@cd "$(CLIENTS_DIR)" && $(NPM) run generate:all
	$(call log,CLIENTS: prepare dotnet package)
	@"$(CLIENTS_DIR)/scripts/clients-prepare-dotnet.sh"
	$(call log,CLIENTS: prepare npm package)
	@"$(CLIENTS_DIR)/scripts/clients-prepare-npm.sh"
	$(call log,CLIENTS: prepare dart package)
	@"$(CLIENTS_DIR)/scripts/clients-prepare-dart.sh"
	$(call log,CLIENTS: summary)
	@"$(CLIENTS_DIR)/scripts/clients-summary.sh"
ifneq ($(CLIENTS_VERIFY),)
	@read -p "[clients] Press Enter to continue publishing (Ctrl+C to abort)... " _
endif
	$(call log,CLIENTS: publish all)
	@"$(CLIENTS_DIR)/scripts/clients-publish-all.sh"
	@$(MAKE) api-contract-update

summary:
	$(call log,CLIENTS: summary)
	@"$(CLIENTS_DIR)/scripts/clients-summary.sh"

clean:
	$(call log,CLIENTS: clean)
	rm -Rf "$(ROOT)/.local/backend/clients"

veryclean: clean
	$(call log,CLIENTS: veryclean)
	rm -Rf "$(CLIENTS_DIR)/node_modules"

api-contract-status:
	$(call run_if_changed,echo CHANGED,echo Unchanged)

api-contract-update:
	@$(CLIENTS_DIR)/scripts/cond-copy.sh "$(API_SPEC)" "$(CACHED_API_SPEC)"
	@ls -la "$(API_SPEC)" "$(CACHED_API_SPEC)"
