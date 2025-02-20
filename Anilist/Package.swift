// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "Anilist",
  platforms: [
    .iOS(.v12),
    .macOS(.v10_14),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "Anilist", targets: ["Anilist"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios", exact: "1.17.0"),
  ],
  targets: [
    .target(
      name: "Anilist",
      dependencies: [
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      path: "./Sources"
    ),
  ]
)
