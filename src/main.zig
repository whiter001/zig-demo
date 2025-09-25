const std = @import("std");
const fetch = @import("fetch/mod.zig");
const examples = @import("fetch/examples.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("Zig Demo - HTTP Fetch Examples", .{});
    
    // Run basic examples from the fetch module
    try fetch.runExamples(allocator);
    
    // Run comprehensive httpbin.org examples  
    try examples.runHttpbinExamples(allocator);
}

test "basic test" {
    try std.testing.expect(true);
}