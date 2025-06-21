//! This module implements the logic for generating Zig code using:
//!
//! - The JSON definitions defined in `./Schema.zig`
//!

pub fn write(json: Schema, writer: anytype) !void {
    var gpa: DebugAllocator(.{}) = .init;
    var arena = ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    _ = arena.allocator();

    // todo; pass along to renderers as needed.

    try writeGlobalConstants(json, writer);
    try writeBuiltins(json, writer);
    try writeClasses(json, writer);
    try writeGlobalEnums(json, writer);
    try writeUtilityFunctions(json, writer);
}

fn writeBuiltins(json: Schema, writer: anytype) !void {
    try writeBanner(0, "Builtins", writer);

    for (json.builtin_classes, 0..) |builtin, i| {
        if (i > 0) try writer.writeAll("\n");
        if (Data.skipped_types.has(builtin.name)) continue;
        try writeBuiltin(&builtin, writer);
    }
}

fn writeBuiltin(builtin: *const Schema.Builtin, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{Name.type_(builtin.name)});

    if (builtin.constants) |constants| {
        if (constants.len > 0) {
            try writeBanner(1, "Constants", w);
            for (constants) |constant| {
                try writeBuiltinConstant(&constant, w);
            }
            try w.writeAll("\n");
        }
    }

    if (builtin.enums) |enums| {
        if (enums.len > 0) {
            try writeBanner(1, "Enums", w);
            for (enums, 0..) |enum_def, i| {
                if (i > 0) try w.writeAll("\n");
                try writeBuiltinEnum(&enum_def, w);
            }
            try w.writeAll("\n");
        }
    }

    if (builtin.methods) |methods| {
        if (methods.len > 0) {
            try writeBanner(1, "Methods", w);
            for (methods, 0..) |method, i| {
                if (i > 0) try w.writeAll("\n");
                try writeBuiltinMethod(builtin, &method, w);
            }
            try w.writeAll("\n");
        }
    }

    if (builtin.constructors.len > 0) {
        try writeBanner(1, "Constructors", w);
        for (builtin.constructors, 0..) |constructor, i| {
            if (i > 0) try w.writeAll("\n");
            try writeBuiltinConstructor(builtin, &constructor, w);
        }
        try w.writeAll("\n");
    }

    try w.print(
        \\}};
        \\
    , .{});
}

fn writeBuiltinMethod(builtin: *const Schema.Builtin, method: *const Schema.Builtin.Method, w: anytype) !void {
    const return_type = if (std.mem.eql(u8, method.return_type, "void")) "void" else method.return_type;

    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(
        , .{Name.func(method.name)});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}
        , .{
            Name.func(method.name),
            ptr,
            Name.type_(builtin.name),
        });
        if (method.arguments != null and method.arguments.?.len > 0) {
            try w.writeAll(", ");
        }
    }

    if (method.arguments) |args| {
        try writeBuiltinMethodArguments(args, w);
    }

    try w.print(
        \\) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{Name.type_(return_type)});
}

fn writeBuiltinMethodArguments(args: []const Schema.Builtin.Method.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ Name.val(arg.name), Name.type_(arg.type) });
    }
}

fn writeBuiltinConstructor(builtin: *const Schema.Builtin, constructor: *const Schema.Builtin.Constructor, w: anytype) !void {
    try w.print(
        \\    pub fn init{d}(
    , .{constructor.index});

    if (constructor.arguments) |args| {
        try writeBuiltinConstructorArguments(args, w);
    }

    try w.print(
        \\) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{Name.type_(builtin.name)});
}

fn writeBuiltinConstructorArguments(args: []const Schema.Builtin.Constructor.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ Name.val(arg.name), Name.type_(arg.type) });
    }
}

fn writeBuiltinConstant(constant: *const Schema.Builtin.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: {s} = {s};
        \\
    , .{ Name.val(constant.name), Name.type_(constant.type), constant.value });
}

fn writeBuiltinEnum(enum_def: *const Schema.Builtin.Enum, w: anytype) !void {
    try w.print(
        \\    pub const {s} = enum(i64) {{
        \\
    , .{Name.type_(enum_def.name)});

    for (enum_def.values) |value| {
        try w.print(
            \\        {s} = {d},
            \\
        , .{ enumFieldName(enum_def.name, value.name), value.value });
    }

    try w.print(
        \\    }};
        \\
    , .{});
}

fn writeClasses(json: Schema, writer: anytype) !void {
    try writeBanner(0, "Classes", writer);

    for (json.classes, 0..) |class, i| {
        if (i > 0) try writer.writeAll("\n");
        try writeClass(&class, json.is_singleton(class.name), writer);
    }
}

fn writeClass(class: *const Schema.Class, is_singleton: bool, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{Name.type_(class.name)});

    if (is_singleton) {
        try w.print(
            \\    pub const Instance: {s} = todo;
            \\
            \\
        , .{Name.type_(class.name)});
    }

    if (class.inherits) |inherits| {
        try w.print(
            \\    pub const Base = {s};
            \\
            \\
        , .{Name.type_(inherits)});
    }

    if (class.constants) |constants| {
        if (constants.len > 0) {
            try writeBanner(1, "Constants", w);
            for (constants) |constant| {
                try writeClassConstant(&constant, w);
            }
            try w.writeAll("\n");
        }
    }

    if (class.enums) |enums| {
        if (enums.len > 0) {
            try writeBanner(1, "Enums", w);
            for (enums, 0..) |enum_def, i| {
                if (i > 0) try w.writeAll("\n");
                try writeClassEnum(&enum_def, w);
            }
            try w.writeAll("\n");
        }
    }

    if (class.properties) |properties| {
        if (properties.len > 0) {
            try writeBanner(1, "Properties", w);
            for (properties, 0..) |property, i| {
                if (i > 0) try w.writeAll("\n");
                try writeClassProperty(class, &property, w);
            }
            try w.writeAll("\n");
        }
    }

    if (class.is_instantiable) {
        try writeBanner(1, "Constructors", w);
        try w.print(
            \\    pub fn init() {s} {{
            \\        @panic("todo");
            \\    }}
            \\
            \\
        , .{Name.type_(class.name)});
    }

    if (class.methods) |methods| {
        if (methods.len > 0) {
            var i: i32 = 0;

            for (methods) |method| {
                if (!method.is_static) continue;
                if (i > 0) try w.writeAll("\n");
                if (i == 0) try writeBanner(1, "Static methods", w);
                try writeClassMethod(class, &method, w);
                i += 1;
            }

            i = 0;

            for (methods) |method| {
                if (method.is_virtual or method.is_static) continue;
                if (i > 0) try w.writeAll("\n");
                if (i == 0) try writeBanner(1, "Methods", w);
                try writeClassMethod(class, &method, w);
                i += 1;
            }

            i = 0;

            for (methods) |method| {
                if (!method.is_virtual) continue;
                if (i > 0) try w.writeAll("\n");
                if (i == 0) try writeBanner(1, "Virtual methods", w);
                try writeClassMethod(class, &method, w);
                i += 1;
            }
        }
    }

    try w.print(
        \\}};
        \\
    , .{});
}

fn writeClassConstant(constant: *const Schema.Class.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: i64 = {d};
        \\
    , .{ Name.val(constant.name), constant.value });
}

fn writeClassEnum(enum_def: *const Schema.Class.Enum, w: anytype) !void {
    if (enum_def.is_bitfield) {
        try w.print(
            \\    pub const {s} = packed struct(i64) {{
            \\
        , .{Name.type_(enum_def.name)});

        // Find the default (if there is one)
        const default: i64 = blk: {
            for (enum_def.values) |value| {
                if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                    break :blk value.value;
                }
            }
            break :blk 0;
        };

        // Print non-defaults
        var current_bit: u6 = 0;

        for (enum_def.values) |value| {
            if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                continue;
            }

            const is_default = (default & value.value) == value.value;

            if (value.value > 0 and (value.value & (value.value - 1)) == 0) {
                // Is a power of 2, so it's a field
                const bit_pos = @ctz(value.value);

                if (value.value < (@as(i64, 1) << current_bit)) {
                    // Value is less than current bit position, make it a constant
                    try w.print(
                        \\        pub const {s}: {s} = @bitCast({d});
                        \\
                    , .{ enumFieldName(enum_def.name, value.name), Name.type_(enum_def.name), value.value });
                } else {
                    // Fill any gaps with padding fields
                    while (current_bit < bit_pos) {
                        try w.print(
                            \\        _{d}: u1 = 0,
                            \\
                        , .{current_bit});
                        current_bit += 1;
                    }

                    try w.print(
                        \\        // {d}
                        \\        {s}: u1 = {d},
                        \\
                    , .{ bit_pos, enumFieldName(enum_def.name, value.name), @intFromBool(is_default) });
                    current_bit += 1;
                }
            } else {
                // Not a power of 2, so it's a constant
                try w.print(
                    \\        pub const {s}: {s} = @bitCast({d});
                    \\
                , .{ enumFieldName(enum_def.name, value.name), Name.type_(enum_def.name), value.value });
            }
        }
    } else {
        try w.print(
            \\    pub const {s} = enum(i64) {{
            \\
        , .{Name.type_(enum_def.name)});

        for (enum_def.values) |value| {
            try w.print(
                \\        {s} = {d},
                \\
            , .{ enumFieldName(enum_def.name, value.name), value.value });
        }
    }

    try w.print(
        \\    }};
        \\
    , .{});
}

fn writeClassMethod(class: *const Schema.Class, method: *const Schema.Class.Method, w: anytype) !void {
    const return_type = if (method.return_value) |ret_val| ret_val.type else "void";

    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(
        , .{Name.func(method.name)});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}
        , .{ if (method.is_virtual) Name.virtualFunc(method.name) else Name.func(method.name), ptr, Name.type_(class.name) });
        if (method.arguments != null and method.arguments.?.len > 0) {
            try w.writeAll(", ");
        }
    }

    if (method.arguments) |args| {
        try writeClassMethodArguments(args, w);
    }

    try w.print(
        \\) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{Name.type_(return_type)});
}

fn writeClassMethodArguments(args: []const Schema.Class.Method.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ Name.val(arg.name), Name.type_(arg.type) });
    }
}

fn writeClassProperty(class: *const Schema.Class, property: *const Schema.Class.Property, w: anytype) !void {
    // Getter
    try w.print(
        \\    pub fn {s}(self: *const {s}) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{ Name.func(property.getter), Name.type_(class.name), Name.type_(property.type) });

    if (property.setter) |setter| {
        try w.writeAll("\n");
        try w.print(
            \\    pub fn {s}(self: *{s}, value: {s}) void {{
            \\        @panic("todo");
            \\    }}
            \\
        , .{ Name.func(setter), Name.type_(class.name), Name.type_(property.type) });
    }
}

fn writeUtilityFunctions(json: Schema, writer: anytype) !void {
    try writeBanner(0, "Functions", writer);

    // This takes advantage of the fact that utility functions are sorted by category in the JSON
    var i: i32 = 0;
    var category: []const u8 = undefined;
    for (json.utility_functions) |func| {
        if (!std.mem.eql(u8, func.category, category)) {
            if (i > 0) try writer.print("}};\n", .{});
            try writer.print("pub const {s} = struct {{\n", .{Name.val(func.category)});
            category = func.category;
            i = 0;
        }
        if (i > 0) try writer.writeAll("\n");
        try writeUtilityFunction(&func, writer);
        i += 1;
    }
    try writer.print("}};\n", .{});
}

fn writeUtilityFunction(func: *const Schema.UtilityFunction, w: anytype) !void {
    const return_type = func.return_type orelse "void";

    try w.print(
        \\    pub fn {s}(
    , .{Name.func(func.name)});

    if (func.arguments.len > 0) {
        try writeUtilityFunctionArguments(func.arguments, w);
    }

    try w.print(
        \\) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{Name.type_(return_type)});
}

fn writeUtilityFunctionArguments(args: []const Schema.UtilityFunction.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ Name.val(arg.name), Name.type_(arg.type) });
    }
}

fn writeGlobalConstants(json: Schema, writer: anytype) !void {
    try writeBanner(0, "Constants", writer);

    for (json.global_constants) |constant| {
        try writeGlobalConstant(&constant, writer);
    }
}

fn writeGlobalConstant(constant: *const Schema.GlobalConstant, w: anytype) !void {
    try w.print(
        \\pub const {s} = {s};
        \\
    , .{ Name.val(constant.name), constant.value });
}

fn writeGlobalEnums(json: Schema, writer: anytype) !void {
    try writeBanner(0, "Enums", writer);

    for (json.global_enums, 0..) |enum_def, i| {
        if (i > 0) try writer.writeAll("\n");
        try writeGlobalEnum(&enum_def, writer);
    }
}

fn writeGlobalEnum(enum_def: *const Schema.GlobalEnum, w: anytype) !void {
    if (enum_def.is_bitfield) {
        try w.print(
            \\pub const {s} = packed struct(i64) {{
            \\
        , .{Name.type_(enum_def.name)});

        // Find the default (if there is one)
        const default: i64 = blk: {
            for (enum_def.values) |value| {
                if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                    break :blk value.value;
                }
            }
            break :blk 0;
        };

        // Print non-defaults
        var current_bit: u6 = 0;

        for (enum_def.values) |value| {
            if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                continue;
            }

            const is_default = (default & value.value) == value.value;

            if (value.value > 0 and (value.value & (value.value - 1)) == 0) {
                // Is a power of 2, so it's a field
                const bit_pos = @ctz(value.value);

                if (value.value < (@as(i64, 1) << current_bit)) {
                    // Value is less than current bit position, make it a constant
                    try w.print(
                        \\    pub const {s}: {s} = @bitCast({d});
                        \\
                    , .{ enumFieldName(enum_def.name, value.name), Name.type_(enum_def.name), value.value });
                } else {
                    // Fill any gaps with padding fields
                    while (current_bit < bit_pos) {
                        try w.print(
                            \\    _{d}: u1 = 0,
                            \\
                        , .{current_bit});
                        current_bit += 1;
                    }

                    try w.print(
                        \\    // {d}
                        \\    {s}: u1 = {d},
                        \\
                    , .{ bit_pos, enumFieldName(enum_def.name, value.name), @intFromBool(is_default) });
                    current_bit += 1;
                }
            } else {
                // Not a power of 2, so it's a constant
                try w.print(
                    \\    pub const {s}: {s} = @bitCast({d});
                    \\
                , .{ enumFieldName(enum_def.name, value.name), Name.type_(enum_def.name), value.value });
            }
        }
    } else {
        try w.print(
            \\pub const {s} = enum(i64) {{
            \\
        , .{Name.type_(enum_def.name)});

        for (enum_def.values) |value| {
            try w.print(
                \\    {s} = {d},
                \\
            , .{ enumFieldName(enum_def.name, value.name), value.value });
        }
    }

    try w.print(
        \\}};
        \\
    , .{});
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

fn enumFieldName(@"enum": []const u8, field: []const u8) Name {
    if (Data.enum_prefix_exceptions.get(@"enum")) |prefix| {
        if (std.mem.startsWith(u8, field, prefix)) {
            return .{ .snake = field[prefix.len..] };
        }
    }

    var buf1: [128]u8 = undefined;
    var buf2: [128]u8 = undefined;
    var plural_name = @"enum";
    var singular_name = plural_name;

    // Remove trailing "s" or "es" from pluralized enum names
    if (std.mem.endsWith(u8, singular_name, "es")) {
        singular_name = plural_name[0 .. plural_name.len - 2];
    } else if (std.mem.endsWith(u8, singular_name, "s")) {
        singular_name = plural_name[0 .. plural_name.len - 1];
    }

    plural_name = case.bufTo(&buf1, .constant, plural_name) catch unreachable;
    singular_name = case.bufTo(&buf2, .constant, singular_name) catch unreachable;

    // Try with underscore separator
    if (std.mem.startsWith(u8, field, plural_name)) {
        const prefix_len = plural_name.len;
        if (field.len > prefix_len and field[prefix_len] == '_') {
            return .{ .snake = field[prefix_len + 1 ..] };
        }
    } else if (std.mem.startsWith(u8, field, singular_name)) {
        const prefix_len = singular_name.len;
        if (field.len > prefix_len and field[prefix_len] == '_') {
            return .{ .snake = field[prefix_len + 1 ..] };
        }
    }

    return .{ .snake = field };
}

const std = @import("std");
const case = @import("case");
const mustache = @import("mustache");

const Schema = @import("Schema.zig");
const Data = @import("./Data.zig");
const template = @import("./template.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;

const Name = Data.Name;
