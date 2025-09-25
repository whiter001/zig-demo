# HTTP Fetch Module

This module provides a comprehensive HTTP client implementation for Zig, specifically designed to work with [httpbin.org](https://httpbin.org/) endpoints for testing and demonstration purposes.

## Features

- Support for all major HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
- JSON request/response handling
- Custom headers support
- Form data encoding
- URL encoding utilities
- Basic and Bearer authentication helpers
- Response caching
- Rate limiting
- Retry mechanisms
- Comprehensive error handling

## Quick Start

```zig
const std = @import("std");
const fetch = @import("fetch/mod.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    // Simple GET request
    var response = try client.get("https://httpbin.org/get", null);
    defer response.deinit();
    
    std.log.info("Status: {}, Body: {s}", .{ response.status_code, response.body });
}
```

## HTTP Methods

### GET Requests

```zig
// Basic GET
var response = try client.get("https://httpbin.org/get", null);

// GET with custom headers
var headers = std.StringHashMap([]const u8).init(allocator);
try headers.put("User-Agent", "MyApp/1.0");
var response = try client.get("https://httpbin.org/get", headers);
```

### POST Requests

```zig
// POST with JSON
const data = .{ .name = "John", .age = 30 };
var response = try fetch.postJson(&client, "https://httpbin.org/post", data);

// POST with form data
var headers = std.StringHashMap([]const u8).init(allocator);
try headers.put("Content-Type", "application/x-www-form-urlencoded");
const form_data = "name=John&age=30";
var response = try client.post("https://httpbin.org/post", form_data, headers);
```

### PUT Requests

```zig
const data = .{ .id = 123, .name = "Updated Name" };
var response = try fetch.putJson(&client, "https://httpbin.org/put", data);
```

### DELETE Requests

```zig
var response = try client.delete("https://httpbin.org/delete", null);
```

### PATCH Requests

```zig
const patch_data = .{ .field = "new_value" };
var response = try fetch.patchJson(&client, "https://httpbin.org/patch", patch_data);
```

## Utilities

### URL Encoding

```zig
const utils = @import("fetch/utils.zig");

const encoded = try utils.urlEncode(allocator, "hello world!");
// Result: "hello+world%21"
```

### Query Parameters

```zig
var params = std.StringHashMap([]const u8).init(allocator);
try params.put("name", "John");
try params.put("age", "30");

const url = try utils.buildUrlWithParams(allocator, "https://httpbin.org/get", params);
// Result: "https://httpbin.org/get?name=John&age=30"
```

### Authentication

```zig
// Basic Auth
const auth = try utils.createBasicAuth(allocator, "user", "password");
var headers = std.StringHashMap([]const u8).init(allocator);
try headers.put("Authorization", auth);

// Bearer Token
const token_auth = try utils.createBearerAuth(allocator, "my-token");
try headers.put("Authorization", token_auth);
```

### Response Caching

```zig
var cache = utils.ResponseCache.init(allocator);
defer cache.deinit();

// Check cache first
if (cache.get("https://httpbin.org/get")) |cached_response| {
    // Use cached response
} else {
    // Make request and cache it
    var response = try client.get("https://httpbin.org/get", null);
    try cache.put("https://httpbin.org/get", response, 300000); // 5 minutes TTL
}
```

### Rate Limiting

```zig
var rate_limiter = utils.RateLimiter.init(1000); // 1 second between requests

rate_limiter.waitIfNeeded();
var response = try client.get("https://httpbin.org/get", null);
```

### Retry Mechanism

```zig
var response = try utils.retryRequest(
    &client,
    .GET,
    "https://httpbin.org/get",
    null,
    null,
    3,    // max retries
    1000  // delay in ms
);
```

## HTTPbin.org Endpoints Covered

This module includes examples for all major httpbin.org endpoints:

- `/get` - GET requests with query parameters
- `/post` - POST requests with JSON and form data
- `/put` - PUT requests with JSON data
- `/delete` - DELETE requests
- `/patch` - PATCH requests with JSON data
- `/headers` - Custom headers inspection
- `/user-agent` - User agent inspection
- `/basic-auth/{user}/{passwd}` - Basic authentication
- `/bearer` - Bearer token authentication
- `/cookies/*` - Cookie handling
- `/redirect/{n}` - Redirect following
- `/status/{code}` - HTTP status codes
- `/json` - JSON response parsing
- `/response-headers` - Response header inspection

## Testing

Run the comprehensive test suite:

```bash
zig build test-fetch
```

Or run all tests:

```bash
zig build test
```

The tests include:
- Unit tests for all HTTP methods
- Integration tests with httpbin.org
- Error handling tests
- Utility function tests
- Network failure simulation

## Examples

See `examples.zig` for comprehensive examples demonstrating:
- All HTTP methods
- Authentication mechanisms
- Header manipulation
- Response parsing
- Error handling
- Real-world usage patterns

Run the examples:

```bash
zig build run
```

## Error Handling

The module provides comprehensive error handling for:
- Network connectivity issues
- HTTP status errors
- JSON parsing errors  
- Memory allocation failures
- Invalid URLs
- Timeout handling

```zig
var response = client.get("https://httpbin.org/get", null) catch |err| switch (err) {
    error.ConnectionRefused => {
        std.log.err("Could not connect to server");
        return;
    },
    error.InvalidUrl => {
        std.log.err("Invalid URL provided");
        return;
    },
    else => return err,
};
```

## Performance Considerations

- The HTTP client reuses connections where possible
- Response bodies are allocated once and reused
- Headers are stored efficiently using StringHashMap
- Memory is properly cleaned up with defer statements
- Large responses are handled incrementally

## Dependencies

This module uses only Zig's standard library:
- `std.http` for HTTP client functionality
- `std.json` for JSON serialization/deserialization
- `std.Uri` for URL parsing
- `std.base64` for basic authentication encoding
- `std.StringHashMap` for header storage