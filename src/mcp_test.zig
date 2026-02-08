const std = @import("std");
const mcp = @import("mcp");

test "greet handler responds to tools/call" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try mcp.MCPServer.init(allocator);
    defer server.deinit();

    // Register the greet tool like in src/main.zig
    try server.registerTool(.{
        .name = "greet",
        .description = "Greets a user by name",
        .input_schema = "",
        .handler = greetHandler,
    });

    const payload = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"tool\":\"greet\",\"input\":{\"name\":\"Alice\"}}}";

    const response = try server.handleRequest(payload);
    defer allocator.free(response);

    // response is a JSON string; check it contains "Hello, Alice"
    const resp_str = response[0..response.len];
    try std.testing.expect(std.mem.contains(u8, resp_str, "Hello, Alice"));
}

fn greetHandler(allocator: std.mem.Allocator, params: std.json.Value) !std.json.Value {
    const maybe_name = params.object.get("name");
    const name = if (maybe_name) |v| v.string else "World";
    const message = try std.fmt.allocPrint(allocator, "Hello, {s}!", .{name});
    return std.json.Value{ .string = message };
}
