// HTTP GET 请求示例程序
// 使用 Zig 标准库发送 GET 请求到 https://httpbin.org/stream/2
// 设置 Accept 头为 application/json，并打印响应体

const std = @import("std");

pub fn main() !void {
    // 初始化通用分配器，用于内存管理
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("[debug] allocator initialized\n", .{});

    // 创建 HTTP 客户端
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    std.debug.print("[debug] http client created\n", .{});

    // 解析目标 URL
    const uri = try std.Uri.parse("https://httpbin.org/get");

    // 定义请求头，设置 Accept 为 application/json
    const headers = [_]std.http.Header{
        .{ .name = "accept", .value = "application/json" },
    };

    // 初始化 ArrayList 用于存储响应体
    var body = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer body.deinit(allocator);

    std.debug.print("[debug] about to call client.fetch\n", .{});

    // 使用 Allocating writer 将响应写入 ArrayList（匹配 API 要求的 Writer 类型）
    var aw: std.io.Writer.Allocating = .fromArrayList(allocator, &body);

    // 发送 HTTP GET 请求，响应写入 aw.writer
    const res = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .extra_headers = &headers,
        .response_writer = &aw.writer,
    });

    // 将 Allocating writer 的内容写回 body，以便之后读取和打印
    body = aw.toArrayList();

    const status_phrase = res.status.phrase() orelse "?";
    std.debug.print("[debug] status phrase = {s}\n", .{status_phrase});
    std.debug.print("[debug] body len = {d}\n", .{body.items.len});

    // 打印响应体内容
    std.debug.print("{s}\n", .{body.items});
}
