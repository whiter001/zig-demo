const std = @import("std");
const testing = std.testing;
const fetch = @import("mod.zig");

// Test utilities
fn expectStatus(response: *const fetch.HttpResponse, expected_status: u16) !void {
    try testing.expect(response.status_code == expected_status);
}

fn expectHeaderExists(response: *const fetch.HttpResponse, header_name: []const u8) !void {
    try testing.expect(response.headers.contains(header_name));
}

fn expectBodyContains(response: *const fetch.HttpResponse, text: []const u8) !void {
    try testing.expect(std.mem.indexOf(u8, response.body, text) != null);
}

// Basic HTTP method tests
test "HTTP GET request" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.get("https://httpbin.org/get", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            // Skip test if network is unavailable
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "httpbin.org");
}

test "HTTP POST request with JSON" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    const test_data = .{ .test = "data", .number = 42 };
    var response = fetch.postJson(&client, "https://httpbin.org/post", test_data) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "test");
    try expectBodyContains(&response, "data");
}

test "HTTP PUT request with JSON" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    const test_data = .{ .update = "test data", .version = 1 };
    var response = fetch.putJson(&client, "https://httpbin.org/put", test_data) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "update");
}

test "HTTP DELETE request" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.delete("https://httpbin.org/delete", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
}

test "HTTP PATCH request with JSON" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    const test_data = .{ .patch = "operation", .field = "value" };
    var response = fetch.patchJson(&client, "https://httpbin.org/patch", test_data) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "patch");
}

test "HTTP HEAD request" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.head("https://httpbin.org/get", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    // HEAD requests should have empty body
    try testing.expect(response.body.len == 0);
}

test "HTTP OPTIONS request" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.options("https://httpbin.org/get", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
}

test "Custom headers" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var headers = std.StringHashMap([]const u8).init(allocator);
    defer headers.deinit();
    try headers.put("User-Agent", "Zig-Test-Client/1.0");
    try headers.put("X-Test-Header", "test-value");

    var response = client.get("https://httpbin.org/headers", headers) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "User-Agent");
    try expectBodyContains(&response, "Zig-Test-Client/1.0");
    try expectBodyContains(&response, "X-Test-Header");
    try expectBodyContains(&response, "test-value");
}

test "Query parameters in URL" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.get("https://httpbin.org/get?param1=value1&param2=value2", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "param1");
    try expectBodyContains(&response, "value1");
    try expectBodyContains(&response, "param2");
    try expectBodyContains(&response, "value2");
}

test "Basic authentication" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    // Test successful authentication
    var response = client.get("https://httpbin.org/basic-auth/user/pass", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    // This should return 401 because we're not providing auth headers
    try expectStatus(&response, 401);
}

test "Status codes" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    // Test 404
    {
        var response = client.get("https://httpbin.org/status/404", null) catch |err| switch (err) {
            error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
                std.log.warn("Skipping network test due to connectivity issues", .{});
                return;
            },
            else => return err,
        };
        defer response.deinit();
        try expectStatus(&response, 404);
    }

    // Test 500
    {
        var response = client.get("https://httpbin.org/status/500", null) catch |err| switch (err) {
            error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
                std.log.warn("Skipping network test due to connectivity issues", .{});
                return;
            },
            else => return err,
        };
        defer response.deinit();
        try expectStatus(&response, 500);
    }
}

test "Response parsing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var response = client.get("https://httpbin.org/json", null) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    
    // Check that we got JSON content
    if (response.headers.get("content-type")) |content_type| {
        try testing.expect(std.mem.indexOf(u8, content_type, "application/json") != null);
    }
    
    // Parse the JSON to ensure it's valid
    var parsed = std.json.parseFromSlice(std.json.Value, allocator, response.body, .{}) catch |err| {
        std.log.err("Failed to parse JSON response: {}", .{err});
        return err;
    };
    defer parsed.deinit();
    
    try testing.expect(parsed.value == .object);
}

test "Form data POST" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = fetch.HttpClient.init(allocator);
    defer client.deinit();

    var headers = std.StringHashMap([]const u8).init(allocator);
    defer headers.deinit();
    try headers.put("Content-Type", "application/x-www-form-urlencoded");

    const form_data = "key1=value1&key2=value2";
    var response = client.post("https://httpbin.org/post", form_data, headers) catch |err| switch (err) {
        error.ConnectionRefused, error.NetworkUnreachable, error.TemporaryNameServerFailure => {
            std.log.warn("Skipping network test due to connectivity issues", .{});
            return;
        },
        else => return err,
    };
    defer response.deinit();

    try expectStatus(&response, 200);
    try expectBodyContains(&response, "key1");
    try expectBodyContains(&response, "value1");
}