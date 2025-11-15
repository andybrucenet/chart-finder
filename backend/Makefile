# Makefile, ABr
#
# chart-finder: Backend Makefile
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
SLN ?= $(ROOT)/ChartFinder.sln
DOTNET ?= dotnet

BUILD_CONFIGURATION ?= Debug

.PHONY: all build-number build test clean rebuild deploy swagger swagger-clean

SWAGGER_DOC_NAME ?= v1
SWAGGER_OUTPUT ?= $(ROOT)/docs/api/backend.$(SWAGGER_DOC_NAME).json
SWAGGER_DLL ?= $(ROOT)/src/backend/ChartFinder.Api/bin/$(BUILD_CONFIGURATION)/net8.0/ChartFinder.Api.dll
SWAGGER_SOURCES := $(shell find $(ROOT)/src/backend -name '*.cs')

log = @printf '\n***** %s\n' "$(1)"

all: swagger

build: build-number
	$(call log,BACKEND: build)
	@echo "[backend] dotnet restore $(SLN)"
	@$(DOTNET) restore "$(SLN)"
	@echo "[backend] dotnet build $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) build "$(SLN)" -c $(BUILD_CONFIGURATION)

build-number:
	$(call log,BACKEND: build-number)
	@echo "[backend] $(ROOT)/scripts/backend-src-sig.sh"
	@"$(ROOT)/scripts/backend-src-sig.sh"

test:
	$(call log,BACKEND: test)
	@echo "[backend] dotnet test $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) test "$(SLN)" -c $(BUILD_CONFIGURATION)

clean:
	$(call log,BACKEND: clean)
	@echo "[backend] dotnet clean $(SLN) -c $(BUILD_CONFIGURATION)"
	@$(DOTNET) clean "$(SLN)" -c $(BUILD_CONFIGURATION)

rebuild:
	$(call log,BACKEND: rebuild)
	@$(MAKE) clean BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)
	@$(MAKE) build BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)

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
	@echo "[backend] dotnet tool restore (nswag)"
	@cd "$(ROOT)/backend" && $(DOTNET) tool restore
	@$(MAKE) build BUILD_CONFIGURATION=$(BUILD_CONFIGURATION)
	$(call log,BACKEND: swagger)
	@tmpfile="$$(mktemp "$(dir $(SWAGGER_OUTPUT))/backend.$(SWAGGER_DOC_NAME).XXXXXX.json")" && \
	echo "[backend] DOTNET_ROLL_FORWARD=Major ASPNETCORE_ENVIRONMENT=Development dotnet tool run nswag -- aspnetcore2openapi /project:$(ROOT)/src/backend/ChartFinder.Api/ChartFinder.Api.csproj /configuration:$(BUILD_CONFIGURATION) /documentName:$(SWAGGER_DOC_NAME) /AspNetCoreEnvironment:Development /output:$$tmpfile" && \
	cd "$(ROOT)/backend" && DOTNET_ROLL_FORWARD=Major ASPNETCORE_ENVIRONMENT=Development $(DOTNET) tool run nswag -- aspnetcore2openapi /project:"$(ROOT)/src/backend/ChartFinder.Api/ChartFinder.Api.csproj" /configuration:"$(BUILD_CONFIGURATION)" /documentName:"$(SWAGGER_DOC_NAME)" /AspNetCoreEnvironment:Development /output:"$$tmpfile" && \
	if [ ! -f "$(SWAGGER_OUTPUT)" ] || ! cmp -s "$$tmpfile" "$(SWAGGER_OUTPUT)"; then \
		mv "$$tmpfile" "$(SWAGGER_OUTPUT)"; \
	else \
		rm "$$tmpfile"; \
		echo "[backend] OpenAPI spec unchanged"; \
	fi

swagger: $(SWAGGER_OUTPUT)

swagger-clean:
	$(call log,BACKEND: swagger clean)
	@rm -f $(SWAGGER_OUTPUT)
