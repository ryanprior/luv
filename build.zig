const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lua_dep = b.dependency("lua", .{
        .target = target,
        .release = optimize != .Debug,
    });
    const lua_lib = lua_dep.artifact(if (target.result.os.tag == .windows)
        "lua54"
    else
        "lua");

    const libuv_dep = b.dependency("libuv", .{
        .target = target,
        .optimize = optimize,
    });
    const libuv_lib = libuv_dep.artifact("uv");

    const libluv = b.addLibrary(.{
        .name = "luv",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    libluv.root_module.addCSourceFile(.{
        .file = b.path("src/luv.c"),
        .flags = &.{},
    });
    libluv.root_module.linkLibrary(lua_lib);
    libluv.root_module.linkLibrary(libuv_lib);

    b.installArtifact(libluv);

    const luv_tests = b.addExecutable(.{
        .name = "luv-tests",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    luv_tests.root_module.addCSourceFile(.{
        .file = b.path("src/test.c"),
        .flags = &.{},
    });
    luv_tests.root_module.addIncludePath(b.path("src"));
    luv_tests.root_module.linkLibrary(libluv);
    luv_tests.root_module.linkLibrary(lua_lib);
    luv_tests.root_module.linkLibrary(libuv_lib);

    const run_luv_tests = b.addRunArtifact(luv_tests);
    run_luv_tests.addArg("tests/manual-test-external-loop.lua");

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_luv_tests.step);
}
