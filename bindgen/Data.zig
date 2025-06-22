interfaces: []Interface = &.{},
has_builtins: bool,
builtins: []Builtin = &.{},
has_classes: bool,
classes: []Class = &.{},
has_constants: bool,
constants: []GlobalConstant = &.{},
has_enums: bool,
enums: []GlobalEnum = &.{},
has_flags: bool,
flags: []GlobalFlag = &.{},
has_functions: bool,
functions: []Function = &.{},

pub const Interface = struct {
    name: []const u8 = "",
    proc_name: []const u8 = "",
    type: []const u8 = "",
};

pub const Builtin = struct {
    doc: []const u8 = "",
    name: []const u8,
    has_members: bool,
    members: []Member = &.{},
    has_constants: bool,
    constants: []Constant = &.{},
    has_constructors: bool,
    constructors: []Constructor = &.{},
    has_methods: bool,
    methods: []Method = &.{},
    has_enums: bool,
    enums: []Enum = &.{},

    pub const Member = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        type: []const u8 = "",
    };

    pub const Constant = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        type: []const u8 = "",
        value: []const u8 = "",
    };

    pub const Constructor = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        type: []const u8 = "",
        offset: []const u8 = "",
        has_args: bool,
        args: []Arg = &.{},
        return_type: []const u8 = "",

        pub const Arg = struct {
            name: []const u8 = "",
            type: []const u8 = "",
        };
    };

    pub const Method = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        type: []const u8 = "",
        offset: []const u8 = "",
        has_args: bool,
        args: []Arg = &.{},
        return_type: []const u8 = "",

        pub const Arg = struct {
            name: []const u8 = "",
            type: []const u8 = "",
        };
    };

    pub const Enum = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        has_values: bool,
        values: []Value = &.{},

        pub const Value = struct {
            doc: []const u8 = "",
            name: []const u8 = "",
            value: []const u8 = "",
        };
    };
};

pub const Class = struct {
    doc: []const u8 = "",
    name: []const u8,
    inherits: ?[]const u8 = null,
    is_singleton: bool = false,
    is_instantiable: bool = false,
    has_constants: bool,
    constants: []Constant = &.{},
    has_enums: bool,
    enums: []Enum = &.{},
    has_properties: bool,
    properties: []Property = &.{},
    has_static_methods: bool,
    static_methods: []Method = &.{},
    has_methods: bool,
    methods: []Method = &.{},
    has_virtual_methods: bool,
    virtual_methods: []Method = &.{},

    pub const Constant = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        value: []const u8 = "",
    };

    pub const Enum = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        is_bitfield: bool = false,
        has_values: bool = false,
        values: []Value = &.{},

        pub const Value = struct {
            doc: []const u8 = "",
            name: []const u8 = "",
            value: []const u8 = "",
            is_field: bool = false,
            is_default: bool = false,
            bit_pos: u6 = 0,
        };
    };

    pub const Property = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        type: []const u8 = "",
        getter: []const u8 = "",
        has_setter: bool,
        setter: ?[]const u8 = null,
    };

    pub const Method = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        is_const: bool = false,
        is_virtual: bool = false,
        return_type: []const u8 = "void",
        has_args: bool,
        args: []Arg = &.{},

        pub const Arg = struct {
            name: []const u8 = "",
            type: []const u8 = "",
        };
    };
};

pub const GlobalConstant = struct {
    doc: []const u8 = "",
    name: []const u8 = "",
    value: []const u8 = "",
};

pub const GlobalEnum = struct {
    doc: []const u8 = "",
    name: []const u8 = "",
    has_values: bool,
    values: []Value = &.{},

    pub const Value = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        value: []const u8 = "",
    };
};

pub const GlobalFlag = struct {
    doc: []const u8 = "",
    name: []const u8 = "",
    has_consts: bool,
    consts: []Const = &.{},
    has_fields: bool,
    fields: []Field = &.{},

    pub const Const = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        value: i64,
    };

    pub const Field = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        value: u1,
    };
};

pub const Function = struct {
    doc: []const u8 = "",
    category: []const u8 = "",
    has_functions: bool,
    functions: []FunctionDef = &.{},

    pub const FunctionDef = struct {
        doc: []const u8 = "",
        name: []const u8 = "",
        return_type: []const u8 = "void",
        has_args: bool,
        args: []Arg = &.{},

        pub const Arg = struct {
            name: []const u8 = "",
            type: []const u8 = "",
        };
    };
};

/// Convenience wrapper for zero-allocation writing of cased string names.
pub const Name = union(enum) {
    pascal: []const u8,
    camel: []const u8,
    snake: []const u8,
    virtual_camel: []const u8,
    none: []const u8,

    pub fn type_(name: []const u8) Name {
        if (type_name_exceptions.get(name)) |override| {
            return .{ .none = override };
        }

        return .{ .pascal = name };
    }

    pub fn func(name: []const u8) Name {
        return .{ .camel = name };
    }

    pub fn virtualFunc(name: []const u8) Name {
        return .{ .virtual_camel = name[1..] };
    }

    pub fn val(name: []const u8) Name {
        return .{ .snake = name };
    }

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

/// Types that should not be printed.
pub const skipped_types: std.StaticStringMap(void) = .initComptime(.{
    .{"void"},
    .{"Nil"},
    .{"bool"},
    .{"int"},
    .{"float"},
});

/// Exceptions to type naming.
pub const type_name_exceptions: std.StaticStringMap([]const u8) = .initComptime(.{
    .{ "void", "void" },
    .{ "Nil", "void" },
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
pub const enum_prefix_exceptions: std.StaticStringMap([]const u8) = .initComptime(.{
    .{ "Error", "ERR_" },
    .{ "MethodFlags", "METHOD_FLAG_" },
    .{ "MouseButtonMask", "MB_" },
    .{ "MIDIMessage", "MIDI_MESSAGE" },
    .{ "PropertyUsageFlags", "PROPERTY_USAGE_" },

    // TODO: Move these under the Variant type.
    .{ "Variant.Operator", "OP_" },
    .{ "Variant.Type", "TYPE_" },
});

const std = @import("std");
const case = @import("case");
const mustache = @import("mustache");
