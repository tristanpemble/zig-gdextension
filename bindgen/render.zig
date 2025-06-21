pub fn render(allocator: Allocator, data: Data, writer: anytype) !void {
    try mustache.render(getTemplate(allocator, template.root), data, writer);
    try mustache.render(getTemplate(allocator, template.interface), data, writer);

    for (data.builtins) |builtin| {
        // TODO: to own file
        try mustache.render(getTemplate(allocator, template.builtin), .{ .builtin = builtin }, writer);
    }

    for (data.classes) |class| {
        // TODO: to own file
        try mustache.render(getTemplate(allocator, template.class), .{ .class = class }, writer);
    }

    for (data.enums) |@"enum"| {
        // TODO: to own file
        try mustache.render(getTemplate(allocator, template.@"enum"), .{ .@"enum" = @"enum" }, writer);
    }

    for (data.flags) |flag| {
        // TODO: to own file
        try mustache.render(getTemplate(allocator, template.flag), .{ .flag = flag }, writer);
    }

    for (data.functions) |function| {
        // TODO: to own file
        try mustache.render(getTemplate(allocator, template.function), .{ .function = function }, writer);
    }
}

fn getTemplate(allocator: Allocator, comptime text: []const u8) mustache.Template {
    return struct {
        var t: ?mustache.Template = null;

        pub fn get(a: Allocator) mustache.Template {
            if (t == null) {
                const result = mustache.parseText(a, text, .{}, .{ .copy_strings = false }) catch unreachable;
                switch (result) {
                    .success => |tmpl| t = tmpl,
                    .parse_error => |err| std.debug.panic("{}", .{err}),
                }
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
