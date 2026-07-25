const std = @import("std");
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub const BitBuffer = struct {
    const Self = @This();

    bits: std.ArrayList(u64),
    len: usize,

    const ShiftInt = std.math.Log2Int(u64);

    pub fn init(values: []const bool, gpa: std.mem.Allocator) !Self {
        const capacity = (values.len / 64) + 1;
        const len = values.len;
        var bits = try std.ArrayList(u64).initCapacity(gpa, capacity);

        try bits.appendNTimes(gpa, 0, capacity);

        var b = Self{ .bits = bits, .len = len };

        for (values, 0..) |value, idx| {
            b.setWithValue(idx, value);
        }

        return b;
    }

    pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
        self.bits.deinit(gpa);
        self.* = undefined;
    }

    pub fn isValid(self: *const Self, idx: usize) bool {
        const byte_idx = idx / 64;
        const bit_idx = @as(ShiftInt, @truncate(idx % 64));
        const v = self.bits.items[byte_idx];
        return ((v >> bit_idx) & 1) != 0;
    }

    pub fn isNull(self: *const Self, idx: usize) bool {
        return !self.isValid(idx);
    }

    fn setWithValue(self: *Self, idx: usize, value: bool) void {
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

pub const BitBufferBuilder = struct {
    const Self = @This();

    length: usize,
    values: ?std.ArrayList(bool),

    pub const empty = Self{
        .length = 0,
        .values = null,
    };

    pub fn appendValue(self: *Self, gpa: std.mem.Allocator, value: bool) std.mem.Allocator.Error!void {
        if (self.values) |*values| {
            try values.append(gpa, value);
        } else if (!value) {
            self.values = try .initCapacity(gpa, self.length + 1);

            for (0..self.length) |_| {
                self.values.?.appendAssumeCapacity(true);
            }

            self.values.?.appendAssumeCapacity(false);
        }

        self.length += 1;
    }

    pub fn finish(self: *Self, gpa: std.mem.Allocator) !?BitBuffer {
        if (self.values) |*values| {
            const buffer = try BitBuffer.init(values.items, gpa);
            values.deinit(gpa);
            self.* = undefined;
            return buffer;
        } else {
            return null;
        }
    }

    pub fn appendNull(self: *Self, gpa: std.mem.Allocator) std.mem.Allocator.Error!void {
        if (self.values) |*values| {
            try values.append(gpa, false);
        } else {}
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

test "case0" {
    const array = [_]bool{ true, false, true };

    var b = try BitBuffer.init(&array, test_allocator);
    defer b.deinit(test_allocator);
    try expect(b.len == 3);
    try expect(b.isValid(0));
    try expect(b.isNull(1));
    try expect(b.isValid(2));
}

test "true builder" {
    var builder = BitBufferBuilder.empty;
    try builder.appendValue(test_allocator, true);
    try builder.appendValue(test_allocator, true);
    try builder.appendValue(test_allocator, true);

    try expect(builder.length == 3);

    const r = try builder.finish(test_allocator);

    try std.testing.expectEqual(r, null);
}

test "mixed builder" {
    var builder = BitBufferBuilder.empty;
    try builder.appendValue(test_allocator, true);
    try builder.appendValue(test_allocator, false);
    try builder.appendValue(test_allocator, true);

    try expect(builder.length == 3);

    var b = try builder.finish(test_allocator) orelse unreachable;
    defer b.deinit(test_allocator);

    try expect(b.len == 3);
    try expect(b.isValid(0));
    try expect(b.isNull(1));
    try expect(b.isValid(2));
}
