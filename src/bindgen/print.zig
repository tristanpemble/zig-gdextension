//! This module implements the logic for generating Zig code using:
//!
//! - The API definitions defined in `./Api.zig`
//! - The templates defined in `./templates.zig`
//!

var buf: [1024]u8 = "";

pub fn dump(json: Json, writer: anytype) !void {
    try printBanner(0, "Builtins", writer);
    for (json.builtin_classes, 0..) |builtin, i| {
        if (i > 0) try writer.writeAll("\n");
        try printBuiltin(builtin, writer);
    }

    // try printBanner(0, "Classes", writer);
    // for (json.classes, 0..) |class, i| {
    //     if (i > 0) try writer.writeAll("\n");
    //     try printClass(class, writer);
    // }
}

fn printBuiltin(builtin: *const Json.Builtin, w: anytype) !void {
    try print(w,
        \\pub const {s} = struct {{
        \\
    , .{typeName(builtin.name)});

    // if (builtin.constants) |constants| {
    //     try printBanner(1, "Constants", w);
    //     for (constants) |constant| {
    //         try printBuiltinConstant(constant, w);
    //     }
    //     try printNewline(w);
    // }

    // if (builtin.enums) |enums| {
    //     try printBanner(1, "Enums", w);
    //     for (enums) |@"enum"| {
    //         try printBuiltinEnum(@"enum", w);
    //     }
    //     try printNewline(w);
    // }

    if (builtin.methods) |methods| {
        try printBanner(1, "Methods", w);
        for (methods, 0..) |method, i| {
            if (i > 0) try printNewline(w);
            try printBuiltinMethod(builtin, method.value_ptr, w);
        }
    }

    try print(w,
        \\}};
        \\
    , .{});
}

fn printBuiltinMethod(builtin: *const Api.Builtin, method: *const Api.Method, w: anytype) !void {
    if (method.is_static) {
        try print(w,
            \\    pub fn {s}(args: anytype) !void {{
            \\
        , .{method.name});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try print(w,
            \\    pub fn {s}(self: {s}{s}, args: anytype) !void {{
            \\
        , .{ method.name, ptr, builtin.name });
    }

    try print(w,
        \\    }};
        \\
    , .{});
}

// fn printClass(class: *const Api.Class, w: anytype) !void {
//     try print(w,
//         \\pub const {s} = struct {{
//         \\
//     , .{class.name});

//     if (class.inherits) |inherits| {
//         try print(w,
//             \\    pub const Base = {s};
//             \\
//         , .{inherits});
//     }

//     if (class.constants.values().len > 0) {
//         try printBanner(1,
//             \\Constants
//         , w);
//         var constant_iter = class.constants.iterator();
//         while (constant_iter.next()) |entry| {
//             try printClassConstant(entry.value_ptr, w);
//         }
//         try printNewline(w);
//     }

//     if (class.enums.values().len > 0) {
//         try printBanner(1,
//             \\Enums
//         , w);
//         var enum_iter = class.enums.iterator();
//         while (enum_iter.next()) |entry| {
//             try printClassEnum(entry.value_ptr, w);
//         }
//         try printNewline(w);
//     }

//     if (class.properties.values().len > 0) {
//         try printBanner(1,
//             \\Properties
//         , w);
//         var property_iter = class.properties.iterator();
//         while (property_iter.next()) |entry| {
//             if (property_iter.index > 1) try printNewline(w);
//             try printClassProperty(class, entry.value_ptr, w);
//         }
//         try printNewline(w);
//     }

//     if (class.is_instantiable) {
//         try printBanner(1,
//             \\Constructors
//         , w);
//         try printNewline(w);

//         try print(w,
//             \\    pub fn init() {s} {{
//             \\        @panic("todo");
//             \\    }}
//             \\
//         , .{class.name});
//     }

//     if (class.methods.values().len > 0) {
//         try printBanner(1,
//             \\Methods
//         , w);
//         var method_iter = class.methods.iterator();
//         while (method_iter.next()) |entry| {
//             if (method_iter.index > 1) try printNewline(w);
//             try printClassMethod(class, entry.value_ptr, w);
//         }
//     }

//     try print(w,
//         \\}};
//         \\
//     , .{});
// }

// fn printClassConstant(constant: *const Api.Constant, w: anytype) !void {
//     try print(w,
//         \\    pub const {s}: {s} = {s};
//         \\
//     , .{ constant.name, constant.type, constant.value });
// }

// fn printClassEnum(@"enum": *const Api.Enum, w: anytype) !void {
//     try print(w,
//         \\    pub const {s} = enum {{
//         \\
//     , .{@"enum".name});

//     var variant_iter = @"enum".values.iterator();
//     while (variant_iter.next()) |entry| {
//         try print(w,
//             \\        {s} = {d},
//             \\
//         , .{ entry.value_ptr.name, entry.value_ptr.value });
//     }

//     try print(w,
//         \\    }};
//         \\
//     , .{});
// }

// fn printClassMethod(class: *const Api.Class, method: *const Api.Method, w: anytype) !void {
//     if (method.is_static) {
//         try print(w,
//             \\    pub fn {s}(args: anytype) !void {{
//             \\
//         , .{method.name});
//     } else {
//         const ptr = if (method.is_const) "*const " else "*";
//         try print(w,
//             \\    pub fn {s}(self: {s}{s}, args: anytype) !void {{
//             \\
//         , .{ method.name, ptr, class.name });
//     }

//     try print(w,
//         \\    }}
//         \\
//     , .{});
// }

// fn printClassProperty(class: *const Api.Class, property: *const Api.Property, w: anytype) !void {
//     if (property.getter) |getter| {
//         try print(w,
//             \\    pub fn {s}(self: *const {s}) !{s} {{
//             \\    }}
//             \\
//         , .{ getter, class.name, property.type });
//     }

//     if (property.getter != null and property.setter != null) {
//         try printNewline(w);
//     }

//     if (property.setter) |setter| {
//         try print(w,
//             \\    pub fn {s}(self: *const {s}, value: {s}) !void {{
//             \\    }}
//             \\
//         , .{ setter, class.name, property.type });
//     }
}

fn printBanner(comptime indent: u4, text: anytype, w: anytype) !void {
    comptime var indentStr: []const u8 = "";
    inline for (0..indent) |_| {
        indentStr = indentStr ++ "    ";
    }
    try print(w,
        \\{0s}// {1s}
        \\
        \\
    , .{ indentStr, text });
}

var newlines = 0;
fn print(writer: anytype, comptime format: []const u8, args: anytype) !void {
    // Iterate backward over format, increasing newlines until we reach a non-newline
    var i = format.len;
    while (i > 0) : (i -= 1) {
        if (format[i - 1] != '\n') {
            break;
        }
        newlines += 1;
    }
    try writer.print(format, args);
}

fn printNewline(w: anytype) !void {
    try print(w, "\n", .{});
}

fn typeName(name: []const u8) []const u8 {
    return safeName(.pascal, name);
}

fn funcName(name: []const u8) []const u8 {
    return safeName(.camel, name);
}

fn varName(name: []const u8) []const u8 {
    return safeName(.snake, name);
}

fn safeName(comptime case_: case.Case, text: []const u8) []const u8 {
    const name = if (case.of(text, .{}) == case_)
        text
    else
        return case.bufTo(&buf, case_, text) orelse unreachable;

    if (std.zig.Token.keywords.has(name)) {
        return std.fmt.bufPrint(buf, "@\"{s}\"", .{name}) orelse unreachable;
    } else {
        return name;
    }
}

const std = @import("std");
const Allocator = std.mem.Allocator;

const case = @import("case");

const Json = @import("Json.zig");
