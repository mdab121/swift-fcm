import PackageDescription

let package = Package(
	name: "FCM",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/DanToml/Jay.git", majorVersion: 1, minor: 0),
		.Package(url: "https://github.com/boostcode/CCurl.git", majorVersion: 0, minor: 3),
	]
)
