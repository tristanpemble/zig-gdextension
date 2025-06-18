//! This module implements the logic for generating Zig code using:
//!
//! - The API definitions defined in `./Api.zig`
//! - The templates defined in `./templates.zig`
//!

const Generator = @This();

api: Api,

pub fn init(api: Api) !Generator {
    return Generator{ .api = api };
}

pub fn run(self: Generator) void {
    _ = self;
}

const std = @import("std");
const Api = @import("Api.zig");
