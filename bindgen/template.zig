pub const root =
    \\pub const c = @import("godot_cpp");
    \\
    \\pub var interface: @import("Interface.zig") = undefined;
    \\
    \\{{#builtins}}
    \\pub const {{{name}}} = builtin.{{{name}}};
    \\{{/builtins}}
    \\{{#classes}}
    \\pub const {{{name}}} = builtin.{{{name}}};
    \\{{/classes}}
    \\{{#constants}}
    \\pub const {{{name}}} = {{{value}}};
    \\{{/constants}}
    \\{{#enums}}
    \\pub const {{{name}}} = builtin.{{{name}}};
    \\{{/enums}}
    \\{{#flags}}
    \\pub const {{{name}}} = builtin.{{{name}}};
    \\{{/flags}}
    \\{{#functions}}
    \\pub const {{{category}}} = @import("{{{category}}}.zig");
    \\{{/functions}}
    \\
    \\pub const builtin = struct {
    \\    {{#builtins}}
    \\    pub const {{{name}}} = @import("{{{name}}}.zig");
    \\    {{/builtins}}
    \\    {{#enums}}
    \\    pub const {{{name}}} = @import("{{{name}}}.zig");
    \\    {{/enums}}
    \\    {{#flags}}
    \\    pub const {{{name}}} = @import("{{{name}}}.zig");
    \\    {{/flags}}
    \\};
    \\
    \\pub const engine = struct {
    \\    {{#classes}}
    \\    pub const {{{name}}} = @import("{{{name}}}.zig");
    \\    {{/classes}}
    \\};
    \\
;

pub const interface =
    \\{{#interfaces}}
    \\{{{name}}}: Child(gd.c.{{{type}}}),
    \\{{/interfaces}}
    \\
    \\pub fn init(getProcAddress: Child(gd.c.GDExtensionInterfaceGetProcAddress)) @This() {
    \\    return .{
    \\        {{#interfaces}}
    \\        .{{{name}}} = @ptrCast(getProcAddress("{{{proc_name}}}")),
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
    \\/// {{doc}}
    \\pub const {{name}} = extern struct {
    \\    {{#members}}
    \\    /// {{{doc}}}
    \\    {{{name}}}: {{{type}}},
    \\
    \\    {{/members}}
    \\    {{#constants}}
    \\    /// {{{doc}}}
    \\    pub const {{{name}}}: {{{type}}} = {{{value}}};
    \\
    \\    {{/constants}}
    \\    {{#constructors}}
    \\    /// {{{doc}}}
    \\    {{>signature}}
    \\        var constructor = struct {
    \\            var method: gd.c.{{{type}}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{{type}}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrConstructor("todo", {{{offset}}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var out = std.mem.zeroes(@This());
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#args}}
    \\          @ptrCast(&{{{name}}}),
    \\          {{/args}}
    \\        };
    \\        constructor(@ptrCast(&out), @ptrCast(&args))
    \\        return out orelse error.UnexpectedNull;
    \\    }
    \\
    \\    {{/constructors}}
    \\    {{#methods}}
    \\    /// {{{doc}}}
    \\    {{>signature}}
    \\        var method = struct {
    \\            var method: gd.c.{{{type}}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{{type}}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrBuiltinMethod("{{../name}}", "{{{name}}}", {{{offset}}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var ret: {{{return_type}}} = undefined;
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#args}}
    \\          @ptrCast(&{{{name}}}),
    \\          {{/args}}
    \\        };
    \\        method(@ptrCast(self), @ptrCast(&args), @ptrCast(&ret), {{args.len}});
    \\        return ret;
    \\    }
    \\
    \\    {{/methods}}
    \\    {{#enums}}
    \\    {{>enum}}{{/enums}}
    \\};
    \\
    \\const std = @import("std");
    \\const gd = @import("godot");
    \\
;

pub const class =
    \\/// {{doc}}
    \\pub const {{name}} = struct {
    \\    {{#inherits}}
    \\    pub const Base = {{inherits}};
    \\
    \\    {{/inherits}}
    \\    {{#constants}}
    \\    /// {{{doc}}}
    \\    pub const {{{name}}}: i64 = {{{value}}};
    \\
    \\    {{/constants}}
    \\    {{#is_instantiable}}
    \\    pub fn init() {{{type}}} {
    \\
    \\    }
    \\
    \\    {{/is_instantiable}}
    // \\    {{#properties}}
    // \\    pub fn {{{getter}}}(self: *const @This()) {{{type}}} {
    // \\    }
    // \\
    // \\    {{#has_setter}}
    // \\    pub fn {{{setter}}}(self: *@This(), value: {{{type}}}) void {
    // \\    }
    // \\
    // \\    {{/has_setter}}
    // \\    {{/properties}}
    \\    {{#static_methods}}
    \\    /// {{doc}}
    \\    {{>signature}}
    \\    }
    \\
    \\    {{/static_methods}}
    \\    {{#methods}}
    \\    /// {{doc}}
    \\    {{>signature}}
    \\    }
    \\
    \\    {{/methods}}
    \\    {{#virtual_methods}}
    \\    /// {{doc}}
    \\    {{>signature}}
    \\    }
    \\
    \\    {{/virtual_methods}}
    \\    {{#enums}}
    \\    ///
    \\    {{>enum}}
    \\
    \\    {{/enums}}
    \\    {{#flags}}
    \\    ///
    \\    {{>flag}}
    \\
    \\    {{/flags}}
    \\    {{#is_singleton}}
    \\    var instance: ?@This() = undefined;
    \\
    \\    fn getSingleton() @This() {
    \\        if (instance == null) {
    \\            @panic("TODO: implement getSingleton");
    \\        }
    \\        return instance.?;
    \\    }
    \\    {{/is_singleton}}
    \\};
    \\
;

pub const enum_ =
    \\/// {{{doc}}}
    \\pub const {{name}} = enum(i32) {
    \\    {{#values}}
    \\    {{{name}}} = {{{value}}},
    \\    {{/values}}
    \\};
    \\
;

pub const flag =
    // The extraneous newlines are because of https://github.com/batiati/mustache-zig/issues/29
    \\/// {{doc}}
    \\pub const {{name}} = packed struct(i32) {
    \\    {{#values}}
    \\    {{{name}}}: u1 = {{value}},
    \\    {{/values}}
    \\
    \\    {{#consts}}
    \\    pub const {{{name}}}: @This() = @bitCast({{{value}}});
    \\    {{/consts}}
    \\};
    \\
;

pub const function =
    \\/// {{function.doc}}
    \\pub const {{function.category}} = struct {
    \\    {{#function.functions}}
    \\    /// {{{doc}}}
    \\    {{>signature}}
    \\        @panic("todo");
    \\    }
    \\    {{/function.functions}}
    \\};
    \\
;

pub const signature =
    \\pub fn {{{name}}}({{^is_static}}self: *{{#is_const}}const {{/is_const}}@This(){{#has_args}}, {{/has_args}}{{/is_static}}{{#args}}{{{name}}}: {{{type}}}{{^is_last}}, {{/is_last}}{{/args}}) {{{return_type}}} {
    \\
;
