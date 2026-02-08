const std = @import("std");

pub fn target_uri() []const u8 {
    return "https://httpbin.org/stream/2";
}

pub fn accept_json_header() std.http.Header {
    return .{ .name = "accept", .value = "application/json" };
}

pub fn accept_json_header_name() []const u8 {
    return "accept";
}

pub fn accept_json_header_value() []const u8 {
    return "application/json";
}

// Split a buffer into lines (without trailing newline characters) and
// return an allocated array of slices referencing `body`. The returned
// array must be freed by the caller using the provided allocator.
pub fn split_lines(allocator: std.mem.Allocator, body: []const u8) std.mem.Allocator.Error![]const []const u8 {
    // Count lines
    var count: usize = 0;
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (body[i] == '\n') count += 1;
    }
    // If body doesn't end with newline and not empty, it has a last line
    if (body.len != 0 and (body[body.len - 1] != '\n')) count += 1;

    const out = try allocator.alloc([]const u8, count);
    var idx: usize = 0;
    var start: usize = 0;
    i = 0;
    while (i < body.len) : (i += 1) {
        if (body[i] == '\n') {
            out[idx] = body[start..i];
            idx += 1;
            start = i + 1;
        }
    }
    if (start < body.len) {
        out[idx] = body[start..body.len];
    }

    return out;
}