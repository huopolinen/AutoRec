// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoRec",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AutoRec",
            path: "AutoRec",
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("CoreAudio"),
            ]
        ),
    ]
)
