.DEFAULT_GOAL := help
.PHONY: help dev dev-ios dev-iphone dev-android devices get format format-check analyze test check build-ios build-android release-ios release-android icons clean

FLUTTER ?= flutter
DART := $(shell dirname $$(command -v $(FLUTTER)))/dart
ANDROID_EMU ?= motaa_parity_api35
DEVICE ?=

define FIND_DEVICE
$(FLUTTER) devices --machine --suppress-analytics --no-version-check 2>/dev/null | python3 -c 'import json,sys; raw=sys.stdin.read(); s=raw.find("["); ds=json.loads(raw[s:]) if s>=0 else []; print(next((d["id"] for d in ds if d.get("isSupported") and "$(1)" in str(d.get("targetPlatform","")) and ($(2))), ""))'
endef

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Boot iOS Simulator and run (override with DEVICE=<id>)
	@if [ -n "$(DEVICE)" ]; then \
		$(FLUTTER) run -d "$(DEVICE)"; \
	else \
		$(MAKE) dev-ios; \
	fi

dev-ios: ## Boot iOS Simulator and run
	@if ! xcrun simctl list devices booted | grep -q "(Booted)"; then \
		UDID=$$(xcrun simctl list devices available -j | python3 -c 'import json,sys; devs=json.load(sys.stdin).get("devices",{}); print(next((d["udid"] for r in sorted(devs.keys(), reverse=True) if "iOS" in r for d in devs[r] if d.get("isAvailable") and "iPhone" in d.get("name","")), ""))'); \
		if [ -z "$$UDID" ]; then echo "No available iPhone simulator found."; exit 1; fi; \
		xcrun simctl boot "$$UDID"; \
		open -a Simulator 2>/dev/null || true; \
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do \
			ID=$$($(call FIND_DEVICE,ios,d.get("emulator"))); \
			[ -n "$$ID" ] && break; \
			sleep 1; \
		done; \
	fi; \
	ID=$$($(call FIND_DEVICE,ios,d.get("emulator"))); \
	if [ -z "$$ID" ]; then echo "No iOS simulator found."; exit 1; fi; \
	$(FLUTTER) run -d "$$ID"

dev-iphone: ## Run on connected physical iPhone
	@ID=$$($(call FIND_DEVICE,ios,not d.get("emulator"))); \
	if [ -z "$$ID" ]; then echo "No physical iPhone found."; exit 1; fi; \
	$(FLUTTER) run -d "$$ID"

dev-android: ## Boot Android emulator and run
	@ID=$$($(call FIND_DEVICE,android,True)); \
	if [ -z "$$ID" ]; then \
		$(FLUTTER) emulators --launch "$(ANDROID_EMU)"; \
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do \
			ID=$$($(call FIND_DEVICE,android,True)); \
			[ -n "$$ID" ] && break; \
			sleep 2; \
		done; \
	fi; \
	if [ -z "$$ID" ]; then echo "No Android device or emulator found."; exit 1; fi; \
	$(FLUTTER) run -d "$$ID"

devices: ## List connected devices and emulators
	$(FLUTTER) devices
	$(FLUTTER) emulators

get: ## Install Flutter dependencies
	$(FLUTTER) pub get

format: ## Format lib and test with bundled Dart
	$(DART) format lib test

format-check: ## Check formatting without modifying files
	$(DART) format --output=none --set-exit-if-changed lib test

analyze: ## Run static analyzer
	$(FLUTTER) analyze --suppress-analytics --no-color

test: ## Run all unit and widget tests
	$(FLUTTER) test --suppress-analytics --no-color

check: format-check analyze test ## Run format-check, analyze, and test

build-ios: ## Build iOS simulator app
	$(FLUTTER) build ios --simulator --suppress-analytics --no-color

build-android: ## Build Android debug APK
	$(FLUTTER) build apk --debug --suppress-analytics --no-color

release-ios: ## Build obfuscated release IPA
	$(FLUTTER) build ipa --release --obfuscate --split-debug-info=build/symbols/ios

release-android: ## Build obfuscated release Android App Bundle
	$(FLUTTER) build appbundle --release --obfuscate --split-debug-info=build/symbols/android

icons: ## Regenerate iOS & Android app icons from design/exports/icon
	python3 tool/gen_icons.py

clean: ## Clean build artifacts and re-fetch packages
	$(FLUTTER) clean
	$(FLUTTER) pub get
