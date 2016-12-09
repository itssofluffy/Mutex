import PackageDescription

let package = Package(
    name: "Mutex",
    dependencies: [
        .Package (
            url:          "https://github.com/itssofluffy/ISFLibrary.git",
            majorVersion: 0
        )
    ]
)
