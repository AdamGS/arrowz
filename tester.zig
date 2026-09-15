//! Shared test runner because why not

const builtin = @import("builtin");
const std = @import("std");

const TestFn = std.builtin.TestFn;

pub fn main(init: std.process.Init) !void {
    var gpa: std.heap.DebugAllocator(.{}) = .{};
    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = init.minimal.environ });
    defer threaded.deinit();

    const tests = builtin.test_functions;

    var buffer: [4096]u8 = undefined;
    // var file = std.Io.File.stdout();

    var reporter = try Reporter.init(&threaded, std.Io.File.stdout(), &buffer);

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
                try reporter.reportSuccess(.{
                    .namespace = namespace,
                    .name = name,
                });
            }
        } else |err| {
            std.debug.print("Test Failed: {s} - {s}: {s}", .{ namespace, name, @errorName(err) });
        }

        // Run tests:
        // report.test_results[idx] = try t.run(arena, io, environ, &test_timer, no_stack_trace);
    }
}

const TestResult = struct {
    namespace: []const u8,
    name: []const u8,
};

const Reporter = struct {
    const Self = @This();

    writer: std.Io.File.Writer,
    mode: std.Io.Terminal.Mode,

    fn init(
        io: *std.Io.Threaded,
        file: std.Io.File,
        buffer: []u8,
    ) !Self {
        const NO_COLOR = io.environ.exist.NO_COLOR;
        const CLICOLOR_FORCE = io.environ.exist.CLICOLOR_FORCE;

        const mode = try std.Io.Terminal.Mode.detect(io.io(), file, NO_COLOR, CLICOLOR_FORCE);
        return .{
            .writer = file.writer(io.io(), buffer),
            .mode = mode,
        };
    }

    fn reportSuccess(self: *Self, test_result: TestResult) !void {
        const t = std.Io.Terminal{
            .writer = &self.writer.interface,
            .mode = self.mode,
        };
        try t.setColor(.green);

        try self.writer.interface.print("Test Passed: {s} - {s}\n", .{ test_result.namespace, test_result.name });
        try self.writer.interface.flush();

        try t.setColor(.reset);
    }
};
