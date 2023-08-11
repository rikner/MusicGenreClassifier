// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowDSP",
    products: [
        .library(
            name: "FlowDSP",
            targets: ["FlowDSP"]),
    ],
    targets: [
        .target(
            name: "FlowDSP",
            dependencies: ["Cspblas", "CKissFFT"]),
        .target(
            name: "Cspblas"),
        .target(
            name: "CKissFFT"),
        .testTarget(
            name: "FlowDSPTests",
            dependencies:["FlowDSP"]),
    ]
)
