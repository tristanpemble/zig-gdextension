pub fn transform(allocator: Allocator, json: Schema) !Data {
    _ = allocator;
    _ = json;
    return Data{};
}

const std = @import("std");
const gd = @import("godot");

const Schema = @import("./Schema.zig");
const Data = @import("./Data.zig");

const Allocator = std.mem.Allocator;
