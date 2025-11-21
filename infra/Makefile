# Makefile, ABr
#
# chart-finder: Infra Makefile

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

# import chart-finder environment
$(shell $(ROOT)/scripts/cf-env-vars-to-make.sh)
include $(ROOT)/.local/state/cf-env-vars.mk

SCRIPTS_DIR := $(ROOT)/scripts
STACK_STATE_SCRIPT := $(SCRIPTS_DIR)/aws-sam-stack-state.sh
STACK_DEPLOYMENT_MODE ?= $(CF_STACK_DEPLOYMENT_MODE)
SAM_DEPLOY_ENV :=
ifeq ($(STACK_DEPLOYMENT_MODE),batch)
SAM_DEPLOY_ENV := AWS_SAM_DEPLOY_OPTION_NO_CONFIRM=1
endif

.PHONY: all configs build stage publish status uri smoke test clean veryclean rebuild

log = @printf '\n***** %s\n' "$(1)"

all: build

configs:
	$(call log,INFRA: configs)
	@echo "[infra] $(SCRIPTS_DIR)/sync-configs.sh"
	@"$(SCRIPTS_DIR)"/sync-configs.sh

build stage: configs
	$(call log,INFRA: build)
	@echo "[infra] $(SCRIPTS_DIR)/aws-sam-preflight.sh"
	@"$(SCRIPTS_DIR)"/aws-sam-preflight.sh

publish:
	$(call log,INFRA: publish)
	@if [ "$${CF_LOCAL_CLOUD_PROVIDER:-aws}" != "aws" ]; then \
		echo "ERROR: infra publish currently supports only aws (set CF_LOCAL_CLOUD_PROVIDER=aws)"; \
		exit 1; \
	fi
	@echo "[infra] $(SCRIPTS_DIR)/aws-sam-deploy.sh build (mode: $(STACK_DEPLOYMENT_MODE))"
	@$(SAM_DEPLOY_ENV) "$(SCRIPTS_DIR)"/aws-sam-deploy.sh build
	@$(MAKE) smoke

status:
	$(call log,INFRA: status)
	@if [ "$${CF_LOCAL_CLOUD_PROVIDER:-aws}" != "aws" ]; then \
		echo "ERROR: infra status currently supports only aws (set CF_LOCAL_CLOUD_PROVIDER=aws)"; \
		exit 1; \
	fi
	@echo "[infra] $(SCRIPTS_DIR)/aws-sam-deploy.sh status"
	@"$(SCRIPTS_DIR)"/aws-sam-deploy.sh status


uri:
	$(call log,INFRA: uri)
	@if [ "$${CF_LOCAL_CLOUD_PROVIDER:-aws}" != "aws" ]; then \
		echo "ERROR: infra status currently supports only aws (set CF_LOCAL_CLOUD_PROVIDER=aws)"; \
		exit 1; \
	fi
	@echo "[infra] $(SCRIPTS_DIR)/aws-sam-deploy.sh uri"
	@"$(SCRIPTS_DIR)"/aws-sam-deploy.sh uri

smoke:
	$(call log,INFRA: smoke)
	@if [ "$${CF_LOCAL_CLOUD_PROVIDER:-aws}" != "aws" ]; then \
		echo "ERROR: infra smoke currently supports only aws (set CF_LOCAL_CLOUD_PROVIDER=aws)"; \
		exit 1; \
	fi
	@echo "[infra] $(STACK_STATE_SCRIPT)"
	@output="$$( $(STACK_STATE_SCRIPT) )"; \
		endpoint="$$(printf '%s\n' "$$output" | jq -r '.Outputs[] | select(.OutputKey=="ApiInvokeUrl").OutputValue')"; \
		if [ -z "$$endpoint" ] || [ "$$endpoint" = "null" ]; then \
			echo "ERROR: Unable to locate ApiInvokeUrl in stack outputs"; \
			exit 1; \
		fi; \
		base="$$endpoint"; \
		base="$${base%calculator/v1/}"; \
		if [ -z "$$base" ]; then \
			echo "ERROR: Derived base URL is empty"; \
			exit 1; \
		fi; \
		url="$$base"utils/v1/version; \
		echo "[infra] curl --fail --silent --show-error $$url"; \
		curl --fail --silent --show-error "$$url" | jq '.'; \
		current_uri="$${CF_LOCAL_AWS_BASE_URI:-}"; \
		if [ "$$base" != "$$current_uri" ]; then \
			echo "[infra] Updating CF_LOCAL_AWS_BASE_URI to $$base"; \
			bash -lc "source $(ROOT)/scripts/lcl-os-checks.sh source-only && lcl_dot_local_settings_update $(ROOT) CF_LOCAL_AWS_BASE_URI '$$base'"; \
		fi

clean:
	$(call log,INFRA: clean)
	@echo "[infra] No dedicated infra clean step defined."

test:
	$(call log,INFRA: test)
	@echo "[infra] No automated infra tests defined; skipping."

veryclean: clean
	$(call log,INFRA: veryclean)
	@echo "[infra] No extra cleanup defined (extend this target as needed)."

rebuild:
	$(call log,INFRA: rebuild)
	@$(MAKE) clean
	@$(MAKE) build
