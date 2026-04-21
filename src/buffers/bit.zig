const std = @import("std");
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const BitBuffer = struct {
    bits: std.ArrayList(u64),
    len: usize,

    const ShiftInt = std.math.Log2Int(u64);

    pub fn init(values: []const bool, gpa: std.mem.Allocator) !BitBuffer {
        const capacity = (values.len / 64) + 1;
        const len = values.len;
        var bits = try std.ArrayList(u64).initCapacity(gpa, capacity);

        try bits.appendNTimes(gpa, 0, capacity);

        var b = BitBuffer{ .bits = bits, .len = len };

        for (values, 0..) |value, idx| {
            b.setWithValue(idx, value);
        }

        return b;
    }

    pub fn deinit(self: *BitBuffer, gpa: std.mem.Allocator) void {
        self.bits.deinit(gpa);
        self.* = undefined;
    }

    pub fn isValid(self: *BitBuffer, idx: usize) bool {
        const byte_idx = idx / 64;
        const bit_idx = @as(ShiftInt, @truncate(idx % 64));
        const v = self.bits.items[byte_idx];
        return ((v >> bit_idx) & 1) != 0;
    }

    pub fn setWithValue(self: *BitBuffer, idx: usize, value: bool) void {
        const byte_idx = idx / 64;
        const bit_idx: u6 = @truncate(idx % 64);
        const mask: u64 = @as(u64, 1) << bit_idx;
        if (value) {
            self.bits.items[byte_idx] |= mask;
        } else {
            self.bits.items[byte_idx] &= ~mask;
        }
    }
};

test "init from values" {
    const array = [_]bool{ false, true, false, true, true };

    var b = try BitBuffer.init(&array, test_allocator);
    defer b.deinit(test_allocator);

    try expect(!b.isValid(0));
    try expect(b.isValid(1));
    try expect(!b.isValid(2));
    try expect(b.isValid(3));
    try expect(b.isValid(4));
    try expect(b.len == 5);
}

test "is_valid" {
    const array = [_]bool{ false, false, false };

    var b = try BitBuffer.init(&array, test_allocator);
    defer b.deinit(test_allocator);
    try expect(b.len == 3);
    try expect(!b.isValid(0));
    try expect(!b.isValid(1));
    try expect(!b.isValid(2));

    b.setWithValue(1, true);
    try expect(b.isValid(1));
}

test "set_bit" {
    const array = [_]bool{ false, false, false };

    var b = try BitBuffer.init(&array, test_allocator);
    defer b.deinit(test_allocator);

    b.setWithValue(1, true);

    try expect(!b.isValid(0));
    try expect(b.isValid(1));
    try expect(!b.isValid(2));
}
