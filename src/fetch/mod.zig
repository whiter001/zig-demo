const std = @import("std");
const http = std.http;
const json = std.json;

pub const HttpMethod = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
};

pub const HttpResponse = struct {
    status_code: u16,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *HttpResponse) void {
        self.allocator.free(self.body);
        var iterator = self.headers.iterator();
        while (iterator.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.headers.deinit();
    }
};

pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    client: http.Client,

    pub fn init(allocator: std.mem.Allocator) HttpClient {
        return HttpClient{
            .allocator = allocator,
            .client = http.Client{ .allocator = allocator },
        };
    }

    pub fn deinit(self: *HttpClient) void {
        self.client.deinit();
    }

    pub fn request(
        self: *HttpClient,
        method: HttpMethod,
        url: []const u8,
        headers: ?std.StringHashMap([]const u8),
        body: ?[]const u8,
    ) !HttpResponse {
        const uri = try std.Uri.parse(url);
        
        const http_method = switch (method) {
            .GET => std.http.Method.GET,
            .POST => std.http.Method.POST,
            .PUT => std.http.Method.PUT,
            .DELETE => std.http.Method.DELETE,
            .PATCH => std.http.Method.PATCH,
            .HEAD => std.http.Method.HEAD,
            .OPTIONS => std.http.Method.OPTIONS,
        };

        var req = try self.client.open(http_method, uri, .{
            .server_header_buffer = try self.allocator.alloc(u8, 8192),
        });
        defer req.deinit();

        // Add custom headers if provided
        if (headers) |h| {
            var iterator = h.iterator();
            while (iterator.next()) |entry| {
                try req.headers.append(entry.key_ptr.*, entry.value_ptr.*);
            }
        }

        try req.send();
        
        if (body) |b| {
            try req.writeAll(b);
        }
        
        try req.finish();
        try req.wait();

        // Read response
        const response_body = try req.reader().readAllAlloc(self.allocator, 1024 * 1024);
        
        var response_headers = std.StringHashMap([]const u8).init(self.allocator);
        var header_iterator = req.response.iterateHeaders();
        while (header_iterator.next()) |header| {
            const key = try self.allocator.dupe(u8, header.name);
            const value = try self.allocator.dupe(u8, header.value);
            try response_headers.put(key, value);
        }

        return HttpResponse{
            .status_code = @intCast(req.response.status.int()),
            .headers = response_headers,
            .body = response_body,
            .allocator = self.allocator,
        };
    }

    // Convenience methods for different HTTP verbs
    pub fn get(self: *HttpClient, url: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.GET, url, headers, null);
    }

    pub fn post(self: *HttpClient, url: []const u8, body: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.POST, url, headers, body);
    }

    pub fn put(self: *HttpClient, url: []const u8, body: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.PUT, url, headers, body);
    }

    pub fn delete(self: *HttpClient, url: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.DELETE, url, headers, null);
    }

    pub fn patch(self: *HttpClient, url: []const u8, body: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.PATCH, url, headers, body);
    }

    pub fn head(self: *HttpClient, url: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.HEAD, url, headers, null);
    }

    pub fn options(self: *HttpClient, url: []const u8, headers: ?std.StringHashMap([]const u8)) !HttpResponse {
        return self.request(.OPTIONS, url, headers, null);
    }
};

// JSON helper functions
pub fn postJson(client: *HttpClient, url: []const u8, json_data: anytype) !HttpResponse {
    var json_string = std.ArrayList(u8).init(client.allocator);
    defer json_string.deinit();
    
    try json.stringify(json_data, .{}, json_string.writer());
    
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("Content-Type", "application/json");
    
    return client.post(url, json_string.items, headers);
}

pub fn putJson(client: *HttpClient, url: []const u8, json_data: anytype) !HttpResponse {
    var json_string = std.ArrayList(u8).init(client.allocator);
    defer json_string.deinit();
    
    try json.stringify(json_data, .{}, json_string.writer());
    
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("Content-Type", "application/json");
    
    return client.put(url, json_string.items, headers);
}

pub fn patchJson(client: *HttpClient, url: []const u8, json_data: anytype) !HttpResponse {
    var json_string = std.ArrayList(u8).init(client.allocator);
    defer json_string.deinit();
    
    try json.stringify(json_data, .{}, json_string.writer());
    
    var headers = std.StringHashMap([]const u8).init(client.allocator);
    defer headers.deinit();
    try headers.put("Content-Type", "application/json");
    
    return client.patch(url, json_string.items, headers);
}

// Example usage function
pub fn runExamples(allocator: std.mem.Allocator) !void {
    var client = HttpClient.init(allocator);
    defer client.deinit();

    std.log.info("Running HTTP examples with httpbin.org", .{});

    // Example 1: GET request
    {
        std.log.info("1. GET request to /get", .{});
        var response = client.get("https://httpbin.org/get", null) catch |err| {
            std.log.err("GET request failed: {}", .{err});
            return;
        };
        defer response.deinit();
        std.log.info("Status: {}, Body length: {}", .{ response.status_code, response.body.len });
    }

    // Example 2: POST request with JSON
    {
        std.log.info("2. POST request to /post with JSON", .{});
        const data = .{ .name = "Zig Demo", .message = "Hello from Zig!" };
        var response = postJson(&client, "https://httpbin.org/post", data) catch |err| {
            std.log.err("POST request failed: {}", .{err});
            return;
        };
        defer response.deinit();
        std.log.info("Status: {}, Body length: {}", .{ response.status_code, response.body.len });
    }

    // Example 3: PUT request
    {
        std.log.info("3. PUT request to /put", .{});
        const data = .{ .update = "from Zig" };
        var response = putJson(&client, "https://httpbin.org/put", data) catch |err| {
            std.log.err("PUT request failed: {}", .{err});
            return;
        };
        defer response.deinit();
        std.log.info("Status: {}, Body length: {}", .{ response.status_code, response.body.len });
    }

    // Example 4: DELETE request
    {
        std.log.info("4. DELETE request to /delete", .{});
        var response = client.delete("https://httpbin.org/delete", null) catch |err| {
            std.log.err("DELETE request failed: {}", .{err});
            return;
        };
        defer response.deinit();
        std.log.info("Status: {}, Body length: {}", .{ response.status_code, response.body.len });
    }

    // Example 5: Custom headers
    {
        std.log.info("5. GET request with custom headers", .{});
        var headers = std.StringHashMap([]const u8).init(allocator);
        defer headers.deinit();
        try headers.put("User-Agent", "Zig-Demo-Client/1.0");
        try headers.put("X-Custom-Header", "test-value");
        
        var response = client.get("https://httpbin.org/headers", headers) catch |err| {
            std.log.err("Custom headers request failed: {}", .{err});
            return;
        };
        defer response.deinit();
        std.log.info("Status: {}, Body length: {}", .{ response.status_code, response.body.len });
    }

    std.log.info("All examples completed successfully!", .{});
}