pub fn render(allocator: Allocator, data: Data, writer: anytype) !void {
    try mustache.render(getTemplate(allocator, template.root), data, writer);
    try mustache.render(getTemplate(allocator, template.interface), data, writer);

    const builtin_tmpl = getTemplate(allocator, template.builtin);
    const class_tmpl = getTemplate(allocator, template.class);
    const enum_tmpl = getTemplate(allocator, template.enum_);
    const flag_tmpl = getTemplate(allocator, template.flag);
    const function_tmpl = getTemplate(allocator, template.function);
    const signature_tmpl = getTemplate(allocator, template.signature);

    for (data.builtins) |builtin| {
        try mustache.renderPartials(builtin_tmpl, .{ .{ "enum", enum_tmpl }, .{ "flag", flag_tmpl }, .{ "signature", signature_tmpl } }, builtin, writer);
    }

    for (data.classes) |class| {
        try mustache.renderPartials(class_tmpl, .{ .{ "enum", enum_tmpl }, .{ "flag", flag_tmpl }, .{ "signature", signature_tmpl } }, class, writer);
    }

    for (data.enums) |enum_| {
        try mustache.render(enum_tmpl, enum_, writer);
    }

    for (data.flags) |flag| {
        try mustache.render(flag_tmpl, flag, writer);
    }

    for (data.functions) |function| {
        try mustache.renderPartials(function_tmpl, .{.{ "signature", signature_tmpl }}, .{ .function = function }, writer);
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
