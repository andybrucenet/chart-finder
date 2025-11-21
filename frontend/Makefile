# Frontend wrapper Makefile
# Routes targets to the active stack (React or Flutter) using CF_LOCAL_FRONTEND_ENV.
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
FRONTEND_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# import chart-finder environment
$(shell $(ROOT)/scripts/cf-env-vars-to-make.sh)
include $(ROOT)/.local/state/cf-env-vars.mk

KNOWN_FRONTEND_STACKS := react flutter
FRONTEND_STACK ?= $(strip $(CF_LOCAL_FRONTEND_ENV))
FRONTEND_STACK := $(if $(FRONTEND_STACK),$(FRONTEND_STACK),react)

ifeq ($(filter $(FRONTEND_STACK),$(KNOWN_FRONTEND_STACKS)),)
$(error Unsupported CF_LOCAL_FRONTEND_ENV='$(FRONTEND_STACK)'; expected one of $(KNOWN_FRONTEND_STACKS))
endif

FRONTEND_STACK_MAKEFILE := $(FRONTEND_DIR)/Makefile-$(FRONTEND_STACK)

ifeq ($(wildcard $(FRONTEND_STACK_MAKEFILE)),)
$(error Missing stack makefile: $(FRONTEND_STACK_MAKEFILE))
endif

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "Front-end stack: %s (set CF_LOCAL_FRONTEND_ENV to switch)\n\n" "$(FRONTEND_STACK)"
	@$(MAKE) -f "$(FRONTEND_STACK_MAKEFILE)" --no-print-directory help

%:
	@$(MAKE) -f "$(FRONTEND_STACK_MAKEFILE)" --no-print-directory $@
