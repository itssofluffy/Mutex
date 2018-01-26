# Mutex

[![Swift][swift-badge-3]][swift-url]
[![Swift][swift-badge-4]][swift-url]
[![Build Status][travis-build-badge]][travis-build-url]
![macOS][macos-badge]
![Linux][linux-badge]
[![License][mit-badge]][mit-url]

**Mutex** is a **Swift-3/4** class library for mutual exclusion locks.

## Usage

If [Swift Package Manager](https://github.com/apple/swift-package-manager) is used, add this package as a dependency in `Package.swift`,

```swift
import PackageDescription

let package = Package (
    name:  "<your-app-name>",
    dependencies: [
        .Package(url: "https://github.com/itssofluffy/Mutex.git", majorVersion: 0)
    ]
)
```

## Examples

Mutex

```swift
let mutex = try Mutex()

...

try mutex.lock {
    result = 1
}
```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge-3]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-badge-4]: https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat
[swift-url]: https://swift.org
[travis-build-badge]: https://travis-ci.org/itssofluffy/Mutex.svg?branch=master
[travis-build-url]: https://travis-ci.org/itssofluffy/Mutex
[macos-badge]: https://img.shields.io/badge/os-macOS-green.svg?style=flat
[linux-badge]: https://img.shields.io/badge/os-linux-green.svg?style=flat
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
