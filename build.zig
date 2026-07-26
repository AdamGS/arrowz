const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // This creates a module, which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Zig modules are the preferred way of making Zig code available to consumers.
    // addModule defines a module that we intend to make available for importing
    // to our consumers. We must give it a name because a Zig package can expose
    // multiple modules and consumers will need to be able to specify which
    // module they want to access.
    const arrowz_mod = b.addModule("arrowz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "arrowz",
        .root_module = arrowz_mod,
        .linkage = .static,
    });

    b.installArtifact(lib);

    // Creates an executable that will run `test` blocks from the provided module.
    // Here `mod` needs to define a target, which is why earlier we made sure to
    // set the releative field.
    const mod_tests = b.addTest(.{
        .root_module = arrowz_mod,
    });

    // A run step that will run the test executable.
    const run_mod_tests = b.addRunArtifact(mod_tests);

    // A top level step for running all tests. dependOn can be called multiple
    // times and since the two run steps do not depend on one another, this will
    // make the two of them run in parallel.

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Install docs into zig-out/docs");

    docs_step.dependOn(&install_docs.step);

    // Integration tests

    const nanoarrow_mod = setup_nanoarrow(b, target, optimize);

    const integration_test_mod = b.createModule(.{
        .root_source_file = b.path("test/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    integration_test_mod.addImport("arrowz", arrowz_mod);
    integration_test_mod.addImport("nanoarrow", nanoarrow_mod);

    const integration_tests = b.addTest(.{
        .root_module = integration_test_mod,
    });

    // A run step that will run the test executable.
    const integration_mod_tests = b.addRunArtifact(integration_tests);

    // A top level step for running all tests. dependOn can be called multiple
    // times and since the two run steps do not depend on one another, this will
    // make the two of them run in parallel.

    const integration_step = b.step("integration", "Run integration tests");
    integration_step.dependOn(&integration_mod_tests.step);

    // Just like flags, top level steps are also listed in the `--help` menu.
    //
    // The Zig build system is entirely implemented in userland, which means
    // that it cannot hook into private compiler APIs. All compilation work
    // orchestrated by the build system will result in other Zig compiler
    // subcommands being invoked with the right flags defined. You can observe
    // these invocations when one fails (or you pass a flag to increase
    // verbosity) to validate assumptions and diagnose problems.
    //
    // Lastly, the Zig build system is relatively simple and self-contained,
    // and reading its source code will allow you to master it.
}

// Setup the nanoarrow dependency
fn setup_nanoarrow(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const upstream = b.dependency("upstream", .{});

    const config = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("src/nanoarrow/nanoarrow_config.h.in") },
        .include_path = "nanoarrow/nanoarrow_config.h",
    }, .{
        .NANOARROW_VERSION_MAJOR = 0,
        .NANOARROW_VERSION_MINOR = 8,
        .NANOARROW_VERSION_PATCH = 0,
        .NANOARROW_VERSION = "0.8.0",
        .NANOARROW_NAMESPACE_DEFINE = "",
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("test/nanoarrow.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    mod.addConfigHeader(config);
    mod.addIncludePath(upstream.path("src"));
    mod.addIncludePath(b.path("test/include"));

    mod.addCSourceFiles(.{
        .root = upstream.path("src/nanoarrow/common"),
        .files = &.{ "array.c", "schema.c", "array_stream.c", "utils.c" },
    });
    mod.addCSourceFiles(.{
        .root = b.path("test/include"),
        .files = &.{"nanoarrow_zig.c"},
    });

    return mod;
}
