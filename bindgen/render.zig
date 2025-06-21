pub fn render(allocator: Allocator, data: Data, writer: anytype) !void {
    for (data.builtins) |builtin| {
        try mustache.render(getTemplate(allocator, template.builtin), .{ .builtin = builtin }, writer);
    }

    for (data.classes) |class| {
        try mustache.render(getTemplate(allocator, template.class), .{ .class = class }, writer);
    }

    for (data.constants) |constant| {
        try mustache.render(getTemplate(allocator, template.constant), .{ .constant = constant }, writer);
    }

    for (data.enums) |@"enum"| {
        try mustache.render(getTemplate(allocator, template.@"enum"), .{ .@"enum" = @"enum" }, writer);
    }

    for (data.flags) |function| {
        try mustache.render(getTemplate(allocator, template.flag), .{ .function = function }, writer);
    }

    for (data.functions) |function| {
        try mustache.render(getTemplate(allocator, template.function), .{ .function = function }, writer);
    }
}

fn getTemplate(allocator: Allocator, comptime text: []const u8) mustache.Template {
    return struct {
        var t: ?mustache.Template = null;

        pub fn get(a: Allocator) mustache.Template {
            if (t == null) {
                const result = mustache.parseText(a, text, .{}, .{ .copy_strings = false }) catch unreachable;
                t = result.success;
            }
            return t.?;
        }
    }.get(allocator);
}

const std = @import("std");
const mustache = @import("mustache");

const Data = @import("Data.zig");
const template = @import("template.zig");

const Allocator = std.mem.Allocator;
