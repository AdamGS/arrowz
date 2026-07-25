//! Variable-size binary layout
//!
//! Spec: https://arrow.apache.org/docs/format/Columnar.html#variable-size-binary-layout

const std = @import("std");
const testing = std.testing;

const BitBuffer = @import("bit.zig").BitBuffer;
const types = @import("../types.zig");
const DataType = types.DataType;

pub fn VariableBinary(comptime T: type, comptime V: type) type {
    comptime switch (T) {
        i32, i64 => {},
        else => @compileError("unsupported Varbin array offset type: " ++ @typeName(T)),
    };

    comptime switch (V) {
        types.StringType, types.BinaryType => {},
        else => @compileError("unsupported Varbin array value type: " ++ @typeName(V)),
    };

    return struct {
        const Self = @This();
        const alignment = std.mem.Alignment.@"64";

        offsets: std.array_list.Aligned(T, alignment),
        data: std.array_list.Aligned(
            u8,
            alignment,
        ),
        length: usize,

        nulls: ?BitBuffer = null,

        pub const empty: Self = .{
            .offsets = .empty,
            .data = .empty,
            .length = 0,
        };

        pub fn initCapacity(gpa: std.mem.Allocator, num: usize) !Self {
            return Self{
                .data = .empty,
                .offsets = try .initCapacity(gpa, num + 1),
                .length = 0,
            };
        }

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
            const start = @abs(self.offsets.items[idx]);
            const end = @abs(self.offsets.items[idx + 1]);
            return self.data.items[start..end];
        }

        pub fn data_type(_: Self) DataType {
            return switch (V) {
                types.BinaryType => {
                    return switch (T) {
                        i32 => DataType.binary,
                        i64 => DataType.large_binary,
                        else => @compileError(
                            "unsupported VarBin offset element type: " ++ @typeName(T),
                        ),
                    };
                },
                types.StringType => {
                    return switch (T) {
                        i32 => DataType.utf8,
                        i64 => DataType.large_utf8,
                        else => @compileError(
                            "unsupported VarBin offset element type: " ++ @typeName(T),
                        ),
                    };
                },
                else => @compileError(
                    "unsupported VarBin array element type: " ++ @typeName(V),
                ),
            };
        }
    };
}

const ValueTypes = [_]type{ types.BinaryType, types.StringType };

test "init test" {
    const allocator = testing.allocator;

    inline for (ValueTypes) |V| {
        var arr = try VariableBinary(i32, V).initCapacity(allocator, 3);
        defer arr.deinit(allocator);

        try testing.expect(arr.length == 0);
    }
}

test "basic get value" {
    const allocator = testing.allocator;
    const alignment = std.mem.Alignment.@"64";

    const data = try allocator.alignedAlloc(u8, alignment, 6);
    errdefer allocator.free(data);
    @memcpy(data, "AAABBB");

    const offsets = try allocator.alignedAlloc(i32, alignment, 4);
    errdefer allocator.free(offsets);
    @memcpy(offsets, &[_]i32{ 0, 3, 3, 6 });

    var arr = VariableBinary(i32, types.StringType){
        .length = 3,
        .data = .fromOwnedSlice(data),
        .offsets = .fromOwnedSlice(offsets),
    };
    defer arr.deinit(allocator);

    try testing.expectEqualStrings(arr.value(0), "AAA");
    try testing.expectEqual(@as(usize, 0), arr.value(1).len);
    try testing.expectEqualStrings(arr.value(2), "BBB");
}

test "binary data type" {
    const bin = VariableBinary(i32, types.BinaryType).empty;
    try testing.expectEqual(DataType.binary, bin.data_type());

    const large_bin = VariableBinary(i64, types.BinaryType).empty;
    try testing.expectEqual(DataType.large_binary, large_bin.data_type());

    const str = VariableBinary(i32, types.StringType).empty;
    try testing.expectEqual(DataType.utf8, str.data_type());

    const large_str = VariableBinary(i64, types.StringType).empty;
    try testing.expectEqual(DataType.large_utf8, large_str.data_type());
}
