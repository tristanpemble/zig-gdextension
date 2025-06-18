pub const module =
    \\{{#exports}}
    \\pub const {{ident}} = @import({{path}});
    \\{{/exports}}
;

pub const class =
    \\{{#imports}}
    \\const {{ident}} = @import({{path}});
    \\{{/imports}}
    \\
    \\{{#constants}}
    \\{{/constants}}
    \\
    \\{{#fields}}
    \\{{/fields}}
    \\
    \\{{#methods}}
    \\{{/methods}}
;

pub const @"enum" =
    \\
;

pub const flag =
    \\
;
