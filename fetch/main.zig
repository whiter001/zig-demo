// HTTP GET 请求示例程序
// 使用 Zig 标准库发送 GET 请求到 https://httpbin.org/stream/2
// 设置 Accept 头为 application/json，并打印响应体

const std = @import("std");

fn run_get(client: *std.http.Client, allocator: std.mem.Allocator, url: []const u8) !void {
    const uri = try std.Uri.parse(url);

    const headers = [_]std.http.Header{
        .{ .name = "accept", .value = "application/json" },
    };

    var body = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer body.deinit(allocator);

    var aw: std.io.Writer.Allocating = .fromArrayList(allocator, &body);

    const res = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .extra_headers = &headers,
        .response_writer = &aw.writer,
    });

    body = aw.toArrayList();

    std.debug.print("HTTP status: {}\n", .{res.status});
    std.debug.print("body length: {}\n", .{body.items.len});
    std.debug.print("{s}\n", .{body.items});
}

fn run_stream(client: *std.http.Client, allocator: std.mem.Allocator, url: []const u8) !void {
    const uri = try std.Uri.parse(url);

    const headers = [_]std.http.Header{
        .{ .name = "accept", .value = "application/json" },
    };

    var body = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer body.deinit(allocator);

    var aw: std.io.Writer.Allocating = .fromArrayList(allocator, &body);

    const res = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .extra_headers = &headers,
        .response_writer = &aw.writer,
    });

    body = aw.toArrayList();

    // 把 body 按行拆分并逐行打印，适用于 stream/2 的逐行 JSON 返回
    var start: usize = 0;
    var idx: usize = 0;
    while (idx < body.items.len) : (idx += 1) {
        const b = body.items[idx];
        if (b == '\n') {
            const line = body.items[start..idx];
            if (line.len != 0) std.debug.print("stream line: {s}\n", .{line});
            start = idx + 1;
        }
    }
    if (start < body.items.len) {
        const last = body.items[start..body.items.len];
        if (last.len != 0) std.debug.print("stream line: {s}\n", .{last});
    }

    std.debug.print("stream finished, status: {}\n", .{res.status});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const mode = if (args.len > 1) args[1] else "get";

    if (std.mem.eql(u8, mode, "stream")) {
        try run_stream(&client, allocator, "https://httpbin.org/stream/2");
    } else {
        try run_get(&client, allocator, "https://httpbin.org/get");
    }
}
