// swift-tools-version: 6.0
@preconcurrency import PackageDescription

let package = Package(
    name: "Pickflow",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.9.0"),
    ]
)
