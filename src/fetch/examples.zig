const std = @import("std");
const fetch = @import("mod.zig");

/// Demonstrates various httpbin.org endpoints
pub fn runHttpbinExamples(allocator: std.mem.Allocator) !void {
    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    std.log.info("=== HTTPbin.org Examples ===", .{});

    // 1. Basic GET request
    try getExample(&client);

    // 2. GET with query parameters
    try getWithParamsExample(&client);

    // 3. POST with JSON data
    try postJsonExample(&client);

    // 4. POST with form data
    try postFormExample(&client);

    // 5. PUT request
    try putExample(&client);

    // 6. DELETE request
    try deleteExample(&client);

    // 7. PATCH request
    try patchExample(&client);

    // 8. Custom headers
    try customHeadersExample(&client);

    // 9. User agent
    try userAgentExample(&client);

    // 10. Basic auth (will fail without credentials)
    try basicAuthExample(&client);

    // 11. Bearer token auth
    try bearerTokenExample(&client);

    // 12. Cookies
    try cookiesExample(&client);

    // 13. Redirect handling
    try redirectExample(&client);

    // 14. Status codes
    try statusCodesExample(&client);

    // 15. Response inspection
    try responseInspectionExample(&client);

    std.log.info("=== All examples completed ===", .{});
}

fn getExample(client: *fetch.HttpClient) !void {
    std.log.info("\n1. Basic GET request", .{});
    var response = client.get("https://httpbin.org/get", null) catch |err| {
        std.log.err("GET request failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    std.log.info("Body length: {} bytes", .{response.body.len});
}

fn getWithParamsExample(client: *fetch.HttpClient) !void {
    std.log.info("\n2. GET with query parameters", .{});
    var response = client.get("https://httpbin.org/get?name=Zig&version=0.13&feature=http", null) catch |err| {
        std.log.err("GET with params failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    if (std.mem.indexOf(u8, response.body, "\"name\": \"Zig\"") != null) {
        std.log.info("✓ Query parameter 'name' found in response");
    }
}

fn postJsonExample(client: *fetch.HttpClient) !void {
    std.log.info("\n3. POST with JSON data", .{});
    const json_data = .{
        .message = "Hello from Zig!",
        .timestamp = std.time.timestamp(),
        .data = .{
            .language = "Zig",
            .version = "0.13.0",
            .features = [_][]const u8{ "safety", "performance", "simplicity" },
        },
    };
    
    var response = fetch.postJson(client, "https://httpbin.org/post", json_data) catch |err| {
        std.log.err("POST JSON failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    if (std.mem.indexOf(u8, response.body, "Hello from Zig!") != null) {
        std.log.info("✓ JSON data found in response");
    }
}

fn postFormExample(client: *fetch.HttpClient) !void {
    std.log.info("\n4. POST with form data", .{});
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("Content-Type", "application/x-www-form-urlencoded");
    
    const form_data = "username=ziguser&password=secret123&email=user@example.com";
    var response = client.post("https://httpbin.org/post", form_data, headers) catch |err| {
        std.log.err("POST form failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    if (std.mem.indexOf(u8, response.body, "ziguser") != null) {
        std.log.info("✓ Form data found in response");
    }
}

fn putExample(client: *fetch.HttpClient) !void {
    std.log.info("\n5. PUT request", .{});
    const update_data = .{
        .id = 123,
        .name = "Updated Resource",
        .description = "This resource was updated via PUT",
        .last_modified = std.time.timestamp(),
    };
    
    var response = fetch.putJson(client, "https://httpbin.org/put", update_data) catch |err| {
        std.log.err("PUT failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
}

fn deleteExample(client: *fetch.HttpClient) !void {
    std.log.info("\n6. DELETE request", .{});
    var response = client.delete("https://httpbin.org/delete", null) catch |err| {
        std.log.err("DELETE failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
}

fn patchExample(client: *fetch.HttpClient) !void {
    std.log.info("\n7. PATCH request", .{});
    const patch_data = .{
        .operation = "update",
        .field = "name",
        .value = "Patched Value",
    };
    
    var response = fetch.patchJson(client, "https://httpbin.org/patch", patch_data) catch |err| {
        std.log.err("PATCH failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
}

fn customHeadersExample(client: *fetch.HttpClient) !void {
    std.log.info("\n8. Custom headers", .{});
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("X-Custom-Header", "Zig-Demo-Value");
    try headers.put("X-API-Version", "v1.0");
    try headers.put("X-Request-ID", "12345-abcde");
    
    var response = client.get("https://httpbin.org/headers", headers) catch |err| {
        std.log.err("Custom headers failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    if (std.mem.indexOf(u8, response.body, "X-Custom-Header") != null) {
        std.log.info("✓ Custom headers found in response");
    }
}

fn userAgentExample(client: *fetch.HttpClient) !void {
    std.log.info("\n9. User agent", .{});
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("User-Agent", "Zig-HTTP-Client/1.0 (github.com/whiter001/zig-demo)");
    
    var response = client.get("https://httpbin.org/user-agent", headers) catch |err| {
        std.log.err("User agent failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    if (std.mem.indexOf(u8, response.body, "Zig-HTTP-Client") != null) {
        std.log.info("✓ User agent found in response");
    }
}

fn basicAuthExample(client: *fetch.HttpClient) !void {
    std.log.info("\n10. Basic auth (without credentials - should fail)", .{});
    var response = client.get("https://httpbin.org/basic-auth/user/pass", null) catch |err| {
        std.log.err("Basic auth failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {} (expected 401)", .{response.status_code});
    if (response.status_code == 401) {
        std.log.info("✓ Correctly received 401 Unauthorized");
    }
}

fn bearerTokenExample(client: *fetch.HttpClient) !void {
    std.log.info("\n11. Bearer token auth", .{});
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("Authorization", "Bearer fake-token-for-demo");
    
    var response = client.get("https://httpbin.org/bearer", headers) catch |err| {
        std.log.err("Bearer token failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
}

fn cookiesExample(client: *fetch.HttpClient) !void {
    std.log.info("\n12. Cookies", .{});
    
    // First set a cookie
    var response1 = client.get("https://httpbin.org/cookies/set/demo-cookie/zig-value", null) catch |err| {
        std.log.err("Set cookie failed: {}", .{err});
        return;
    };
    defer response1.deinit();
    
    std.log.info("Set cookie status: {}", .{response1.status_code});
    
    // Then read cookies (in a real scenario, you'd need to handle cookie storage)
    var response2 = client.get("https://httpbin.org/cookies", null) catch |err| {
        std.log.err("Get cookies failed: {}", .{err});
        return;
    };
    defer response2.deinit();
    
    std.log.info("Get cookies status: {}", .{response2.status_code});
}

fn redirectExample(client: *fetch.HttpClient) !void {
    std.log.info("\n13. Redirect handling", .{});
    // This will redirect to /get
    var response = client.get("https://httpbin.org/redirect/1", null) catch |err| {
        std.log.err("Redirect failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Final status: {}", .{response.status_code});
}

fn statusCodesExample(client: *fetch.HttpClient) !void {
    std.log.info("\n14. Status codes", .{});
    
    const status_codes = [_]u16{ 200, 201, 400, 404, 500 };
    for (status_codes) |code| {
        const url = try std.fmt.allocPrint(client.allocator, "https://httpbin.org/status/{}", .{code});
        defer client.allocator.free(url);
        
        var response = client.get(url, null) catch |err| {
            std.log.err("Status {} failed: {}", .{ code, err });
            continue;
        };
        defer response.deinit();
        
        std.log.info("Requested {}, got {}", .{ code, response.status_code });
    }
}

fn responseInspectionExample(client: *fetch.HttpClient) !void {
    std.log.info("\n15. Response inspection", .{});
    var response = client.get("https://httpbin.org/response-headers?Content-Type=application/json&X-Custom=test", null) catch |err| {
        std.log.err("Response inspection failed: {}", .{err});
        return;
    };
    defer response.deinit();
    
    std.log.info("Status: {}", .{response.status_code});
    std.log.info("Headers received:", .{});
    
    var header_iterator = response.headers.iterator();
    var count: u32 = 0;
    while (header_iterator.next()) |entry| {
        count += 1;
        if (count <= 5) { // Show first 5 headers
            std.log.info("  {s}: {s}", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    std.log.info("Total headers: {}", .{count});
}