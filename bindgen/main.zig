pub fn main() !void {
    // Setup allocators
    var gpa: DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    // Parse extension_api.json
    const cwd = fs.cwd();
    const path = try cwd.realpathAlloc(allocator, "extension_api.json");
    const contents = try cwd.readFileAlloc(allocator, path, 10 * 1024 * 1024);
    const json = try Json.parse(allocator, contents);

    // Generate the code
    try write(json.value, std.io.getStdOut().writer());
}

const std = @import("std");

const Json = @import("Json.zig");
const write = @import("print.zig").write;

const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const fs = std.fs;
