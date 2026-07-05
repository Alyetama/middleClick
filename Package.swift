// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MiddleClick",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "CMultitouch"),
        .executableTarget(
            name: "MiddleClick",
            dependencies: ["CMultitouch"],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/System/Library/PrivateFrameworks",
                    "-framework", "MultitouchSupport",
                ])
            ]
        ),
    ]
)
