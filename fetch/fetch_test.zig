const std = @import("std");
const fetch = @import("fetch.zig");

test "target_uri correct" {
    try std.testing.expectEqualStrings("https://httpbin.org/stream/2", fetch.target_uri());
}

test "accept header correct" {
    try std.testing.expectEqualStrings("accept", fetch.accept_json_header_name());
    try std.testing.expectEqualStrings("application/json", fetch.accept_json_header_value());

    const h = fetch.accept_json_header();
    try std.testing.expectEqualStrings(fetch.accept_json_header_name(), h.name);
    try std.testing.expectEqualStrings(fetch.accept_json_header_value(), h.value);
}

test "target_uri parses and has expected host and path" {
    const uri = try std.Uri.parse(fetch.target_uri());

    var host_buf: [256]u8 = undefined;
    const host = try uri.getHost(&host_buf);
    try std.testing.expectEqualStrings("httpbin.org", host);

    var path_buf: [256]u8 = undefined;
    const path = try uri.path.toRaw(&path_buf);
    try std.testing.expectEqualStrings("/stream/2", path);
}

test "split_lines splits CRLF/LF inputs correctly" {
    const input1 = "line1\nline2\n";
    const lines1 = try fetch.split_lines(std.testing.allocator, input1);
    defer std.testing.allocator.free(lines1);
    try std.testing.expectEqualStrings("line1", lines1[0]);
    try std.testing.expectEqualStrings("line2", lines1[1]);

    const input2 = "line1\nline2"; // no trailing newline
    const lines2 = try fetch.split_lines(std.testing.allocator, input2);
    defer std.testing.allocator.free(lines2);
    try std.testing.expectEqualStrings("line1", lines2[0]);
    try std.testing.expectEqualStrings("line2", lines2[1]);

    const input3 = "";
    const lines3 = try fetch.split_lines(std.testing.allocator, input3);
    defer std.testing.allocator.free(lines3);
    try std.testing.expectEqual(lines3.len, 0);
}