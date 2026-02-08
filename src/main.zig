const std = @import("std");
const mcp = @import("mcp");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try mcp.MCPServer.init(allocator);
    defer server.deinit();

    // Register a simple greet tool
    try server.registerTool(.{
        .name = "greet",
        .description = "Greets a user by name",
        .input_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "name": { "type": "string" }
        \\  },
        \\  "required": ["name"]
        \\}
        ,
        .handler = greetHandler,
    });

    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    var read_buf: [8192]u8 = undefined;
    var write_buf: [8192]u8 = undefined;
    var reader = stdin.reader(&read_buf);
    var writer = stdout.writer(&write_buf);

    while (true) {
        const message = mcp.readContentLengthFrame(allocator, &reader.interface) catch break;
        defer allocator.free(message);

        if (message.len == 0) continue;

        const response = try server.handleRequest(message);
        defer allocator.free(response);

        if (response.len > 0) {
            try mcp.writeContentLengthFrame(&writer.interface, response);
            try writer.interface.flush();
        }
    }
}

fn greetHandler(allocator: std.mem.Allocator, params: std.json.Value) !std.json.Value {
    const maybe_name = params.object.get("name");
    const name = if (maybe_name) |v| v.string else "World";
    const message = try std.fmt.allocPrint(allocator, "Hello, {s}!", .{name});
    return std.json.Value{ .string = message };
}
