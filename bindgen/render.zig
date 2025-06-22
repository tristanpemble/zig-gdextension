pub fn render(allocator: Allocator, dir: fs.Dir, data: Data) !void {
    const builtin_dir = try dir.makeOpenPath("builtin", .{});
    const engine_dir = try dir.makeOpenPath("engine", .{});

    try renderRoot(allocator, dir, data);

    for (data.builtins) |builtin| {
        try renderBuiltin(allocator, builtin_dir, builtin);
    }

    for (data.classes) |class| {
        try renderClass(allocator, engine_dir, class);
    }

    for (data.enums) |enum_| {
        try renderEnum(allocator, builtin_dir, enum_);
    }

    for (data.flags) |flag| {
        try renderFlag(allocator, builtin_dir, flag);
    }

    for (data.modules) |module| {
        try renderModule(allocator, dir, module);
    }
}

pub fn renderRoot(allocator: Allocator, path: fs.Dir, data: Data) !void {
    const file = try path.createFile("root.zig", .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.render(getTemplate(allocator, template.root), data, writer);
}

pub fn renderBuiltin(allocator: Allocator, dir: fs.Dir, builtin: Data.Builtin) !void {
    const filename = std.fmt.allocPrint(allocator, "{s}.zig", .{builtin.name}) catch unreachable;
    const file = try dir.createFile(filename, .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.renderPartials(getTemplate(allocator, template.builtin), .{
        .{ "enum", getTemplate(allocator, template.enum_) },
        .{ "flag", getTemplate(allocator, template.flag) },
        .{ "signature", getTemplate(allocator, template.signature) },
    }, builtin, writer);
}

pub fn renderClass(allocator: Allocator, dir: fs.Dir, class: Data.Class) !void {
    const filename = std.fmt.allocPrint(allocator, "{s}.zig", .{class.name}) catch unreachable;
    const file = try dir.createFile(filename, .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.renderPartials(getTemplate(allocator, template.class), .{
        .{ "enum", getTemplate(allocator, template.enum_) },
        .{ "flag", getTemplate(allocator, template.flag) },
        .{ "signature", getTemplate(allocator, template.signature) },
    }, class, writer);
}

pub fn renderEnum(allocator: Allocator, dir: fs.Dir, enum_: Data.Enum) !void {
    const filename = std.fmt.allocPrint(allocator, "{s}.zig", .{enum_.name}) catch unreachable;
    const file = try dir.createFile(filename, .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.renderPartials(getTemplate(allocator, template.enum_), .{}, enum_, writer);
}

pub fn renderFlag(allocator: Allocator, dir: fs.Dir, flag: Data.Flag) !void {
    const filename = std.fmt.allocPrint(allocator, "{s}.zig", .{flag.name}) catch unreachable;
    const file = try dir.createFile(filename, .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.renderPartials(getTemplate(allocator, template.flag), .{}, flag, writer);
}

pub fn renderModule(allocator: Allocator, dir: fs.Dir, module: Data.Module) !void {
    const filename = std.fmt.allocPrint(allocator, "{s}.zig", .{module.name}) catch unreachable;
    const file = try dir.createFile(filename, .{
        .lock = .exclusive,
    });
    defer file.close();

    const writer = file.writer();

    try mustache.renderPartials(getTemplate(allocator, template.module), .{
        .{ "signature", getTemplate(allocator, template.signature) },
    }, module, writer);
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
const fs = std.fs;
