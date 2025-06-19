//! This module provides a cleaner API over the `extension_api.json` document.
//!
//! It does so by normalizing the types and standardizing naming conventions for Zig.

const Api = @This();

classes: HashMap(Class) = .{},
constants: HashMap(Constant) = .{},
enums: HashMap(Enum) = .{},
functions: HashMap(Function) = .{},
structs: HashMap(Struct) = .{},

pub const Config = struct {
    case: struct {
        argument: case.Case = .snake,
        constant: case.Case = .snake,
        function: case.Case = .camel,
        type: case.Case = .pascal,
        variant: case.Case = .snake,
    } = .{},
};

pub fn init(allocator: Allocator, json: *const Json, comptime config: Config) !Api {
    var api = Api{};

    // Create singleton lookup
    var singletons = HashMap(void){};
    defer singletons.deinit(allocator);
    for (json.singletons) |singleton| {
        try singletons.put(allocator, singleton.name, {});
    }

    // Engine classes
    for (json.classes) |json_class| {
        const is_singleton = singletons.contains(json_class.name);
        const class = Class{ .engine = try Class.Engine.init(allocator, json_class, is_singleton, config) };
        try api.classes.put(allocator, class.getName(), class);
    }

    // Builtin classes
    for (json.builtin_classes) |json_builtin| {
        const class = Class{ .builtin = try Class.Builtin.init(allocator, json_builtin, config) };
        try api.classes.put(allocator, class.getName(), class);
    }

    // Functions
    for (json.utility_functions) |json_func| {
        const func = try Function.init(allocator, json_func, config);
        try api.functions.put(allocator, func.name, func);
    }

    // Enums
    for (json.global_enums) |json_enum| {
        const enum_obj = try Enum.initGlobal(allocator, json_enum, config);
        try api.enums.put(allocator, enum_obj.name, enum_obj);
    }

    // Constants
    for (json.global_constants) |json_constant| {
        const constant = try Constant.initString(allocator, json_constant, config);
        try api.constants.put(allocator, constant.name, constant);
    }

    // Structs
    for (json.native_structures) |json_struct| {
        const struct_obj = try Struct.init(allocator, json_struct, config);
        try api.structs.put(allocator, struct_obj.name, struct_obj);
    }

    return api;
}

pub fn jsonStringify(self: @This(), jws: anytype) !void {
    try jws.write(.{
        .classes = std.json.ArrayHashMap(Class){ .map = self.classes },
        .constants = std.json.ArrayHashMap(Constant){ .map = self.constants },
        .enums = std.json.ArrayHashMap(Enum){ .map = self.enums },
        .functions = std.json.ArrayHashMap(Function){ .map = self.functions },
        .structs = std.json.ArrayHashMap(Struct){ .map = self.structs },
    });
}

pub const Argument = struct {
    name: []const u8,
    type: []const u8,
    default: ?[]const u8 = null,

    pub fn init(allocator: Allocator, name: []const u8, type_name: []const u8, default: ?[]const u8, comptime config: Config) !Argument {
        return Argument{
            .name = try safeName(allocator, config.case.argument, name),
            .type = type_name,
            .default = if (default) |d| d else null,
        };
    }

    pub fn deinit(self: *Argument, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.type);
        if (self.default) |default| {
            allocator.free(default);
        }
    }

    fn initJson(allocator: Allocator, json_args: ?[]Json.Argument, comptime config: Config) !HashMap(Argument) {
        var args = HashMap(Argument){};

        if (json_args) |args_slice| {
            for (args_slice) |json_arg| {
                const arg = try Argument.init(
                    allocator,
                    json_arg.name,
                    if (json_arg.meta.len > 0) json_arg.meta else json_arg.type,
                    json_arg.default_value,
                    config,
                );
                try args.put(allocator, arg.name, arg);
            }
        }

        return args;
    }

    fn initNameType(allocator: Allocator, json_args: ?[]Json.NameType, comptime config: Config) !HashMap(Argument) {
        var args = HashMap(Argument){};

        if (json_args) |args_slice| {
            for (args_slice) |json_arg| {
                const arg = try Argument.init(allocator, json_arg.name, json_arg.type, null, config);
                try args.put(allocator, arg.name, arg);
            }
        }

        return args;
    }

    fn initNameTypeDefault(allocator: Allocator, json_args: ?[]Json.NameTypeDefault, comptime config: Config) !HashMap(Argument) {
        var args = HashMap(Argument){};

        if (json_args) |args_slice| {
            for (args_slice) |json_arg| {
                const arg = try Argument.init(allocator, json_arg.name, json_arg.type, json_arg.default_value, config);
                try args.put(allocator, arg.name, arg);
            }
        }

        return args;
    }
};

pub const Class = union(enum) {
    builtin: Builtin,
    engine: Engine,

    pub const Property = struct {
        name: []const u8,
        type: []const u8,
        setter: []const u8,
        getter: []const u8,
        index: i64,

        pub fn init(allocator: Allocator, json_prop: Json.Property, comptime config: Config) !Property {
            return Property{
                .name = try safeName(allocator, config.case.type, json_prop.name),
                .type = json_prop.type,
                .setter = try safeName(allocator, config.case.function, json_prop.setter),
                .getter = try safeName(allocator, config.case.function, json_prop.getter),
                .index = json_prop.index,
            };
        }
    };

    pub const Engine = struct {
        name: []const u8,
        is_refcounted: bool,
        is_instantiable: bool,
        is_singleton: bool,
        inherits: []const u8,
        api_type: []const u8,
        methods: HashMap(Method) = .{},
        constants: HashMap(Constant) = .{},
        enums: HashMap(Enum) = .{},
        signals: HashMap(Signal) = .{},
        properties: HashMap(Property) = .{},

        pub fn init(allocator: Allocator, json_class: Json.Class, is_singleton: bool, comptime config: Config) !Engine {
            var engine = Engine{
                .name = try safeName(allocator, config.case.type, json_class.name),
                .is_refcounted = json_class.is_refcounted,
                .is_instantiable = json_class.is_instantiable,
                .is_singleton = is_singleton,
                .inherits = json_class.inherits,
                .api_type = json_class.api_type,
            };

            // Methods
            if (json_class.methods) |methods| {
                for (methods) |json_method| {
                    const method = try Method.initClass(allocator, json_method, config);
                    try engine.methods.put(allocator, method.name, method);
                }
            }

            // Constants
            if (json_class.constants) |constants| {
                for (constants) |json_constant| {
                    const constant = try Constant.initInt(allocator, json_constant, config);
                    try engine.constants.put(allocator, constant.name, constant);
                }
            }

            // Enums
            if (json_class.enums) |enums| {
                for (enums) |json_enum| {
                    const enum_obj = try Enum.initClass(allocator, json_enum, config);
                    try engine.enums.put(allocator, enum_obj.name, enum_obj);
                }
            }

            // Signals
            if (json_class.signals) |signals| {
                for (signals) |json_signal| {
                    const signal = try Signal.init(allocator, json_signal, config);
                    try engine.signals.put(allocator, signal.name, signal);
                }
            }

            // Properties
            if (json_class.properties) |properties| {
                for (properties) |json_prop| {
                    const prop = try Property.init(allocator, json_prop, config);
                    try engine.properties.put(allocator, prop.name, prop);
                }
            }

            return engine;
        }

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.write(.{
                .name = self.name,
                .is_refcounted = self.is_refcounted,
                .is_instantiable = self.is_instantiable,
                .is_singleton = self.is_singleton,
                .inherits = self.inherits,
                .api_type = self.api_type,
                .methods = std.json.ArrayHashMap(Method){ .map = self.methods },
                .constants = std.json.ArrayHashMap(Constant){ .map = self.constants },
                .enums = std.json.ArrayHashMap(Enum){ .map = self.enums },
                .signals = std.json.ArrayHashMap(Signal){ .map = self.signals },
                .properties = std.json.ArrayHashMap(Property){ .map = self.properties },
            });
        }
    };

    pub const Builtin = struct {
        name: []const u8,
        indexing_return_type: []const u8,
        is_keyed: bool,
        has_destructor: bool,
        methods: HashMap(Method) = .{},
        constants: HashMap(Constant) = .{},
        enums: HashMap(Enum) = .{},
        members: ?[]Json.NameType,

        pub fn init(allocator: Allocator, json_builtin: Json.BuiltinClass, comptime config: Config) !Builtin {
            var builtin = Builtin{
                .name = try safeName(allocator, config.case.type, json_builtin.name),
                .indexing_return_type = json_builtin.indexing_return_type,
                .is_keyed = json_builtin.is_keyed,
                .has_destructor = json_builtin.has_destructor,
                .members = json_builtin.members,
            };

            // Methods
            if (json_builtin.methods) |methods| {
                for (methods) |json_method| {
                    const method = try Method.initBuiltin(allocator, json_method, config);
                    try builtin.methods.put(allocator, method.name, method);
                }
            }

            // Constants
            if (json_builtin.constants) |constants| {
                for (constants) |json_constant| {
                    const constant = try Constant.initJson(allocator, json_constant, config);
                    try builtin.constants.put(allocator, constant.name, constant);
                }
            }

            // Enums
            if (json_builtin.enums) |enums| {
                for (enums) |json_enum| {
                    const enum_obj = try Enum.initBuiltin(allocator, json_enum, config);
                    try builtin.enums.put(allocator, enum_obj.name, enum_obj);
                }
            }

            return builtin;
        }

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.write(.{
                .name = self.name,
                .indexing_return_type = self.indexing_return_type,
                .is_keyed = self.is_keyed,
                .has_destructor = self.has_destructor,
                .methods = std.json.ArrayHashMap(Method){ .map = self.methods },
                .constants = std.json.ArrayHashMap(Constant){ .map = self.constants },
                .enums = std.json.ArrayHashMap(Enum){ .map = self.enums },
                .members = self.members,
            });
        }
    };

    pub fn getName(self: Class) []const u8 {
        return switch (self) {
            inline else => |c| c.name,
        };
    }
};

pub const Constant = struct {
    name: []const u8,
    type: []const u8,
    value: []const u8,

    pub fn initJson(allocator: Allocator, json_constant: Json.Constant, comptime config: Config) !Constant {
        return Constant{
            .name = try safeName(allocator, config.case.constant, json_constant.name),
            .type = "json",
            .value = json_constant.value,
        };
    }

    pub fn initString(allocator: Allocator, json_constant: Json.NameValueString, comptime config: Config) !Constant {
        return Constant{
            .name = try safeName(allocator, config.case.constant, json_constant.name),
            .type = "string",
            .value = json_constant.value,
        };
    }

    pub fn initInt(allocator: Allocator, json_constant: Json.NameValueInt, comptime config: Config) !Constant {
        return Constant{
            .name = try safeName(allocator, config.case.constant, json_constant.name),
            .type = "int",
            .value = try std.fmt.allocPrint(allocator, "{d}", .{json_constant.value}),
        };
    }
};

pub const Enum = struct {
    name: []const u8,
    is_bitfield: bool,
    values: HashMap(Value),

    pub fn initGlobal(allocator: Allocator, json_enum: Json.GlobalEnum, comptime config: Config) !Enum {
        var values = HashMap(Value){};
        for (json_enum.values) |json_value| {
            const value = try Value.init(allocator, json_value.name, json_value.value, config);
            try values.put(allocator, value.name, value);
        }

        return Enum{
            .name = try safeName(allocator, config.case.type, json_enum.name),
            .is_bitfield = json_enum.is_bitfield,
            .values = values,
        };
    }

    pub fn initClass(allocator: Allocator, json_enum: Json.ClassEnum, comptime config: Config) !Enum {
        var values = HashMap(Value){};
        for (json_enum.values) |json_value| {
            const value = try Value.init(allocator, json_value.name, json_value.value, config);
            try values.put(allocator, value.name, value);
        }

        return Enum{
            .name = try safeName(allocator, config.case.type, json_enum.name),
            .is_bitfield = json_enum.is_bitfield,
            .values = values,
        };
    }

    pub fn initBuiltin(allocator: Allocator, json_enum: Json.Enum, comptime config: Config) !Enum {
        var values = HashMap(Value){};
        for (json_enum.values) |json_value| {
            const value = try Value.init(allocator, json_value.name, json_value.value, config);
            try values.put(allocator, value.name, value);
        }

        return Enum{
            .name = try safeName(allocator, config.case.type, json_enum.name),
            .is_bitfield = false,
            .values = values,
        };
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(.{
            .name = self.name,
            .is_bitfield = self.is_bitfield,
            .values = std.json.ArrayHashMap(Value){ .map = self.values },
        });
    }

    pub const Value = struct {
        name: []const u8,
        value: i64,

        pub fn init(allocator: Allocator, name: []const u8, value: i64, comptime config: Config) !Value {
            return Value{
                .name = try safeName(allocator, config.case.variant, name),
                .value = value,
            };
        }
    };
};

pub const Function = struct {
    name: []const u8,
    return_type: []const u8,
    category: []const u8,
    is_vararg: bool,
    hash: u64,
    arguments: HashMap(Argument),

    pub fn init(allocator: Allocator, json_func: Json.UtilityFunction, comptime config: Config) !Function {
        return Function{
            .name = try safeName(allocator, config.case.function, json_func.name),
            .return_type = try safeName(allocator, config.case.type, json_func.return_type),
            .category = json_func.category,
            .is_vararg = json_func.is_vararg,
            .hash = json_func.hash,
            .arguments = try Argument.initNameType(allocator, json_func.arguments, config),
        };
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(.{
            .name = self.name,
            .return_type = self.return_type,
            .category = self.category,
            .is_vararg = self.is_vararg,
            .hash = self.hash,
            .arguments = std.json.ArrayHashMap(Argument){ .map = self.arguments },
        });
    }
};

pub const Method = struct {
    name: []const u8,
    return_type: []const u8,
    is_const: bool,
    is_static: bool,
    is_vararg: bool,
    hash: u64,
    arguments: HashMap(Argument),
    is_required: bool,
    is_virtual: bool,
    hash_compatibility: ?[]u64,
    return_meta: []const u8,

    pub fn initClass(allocator: Allocator, json_method: Json.ClassMethod, comptime config: Config) !Method {
        return Method{
            .name = try safeName(allocator, config.case.function, json_method.name),
            .return_type = if (json_method.return_value) |rv| rv.type else "void",
            .is_const = json_method.is_const,
            .is_static = json_method.is_static,
            .is_vararg = json_method.is_vararg,
            .hash = json_method.hash,
            .arguments = try Argument.initJson(allocator, json_method.arguments, config),
            .is_required = json_method.is_required,
            .is_virtual = json_method.is_virtual,
            .hash_compatibility = json_method.hash_compatibility,
            .return_meta = if (json_method.return_value) |rv| rv.meta else "",
        };
    }

    pub fn initBuiltin(allocator: Allocator, json_method: Json.Method, comptime config: Config) !Method {
        return Method{
            .name = try safeName(allocator, config.case.function, json_method.name),
            .return_type = json_method.return_type,
            .is_const = json_method.is_const,
            .is_static = json_method.is_static,
            .is_vararg = json_method.is_vararg,
            .hash = json_method.hash,
            .arguments = try Argument.initNameTypeDefault(allocator, json_method.arguments, config),
            .is_required = false,
            .is_virtual = false,
            .hash_compatibility = null,
            .return_meta = "",
        };
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(.{
            .name = self.name,
            .return_type = self.return_type,
            .is_const = self.is_const,
            .is_static = self.is_static,
            .is_vararg = self.is_vararg,
            .hash = self.hash,
            .arguments = std.json.ArrayHashMap(Argument){ .map = self.arguments },
            .is_required = self.is_required,
            .is_virtual = self.is_virtual,
            .hash_compatibility = self.hash_compatibility,
            .return_meta = self.return_meta,
        });
    }
};

pub const Signal = struct {
    name: []const u8,
    arguments: HashMap(Argument) = .{},

    pub fn init(allocator: Allocator, json_signal: Json.Signal, comptime config: Config) !Signal {
        var signal = Signal{
            .name = try safeName(allocator, config.case.function, json_signal.name),
        };

        if (json_signal.arguments) |args_slice| {
            for (args_slice) |json_arg| {
                const arg = try Argument.init(allocator, json_arg.name, json_arg.type, null, config);
                try signal.arguments.put(allocator, arg.name, arg);
            }
        }

        return signal;
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(.{
            .name = self.name,
            .arguments = std.json.ArrayHashMap(Argument){ .map = self.arguments },
        });
    }
};

pub const Struct = struct {
    name: []const u8,
    format: []const u8,

    pub fn init(allocator: Allocator, json_struct: Json.NativeStructure, comptime config: Config) !Struct {
        return Struct{
            .name = try safeName(allocator, config.case.type, json_struct.name),
            .format = json_struct.format,
        };
    }
};

inline fn safeName(
    allocator: std.mem.Allocator,
    comptime case_: case.Case,
    text: []const u8,
) ![]const u8 {
    const name = if (case.of(text, .{}) == case_)
        text
    else
        return try case.allocTo(allocator, case_, text);

    if (std.zig.Token.keywords.has(name)) {
        return try std.fmt.allocPrint(allocator, "@\"{s}\"", .{name});
    } else {
        return name;
    }
}

const std = @import("std");
const case = @import("case");
const Json = @import("Json.zig");
const Allocator = std.mem.Allocator;
const HashMap = std.StringArrayHashMapUnmanaged;
