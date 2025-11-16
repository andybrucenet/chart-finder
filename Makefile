# Makefile, ABr
#
# chart-finder: Top-level Makefile

.PHONY: help setup-dev-env stack-refresh stack-refresh-batch tls-status tls-renew backend backend-build backend-test backend-clean backend-rebuild backend-all backend-deploy backend-swagger \
	frontend frontend-install frontend-ci frontend-build frontend-test frontend-lint frontend-typecheck frontend-start frontend-start-ios frontend-start-android frontend-start-macos frontend-android \
	frontend-ios frontend-doctor frontend-format frontend-reinstall frontend-clean frontend-version \
	infra infra-build infra-stage infra-status infra-uri infra-publish infra-smoke infra-clean

log = @printf '\n***** %s\n' "$(1)"

help:
	@printf "%s\n" \
		"Available targets:" \
		"  setup-dev-env     Hydrate local environment via scripts/setup-dev-env.sh" \
		"  stack-refresh     Rebuild backend and refresh infra targets" \
		"  stack-refresh-batch Same as stack-refresh but auto-confirms SAM deploy" \
		"  tls-status       Show the current TLS certificate status" \
		"  tls-renew        Run scripts/tls-renew.sh to renew/import the wildcard cert" \
		"  backend-all       Build + test backend projects" \
		"  backend-build     Restore and build the backend solution (delegates to backend/Makefile)" \
		"  backend-test      Run backend tests" \
		"  backend-clean     Clean backend build artifacts" \
		"  backend-rebuild   Clean then build backend projects" \
		"  backend-deploy    SAM preflight + deploy (delegates to backend/Makefile)" \
		"  backend-swagger   Build and export OpenAPI spec (delegates to backend/Makefile)" \
		"  infra-all         Perform all standard infra build instructions" \
		"  infra-build       Run SAM preflight (delegates to infra/Makefile)" \
		"  infra-stage       Alias for infra-build" \
		"  infra-publish     Deploy (publish) SAM stack (delegates to infra/Makefile)" \
		"  infra-status      Status of SAM stack (delegates to infra/Makefile)" \
		"  infra-uri         Current URI endpoint of SAM stack (delegates to infra/Makefile)" \
		"  infra-smoke       Hit deployed utils endpoint to verify deployment" \
		"  frontend          Install frontend dependencies (delegates to frontend/Makefile)" \
		"  frontend-ci       Run npm ci for reproducible installs" \
		"  frontend-build    Invoke frontend build script (if defined)" \
		"  frontend-test     Run frontend test script (if defined)" \
		"  frontend-lint     Run frontend lint script (if defined)" \
		"  frontend-typecheck  Run frontend typecheck script (if defined)" \
		"  frontend-start    Start Expo dev server (multi-platform)" \
		"  frontend-start-ios  Start Expo dev server targeting iOS simulator" \
		"  frontend-start-android  Start Expo dev server targeting Android emulator" \
		"  frontend-start-macos  Start Expo dev server targeting desktop/web preview" \
		"  frontend-android  Run the Expo Android workflow" \
		"  frontend-ios      Run the Expo iOS workflow" \
		"  frontend-doctor   Run Expo doctor" \
		"  frontend-format   Run the formatter (if defined)" \
		"  frontend-reinstall  Clean caches then install dependencies" \
		"  frontend-clean    Remove frontend caches" \
		"  frontend-version  Update the frontend version metadata"

setup-dev-env:
	$(call log,SETUP: dev-env)
	@./scripts/setup-dev-env.sh

stack-refresh:
	$(call log,STACK: refresh)
	@$(MAKE) backend-build
	@$(MAKE) infra-build
	@$(MAKE) infra-publish

stack-refresh-batch:
	$(call log,STACK: refresh batch)
	@CF_STACK_DEPLOYMENT_MODE=batch $(MAKE) stack-refresh

tls-status:
	$(call log,TLS: status)
	@$(ROOT)/scripts/tls-status.sh show

tls-renew:
	$(call log,TLS: renew)
	@$(ROOT)/scripts/tls-renew.sh run
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

infra-all:
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

frontend frontend-install:
	@$(MAKE) -C frontend install

frontend-ci:
	@$(MAKE) -C frontend ci

frontend-build:
	@$(MAKE) -C frontend build

frontend-test:
	@$(MAKE) -C frontend test

frontend-lint:
	@$(MAKE) -C frontend lint

frontend-typecheck:
	@$(MAKE) -C frontend typecheck

frontend-start:
	@$(MAKE) -C frontend start

frontend-start-ios:
	@$(MAKE) -C frontend start-ios

frontend-start-android:
	@$(MAKE) -C frontend start-android

frontend-start-macos:
	@$(MAKE) -C frontend start-macos

frontend-android:
	@$(MAKE) -C frontend android

frontend-ios:
	@$(MAKE) -C frontend ios

frontend-doctor:
	@$(MAKE) -C frontend doctor

frontend-format:
	@$(MAKE) -C frontend format

frontend-reinstall:
	@$(MAKE) -C frontend reinstall

frontend-clean:
	@$(MAKE) -C frontend clean

frontend-version:
	@$(MAKE) -C frontend version
