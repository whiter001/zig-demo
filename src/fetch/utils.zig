const std = @import("std");
const fetch = @import("mod.zig");

/// URL encoding utility
pub fn urlEncode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var encoded = std.ArrayList(u8).init(allocator);
    defer encoded.deinit();
    
    for (input) |byte| {
        switch (byte) {
            'A'...'Z', 'a'...'z', '0'...'9', '-', '_', '.', '~' => {
                try encoded.append(byte);
            },
            ' ' => {
                try encoded.append('+');
            },
            else => {
                try encoded.writer().print("%{X:0>2}", .{byte});
            },
        }
    }
    
    return encoded.toOwnedSlice();
}

/// Build query string from key-value pairs
pub fn buildQueryString(allocator: std.mem.Allocator, params: std.StringHashMap([]const u8)) ![]u8 {
    var query = std.ArrayList(u8).init(allocator);
    defer query.deinit();
    
    var iterator = params.iterator();
    var first = true;
    
    while (iterator.next()) |entry| {
        if (!first) {
            try query.append('&');
        }
        first = false;
        
        const encoded_key = try urlEncode(allocator, entry.key_ptr.*);
        defer allocator.free(encoded_key);
        const encoded_value = try urlEncode(allocator, entry.value_ptr.*);
        defer allocator.free(encoded_value);
        
        try query.writer().print("{s}={s}", .{ encoded_key, encoded_value });
    }
    
    return query.toOwnedSlice();
}

/// Build URL with query parameters
pub fn buildUrlWithParams(allocator: std.mem.Allocator, base_url: []const u8, params: std.StringHashMap([]const u8)) ![]u8 {
    const query_string = try buildQueryString(allocator, params);
    defer allocator.free(query_string);
    
    if (query_string.len == 0) {
        return allocator.dupe(u8, base_url);
    }
    
    const separator = if (std.mem.indexOf(u8, base_url, "?") != null) "&" else "?";
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ base_url, separator, query_string });
}

/// Create basic auth header value
pub fn createBasicAuth(allocator: std.mem.Allocator, username: []const u8, password: []const u8) ![]u8 {
    const credentials = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ username, password });
    defer allocator.free(credentials);
    
    const encoder = std.base64.standard.Encoder;
    const encoded_len = encoder.calcSize(credentials.len);
    const encoded = try allocator.alloc(u8, encoded_len);
    _ = encoder.encode(encoded, credentials);
    
    const auth_header = try std.fmt.allocPrint(allocator, "Basic {s}", .{encoded});
    allocator.free(encoded);
    
    return auth_header;
}

/// Create bearer token header value
pub fn createBearerAuth(allocator: std.mem.Allocator, token: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "Bearer {s}", .{token});
}

/// Parse JSON response body
pub fn parseJsonResponse(comptime T: type, allocator: std.mem.Allocator, response: *const fetch.HttpResponse) !std.json.Parsed(T) {
    return std.json.parseFromSlice(T, allocator, response.body, .{});
}

/// Check if response is JSON
pub fn isJsonResponse(response: *const fetch.HttpResponse) bool {
    if (response.headers.get("content-type")) |content_type| {
        return std.mem.indexOf(u8, content_type, "application/json") != null;
    }
    return false;
}

/// Extract filename from Content-Disposition header
pub fn extractFilename(response: *const fetch.HttpResponse) ?[]const u8 {
    if (response.headers.get("content-disposition")) |disposition| {
        if (std.mem.indexOf(u8, disposition, "filename=")) |start_idx| {
            const filename_start = start_idx + "filename=".len;
            if (filename_start < disposition.len) {
                var filename_end = disposition.len;
                for (disposition[filename_start..], filename_start..) |char, idx| {
                    if (char == ';' or char == ' ') {
                        filename_end = idx;
                        break;
                    }
                }
                var filename = disposition[filename_start..filename_end];
                // Remove quotes if present
                if (filename.len >= 2 and filename[0] == '"' and filename[filename.len - 1] == '"') {
                    filename = filename[1 .. filename.len - 1];
                }
                return filename;
            }
        }
    }
    return null;
}

/// Download file to disk
pub fn downloadFile(client: *fetch.HttpClient, url: []const u8, file_path: []const u8) !void {
    var response = try client.get(url, null);
    defer response.deinit();
    
    if (response.status_code != 200) {
        return error.DownloadFailed;
    }
    
    const file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();
    
    try file.writeAll(response.body);
}

/// Retry mechanism for HTTP requests
pub fn retryRequest(
    client: *fetch.HttpClient,
    method: fetch.HttpMethod,
    url: []const u8,
    headers: ?std.StringHashMap([]const u8),
    body: ?[]const u8,
    max_retries: u32,
    delay_ms: u64,
) !fetch.HttpResponse {
    var last_error: anyerror = error.MaxRetriesExceeded;
    
    for (0..max_retries + 1) |attempt| {
        const response = client.request(method, url, headers, body) catch |err| {
            last_error = err;
            if (attempt < max_retries) {
                std.log.warn("Request attempt {} failed: {}, retrying in {}ms...", .{ attempt + 1, err, delay_ms });
                std.time.sleep(delay_ms * std.time.ns_per_ms);
                continue;
            }
            break;
        };
        return response;
    }
    
    return last_error;
}

/// Rate limiter for API calls
pub const RateLimiter = struct {
    last_request_time: i64,
    min_interval_ms: u64,
    
    pub fn init(min_interval_ms: u64) RateLimiter {
        return RateLimiter{
            .last_request_time = 0,
            .min_interval_ms = min_interval_ms,
        };
    }
    
    pub fn waitIfNeeded(self: *RateLimiter) void {
        const now = std.time.milliTimestamp();
        const elapsed = now - self.last_request_time;
        
        if (elapsed < self.min_interval_ms) {
            const wait_time = self.min_interval_ms - @as(u64, @intCast(elapsed));
            std.time.sleep(wait_time * std.time.ns_per_ms);
        }
        
        self.last_request_time = std.time.milliTimestamp();
    }
};

/// HTTP response cache
pub const ResponseCache = struct {
    cache: std.StringHashMap(CachedResponse),
    allocator: std.mem.Allocator,
    
    const CachedResponse = struct {
        response: fetch.HttpResponse,
        timestamp: i64,
        ttl_ms: u64,
        
        pub fn isExpired(self: *const CachedResponse) bool {
            const now = std.time.milliTimestamp();
            return (now - self.timestamp) > self.ttl_ms;
        }
    };
    
    pub fn init(allocator: std.mem.Allocator) ResponseCache {
        return ResponseCache{
            .cache = std.StringHashMap(CachedResponse).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *ResponseCache) void {
        var iterator = self.cache.iterator();
        while (iterator.next()) |entry| {
            var cached = entry.value_ptr;
            cached.response.deinit();
            self.allocator.free(entry.key_ptr.*);
        }
        self.cache.deinit();
    }
    
    pub fn get(self: *ResponseCache, url: []const u8) ?*const fetch.HttpResponse {
        if (self.cache.getPtr(url)) |cached| {
            if (!cached.isExpired()) {
                return &cached.response;
            }
            // Clean up expired entry
            cached.response.deinit();
            self.allocator.free(url);
            _ = self.cache.remove(url);
        }
        return null;
    }
    
    pub fn put(self: *ResponseCache, url: []const u8, response: fetch.HttpResponse, ttl_ms: u64) !void {
        const url_copy = try self.allocator.dupe(u8, url);
        const cached = CachedResponse{
            .response = response,
            .timestamp = std.time.milliTimestamp(),
            .ttl_ms = ttl_ms,
        };
        try self.cache.put(url_copy, cached);
    }
};

// Test utilities for the utils module
test "URL encoding" {
    const allocator = std.testing.allocator;
    
    const encoded = try urlEncode(allocator, "hello world!@#$%");
    defer allocator.free(encoded);
    
    try std.testing.expect(std.mem.eql(u8, encoded, "hello+world%21%40%23%24%25"));
}

test "Query string building" {
    const allocator = std.testing.allocator;
    
    var params = std.StringHashMap([]const u8).init(allocator);
    defer params.deinit();
    
    try params.put("name", "John Doe");
    try params.put("age", "30");
    try params.put("city", "New York");
    
    const query = try buildQueryString(allocator, params);
    defer allocator.free(query);
    
    // The order might vary, so we check for presence of all parts
    try std.testing.expect(std.mem.indexOf(u8, query, "name=John+Doe") != null);
    try std.testing.expect(std.mem.indexOf(u8, query, "age=30") != null);
    try std.testing.expect(std.mem.indexOf(u8, query, "city=New+York") != null);
}

test "Basic auth creation" {
    const allocator = std.testing.allocator;
    
    const auth = try createBasicAuth(allocator, "user", "pass");
    defer allocator.free(auth);
    
    try std.testing.expect(std.mem.startsWith(u8, auth, "Basic "));
}

test "Bearer auth creation" {
    const allocator = std.testing.allocator;
    
    const auth = try createBearerAuth(allocator, "my-token");
    defer allocator.free(auth);
    
    try std.testing.expect(std.mem.eql(u8, auth, "Bearer my-token"));
}