pub fn main() !void {
    var gpa: DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    const cwd = fs.cwd();
    const path = try cwd.realpathAlloc(allocator, "extension_api.json");
    const contents = try cwd.readFileAlloc(allocator, path, 10 * 1024 * 1024);

    const json = try Schema.parseLeaky(allocator, contents);
    const data = try transform(allocator, json);

    const writer = std.io.getStdOut().writer();

    // TODO: remove
    try @import("writer.zig").write(json, writer);

    try render(allocator, data, writer);
}

const std = @import("std");

const Schema = @import("Schema.zig");
const transform = @import("transform.zig").transform;
const render = @import("render.zig").render;

const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const fs = std.fs;
