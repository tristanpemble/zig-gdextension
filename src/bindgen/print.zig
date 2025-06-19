//! This module implements the logic for generating Zig code using:
//!
//! - The API definitions defined in `./Api.zig`
//! - The templates defined in `./templates.zig`
//!

pub fn print(api: Api, writer: anytype) !void {
    try printBanner(0,
        \\Classes
    , writer);
    var class_iter = api.classes.iterator();
    while (class_iter.next()) |entry| {
        if (class_iter.index > 1) try writer.writeAll("\n");
        try printClass(entry.value_ptr, writer);
    }
}

fn printClass(class: *const Api.Class, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{class.getName()});

    switch (class.*) {
        .builtin => |builtin| try printBuiltinClass(&builtin, w),
        .engine => |engine| try printEngineClass(&engine, w),
    }

    try w.print(
        \\}};
        \\
    , .{});
}

fn printBuiltinClass(class: *const Api.Class.Builtin, w: anytype) !void {
    if (class.constants.values().len > 0) {
        try printBanner(1,
            \\Constants
        , w);
        var constant_iter = class.constants.iterator();
        while (constant_iter.next()) |constant| {
            try printConstant(constant.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.enums.values().len > 0) {
        try printBanner(1,
            \\Enums
        , w);
        var enum_iter = class.enums.iterator();
        while (enum_iter.next()) |entry| {
            try printClassEnum(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.methods.values().len > 0) {
        try printBanner(1,
            \\Methods
        , w);
        var method_iter = class.methods.iterator();
        while (method_iter.next()) |method| {
            if (method_iter.index > 1) try w.writeAll("\n");
            try printBuiltinMethod(class, method.value_ptr, w);
        }
    }
}

fn printBuiltinMethod(class: *const Api.Class.Builtin, method: *const Api.Method, w: anytype) !void {
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
        \\    }};
        \\
    , .{});
}

fn printEngineClass(class: *const Api.Class.Engine, w: anytype) !void {
    if (class.inherits.len > 0) {
        try w.print(
            \\    pub const Base = {s};
            \\
        , .{class.inherits});
    }

    if (class.constants.values().len > 0) {
        try printBanner(1,
            \\Constants
        , w);
        var constant_iter = class.constants.iterator();
        while (constant_iter.next()) |entry| {
            try printConstant(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.enums.values().len > 0) {
        try printBanner(1,
            \\Enums
        , w);
        var enum_iter = class.enums.iterator();
        while (enum_iter.next()) |entry| {
            try printClassEnum(entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.properties.values().len > 0) {
        try printBanner(1,
            \\Properties
        , w);
        var property_iter = class.properties.iterator();
        while (property_iter.next()) |entry| {
            if (property_iter.index > 1) try w.writeAll("\n");
            try printClassProperty(class, entry.value_ptr, w);
        }
        try w.writeAll("\n");
    }

    if (class.methods.values().len > 0) {
        try printBanner(1,
            \\Methods
        , w);
        var method_iter = class.methods.iterator();
        while (method_iter.next()) |entry| {
            if (method_iter.index > 1) try w.writeAll("\n");
            try printEngineMethod(class, entry.value_ptr, w);
        }
    }
}

fn printEngineMethod(class: *const Api.Class.Engine, method: *const Api.Method, w: anytype) !void {
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

fn printConstant(constant: *const Api.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: {s} = {s};
        \\
    , .{ constant.name, constant.type, constant.value });
}

fn printClassEnum(@"enum": *const Api.Enum, w: anytype) !void {
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

fn printClassProperty(class: *const Api.Class.Engine, property: *const Api.Class.Property, w: anytype) !void {
    if (property.getter.len > 0) {
        try w.print(
            \\    pub fn {s}(self: *const {s}) !{s} {{
            \\    }}
            \\
        , .{ property.getter, class.name, property.type });
    }

    if (property.getter.len > 0 and property.setter.len > 0) {
        try w.writeAll("\n");
    }

    if (property.setter.len > 0) {
        try w.print(
            \\    pub fn {s}(self: *const {s}, value: {s}) !void {{
            \\    }}
            \\
        , .{ property.setter, class.name, property.type });
    }
}

fn printBanner(comptime indent: u4, text: anytype, w: anytype) !void {
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

const std = @import("std");
const Allocator = std.mem.Allocator;

const mustache = @import("mustache");

const Api = @import("Api.zig");
