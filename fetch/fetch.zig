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
