//! Shared test runner because why not

const builtin = @import("builtin");
const std = @import("std");

const TestFn = std.builtin.TestFn;

pub fn main(_: std.process.Init) !void {
    const tests = builtin.test_functions;

    for (tests) |test_fn| {
        const names = if (std.mem.indexOf(u8, test_fn.name, ".test.")) |idx|
            .{ test_fn.name[0..idx], test_fn.name[idx + 6 ..] }
        else if (std.mem.indexOf(u8, test_fn.name, ".decltest.")) |idx|
            .{ test_fn.name[0..idx], test_fn.name[idx + 10 ..] }
        else
            .{ "", test_fn.name };
        const namespace = names[0];
        const name = names[1];

        const result = test_fn.func();

        if (result) {
            if (namespace.len != 0) {
                std.debug.print("Test Passed: {s} - {s}\n", .{ namespace, name });
            }
        } else |err| {
            std.debug.print("Test Failed: {s} - {s}: {s}", .{ namespace, name, @errorName(err) });
        }

        // Run tests:
        // report.test_results[idx] = try t.run(arena, io, environ, &test_timer, no_stack_trace);
    }
}
