.PHONY: bootstrap gen gen-watch analyze test run-dev run-staging run-prod clean

bootstrap:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

analyze:
	flutter analyze

test:
	flutter test

run-dev:
	flutter run -t lib/main_dev.dart --dart-define=API_BASE_URL=http://localhost:3000

run-staging:
	flutter run -t lib/main_staging.dart --dart-define=API_BASE_URL=https://staging-api.algoerp.internal

run-prod:
	flutter run -t lib/main_prod.dart --dart-define=API_BASE_URL=https://api.algoerp.com

clean:
	flutter clean
