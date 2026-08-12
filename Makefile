FLUTTER ?= flutter
DART ?= dart
PYTHON ?= python3

.PHONY: bootstrap catalogue verify-catalogue deps format format-check lint typecheck test check-tests coverage platform-config-test build-android build-ios clean verify repository-check

bootstrap:
	bash tool/bootstrap_platforms.sh

catalogue:
	$(PYTHON) tool/catalogue.py fetch

verify-catalogue:
	$(PYTHON) tool/catalogue.py verify

deps:
	$(FLUTTER) pub get

format:
	$(DART) format lib test

format-check:
	$(DART) format --output=none --set-exit-if-changed lib test

lint:
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

typecheck: lint

test:
	$(FLUTTER) test

check-tests:
	$(PYTHON) tool/check_tests.py

coverage:
	$(FLUTTER) test --coverage
	$(PYTHON) tool/check_coverage.py coverage/lcov.info --minimum 100

repository-check:
	$(PYTHON) tool/repository_check.py

platform-config-test:
	$(PYTHON) tool/test_configure_platforms.py

build-android: verify-catalogue
	$(FLUTTER) build apk --release --split-per-abi

build-ios: verify-catalogue
	$(FLUTTER) build ios --release --no-codesign

verify: verify-catalogue repository-check platform-config-test format-check lint check-tests coverage

clean:
	$(FLUTTER) clean
	rm -rf coverage
