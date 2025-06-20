//! This module uses Zig comptime reflection to inspect `gdextension_interface.zig` and generate a set of metadata about the GDExtension API.

const case = @import("case");
const godot = @import("godot");

/// todo:
/// 1. get the functions and structs defined, dealing with the optional and pointer dereferencing with std.meta.Child
/// 2. standardize naming; strip `GDExtension(s)` from the start of all type and parameter names
/// 3. categorize functions into their parent types - probably by looking at the first `Titlecase` word;
///    eg. `GDExtensionInterfaceClassdbRegisterExtensionClass3` becomes categorized under  `interface` and with method name `classdbRegisterExtensionClass3`
/// 4. support exceptions for all namings and categorizations through const StaticStringMaps
fn inspect() void {
    comptime {
        const decls = @typeInfo(godot).@"struct".decls;
    }
}
