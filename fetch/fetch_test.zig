const std = @import("std");
const fetch = @import("fetch.zig");

test "target_uri correct" {
    try std.testing.expectEqualStrings("https://httpbin.org/stream/2", fetch.target_uri());
}

test "accept header correct" {
    try std.testing.expectEqualStrings("accept", fetch.accept_json_header_name());
    try std.testing.expectEqualStrings("application/json", fetch.accept_json_header_value());
}
