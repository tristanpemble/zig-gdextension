//! This type defines the schema for Godot's `extension_api.json`.

const Schema = @This();

pub fn parse(allocator: Allocator, contents: []const u8) !Parsed(Schema) {
    return try std.json.parseFromSlice(Schema, allocator, contents, .{
        .ignore_unknown_fields = false,
    });
}

pub fn parseLeaky(allocator: Allocator, contents: []const u8) !Schema {
    return try std.json.parseFromSliceLeaky(Schema, allocator, contents, .{
        .ignore_unknown_fields = false,
    });
}

header: Header,
builtin_classes: []Builtin,
builtin_class_sizes: []BuildConfig.Sizes,
builtin_class_member_offsets: []BuildConfig.Offsets,
classes: []Class,
global_constants: []GlobalConstant,
global_enums: []GlobalEnum,
native_structures: []NativeStructure,
singletons: []Singleton,
utility_functions: []UtilityFunction,

pub const Header = struct {
    version_major: i64,
    version_minor: i64,
    version_patch: i64,
    version_status: []const u8,
    version_build: []const u8,
    version_full_name: []const u8,
};

pub const Builtin = struct {
    name: []const u8,
    indexing_return_type: ?[]const u8 = null,
    is_keyed: bool,
    members: ?[]Member = null,
    constants: ?[]Constant = null,
    enums: ?[]Enum = null,
    operators: []Operator,
    methods: ?[]Method = null,
    constructors: []Constructor,
    has_destructor: bool,

    pub const Constructor = struct {
        index: i64,
        arguments: ?[]Argument = null,

        pub const Argument = struct {
            name: []const u8,
            type: []const u8,
            meta: ?[]const u8 = null,
            default_value: ?[]const u8 = null,
        };
    };

    pub const Constant = struct {
        name: []const u8,
        type: []const u8,
        value: []const u8,
    };

    pub const Enum = struct {
        name: []const u8,
        values: []Value,

        pub const Value = struct {
            name: []const u8,
            value: i64,
        };
    };

    pub const Member = struct {
        name: []const u8,
        type: []const u8,
    };

    pub const Method = struct {
        name: []const u8,
        return_type: []const u8 = "void",
        is_vararg: bool,
        is_const: bool,
        is_static: bool,
        hash: u64,
        arguments: ?[]Argument = null,

        pub const Argument = struct {
            name: []const u8,
            type: []const u8,
            meta: ?[]const u8 = null,
            default_value: ?[]const u8 = null,
        };
    };

    pub const Operator = struct {
        name: []const u8,
        right_type: ?[]const u8 = null,
        return_type: []const u8,
    };
};

pub const BuildConfig = struct {
    pub const Offsets = struct {
        build_configuration: []const u8,
        classes: []MemberOffsets,

        pub const MemberOffsets = struct {
            name: []const u8,
            members: []Offset,
        };

        pub const Offset = struct {
            member: []const u8,
            offset: i64,
            meta: []const u8,
        };
    };

    pub const Sizes = struct {
        build_configuration: []const u8,
        sizes: []Size,

        pub const Size = struct {
            name: []const u8,
            size: i64,
        };
    };
};

pub const GlobalConstant = struct {
    name: []const u8,
    value: []const u8,
};

pub const GlobalEnum = struct {
    name: []const u8,
    is_bitfield: bool,
    values: []Value,

    pub const Value = struct {
        name: []const u8,
        value: i64,
    };
};

pub const Class = struct {
    name: []const u8,
    is_refcounted: bool,
    is_instantiable: bool,
    inherits: ?[]const u8 = null,
    api_type: []const u8,
    constants: ?[]Constant = null,
    enums: ?[]Enum = null,
    methods: ?[]Method = null,
    signals: ?[]Signal = null,
    properties: ?[]Property = null,

    pub const Constant = struct {
        name: []const u8,
        value: i64,
    };

    pub const Enum = struct {
        name: []const u8,
        is_bitfield: bool,
        values: []Value,

        pub const Value = struct {
            name: []const u8,
            value: i64,
        };
    };

    pub const Method = struct {
        name: []const u8,
        is_const: bool,
        is_static: bool,
        is_required: bool = false,
        is_vararg: bool,
        is_virtual: bool,
        hash: u64 = 0,
        hash_compatibility: ?[]u64 = null,
        return_value: ?ReturnValue = null,
        arguments: ?[]Argument = null,

        pub const Argument = struct {
            name: []const u8,
            type: []const u8,
            meta: ?[]const u8 = null,
            default_value: ?[]const u8 = null,
        };

        pub const ReturnValue = struct {
            type: []const u8,
            meta: ?[]const u8 = null,
            default_value: ?[]const u8 = null,
        };
    };

    pub const Property = struct {
        type: []const u8,
        name: []const u8,
        setter: ?[]const u8 = null,
        getter: []const u8,
        index: i64 = -1,
    };

    pub const Signal = struct {
        name: []const u8,
        arguments: ?[]Argument = null,

        pub const Argument = struct {
            name: []const u8,
            type: []const u8,
            meta: ?[]const u8 = null,
            default_value: ?[]const u8 = null,
        };
    };
};

pub const NativeStructure = struct {
    name: []const u8,
    format: []const u8,
};

pub const Singleton = struct {
    name: []const u8,
    type: []const u8,
};

pub const UtilityFunction = struct {
    name: []const u8,
    return_type: ?[]const u8 = null,
    category: []const u8,
    is_vararg: bool,
    hash: u64,
    arguments: []Argument = &.{},

    pub const Argument = struct {
        name: []const u8,
        type: []const u8,
        meta: ?[]const u8 = null,
        default_value: ?[]const u8 = null,
    };
};

const std = @import("std");

const Allocator = std.mem.Allocator;
const Parsed = std.json.Parsed;
