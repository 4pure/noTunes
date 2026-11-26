.PHONY: build-mac build-mac-arm build-mac-intel build-mac-app build-mac-arm-app build-mac-intel-app version-bump

build-mac:
	bash scripts/package.sh universal

build-mac-arm:
	bash scripts/package.sh arm

build-mac-intel:
	bash scripts/package.sh intel

build-mac-app:
	bash scripts/package.sh universal --app-only

build-mac-arm-app:
	bash scripts/package.sh arm --app-only

build-mac-intel-app:
	bash scripts/package.sh intel --app-only

version-bump:
	bash scripts/bump-version.sh
