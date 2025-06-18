//! This type defines the schema for Godot's `extension_api.json`.

const Json = @This();

header: Header,
builtin_class_sizes: []BuildConfigSizes,
builtin_class_member_offsets: []BuildConfigMemberOffsets,
global_enums: []GlobalEnum,
global_constants: []NameValueString,
utility_functions: []UtilityFunction,
builtin_classes: []BuiltinClass,
classes: []Class,
singletons: []Singleton,
native_structures: []NativeStructure,

pub fn parse(allocator: Allocator, contents: []const u8) !Parsed(Json) {
    return try std.json.parseFromSlice(Json, allocator, contents, .{
        .ignore_unknown_fields = false,
    });
}

pub fn parseLeaky(allocator: Allocator, contents: []const u8) !Json {
    return try std.json.parseFromSliceLeaky(Json, allocator, contents, .{
        .ignore_unknown_fields = false,
    });
}

pub const Header = struct {
    version_major: i64,
    version_minor: i64,
    version_patch: i64,
    version_status: []const u8,
    version_build: []const u8,
    version_full_name: []const u8,
};

pub const NameValueInt = struct {
    name: []const u8,
    value: i64,
};

pub const NameValueString = struct {
    name: []const u8,
    value: []const u8,
};

pub const NameType = struct {
    name: []const u8,
    type: []const u8,
};

pub const NameTypeDefault = struct {
    name: []const u8,
    type: []const u8,
    default_value: []const u8 = "",
};

pub const NameSize = struct {
    name: []const u8,
    size: i64,
};

pub const BuildConfigSizes = struct {
    build_configuration: []const u8,
    sizes: []NameSize,
};

pub const MemberOffset = struct {
    member: []const u8,
    offset: i64,
    meta: []const u8,
};

pub const ClassMemberOffsets = struct {
    name: []const u8,
    members: []MemberOffset,
};

pub const BuildConfigMemberOffsets = struct {
    build_configuration: []const u8,
    classes: []ClassMemberOffsets,
};

pub const EnumValue = struct {
    name: []const u8,
    value: i64,
};

pub const GlobalEnum = struct {
    name: []const u8,
    is_bitfield: bool,
    values: []EnumValue,
};

pub const Constant = struct {
    name: []const u8,
    type: []const u8,
    value: []const u8,
};

pub const UtilityFunction = struct {
    name: []const u8,
    return_type: []const u8 = "",
    category: []const u8,
    is_vararg: bool,
    hash: u64,
    arguments: ?[]NameType = null,
};

pub const Enum = struct {
    name: []const u8,
    values: []EnumValue,
};

pub const ClassEnum = struct {
    name: []const u8,
    is_bitfield: bool,
    values: []EnumValue,
};

pub const Operator = struct {
    name: []const u8,
    right_type: []const u8 = "",
    return_type: []const u8,
};

pub const Method = struct {
    name: []const u8,
    return_type: []const u8 = "void",
    is_vararg: bool,
    is_const: bool,
    is_static: bool,
    hash: u64,
    arguments: ?[]NameTypeDefault = null,
};

pub const Constructor = struct {
    index: i64,
    arguments: ?[]NameType = null,
};

pub const BuiltinClass = struct {
    name: []const u8,
    indexing_return_type: []const u8 = "",
    is_keyed: bool,
    members: ?[]NameType = null,
    constants: ?[]Constant = null,
    enums: ?[]Enum = null,
    operators: []Operator,
    methods: ?[]Method = null,
    constructors: []Constructor,
    has_destructor: bool,
};

pub const ReturnValue = struct {
    type: []const u8,
    meta: []const u8 = "",
    default_value: []const u8 = "",
};

pub const Argument = struct {
    name: []const u8,
    type: []const u8,
    meta: []const u8 = "",
    default_value: []const u8 = "",
};

pub const ClassMethod = struct {
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
};

pub const Signal = struct {
    name: []const u8,
    arguments: ?[]NameType = null,
};

pub const Property = struct {
    type: []const u8,
    name: []const u8,
    setter: []const u8 = "",
    getter: []const u8,
    index: i64 = -1,
};

pub const Class = struct {
    name: []const u8,
    is_refcounted: bool,
    is_instantiable: bool,
    inherits: []const u8 = "",
    api_type: []const u8,
    constants: ?[]NameValueInt = null,
    enums: ?[]ClassEnum = null,
    methods: ?[]ClassMethod = null,
    signals: ?[]Signal = null,
    properties: ?[]Property = null,
};

pub const Singleton = struct {
    name: []const u8,
    type: []const u8,
};

pub const NativeStructure = struct {
    name: []const u8,
    format: []const u8,
};

const std = @import("std");

const Allocator = std.mem.Allocator;
const Parsed = std.json.Parsed;
