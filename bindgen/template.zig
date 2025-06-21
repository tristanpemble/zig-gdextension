pub const builtin =
    \\/// {{builtin.doc}}
    \\pub const {{builtin.name}} = extern struct {
    \\    {{#builtin.members}}
    \\    /// {{member.doc}}
    \\    {{member.name}}: {{member.type}},
    \\    {{/builtin.members}}
    \\
    \\    {{#builtin.constants}}
    \\    /// {{constant.doc}}
    \\    pub const {{constant.name}}: {{constant.type}} = {{constant.value}};
    \\    {{/builtin.constants}}
    \\
    \\    {{#builtin.constructors}}
    \\    /// {{constructor.doc}}
    \\    pub fn {{constructor.name}}({{args}}) {{constructor.return_type}} {
    \\        var constructor = struct {
    \\            var method: gd.c.{{constructor.type}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{constructor.type}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrConstructor("todo", {{constructor.offset}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var out: {{builtin.name}} = std.mem.zeroes({{builtin.name}});
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#constructor.args}}
    \\          @ptrCast(&{{arg.name}})
    \\          {{/constructor.args}}
    \\        };
    \\        constructor(@ptrCast(&out), @ptrCast(&args))
    \\        return out orelse error.UnexpectedNull;
    \\    }
    \\    {{/builtin.constructors}}
    \\
    \\    {{#builtin.methods}}
    \\    /// {{method.doc}}
    \\    pub fn {{name}}(self: *{{#is_const}}const{{/is_const}} {{class}}, {{args}}) {{return_type}} {
    \\        var method = struct {
    \\            var method: gd.c.{{method.type}} = null;
    \\            pub fn get() std.meta.Child(gd.c.{{method.type}}) {
    \\                if (!method) {
    \\                    method = gd.c.variantGetPtrConstructor("todo", {{method.offset}});
    \\                }
    \\                return method.?;
    \\            }
    \\        }.get();
    \\        var out: {{builtin.name}} = std.mem.zeroes({{builtin.name}});
    \\        var args = [_]gd.c.GDExtensionConstTypePtr {
    \\          {{#method.args}}
    \\          @ptrCast(&{{arg.name}})
    \\          {{/method.args}}
    \\        };
    \\        method(@ptrCast(&out), @ptrCast(&args))
    \\        return out orelse error.UnexpectedNull;
    \\    }
    \\    {{/builtin.methods}}
    \\
    \\    {{#builtin.enums}}
    \\    /// {{enum.doc}}
    \\    pub const {{enum.name}} = enum(i32) {
    \\        {{#enum.values}}
    \\        /// {{value.doc}}
    \\        {{value.name}} = {{value.value}},
    \\        {{/enum.values}}
    \\    };
    \\    {{/builtin.enums}}
    \\};
    \\
    \\ const std = @import("std");
    \\ const gd = @import("godot");
;
