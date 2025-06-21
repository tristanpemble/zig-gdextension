pub const root =
    \\pub const c = @import("godot_cpp");
    \\
    \\pub var interface: @import("Interface.zig") = undefined;
    \\
    \\{{#builtins}}
    \\pub const {{name}} = builtin.{{name}};
    \\{{/builtins}}
    \\{{#classes}}
    \\pub const {{name}} = builtin.{{name}};
    \\{{/classes}}
    \\{{#constants}}
    \\pub const {{name}} = {{value}};
    \\{{/constants}}
    \\{{#enums}}
    \\pub const {{name}} = builtin.{{name}};
    \\{{/enums}}
    \\{{#flags}}
    \\pub const {{name}} = builtin.{{name}};
    \\{{/flags}}
    \\{{#functions}}
    \\pub const {{category}} = @import("{{category}}.zig");
    \\{{/functions}}
    \\
    \\pub const builtin = struct {
    \\    {{#builtins}}
    \\    pub const {{name}} = @import("{{name}}.zig");
    \\    {{/builtins}}
    \\    {{#enums}}
    \\    pub const {{name}} = @import("{{name}}.zig");
    \\    {{/enums}}
    \\    {{#flags}}
    \\    pub const {{name}} = @import("{{name}}.zig");
    \\    {{/flags}}
    \\};
    \\
    \\pub const engine = struct {
    \\    {{#classes}}
    \\    pub const {{name}} = @import("{{name}}.zig");
    \\    {{/classes}}
    \\};
    \\
;

pub const interface =
    \\{{#interfaces}}
    \\{{name}}: Child(gd.c.{{type}}),
    \\{{/interfaces}}
    \\
    \\pub fn init(getProcAddress: Child(gd.c.GDExtensionInterfaceGetProcAddress)) @This() {
    \\    return .{
    \\        {{#interfaces}}
    \\        .{{name}} = @ptrCast(getProcAddress("{{proc_name}}")),
    \\        {{/interfaces}}
    \\    };
    \\}
    \\
    \\const std = @import("std");
    \\const gd = @import("godot");
    \\
    \\const Child = std.meta.Child;
    \\
;

pub const builtin =
    \\/// {{builtin.doc}}
    \\pub const {{builtin.name}} = extern struct {
    \\    {{#builtin.members}}
    \\    /// {{doc}}
    \\    {{name}}: {{type}},
    \\
    \\    {{/builtin.members}}
    \\    {{#builtin.constants}}
    \\    /// {{doc}}
    \\    pub const {{name}}: {{type}} = {{value}};
    \\
    \\    {{/builtin.constants}}
    \\    {{#builtin.constructors}}
    \\    /// {{doc}}
    \\    pub fn {{name}}({{#args}}{{name}}: {{type}}, {{/args}}) {{return_type}} {
    \\        var constructor = struct {
    \\            var method: gd.c.{{type}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{type}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrConstructor("todo", {{offset}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var out: {{builtin.name}} = std.mem.zeroes({{builtin.name}});
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#args}}
    \\          @ptrCast(&{{name}}),
    \\          {{/args}}
    \\        };
    \\        constructor(@ptrCast(&out), @ptrCast(&args))
    \\        return out orelse error.UnexpectedNull;
    \\    }
    \\
    \\    {{/builtin.constructors}}
    \\    {{#builtin.methods}}
    \\    /// {{doc}}
    \\    pub fn {{name}}(self: *{{builtin.name}}{{#args}}, {{name}}: {{type}}{{/args}}) {{return_type}} {
    \\        var method = struct {
    \\            var method: gd.c.{{type}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{type}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrBuiltinMethod("{{../name}}", "{{name}}", {{offset}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var ret: {{return_type}} = undefined;
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#args}}
    \\          @ptrCast(&{{name}}),
    \\          {{/args}}
    \\        };
    \\        method(@ptrCast(self), @ptrCast(&args), @ptrCast(&ret), {{args.len}});
    \\        return ret;
    \\    }
    \\
    \\    {{/builtin.methods}}
    \\    {{#builtin.enums}}
    \\    /// {{doc}}
    \\    pub const {{name}} = enum(i32) {
    \\        {{#values}}
    \\        /// {{doc}}
    \\        {{name}} = {{value}},
    \\        {{/values}}
    \\    };
    \\    {{/builtin.enums}}
    \\};
    \\
    \\const std = @import("std");
    \\const gd = @import("godot");
    \\
;

pub const class =
    \\/// {{class.doc}}
    \\pub const {{class.name}} = struct {
    \\    {{#class.inherits}}
    \\    pub const Base = {{class.inherits}};
    \\
    \\    {{/class.inherits}}
    \\    {{#class.constants}}
    \\    /// {{doc}}
    \\    pub const {{name}}: i64 = {{value}};
    \\
    \\    {{/class.constants}}
    \\    {{#class.is_instantiable}}
    \\    pub fn init() {{type}} {
    \\
    \\    }
    \\
    \\    {{/class.is_instantiable}}
    // \\    {{#class.properties}}
    // \\    pub fn {{getter}}(self: *const {{class.name}}) {{type}} {
    // \\    }
    // \\
    // \\    {{#has_setter}}
    // \\    pub fn {{setter}}(self: *{{class.name}}, value: {{type}}) void {
    // \\    }
    // \\
    // \\    {{/has_setter}}
    // \\    {{/class.properties}}
    \\    {{#class.static_methods}}
    \\    pub fn {{name}}({{#args}}, {{name}}: {{type}}{{/args}}) {{return_type}} {
    \\    }
    \\
    \\    {{/class.static_methods}}
    \\    {{#class.methods}}
    \\    pub fn {{name}}(self: *{{#is_const}}const {{/is_const}}{{class.name}}{{#args}}, {{name}}: {{type}}{{/args}}) {{return_type}} {
    \\    }
    \\
    \\    {{/class.methods}}
    \\    {{#class.virtual_methods}}
    \\    pub fn {{name}}(self: *{{class.name}}{{#args}}, {{name}}: {{type}}{{/args}}) {{return_type}} {
    \\    }
    \\
    \\    {{/class.virtual_methods}}
    \\    {{#class.enums}}
    \\    /// {{doc}}
    \\    pub const {{name}} = enum(i32) {
    \\        {{#values}}
    \\        {{name}} = {{value}},
    \\        {{/values}}
    \\    };
    \\
    \\    {{/class.enums}}
    \\    {{#class.is_singleton}}
    \\    var instance: ?{{class.name}} = undefined;
    \\
    \\    fn getSingleton() {{class.name}} {
    \\        if (instance == null) {
    \\            @panic("TODO: implement getSingleton");
    \\        }
    \\        return instance.?;
    \\    }
    \\    {{/class.is_singleton}}
    \\};
    \\
;

pub const @"enum" =
    \\/// {{doc}}
    \\pub const {{enum.name}} = enum(i32) {
    \\    {{#enum.values}}
    \\    {{name}} = {{value}},
    \\    {{/enum.values}}
    \\};
    \\
;

pub const flag =
    \\/// {{flag.doc}}
    \\pub const {{flag.name}} = packed struct(i32) {
    \\    {{#flag.values}}
    \\    {{#is_power_of_two}}
    \\    {{name}}: u1 = {{#is_default}}1{{/is_default}}{{^is_default}}0{{/is_default}},
    \\    {{/is_power_of_two}}
    \\    {{/flag.values}}
    \\
    \\    {{#flag.values}}
    \\    {{^is_power_of_two}}
    \\    pub const {{name}}: {{../name}} = @bitCast({{value}});
    \\    {{/is_power_of_two}}
    \\    {{/flag.values}}
    \\};
    \\
;

pub const function =
    \\/// {{function.doc}}
    \\pub const {{function.category}} = struct {
    \\    {{#function.functions}}
    \\    /// {{doc}}
    \\    pub fn {{name}}({{#args}}{{name}}: {{type}}, {{/args}}) {{return_type}} {
    \\        @panic("todo");
    \\    }
    \\    {{/function.functions}}
    \\};
    \\
;
