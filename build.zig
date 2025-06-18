const std = @import("std");

const Build = std.Build;
const Dependency = Build.Dependency;
const Module = Build.Module;
const Optimize = std.builtin.OptimizeMode;
const Step = Build.Step;
const Target = Build.ResolvedTarget;

const DepTarget = struct { dep: *Dependency, mod: *Module };
const ExeTarget = struct { cmd: *Step.Run, exe: *Step.Compile, mod: *Module };
const LibTarget = struct { lib: *Step.Compile, mod: *Module };
const TestTarget = struct { cmd: *Step.Run, tests: *Step.Compile };

pub fn build(b: *Build) void {
    // Config
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Targets
    const bindgen = buildBindgen(b, target, optimize);
    const godot = buildGodot(b, target, optimize);
    const lib = buildLib(b, target, optimize);
    const mustache = buildMustache(b, target, optimize);
    const tests = buildTests(b, lib.mod);

    // Dependencies
    bindgen.mod.addImport("godot", godot.mod);
    bindgen.mod.addImport("mustache", mustache.mod);
    lib.mod.addImport("godot", godot.mod);

    bindgen.cmd.setCwd(godot.dep.path("gdextension"));

    // Steps
    b.step("bindgen", "Generate bindings").dependOn(&bindgen.cmd.step);
    b.step("test", "Run tests").dependOn(&tests.cmd.step);
}

// Library
pub fn buildLib(b: *Build, target: Target, optimize: Optimize) LibTarget {
    const mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "gdextz",
        .root_module = mod,
    });

    b.installArtifact(lib);

    return .{ .lib = lib, .mod = mod };
}

// Bindgen
pub fn buildBindgen(b: *Build, target: Target, optimize: Optimize) ExeTarget {
    const mod = b.addModule("bindgen", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/bindgen/main.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "bindgen",
        .root_module = mod,
    });

    const cmd = b.addRunArtifact(exe);
    cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        cmd.addArgs(args);
    }

    return .{ .cmd = cmd, .exe = exe, .mod = mod };
}

// Godot
pub fn buildGodot(b: *Build, target: Target, optimize: Optimize) DepTarget {
    const dep = b.dependency("godot_cpp", .{});

    const translation = b.addTranslateC(.{
        .link_libc = true,
        .target = target,
        .optimize = optimize,
        .root_source_file = dep.builder.path("gdextension/gdextension_interface.h"),
    });

    const mod = b.createModule(.{
        .root_source_file = translation.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    return .{ .dep = dep, .mod = mod };
}

// Mustache
pub fn buildMustache(b: *Build, target: Target, optimize: Optimize) DepTarget {
    const dep = b.dependency("mustache", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = dep.module("mustache");

    return .{ .dep = dep, .mod = mod };
}

// Tests
pub fn buildTests(b: *Build, mod: *Module) TestTarget {
    const tests = b.addTest(.{
        .root_module = mod,
    });

    const cmd = b.addRunArtifact(tests);

    return .{ .cmd = cmd, .tests = tests };
}
