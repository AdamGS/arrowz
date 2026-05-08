//! Variable-size binary layout
//!
//! Spec: https://arrow.apache.org/docs/format/Columnar.html#variable-size-binary-layout

const std = @import("std");
const testing = std.testing;

const BitBuffer = @import("bit.zig").BitBuffer;

pub fn VariableBinary(comptime T: type) type {
    return struct {
        const Self = @This();
        const alignment = std.mem.Alignment.@"64";

        offsets: std.array_list.Aligned(T, alignment),
        data: std.array_list.Aligned(
            u8,
            alignment,
        ),
        length: usize,
        nulls: ?BitBuffer,

        pub const empty: Self = .{ .offsets = .empty, .data = .empty, .length = 0, .nulls = null };

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            self.data.deinit(gpa);
            self.offsets.deinit(gpa);

            if (self.nulls) |*nulls| {
                nulls.deinit(gpa);
            }

            self.* = undefined;
        }

        pub fn isValid(self: Self, idx: usize) bool {
            if (self.nulls) |nulls| {
                return nulls.isValid(idx);
            } else {
                return true;
            }
        }

        pub fn isNull(self: Self, idx: usize) bool {
            return !self.isValid(idx);
        }

        pub fn len(self: *const Self) usize {
            return self.length;
        }

        pub fn value(self: *const Self, idx: usize) []const u8 {
            const start: usize = @intCast(self.offsets.items[idx]);
            const end: usize = @intCast(self.offsets.items[idx + 1]);
            return self.data.items[start..end];
        }
    };
}

test "basic get value" {
    const data align(64) = [_]u8{ 65, 65, 65, 66, 66, 66 };
    const offsets align(64) = [_]i32{ 0, 3, 3, 6 };

    const arr = VariableBinary(i32){
        .length = 3,
        .data = .fromOwnedSlice(@constCast(&data)),
        .offsets = .fromOwnedSlice(@constCast(&offsets)),
        .nulls = null,
    };

    try testing.expect(std.mem.eql(u8, arr.value(0), "AAA"));
    try testing.expectEqual(arr.value(1).len, 0);
    try testing.expect(std.mem.eql(u8, arr.value(2), "BBB"));
}
