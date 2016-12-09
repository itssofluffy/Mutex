all: build

build:
	swift build

release:
	swift build --configuration release

test:
	swift test

runtest:
	swift test --skip-build

docs:
	swift package generate-xcodeproj

clean:
	swift build --clean

.PHONY: build release test runtest docs clean
