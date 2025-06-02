// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let local = false

let pykit_package: Package.Dependency = if local {
    .package(path: ".../PySwiftKit")
} else {
    .package(url: "https://github.com/KivySwiftLink/PySwiftKit", from: .init(311, 0, 0))
}

let pykit: Target.Dependency = .product(name: "SwiftonizeModules", package: "PySwiftKit")

let package = Package(
    name: "KivyTexture",
	platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KivyTexture",
            targets: ["KivyTexture"]),
    ],
	dependencies: [
        pykit_package,
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
			name: "KivyTexture",
			dependencies: [
				.product(name: "SwiftonizeModules", package: "PySwiftKit"),
				//.product(name: "PythonCore", package: "PythonCore")
			],
			plugins: [
				//.plugin(name: "Swiftonize", package: "SwiftonizePlugin"),
			]
		),
        .testTarget(
            name: "KivyTextureTests",
            dependencies: ["KivyTexture"]),
    ]
)
