const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var it = std.process.args();
    _ = it.next(); // skip program name
    const maybe_name = it.next();
    const name = if (maybe_name) |v| v else "World";

    const prefix = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"tool\":\"greet\",\"input\":{\"name\":\"";
    const suffix = "\"}}}";
    const payload = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ prefix, name, suffix });
    defer allocator.free(payload);

    const len = payload.len;

    // Write Content-Length framed message to stdout
    const stdout = std.fs.File.stdout();
    const header = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n", .{len});
    defer allocator.free(header);
    try stdout.writeAll(header);
    try stdout.writeAll(payload);
}
