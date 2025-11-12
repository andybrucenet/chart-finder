ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
SCRIPTS_DIR := $(ROOT)/scripts
STACK_STATE_SCRIPT := $(SCRIPTS_DIR)/aws-sam-stack-state.sh

.PHONY: configs build stage publish status uri smoke clean

log = @printf '\n***** %s\n' "$(1)"

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
	@echo "[infra] $(SCRIPTS_DIR)/aws-sam-deploy.sh build"
	@"$(SCRIPTS_DIR)"/aws-sam-deploy.sh build

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
	@response="$$(\"$(STACK_STATE_SCRIPT)\")"; \
		endpoint="$$(printf '%s\n' "$$response" | jq -r '.Outputs[] | select(.OutputKey=="ApiInvokeUrl").OutputValue')"; \
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
		curl --fail --silent --show-error "$$url" | jq '.'

clean:
	$(call log,INFRA: clean)
	@echo "[infra] No dedicated infra clean step defined."
