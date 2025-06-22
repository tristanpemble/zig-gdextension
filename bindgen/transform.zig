const Transformer = @This();

allocator: Allocator,
json: Schema,

pub fn transform(allocator: Allocator, json: Schema) !Data {
    var self = Transformer{
        .allocator = allocator,
        .json = json,
    };

    const interfaces = try self.transformInterfaces();
    const builtins = try self.transformBuiltins();
    const classes = try self.transformClasses();
    const constants = try self.transformGlobalConstants();
    const enums = try self.transformGlobalEnums();
    const flags = try self.transformGlobalFlags();
    const functions = try self.transformUtilityFunctions();

    return .{
        .interfaces = interfaces,
        .builtins = builtins,
        .classes = classes,
        .constants = constants,
        .enums = enums,
        .flags = flags,
        .functions = functions,

        .has_builtins = builtins.len > 0,
        .has_classes = classes.len > 0,
        .has_constants = constants.len > 0,
        .has_enums = enums.len > 0,
        .has_flags = flags.len > 0,
        .has_functions = functions.len > 0,
    };
}

fn parseFunctionPointers(self: *Transformer, header_path: []const u8) !std.StringHashMapUnmanaged([]const u8) {
    const header_file = try std.fs.openFileAbsolute(header_path, .{});
    var buffered_reader = std.io.bufferedReader(header_file.reader());
    const reader = buffered_reader.reader();

    var fp_map = std.StringHashMapUnmanaged([]const u8){};

    const name_doc = "@name";

    var buf: [1024]u8 = undefined;
    var fn_name: ?[]const u8 = null;
    var fp_type: ?[]const u8 = null;
    const safe_ident_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

    while (true) {
        const line: []const u8 = reader.readUntilDelimiterOrEof(&buf, '\n') catch break orelse break;

        if (std.mem.containsAtLeast(u8, line, 1, name_doc)) {
            const name_index = std.mem.indexOf(u8, line, name_doc).?;
            const start = name_index + name_doc.len + 1; // +1 to skip the space after @name
            fn_name = try self.allocator.dupe(u8, line[start..]);
            fp_type = null;
        } else if (std.mem.startsWith(u8, line, "typedef")) {
            if (fn_name == null) continue; // skip if we don't have a function name yet

            var iterator = std.mem.splitSequence(u8, line, " ");
            _ = iterator.next(); // skip "typedef"
            const const_or_return_type = iterator.next().?; // skip the return type
            if (std.mem.eql(u8, const_or_return_type, "const")) {
                // skip "const" keyword
                _ = iterator.next();
            }

            const fp_type_slice = iterator.next().?;
            const start = std.mem.indexOfAny(u8, fp_type_slice, safe_ident_chars).?;
            const end = std.mem.indexOf(u8, fp_type_slice[start..], ")").?;
            fp_type = try self.allocator.dupe(u8, fp_type_slice[start..(end + start)]);
        }

        if (fn_name) |_| if (fp_type) |_| {
            try fp_map.putNoClobber(self.allocator, fp_type.?, fn_name.?);

            fn_name = null;
            fp_type = null;
        };
    }

    return fp_map;
}

fn transformInterfaces(self: *Transformer) ![]Data.Interface {
    const path = try std.fs.cwd().realpathAlloc(self.allocator, "gdextension_interface.h");
    var fp_map = try self.parseFunctionPointers(path);
    var result = std.ArrayListUnmanaged(Data.Interface){};

    for (comptime @typeInfo(gd).@"struct".decls) |decl| {
        if (std.mem.startsWith(u8, decl.name, "GDExtensionInterface")) {
            const name = try std.mem.replaceOwned(u8, self.allocator, decl.name, "GDExtensionInterface", "");
            if (std.mem.eql(u8, name, "FunctionPtr") or std.mem.eql(u8, name, "GetProcAddress")) {
                continue;
            }

            const proc_name = fp_map.get(decl.name).?;

            name[0] = std.ascii.toLower(name[0]);

            try result.append(self.allocator, .{
                .name = name,
                .proc_name = proc_name,
                .type = decl.name,
            });
        }
    }

    return result.items;
}

fn transformGlobalConstants(self: *Transformer) ![]Data.GlobalConstant {
    var result = try self.allocator.alloc(Data.GlobalConstant, self.json.global_constants.len);
    for (self.json.global_constants, 0..) |constant, i| {
        result[i] = Data.GlobalConstant{
            .name = try self.formatName(Data.Name.val(constant.name)),
            .value = try self.allocator.dupe(u8, constant.value),
        };
    }
    return result;
}

fn transformGlobalEnums(self: *Transformer) ![]Data.Enum {
    var capacity: u32 = 0;
    for (self.json.global_enums) |enum_def| {
        if (enum_def.is_bitfield) continue;
        capacity += 1;
    }

    var result = try std.ArrayListUnmanaged(Data.Enum).initCapacity(self.allocator, capacity);
    for (self.json.global_enums) |enum_def| {
        if (enum_def.is_bitfield) continue;

        var values = try self.allocator.alloc(Data.Enum.Value, enum_def.values.len);

        for (enum_def.values, 0..) |value, j| {
            values[j] = Data.Enum.Value{
                .name = try self.formatName(enumFieldName(enum_def.name, value.name)),
                .value = try std.fmt.allocPrint(self.allocator, "{d}", .{value.value}),
            };
        }

        result.appendAssumeCapacity(Data.Enum{
            .name = try self.formatName(Data.Name.type_(enum_def.name)),
            .has_values = values.len > 0,
            .values = values,
        });
    }
    return result.items;
}

fn transformGlobalFlags(self: *Transformer) ![]Data.Flag {
    var flag_capacity: u32 = 0;
    for (self.json.global_enums) |flag_def| {
        if (!flag_def.is_bitfield) continue;
        flag_capacity += 1;
    }

    var result = try std.ArrayListUnmanaged(Data.Flag).initCapacity(self.allocator, flag_capacity);
    for (self.json.global_enums) |flag_def| {
        if (!flag_def.is_bitfield) continue;

        var const_capacity: u32 = 0;
        var field_capacity: u32 = 0;
        for (flag_def.values) |value_def| {
            const is_field = value_def.value > 0 and (value_def.value & (value_def.value - 1)) == 0;
            if (is_field) {
                field_capacity += 1;
            } else {
                const_capacity += 1;
            }
        }

        var consts = try std.ArrayListUnmanaged(Data.Flag.Const).initCapacity(self.allocator, const_capacity);
        var fields = try std.ArrayListUnmanaged(Data.Flag.Value).initCapacity(self.allocator, field_capacity);

        // Find default value
        const default: i64 = blk: {
            for (flag_def.values) |value| {
                if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                    break :blk value.value;
                }
            }
            break :blk 0;
        };

        var current_bit: u6 = 0;
        for (flag_def.values) |value| {
            const is_field = value.value > 0 and (value.value & (value.value - 1)) == 0;
            const is_default = std.mem.endsWith(u8, value.name, "DEFAULT") or (default & value.value) == value.value;
            const bit_pos = if (is_field) @ctz(value.value) else 0;

            if (is_field and value.value >= (@as(i64, 1) << current_bit)) {
                current_bit = @intCast(bit_pos + 1);
            }

            if (is_field) {
                fields.appendAssumeCapacity(.{
                    .name = try self.formatName(enumFieldName(flag_def.name, value.name)),
                    .value = @intFromBool(is_default),
                });
            } else {
                consts.appendAssumeCapacity(.{
                    .name = try self.formatName(enumFieldName(flag_def.name, value.name)),
                    .value = value.value,
                });
            }
        }

        result.appendAssumeCapacity(Data.Flag{
            .name = try self.formatName(Data.Name.type_(flag_def.name)),
            .has_consts = consts.items.len > 0,
            .consts = consts.items,
            .has_values = fields.items.len > 0,
            .values = fields.items,
        });
    }

    return result.items;
}

fn transformBuiltins(self: *Transformer) ![]Data.Builtin {
    var result = try self.allocator.alloc(Data.Builtin, self.json.builtin_classes.len);
    for (self.json.builtin_classes, 0..) |builtin, i| {
        const formatted_name = try self.formatName(Data.Name.type_(builtin.name));

        const members = @constCast(if (builtin.members) |members| try self.transformBuiltinMembers(members) else &.{});
        const constants = @constCast(if (builtin.constants) |constants| try self.transformBuiltinConstants(constants) else &.{});
        const constructors = @constCast(try self.transformBuiltinConstructors(builtin.constructors, formatted_name));
        const methods = @constCast(if (builtin.methods) |methods| try self.transformBuiltinMethods(methods) else &.{});
        const enums = @constCast(if (builtin.enums) |enums| try self.transformBuiltinEnums(enums) else &.{});

        result[i] = Data.Builtin{
            .name = formatted_name,
            .has_members = members.len > 0,
            .members = members,
            .has_constants = constants.len > 0,
            .constants = constants,
            .has_constructors = constructors.len > 0,
            .constructors = constructors,
            .has_methods = methods.len > 0,
            .methods = methods,
            .has_enums = enums.len > 0,
            .enums = enums,
        };
    }
    return result;
}

fn transformBuiltinMembers(self: *Transformer, members: []Schema.Builtin.Member) ![]Data.Builtin.Member {
    var result = try self.allocator.alloc(Data.Builtin.Member, members.len);
    for (members, 0..) |member, i| {
        result[i] = Data.Builtin.Member{
            .name = try self.formatName(Data.Name.val(member.name)),
            .type = try self.formatName(Data.Name.type_(member.type)),
        };
    }
    return result;
}

fn transformBuiltinConstants(self: *Transformer, constants: []Schema.Builtin.Constant) ![]Data.Builtin.Constant {
    var result = try self.allocator.alloc(Data.Builtin.Constant, constants.len);
    for (constants, 0..) |constant, i| {
        result[i] = Data.Builtin.Constant{
            .name = try self.formatName(Data.Name.val(constant.name)),
            .type = try self.formatName(Data.Name.type_(constant.type)),
            .value = try self.allocator.dupe(u8, constant.value),
        };
    }
    return result;
}

fn transformBuiltinConstructors(self: *Transformer, constructors: []Schema.Builtin.Constructor, builtin_name: []const u8) ![]Data.Builtin.Constructor {
    var result = try self.allocator.alloc(Data.Builtin.Constructor, constructors.len);
    for (constructors, 0..) |constructor, i| {
        const args = @constCast(if (constructor.arguments) |args| try self.transformBuiltinConstructorArgs(args) else &.{});
        result[i] = Data.Builtin.Constructor{
            .name = try std.fmt.allocPrint(self.allocator, "init{d}", .{constructor.index}),
            .type = "GDExtensionPtrConstructor",
            .offset = try std.fmt.allocPrint(self.allocator, "{d}", .{constructor.index}),
            .has_args = args.len > 0,
            .args = args,
            .return_type = try std.fmt.allocPrint(self.allocator, "!{s}", .{builtin_name}),
        };
    }
    return result;
}

fn transformBuiltinConstructorArgs(self: *Transformer, args: []Schema.Builtin.Constructor.Argument) ![]Data.Builtin.Constructor.Arg {
    var result = try self.allocator.alloc(Data.Builtin.Constructor.Arg, args.len);
    for (args, 0..) |arg, i| {
        result[i] = Data.Builtin.Constructor.Arg{
            .name = try self.formatName(Data.Name.val(arg.name)),
            .type = try self.formatName(Data.Name.type_(arg.type)),
        };
    }
    return result;
}

fn transformBuiltinMethods(self: *Transformer, methods: []Schema.Builtin.Method) ![]Data.Builtin.Method {
    var result = try self.allocator.alloc(Data.Builtin.Method, methods.len);
    for (methods, 0..) |method, i| {
        const args = @constCast(if (method.arguments) |args| try self.transformBuiltinMethodArgs(args) else &.{});
        result[i] = Data.Builtin.Method{
            .name = try self.formatName(Data.Name.func(method.name)),
            .type = "GDExtensionPtrBuiltInMethod",
            .offset = try std.fmt.allocPrint(self.allocator, "{d}", .{method.hash}),
            .has_args = args.len > 0,
            .args = args,
            .return_type = try self.formatName(Data.Name.type_(method.return_type)),
        };
    }
    return result;
}

fn transformBuiltinMethodArgs(self: *Transformer, args: []Schema.Builtin.Method.Argument) ![]Data.Builtin.Method.Arg {
    var result = try self.allocator.alloc(Data.Builtin.Method.Arg, args.len);
    for (args, 0..) |arg, i| {
        result[i] = Data.Builtin.Method.Arg{
            .name = try self.formatName(Data.Name.val(arg.name)),
            .type = try self.formatName(Data.Name.type_(arg.type)),
        };
    }
    return result;
}

fn transformBuiltinEnums(self: *Transformer, enums: []Schema.Builtin.Enum) ![]Data.Enum {
    var result = try self.allocator.alloc(Data.Enum, enums.len);
    for (enums, 0..) |enum_def, i| {
        var values = try self.allocator.alloc(Data.Enum.Value, enum_def.values.len);
        for (enum_def.values, 0..) |value, j| {
            values[j] = Data.Enum.Value{
                .name = try self.formatName(Data.Name.val(value.name)),
                .value = try std.fmt.allocPrint(self.allocator, "{d}", .{value.value}),
            };
        }

        result[i] = Data.Enum{
            .name = try self.formatName(Data.Name.type_(enum_def.name)),
            .has_values = values.len > 0,
            .values = values,
        };
    }
    return result;
}

fn transformClasses(self: *Transformer) ![]Data.Class {
    var result = try self.allocator.alloc(Data.Class, self.json.classes.len);
    for (self.json.classes, 0..) |class, i| {
        var static_methods = std.ArrayList(Data.Class.Method).init(self.allocator);
        var methods = std.ArrayList(Data.Class.Method).init(self.allocator);
        var virtual_methods = std.ArrayList(Data.Class.Method).init(self.allocator);

        if (class.methods) |class_methods| {
            for (class_methods) |method| {
                const method_name = if (method.is_virtual)
                    Data.Name.virtualFunc(method.name)
                else
                    Data.Name.func(method.name);

                const args = @constCast(if (method.arguments) |args| try self.transformClassMethodArgs(args) else &.{});

                const transformed_method = Data.Class.Method{
                    .name = try self.formatName(method_name),
                    .is_const = method.is_const,
                    .is_virtual = method.is_virtual,
                    .return_type = try self.formatName(if (method.return_value) |ret| Data.Name.type_(ret.type) else Data.Name.type_("void")),
                    .has_args = args.len > 0,
                    .args = args,
                };

                if (method.is_static) {
                    try static_methods.append(transformed_method);
                } else if (method.is_virtual) {
                    try virtual_methods.append(transformed_method);
                } else {
                    try methods.append(transformed_method);
                }
            }
        }

        const constants = @constCast(if (class.constants) |constants| try self.transformClassConstants(constants) else &.{});
        const class_enums_and_flags = if (class.enums) |enums| try self.transformClassEnums(enums) else ClassEnumsAndFlags{ .enums = &.{}, .flags = &.{} };
        const properties = @constCast(if (class.properties) |properties| try self.transformClassProperties(properties) else &.{});

        result[i] = Data.Class{
            .name = try self.formatName(Data.Name.type_(class.name)),
            .is_singleton = self.is_singleton(class.name),
            .inherits = if (class.inherits) |inherits| try self.formatName(Data.Name.type_(inherits)) else null,
            .is_instantiable = class.is_instantiable,
            .has_constants = constants.len > 0,
            .constants = constants,
            .has_enums = class_enums_and_flags.enums.len > 0,
            .enums = class_enums_and_flags.enums,
            .has_flags = class_enums_and_flags.flags.len > 0,
            .flags = class_enums_and_flags.flags,
            .has_properties = properties.len > 0,
            .properties = properties,
            .has_static_methods = static_methods.items.len > 0,
            .static_methods = try static_methods.toOwnedSlice(),
            .has_methods = methods.items.len > 0,
            .methods = try methods.toOwnedSlice(),
            .has_virtual_methods = virtual_methods.items.len > 0,
            .virtual_methods = try virtual_methods.toOwnedSlice(),
        };
    }
    return result;
}

fn transformClassConstants(self: *Transformer, constants: []Schema.Class.Constant) ![]Data.Class.Constant {
    var result = try self.allocator.alloc(Data.Class.Constant, constants.len);
    for (constants, 0..) |constant, i| {
        result[i] = Data.Class.Constant{
            .name = try self.formatName(Data.Name.val(constant.name)),
            .value = try std.fmt.allocPrint(self.allocator, "{d}", .{constant.value}),
        };
    }
    return result;
}

const ClassEnumsAndFlags = struct {
    enums: []Data.Enum,
    flags: []Data.Flag,
};

fn transformClassEnums(self: *Transformer, enums: []Schema.Class.Enum) !ClassEnumsAndFlags {
    var enum_list = std.ArrayList(Data.Enum).init(self.allocator);
    var flag_list = std.ArrayList(Data.Flag).init(self.allocator);

    for (enums) |enum_def| {
        if (enum_def.is_bitfield) {
            // Transform as flag
            var const_capacity: u32 = 0;
            var field_capacity: u32 = 0;
            for (enum_def.values) |value_def| {
                const is_field = value_def.value > 0 and (value_def.value & (value_def.value - 1)) == 0;
                if (is_field) {
                    field_capacity += 1;
                } else {
                    const_capacity += 1;
                }
            }

            var consts = try std.ArrayListUnmanaged(Data.Flag.Const).initCapacity(self.allocator, const_capacity);
            var fields = try std.ArrayListUnmanaged(Data.Flag.Value).initCapacity(self.allocator, field_capacity);

            // Find default value
            const default: i64 = blk: {
                for (enum_def.values) |value| {
                    if (std.mem.endsWith(u8, value.name, "DEFAULT")) {
                        break :blk value.value;
                    }
                }
                break :blk 0;
            };

            for (enum_def.values) |value| {
                const is_field = value.value > 0 and (value.value & (value.value - 1)) == 0;
                const is_default = std.mem.endsWith(u8, value.name, "DEFAULT") or (default & value.value) == value.value;

                if (is_field) {
                    fields.appendAssumeCapacity(.{
                        .name = try self.formatName(enumFieldName(enum_def.name, value.name)),
                        .value = @intFromBool(is_default),
                    });
                } else {
                    consts.appendAssumeCapacity(.{
                        .name = try self.formatName(enumFieldName(enum_def.name, value.name)),
                        .value = value.value,
                    });
                }
            }

            try flag_list.append(Data.Flag{
                .name = try self.formatName(Data.Name.type_(enum_def.name)),
                .has_consts = consts.items.len > 0,
                .consts = consts.items,
                .has_values = fields.items.len > 0,
                .values = fields.items,
            });
        } else {
            // Transform as enum
            var values = try self.allocator.alloc(Data.Enum.Value, enum_def.values.len);
            for (enum_def.values, 0..) |value, j| {
                values[j] = Data.Enum.Value{
                    .name = try self.formatName(enumFieldName(enum_def.name, value.name)),
                    .value = try std.fmt.allocPrint(self.allocator, "{d}", .{value.value}),
                };
            }

            try enum_list.append(Data.Enum{
                .name = try self.formatName(Data.Name.type_(enum_def.name)),
                .has_values = values.len > 0,
                .values = values,
            });
        }
    }

    return ClassEnumsAndFlags{
        .enums = try enum_list.toOwnedSlice(),
        .flags = try flag_list.toOwnedSlice(),
    };
}

fn transformClassProperties(self: *Transformer, properties: []Schema.Class.Property) ![]Data.Class.Property {
    var result = try self.allocator.alloc(Data.Class.Property, properties.len);
    for (properties, 0..) |property, i| {
        result[i] = Data.Class.Property{
            .name = try self.formatName(Data.Name.val(property.name)),
            .type = try self.formatName(Data.Name.type_(property.type)),
            .getter = try self.formatName(Data.Name.func(property.getter)),
            .has_setter = property.setter != null,
            .setter = if (property.setter) |setter| try self.formatName(Data.Name.func(setter)) else null,
        };
    }
    return result;
}

fn transformClassMethodArgs(self: *Transformer, args: []Schema.Class.Method.Argument) ![]Data.Class.Method.Arg {
    var result = try self.allocator.alloc(Data.Class.Method.Arg, args.len);
    for (args, 0..) |arg, i| {
        result[i] = Data.Class.Method.Arg{
            .name = try self.formatName(Data.Name.val(arg.name)),
            .type = try self.formatName(Data.Name.type_(arg.type)),
        };
    }
    return result;
}

fn transformUtilityFunctions(self: *Transformer) ![]Data.Function {
    var categories = std.StringHashMap(std.ArrayList(Data.Function.FunctionDef)).init(self.allocator);
    defer {
        var iter = categories.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        categories.deinit();
    }

    for (self.json.utility_functions) |func| {
        const entry = try categories.getOrPut(func.category);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(Data.Function.FunctionDef).init(self.allocator);
        }

        const args = try self.transformUtilityFunctionArgs(func.arguments);

        const function_def = Data.Function.FunctionDef{
            .name = try self.formatName(Data.Name.func(func.name)),
            .return_type = try self.formatName(if (func.return_type) |ret| Data.Name.type_(ret) else Data.Name.type_("void")),
            .has_args = args.len > 0,
            .args = args,
        };

        try entry.value_ptr.append(function_def);
    }

    var result = try self.allocator.alloc(Data.Function, categories.count());
    var iter = categories.iterator();
    var i: usize = 0;
    while (iter.next()) |entry| {
        result[i] = Data.Function{
            .category = try self.formatName(Data.Name.val(entry.key_ptr.*)),
            .has_functions = entry.value_ptr.items.len > 0,
            .functions = try entry.value_ptr.toOwnedSlice(),
        };
        i += 1;
    }

    return result;
}

fn transformUtilityFunctionArgs(self: *Transformer, args: []Schema.UtilityFunction.Argument) ![]Data.Function.FunctionDef.Arg {
    var result = try self.allocator.alloc(Data.Function.FunctionDef.Arg, args.len);
    for (args, 0..) |arg, i| {
        result[i] = Data.Function.FunctionDef.Arg{
            .name = try self.formatName(Data.Name.val(arg.name)),
            .type = try self.formatName(Data.Name.type_(arg.type)),
        };
    }
    return result;
}

fn formatName(self: *Transformer, name: Data.Name) ![]u8 {
    var buf: [256]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try name.format("", .{}, stream.writer());
    return try self.allocator.dupe(u8, buf[0..stream.pos]);
}

fn enumFieldName(@"enum": []const u8, field: []const u8) Data.Name {
    if (Data.enum_prefix_exceptions.get(@"enum")) |prefix| {
        if (std.mem.startsWith(u8, field, prefix)) {
            return Data.Name{ .snake = field[prefix.len..] };
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

    const case = @import("case");
    plural_name = case.bufTo(&buf1, .constant, plural_name) catch return Data.Name{ .snake = field };
    singular_name = case.bufTo(&buf2, .constant, singular_name) catch return Data.Name{ .snake = field };

    // Try with underscore separator
    if (std.mem.startsWith(u8, field, plural_name)) {
        const prefix_len = plural_name.len;
        if (field.len > prefix_len and field[prefix_len] == '_') {
            return Data.Name{ .snake = field[prefix_len + 1 ..] };
        }
    } else if (std.mem.startsWith(u8, field, singular_name)) {
        const prefix_len = singular_name.len;
        if (field.len > prefix_len and field[prefix_len] == '_') {
            return Data.Name{ .snake = field[prefix_len + 1 ..] };
        }
    }

    return Data.Name{ .snake = field };
}

fn is_singleton(self: *Transformer, name: []const u8) bool {
    for (self.json.singletons) |singleton| {
        if (std.mem.eql(u8, singleton.name, name)) return true;
    }
    return false;
}

const std = @import("std");
const gd = @import("godot");

const Schema = @import("./Schema.zig");
const Data = @import("./Data.zig");

const Allocator = std.mem.Allocator;
