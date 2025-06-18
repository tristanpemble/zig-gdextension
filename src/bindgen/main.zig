pub fn main() !void {
    // Setup allocators
    var gpa: DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var arena = ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    // Load the GDExtension API definitions
    const cwd = fs.cwd();
    const path = try cwd.realpathAlloc(allocator, "extension_api.json");
    const contents = try cwd.readFileAlloc(allocator, path, 10 * 1024 * 1024);
    const api = try Api.parseLeaky(allocator, contents);

    // Run the generator
    const generator = try Generator.init(api);
    generator.run();
}

const std = @import("std");

const Api = @import("Api.zig");
const Generator = @import("Generator.zig");

const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const fs = std.fs;
const io = std.io;
const json = std.json;
