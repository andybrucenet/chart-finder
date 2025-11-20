# Makefile, ABr
#
# chart-finder: Backend Makefile

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
$(eval $(shell $(ROOT)/scripts/cf-env-vars-to-make.sh))
SLN ?= $(ROOT)/src/backend/backend.sln
DOTNET ?= dotnet

BUILD_CONFIGURATION ?= Debug

.PHONY: all restore build-number configs build build-core test clean veryclean rebuild deploy publish swagger swagger-clean swagger-rebuild

SWAGGER_DOC_NAME ?= v1
SWAGGER_OUTPUT ?= $(ROOT)/docs/api/chart-finder-openapi-$(SWAGGER_DOC_NAME).json
SWAGGER_DLL ?= $(ROOT)/src/backend/ChartFinder.Api/bin/$(BUILD_CONFIGURATION)/net8.0/ChartFinder.Api.dll
SWAGGER_SOURCES := $(shell find $(ROOT)/src/backend -name '*.cs')

log = @printf '\n***** %s\n' "$(1)"

all: build

restore:
	$(call log,BACKEND: restore)
	@echo "[backend] dotnet restore $(SLN)"
	@$(DOTNET) restore "$(SLN)"

build:
	$(call log,BACKEND: build)
	@$(MAKE) build-core BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)

build-core: build-number configs
	@echo "[backend] dotnet restore $(SLN)"
	@$(DOTNET) restore "$(SLN)"
	@echo "[backend] dotnet build $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) build "$(SLN)" -c $(BUILD_CONFIGURATION)

configs:
	$(call log,BACKEND: configs)
	@echo "[backend] $(ROOT)/scripts/backend-env-metadata.sh"
	@"$(ROOT)/scripts/backend-env-metadata.sh"

build-number:
	$(call log,BACKEND: build-number)
	@echo "[backend] $(ROOT)/scripts/backend-src-sig.sh"
	@"$(ROOT)/scripts/backend-src-sig.sh"

test:
	$(call log,BACKEND: test)
	@echo "[backend] dotnet test $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) test "$(SLN)" -c $(BUILD_CONFIGURATION)
	@$(MAKE) -C "$(ROOT)/backend/clients" test

clean:
	$(call log,BACKEND: clean)
	@echo "[backend] dotnet clean $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) clean "$(SLN)" -c $(BUILD_CONFIGURATION)

veryclean: clean
	$(call log,BACKEND: veryclean)
	@echo "[backend] No extra cleanup defined (extend this target as needed)."

rebuild:
	$(call log,BACKEND: rebuild)
	@$(MAKE) clean BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)
	@$(MAKE) build BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)

publish:
	$(call log,BACKEND: publish)
	@$(MAKE) deploy BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)

deploy:
	$(call log,BACKEND: deploy)
	@if [ "$${CF_LOCAL_CLOUD_PROVIDER:-aws}" != "aws" ]; then \
		echo "ERROR: backend deploy currently supports only aws (set CF_LOCAL_CLOUD_PROVIDER=aws)"; \
		exit 1; \
	fi
	@echo "[backend] $(ROOT)/scripts/aws-sam-preflight.sh"
	@"$(ROOT)"/scripts/aws-sam-preflight.sh
	@echo "[backend] $(ROOT)/scripts/aws-sam-deploy.sh build"
	@"$(ROOT)"/scripts/aws-sam-deploy.sh build

$(SWAGGER_OUTPUT): $(SWAGGER_SOURCES)
	@mkdir -p $(dir $(SWAGGER_OUTPUT))
	@echo "[backend] curl \"$${CF_LOCAL_AWS_BASE_URI}swagger/v1/swagger.json\""
	@source "$(ROOT)/scripts/cf-env-vars.sh" 'source-only' && \
	  tmpfile="$$(mktemp "$(dir $(SWAGGER_OUTPUT))/chart-finder-openapi-$(SWAGGER_DOC_NAME).XXXXXX.json")" && \
	  curl --fail --silent --show-error "$${CF_LOCAL_AWS_BASE_URI}swagger/v1/swagger.json" >"$$tmpfile" && \
	  if [ ! -f "$(SWAGGER_OUTPUT)" ] || ! cmp -s "$$tmpfile" "$(SWAGGER_OUTPUT)"; then \
	    mv "$$tmpfile" "$(SWAGGER_OUTPUT)"; \
	    echo "[backend] OpenAPI spec updated"; \
	    cd clients && $(MAKE); \
	  else \
	    rm "$$tmpfile"; \
	    echo "[backend] OpenAPI spec unchanged"; \
	  fi

swagger: $(SWAGGER_OUTPUT)

swagger-clean:
	$(call log,BACKEND: swagger clean)
	@rm -f $(SWAGGER_OUTPUT)

swagger-rebuild: swagger-clean swagger
