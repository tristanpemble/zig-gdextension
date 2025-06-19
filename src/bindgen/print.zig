//! This module implements the logic for generating Zig code using:
//!
//! - The API definitions defined in `./Api.zig`
//! - The templates defined in `./templates.zig`
//!

pub const Config = struct {
    case: struct {
        argument: case.Case = .snake,
        constant: case.Case = .snake,
        function: case.Case = .camel,
        property: case.Case = .snake,
        type: case.Case = .pascal,
        variant: case.Case = .snake,
    } = .{},
};

pub fn write(api: Api, writer: anytype) !void {
    try writeBanner(0,
        \\Builtins
    , writer);
    var builtins_iter = api.builtins.iterator();
    while (builtins_iter.next()) |entry| {
        if (builtins_iter.index > 1) try writer.writeAll("\n");
        try writeBuiltin(entry.value_ptr, writer);
    }

    try writeBanner(0,
        \\Classes
    , writer);
    var class_iter = api.classes.iterator();
    while (class_iter.next()) |entry| {
        if (class_iter.index > 1) try writer.writeAll("\n");
        try writeClass(entry.value_ptr, writer);
    }
}

fn writeArguments(arguments: []const Api.Argument, w: anytype) !void {
    for (arguments, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ arg.name, arg.type });
    }
}

fn writeBuiltin(builtin: *const Api.Builtin, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{builtin.name});

    if (builtin.constants.values().len > 0) {
        try writeBanner(1,
            \\Constants
        , w);
        var constant_iter = builtin.constants.iterator();
        while (constant_iter.next()) |constant| {
            try writeClassConstant(constant.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (builtin.enums.values().len > 0) {
        try writeBanner(1,
            \\Enums
        , w);
        var enum_iter = builtin.enums.iterator();
        while (enum_iter.next()) |entry| {
            try writeClassEnum(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (builtin.methods.values().len > 0) {
        try writeBanner(1,
            \\Methods
        , w);
        var method_iter = builtin.methods.iterator();
        while (method_iter.next()) |method| {
            if (method_iter.index > 1) try w.writeAll("\n");
            try writeBuiltinMethod(builtin, method.value_ptr, w);
        }
    }

    try w.print(
        \\}};
        \\
    , .{});
}

fn writeBuiltinMethod(builtin: *const Api.Builtin, method: *const Api.Method, w: anytype) !void {
    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(args: anytype) !void {{
            \\
        , .{method.name});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}, args: anytype) !void {{
            \\
        , .{ method.name, ptr, builtin.name });
    }

    try w.print(
        \\    }};
        \\
    , .{});
}

fn writeClass(class: *const Api.Class, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{class.name});

    if (class.inherits) |inherits| {
        try w.print(
            \\    pub const Base = {s};
            \\
        , .{inherits});
    }

    if (class.constants.values().len > 0) {
        try writeBanner(1,
            \\Constants
        , w);
        var constant_iter = class.constants.iterator();
        while (constant_iter.next()) |entry| {
            try writeClassConstant(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.enums.values().len > 0) {
        try writeBanner(1,
            \\Enums
        , w);
        var enum_iter = class.enums.iterator();
        while (enum_iter.next()) |entry| {
            try writeClassEnum(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.properties.values().len > 0) {
        try writeBanner(1,
            \\Properties
        , w);
        var property_iter = class.properties.iterator();
        while (property_iter.next()) |entry| {
            if (property_iter.index > 1) try w.writeAll("\n");
            try writeClassProperty(class, entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.is_instantiable) {
        try writeBanner(1,
            \\Constructors
        , w);
        try w.writeAll("\n");

        try w.print(
            \\    pub fn init() {s} {{
            \\        @panic("todo");
            \\    }}
            \\
        , .{class.name});
    }

    if (class.methods.values().len > 0) {
        try writeBanner(1,
            \\Methods
        , w);
        var method_iter = class.methods.iterator();
        while (method_iter.next()) |entry| {
            if (method_iter.index > 1) try w.writeAll("\n");
            try writeClassMethod(class, entry.value_ptr, w);
        }
    }

    try w.print(
        \\}};
        \\
    , .{});
}

fn writeClassConstant(constant: *const Api.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: {s} = {s};
        \\
    , .{ constant.name, constant.type, constant.value });
}

fn writeClassEnum(@"enum": *const Api.Enum, w: anytype) !void {
    try w.print(
        \\    pub const {s} = enum {{
        \\
    , .{@"enum".name});

    var variant_iter = @"enum".values.iterator();
    while (variant_iter.next()) |entry| {
        try w.print(
            \\        {s} = {d},
            \\
        , .{ entry.value_ptr.name, entry.value_ptr.value });
    }

    try w.print(
        \\    }};
        \\
    , .{});
}

fn writeClassMethod(class: *const Api.Class, method: *const Api.Method, w: anytype) !void {
    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(args: anytype) !void {{
            \\
        , .{method.name});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}, args: anytype) !void {{
            \\
        , .{ method.name, ptr, class.name });
    }

    try w.print(
        \\    }}
        \\
    , .{});
}

fn writeClassProperty(class: *const Api.Class, property: *const Api.Property, w: anytype) !void {
    if (property.getter) |getter| {
        try w.print(
            \\    pub fn {s}(self: *const {s}) !{s} {{
            \\    }}
            \\
        , .{ getter, class.name, property.type });
    }

    if (property.getter != null and property.setter != null) {
        try w.writeAll("\n");
    }

    if (property.setter) |setter| {
        try w.print(
            \\    pub fn {s}(self: *const {s}, value: {s}) !void {{
            \\    }}
            \\
        , .{ setter, class.name, property.type });
    }
}

fn writeBanner(comptime indent: u4, text: anytype, w: anytype) !void {
    comptime var indentStr: []const u8 = "";
    inline for (0..indent) |_| {
        indentStr = indentStr ++ "    ";
    }
    try w.print(
        \\{0s}// {1s}
        \\
        \\
    , .{ indentStr, text });
}

// inline fn writeName(
//     comptime case_: case.Case,
//     text: []const u8,
//     writer: anytype,
// ) ![]const u8 {
//     var buf: [1024]u8 = undefined;

//     if (case.of(text, .{}) == case_)
//         buf = text
//     else
//         try case.bufTo(buf, case_, text);

//     if (std.zig.Token.keywords.has(&buf)) {
//         return try writer.print("@\"{s}\"", .{name});
//     } else {
//         return name;
//     }
// }

const std = @import("std");
const Allocator = std.mem.Allocator;

const case = @import("case");

const Api = @import("Api.zig");
