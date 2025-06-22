pub fn main() !void {
    var gpa: DebugAllocator(.{}) = .init;
    var arena = ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    var args = std.process.args();
    _ = args.skip();

    const dir = try fs.cwd().openDir(args.next() orelse ".", .{});
    const interface = try dir.readFileAlloc(allocator, "gdextension_interface.h", 10 * 1024 * 1024);
    const extension_api = try dir.readFileAlloc(allocator, "extension_api.json", 10 * 1024 * 1024);
    const out = try dir.makeOpenPath("out", .{
        .access_sub_paths = true,
    });

    const json = try Schema.parseLeaky(allocator, extension_api);
    const data = try transform(allocator, json, interface);

    try render(allocator, out, data);
}

const std = @import("std");

const Schema = @import("Schema.zig");
const transform = @import("transform.zig").transform;
const render = @import("render.zig").render;

const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const fs = std.fs;
