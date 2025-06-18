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

pub fn run(self: *Generator, allocator: Allocator, writer: anytype) !void {
    _ = self;
    _ = allocator;
    _ = writer;

    // var class_iter = self.api.classes.iterator();
    // while (class_iter.next()) |entry| {
    //     switch (entry.value_ptr.*) {
    //         inline else => |class| try mustache.renderText(allocator, templates.class, class, writer),
    //     }
    // }
}

const std = @import("std");
const Allocator = std.mem.Allocator;

const mustache = @import("mustache");

const Api = @import("Api.zig");
const templates = @import("templates.zig");
