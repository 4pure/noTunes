.PHONY: build-mac build-mac-arm build-mac-intel version-bump

build-mac:
	bash scripts/package-dmg.sh universal

build-mac-arm:
	bash scripts/package-dmg.sh arm

build-mac-intel:
	bash scripts/package-dmg.sh intel

version-bump:
	bash scripts/bump-version.sh
