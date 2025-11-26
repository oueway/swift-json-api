# SwiftJsonApi

A lightweight, strongly-typed JSON:API model layer for Swift. It focuses on clear protocols for representing resources (data), attributes, and relationships, while remaining flexible for different app architectures.

This package is designed as a foundation for decoding JSON:API responses, resolving relationships from the `included` section, and working with type-safe resource models across iOS and macOS.

## Features

- Protocol-first design for JSON:API resources
- Strongly-typed `Attributes` and `Relationships`
- Pluggable relationship resolution from `included` resources
- Codable-friendly APIs
- Small, focused utilities for file IO and path management

# SwiftJsonApi — Quick Guidelines

`SwiftJsonApi` helps your app easily access any JSON:API-compliant backend. Define your data structures, conform to the required protocols, and you’ll get type-safe, convenient access to RESTful services.

```swift
// Simple usage:
let tasks = try await TaskDto.list().datums

// Usage with type-safe query parameters:
let tasks = try await TaskDto.list(
    filterBy: [
        .assignee("octocat"),
        .status([.todo, .inProgress]),
    ],
    sortBy: [.assignee, .status.asc, .updated.desc],
    include: [.assignee],
    pageSize: 20
).datums

// Fetch a single resource:
let task = try await TaskDto.get(byID: "123").datums.first
// _ = try await TaskDto.get(byID: "123", include: [.assignee])
```
[View Full Examples](README_EXAMPLES.md)

## Requirements

- iOS 14.0+ / macOS 10.16+ / tvOS 14.0+ / visionOS 2.0+

## Installation

### Swift Package Manager

Add the package to your project:

1. In Xcode: File > Add Packages…
2. Enter the repository URL for this package
3. Select the latest version and add the `SwiftJsonApi` product to your target

Or in `Package.swift`:

```swift
.dependencies([
    .package(url: "https://github.com/your-org/SwiftJsonApi.git", from: "0.0.1")
])

