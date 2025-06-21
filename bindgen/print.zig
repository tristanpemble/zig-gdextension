//! This module implements the logic for generating Zig code using:
//!
//! - The JSON definitions defined in `./Json.zig`
//!

/// Types that should not be printed.
const skipped_types: std.StaticStringMap(void) = .initComptime(.{
    .{"void"},
    .{"Nil"},
    .{"bool"},
    .{"int"},
    .{"float"},
});

/// Exceptions to type naming.
const type_name_exceptions: std.StaticStringMap([]const u8) = .initComptime(.{
    .{ "void", "void" },
    .{ "Nil", "null" },
    .{ "bool", "bool" },
    .{ "int", "i64" },
    .{ "float", "f64" },

    .{ "AESContext", "AesContext" },
    .{ "AStar2D", "AStar2D" },
    .{ "AStar3D", "AStar3D" },
    .{ "AStarGrid2D", "AStarGrid2D" },
    .{ "MIDIMessage", "MidiMessage" },
    .{ "TLSOptions", "TlsOptions" },
    .{ "UDPServer", "UdpServer" },
    .{ "VBoxContainer", "VBoxContainer" },
    .{ "VFlowContainer", "VFlowContainer" },
    .{ "VScrollBar", "VScrollBar" },
    .{ "VSeparator", "VSeparator" },
    .{ "VSlider", "VSlider" },
    .{ "VSplitContainer", "VSplitContainer" },
    .{ "VoxelGidata", "VoxelGiData" },
    .{ "XMLParser", "XmlParser" },
    .{ "XRAnchor3D", "XrAnchor3D" },
    .{ "XRBodyModifier3D", "XrBodyModifier3D" },
    .{ "XRBodyTracker", "XrBodyTracker" },
    .{ "XRCamera3D", "XrCamera3D" },
    .{ "XRController3D", "XrController3D" },
    .{ "XRControllerTracker", "XrControllerTracker" },
    .{ "XRFaceModifier3D", "XrFaceModifier3D" },
    .{ "XRFaceTracker", "XrFaceTracker" },
    .{ "XRHandModifier3D", "XrHandModifier3D" },
    .{ "XRHandTracker", "XrHandTracker" },
    .{ "XRInterface", "XrInterface" },
    .{ "XRInterfaceExtension", "XrInterfaceExtension" },
    .{ "XRNode3D", "XrNode3D" },
    .{ "XROrigin3D", "XrOrigin3D" },
    .{ "XRPose", "XrPose" },
    .{ "XRPositionalTracker", "XrPositionalTracker" },
    .{ "XRServer", "XrServer" },
    .{ "XRTracker", "XrTracker" },
    .{ "XRVRS", "XrVrs" },
    .{ "ZIPPacker", "ZipPacker" },
    .{ "ZIPReader", "ZipReader" },
});

/// Exceptions to the enum prefix rule.
const enum_prefix_exceptions: std.StaticStringMap([]const u8) = .initComptime(.{
    .{ "Error", "ERR_" },
    .{ "MethodFlags", "METHOD_FLAG_" },
    .{ "MouseButtonMask", "MB_" },
    .{ "MIDIMessage", "MIDI_MESSAGE" },
    .{ "PropertyUsageFlags", "PROPERTY_USAGE_" },

    // TODO: Move these under the Variant type.
    .{ "Variant.Operator", "OP_" },
    .{ "Variant.Type", "TYPE_" },
});

pub fn write(json: Json, writer: anytype) !void {
    try writeGlobalConstants(json, writer);
    try writeBuiltins(json, writer);
    try writeClasses(json, writer);
    try writeGlobalEnums(json, writer);
    try writeUtilityFunctions(json, writer);
}

fn writeBuiltins(json: Json, writer: anytype) !void {
    try writeBanner(0, "Builtins", writer);

    for (json.builtin_classes, 0..) |builtin, i| {
        if (i > 0) try writer.writeAll("\n");
        if (skipped_types.has(builtin.name)) continue;
        try writeBuiltin(&builtin, writer);
    }
}

fn writeBuiltin(builtin: *const Json.Builtin, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{typeName(builtin.name)});

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

fn writeBuiltinMethod(builtin: *const Json.Builtin, method: *const Json.Builtin.Method, w: anytype) !void {
    const return_type = if (std.mem.eql(u8, method.return_type, "void")) "void" else method.return_type;

    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(
        , .{funcName(method.name)});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}
        , .{
            funcName(method.name),
            ptr,
            typeName(builtin.name),
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
    , .{typeName(return_type)});
}

fn writeBuiltinMethodArguments(args: []const Json.Builtin.Method.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ valName(arg.name), typeName(arg.type) });
    }
}

fn writeBuiltinConstructor(builtin: *const Json.Builtin, constructor: *const Json.Builtin.Constructor, w: anytype) !void {
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
    , .{typeName(builtin.name)});
}

fn writeBuiltinConstructorArguments(args: []const Json.Builtin.Constructor.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ valName(arg.name), typeName(arg.type) });
    }
}

fn writeBuiltinConstant(constant: *const Json.Builtin.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: {s} = {s};
        \\
    , .{ valName(constant.name), typeName(constant.type), constant.value });
}

fn writeBuiltinEnum(enum_def: *const Json.Builtin.Enum, w: anytype) !void {
    try w.print(
        \\    pub const {s} = enum(i64) {{
        \\
    , .{typeName(enum_def.name)});

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

fn writeClasses(json: Json, writer: anytype) !void {
    try writeBanner(0, "Classes", writer);

    for (json.classes, 0..) |class, i| {
        if (i > 0) try writer.writeAll("\n");
        try writeClass(&class, json.is_singleton(class.name), writer);
    }
}

fn writeClass(class: *const Json.Class, is_singleton: bool, w: anytype) !void {
    try w.print(
        \\pub const {s} = struct {{
        \\
    , .{typeName(class.name)});

    if (is_singleton) {
        try w.print(
            \\    pub const Instance: {s} = todo;
            \\
            \\
        , .{typeName(class.name)});
    }

    if (class.inherits) |inherits| {
        try w.print(
            \\    pub const Base = {s};
            \\
            \\
        , .{typeName(inherits)});
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
        , .{typeName(class.name)});
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

fn writeClassConstant(constant: *const Json.Class.Constant, w: anytype) !void {
    try w.print(
        \\    pub const {s}: i64 = {d};
        \\
    , .{ valName(constant.name), constant.value });
}

fn writeClassEnum(enum_def: *const Json.Class.Enum, w: anytype) !void {
    if (enum_def.is_bitfield) {
        try w.print(
            \\    pub const {s} = packed struct(i64) {{
            \\
        , .{typeName(enum_def.name)});

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
                    , .{ enumFieldName(enum_def.name, value.name), typeName(enum_def.name), value.value });
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
                , .{ enumFieldName(enum_def.name, value.name), typeName(enum_def.name), value.value });
            }
        }
    } else {
        try w.print(
            \\    pub const {s} = enum(i64) {{
            \\
        , .{typeName(enum_def.name)});

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

fn writeClassMethod(class: *const Json.Class, method: *const Json.Class.Method, w: anytype) !void {
    const return_type = if (method.return_value) |ret_val| ret_val.type else "void";

    if (method.is_static) {
        try w.print(
            \\    pub fn {s}(
        , .{funcName(method.name)});
    } else {
        const ptr = if (method.is_const) "*const " else "*";
        try w.print(
            \\    pub fn {s}(self: {s}{s}
        , .{ if (method.is_virtual) virtualFuncName(method.name) else funcName(method.name), ptr, typeName(class.name) });
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
    , .{typeName(return_type)});
}

fn writeClassMethodArguments(args: []const Json.Class.Method.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ valName(arg.name), typeName(arg.type) });
    }
}

fn writeClassProperty(class: *const Json.Class, property: *const Json.Class.Property, w: anytype) !void {
    // Getter
    try w.print(
        \\    pub fn {s}(self: *const {s}) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{ funcName(property.getter), typeName(class.name), typeName(property.type) });

    if (property.setter) |setter| {
        try w.writeAll("\n");
        try w.print(
            \\    pub fn {s}(self: *{s}, value: {s}) void {{
            \\        @panic("todo");
            \\    }}
            \\
        , .{ funcName(setter), typeName(class.name), typeName(property.type) });
    }
}

fn writeUtilityFunctions(json: Json, writer: anytype) !void {
    try writeBanner(0, "Functions", writer);

    // This takes advantage of the fact that utility functions are sorted by category in the JSON
    var i: i32 = 0;
    var category: []const u8 = undefined;
    for (json.utility_functions) |func| {
        if (!std.mem.eql(u8, func.category, category)) {
            if (i > 0) try writer.print("}};\n", .{});
            try writer.print("pub const {s} = struct {{\n", .{valName(func.category)});
            category = func.category;
            i = 0;
        }
        if (i > 0) try writer.writeAll("\n");
        try writeUtilityFunction(&func, writer);
        i += 1;
    }
    try writer.print("}};\n", .{});
}

fn writeUtilityFunction(func: *const Json.UtilityFunction, w: anytype) !void {
    const return_type = func.return_type orelse "void";

    try w.print(
        \\    pub fn {s}(
    , .{funcName(func.name)});

    if (func.arguments.len > 0) {
        try writeUtilityFunctionArguments(func.arguments, w);
    }

    try w.print(
        \\) {s} {{
        \\        @panic("todo");
        \\    }}
        \\
    , .{typeName(return_type)});
}

fn writeUtilityFunctionArguments(args: []const Json.UtilityFunction.Argument, w: anytype) !void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try w.print("{s}: {s}", .{ valName(arg.name), typeName(arg.type) });
    }
}

fn writeGlobalConstants(json: Json, writer: anytype) !void {
    try writeBanner(0, "Constants", writer);

    for (json.global_constants) |constant| {
        try writeGlobalConstant(&constant, writer);
    }
}

fn writeGlobalConstant(constant: *const Json.GlobalConstant, w: anytype) !void {
    try w.print(
        \\pub const {s} = {s};
        \\
    , .{ valName(constant.name), constant.value });
}

fn writeGlobalEnums(json: Json, writer: anytype) !void {
    try writeBanner(0, "Enums", writer);

    for (json.global_enums, 0..) |enum_def, i| {
        if (i > 0) try writer.writeAll("\n");
        try writeGlobalEnum(&enum_def, writer);
    }
}

fn writeGlobalEnum(enum_def: *const Json.GlobalEnum, w: anytype) !void {
    if (enum_def.is_bitfield) {
        try w.print(
            \\pub const {s} = packed struct(i64) {{
            \\
        , .{typeName(enum_def.name)});

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
                    , .{ enumFieldName(enum_def.name, value.name), typeName(enum_def.name), value.value });
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
                , .{ enumFieldName(enum_def.name, value.name), typeName(enum_def.name), value.value });
            }
        }
    } else {
        try w.print(
            \\pub const {s} = enum(i64) {{
            \\
        , .{typeName(enum_def.name)});

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

/// Convenience wrapper for zero-allocation writing of cased string names.
const Name = union(enum) {
    pascal: []const u8,
    camel: []const u8,
    snake: []const u8,
    virtual_camel: []const u8,
    none: []const u8,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        var buf: [128]u8 = undefined;
        const name = switch (self) {
            .pascal => |s| try case.bufTo(&buf, .pascal, s),
            .camel => |s| try case.bufTo(&buf, .camel, s),
            .snake => |s| try case.bufTo(&buf, .snake, s),
            .virtual_camel => |s| blk: {
                const camel_name = try case.bufTo(&buf, .camel, s);
                // Move the result to make room for underscore
                std.mem.copyBackwards(u8, buf[1 .. camel_name.len + 1], buf[0..camel_name.len]);
                buf[0] = '_';
                break :blk buf[0 .. camel_name.len + 1];
            },
            .none => {
                try writer.print("{s}", .{self.none});
                return;
            },
        };

        if (std.zig.Token.keywords.has(name)) {
            try writer.print("@\"{s}\"", .{name});
        } else {
            try writer.print("{s}", .{name});
        }
    }
};

fn typeName(name: []const u8) Name {
    if (type_name_exceptions.get(name)) |override| {
        return .{ .none = override };
    }

    return .{ .pascal = name };
}

fn funcName(name: []const u8) Name {
    return .{ .camel = name };
}

fn virtualFuncName(name: []const u8) Name {
    return .{ .virtual_camel = name[1..] };
}

fn valName(name: []const u8) Name {
    return .{ .snake = name };
}

fn enumFieldName(@"enum": []const u8, field: []const u8) Name {
    if (enum_prefix_exceptions.get(@"enum")) |prefix| {
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
const Json = @import("Json.zig");
