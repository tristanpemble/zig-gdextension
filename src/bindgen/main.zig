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
    const api = try Api.init(allocator, &json.value, .{});

    try print(api, std.io.getStdOut().writer());
}

const std = @import("std");

const Api = @import("Api.zig");
const Json = @import("Json.zig");
const print = @import("print.zig").print;

const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const fs = std.fs;
