
The following steps show quick-start examples for using `SwiftJsonApi` in your app.

## 1. Configure `WebService`

Provide an app-specific `WebServiceDelegate` that defines the API endpoint and manages tokens. Register it at app startup:

```swift
final class AppServiceDelegate: WebServiceDelegate {
    var apiEndpoint: URL { URL(string: "https://api.example.com/")! }
    var accessToken: String? { "token_value" }
    var isTokenExpired: Bool { /* your token logic */ }

    func didReceiveUnauthorizedError() { /* refresh token or notify UI */ }
    func didReceiveForbiddenError() { /* permission error */ }
}

WebService.configure(delegate: AppServiceDelegate())
```
## 2. Define a Resource (Datum)

Create a type that conforms to `JADatumProtocol`. Provide its `Attributes`, optional `Relationships`, and required properties.

```swift
struct UserDto: JADatumProtocol {
    static let typeName = "users"

    let id, type: String
    let links: JASelfLinks
    let attributes: Attributes
    let relationships: Relationships?

    struct Attributes: Codable {
        let name: Int
    }

    struct Relationships: Codable {}
}
```

```swift
struct TaskDto: JADatumProtocol {
    static let typeName = "tasks"
    ...

    struct Relationships: Codable {
        let assignee: JARelationship<UserDto>?
    }
}
```

Register your DTOs so the library can dynamically decode included resources:

```swift
UserDto.register()
TaskDto.register()
```

## 3. Enable GET / POST / PUT / DELETE

```swift
extension TaskDto: JAResourceProtocol {
    static let resourcePath = "/rest/v2/tasks"

    // the JSON:API includes queries that canbe autoresolved to relationships
    enum IncludeItem: String, IncludeItemProtocol {
        case assignee
        case creator
    }
}
```

## 4. Enable List Querying

```swift
extension TaskDto: JAGetListProtocol {
    // Define your type-safe sort items here
    struct SortItem: JASortItemProtocol {
        static let updated = Self("updatedAt")
        static let assignee = Self("assignee.firstName")
        static let status = Self("status")
    }

    // Define your type-safe filter items here
    enum FilterItem: JAFilterItemProtocol {
        case assignee(String)
        case status([Attributes.TaskStatus])
        case title(String)
        case search(String)
        case updatedAfter(Date)

        enum Key: String, KeyProtocol {
            case assignee = "assignee.name"
        }
    }
}
```
## 5. Fetch a List of Resources

```swift
@Published private(set) var tasksResponse: JAResponse<TaskDto>?
```

```swift
do {
    let response = try await TaskDto.list()
    let tasks = response.datums
    tasksResponse = response
    print("Fetched \(tasks.count) tasks")
} catch let error as JsonApiError {
    print("Request failed: \(error.errorDescription ?? "Unknown")")
} catch {
    print("Unexpected error: \(error)")
}
```

## 6. Load More Pages

```swift
if let res = viewModel.tasksResponse, res.hasNextPage {
    YourLastCell("Tap to load more") {
        viewModel.loadNextPage(isAutoPull: false)
    }
    .onAppear {
        viewModel.loadNextPage(isAutoPull: true)
    }
}
```

```swift
func loadNextPage(isAutoPull: Bool) {
    Task {
        try? await tasksResponse?.updateWithNextPage()
    }
}
```

## 7. Fetch a Single Resource by ID

```swift
Task {
    do {
        let task = try await TaskDto.get(byID: "123").datums.first
        // let response = try await TaskDto.get(byID: "123", include: [.assignee])
        print(task?.attributes.title ?? "no title")
    } catch {
        print("Failed: \(error)")
    }
}
```

# Notes

### Error Handling

The library exposes all runtime errors through `JsonApiError`.  
`MyError` remains only as a deprecated alias.

### Date Encoding / Decoding

By default, dates are encoded and decoded in UTC ISO-8601 format:

```swift
JSONEncoder.iso8601UTC
JSONDecoder.iso8601Standard
```
