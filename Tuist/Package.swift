// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pickflow",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.12.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk.git", from: "2.27.2"),
        .package(url: "https://github.com/navermaps/SPM-NMapsMap.git", from: "3.23.2"),
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.9.0"),
    ]
)
