# Makefile, ABr
#
# chart-finder: Frontend Makefile
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
APP_DIR ?= $(ROOT)/src/frontend/chart-finder-mobile
EXPO_PUBLIC_API_BASE_URL ?=

NPM ?= npm
NPX ?= npx
EXPO ?= $(NPX) expo
FRONTEND_SCRIPTS_DIR := $(ROOT)/scripts
FRONTEND_NPM_INSTALL_SCRIPT := $(FRONTEND_SCRIPTS_DIR)/frontend-npm-install.sh
FRONTEND_SRC_SIG_SCRIPT := $(FRONTEND_SCRIPTS_DIR)/frontend-src-sig.sh
FRONTEND_VERSION_ARTIFACTS_SCRIPT := $(FRONTEND_SCRIPTS_DIR)/frontend-version-artifacts.sh

.DEFAULT_GOAL := help

.PHONY: help all install ci build deps build-number version-artifacts test lint typecheck clean veryclean reinstall start start-ios start-android start-macos android ios doctor format version refresh-ios refresh-android refresh-all

log = @printf '\n***** %s\n' "$(1)"

define npm_run
	@cd "$(APP_DIR)" && $(NPM) run $(1) --if-present
endef

define expo_run
	@cd "$(APP_DIR)" && EXPO_PUBLIC_API_BASE_URL="$(EXPO_PUBLIC_API_BASE_URL)" $(EXPO) $(1)
endef

help:
	@printf "%s\n" \
		"Available frontend targets:" \
		"  install           npm install (default workflow)" \
		"  deps              Ensure frontend dependencies + artifacts" \
		"  version-artifacts Generate source artifacts from version metadata" \
		"  build-number      Update build number when sources change" \
		"  ci                npm ci for clean installs" \
		"  build             npm run build (if defined)" \
		"  test              npm run test (if defined)" \
		"  lint              npm run lint (if defined)" \
		"  typecheck         npm run typecheck (if defined)" \
		"  start             expo start --localhost" \
		"  start-ios         expo start --localhost --ios" \
		"  start-android     expo start --localhost --android" \
		"  start-macos       expo start --localhost --web" \
		"  android           expo run:android" \
		"  ios               expo run:ios" \
		"  refresh-ios       Rebuild/run iOS, then start Expo for iOS" \
		"  refresh-android   Rebuild/run Android, then start Expo for Android" \
		"  refresh-all       Rebuild iOS and Android natives (no Expo start)" \
		"  doctor            expo doctor" \
		"  format            npm run format (if defined)" \
		"  reinstall         clean + install" \
		"  clean             remove node_modules/.expo artifacts" \
		"  version           run scripts/update-version.sh frontend"

all: lint typecheck test

install:
	$(call log,FRONTEND: install)
	@cd "$(ROOT)" && "$(FRONTEND_NPM_INSTALL_SCRIPT)" run

deps: install version-artifacts

build-number:
	$(call log,FRONTEND: build-number)
	@cd "$(ROOT)" && "$(FRONTEND_SRC_SIG_SCRIPT)" run

version-artifacts:
	$(call log,FRONTEND: version artifacts)
	@cd "$(ROOT)" && "$(FRONTEND_VERSION_ARTIFACTS_SCRIPT)" run

ci:
	$(call log,FRONTEND: ci)
	@cd "$(ROOT)" && FRONTEND_NPM_INSTALL_OPTION_MODE=ci FRONTEND_NPM_INSTALL_OPTION_FORCE_INSTALL=1 "$(FRONTEND_NPM_INSTALL_SCRIPT)" run

build: deps build-number
	$(call log,FRONTEND: build)
	$(call npm_run,build)

test: deps
	$(call log,FRONTEND: test)
	$(call npm_run,test)

lint: deps
	$(call log,FRONTEND: lint)
	$(call npm_run,lint)

typecheck: deps
	$(call log,FRONTEND: typecheck)
	$(call npm_run,typecheck)

clean:
	$(call log,FRONTEND: clean)
	@rm -rf "$(APP_DIR)/node_modules" "$(APP_DIR)/.expo" "$(APP_DIR)/.expo-shared" "$(APP_DIR)/dist"

veryclean: clean
	$(call log,FRONTEND: veryclean)
	@true

reinstall:
	$(call log,FRONTEND: reinstall)
	@$(MAKE) clean
	@$(MAKE) install

start: deps
	$(call log,FRONTEND: start)
	$(call expo_run,start --localhost)

start-ios: deps
	$(call log,FRONTEND: start ios)
	$(call expo_run,start --localhost --ios)

start-android: deps
	$(call log,FRONTEND: start android)
	$(call expo_run,start --localhost --android)

start-macos: deps
	$(call log,FRONTEND: start macos)
	$(call expo_run,start --localhost --web)

android: deps build-number
	$(call log,FRONTEND: android)
	$(call expo_run,run:android)

refresh-android:
	$(call log,FRONTEND: refresh android)
	@$(MAKE) android
	@$(MAKE) start-android

ios: deps build-number
	$(call log,FRONTEND: ios)
	$(call expo_run,run:ios)

refresh-ios:
	$(call log,FRONTEND: refresh ios)
	@$(MAKE) ios
	@$(MAKE) start-ios

refresh-all:
	$(call log,FRONTEND: refresh all)
	@$(MAKE) ios
	@$(MAKE) android

doctor: deps
	$(call log,FRONTEND: doctor)
	$(call expo_run,doctor)

format: deps
	$(call log,FRONTEND: format)
	$(call npm_run,format)

version:
	$(call log,FRONTEND: version)
	@cd "$(ROOT)" && ./scripts/update-version.sh frontend
	@cd "$(ROOT)" && "$(FRONTEND_VERSION_ARTIFACTS_SCRIPT)" run
