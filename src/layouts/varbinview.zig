const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const BitBuffer = @import("bit.zig").BitBuffer;
const types = @import("../types.zig");
const DataType = types.DataType;

const Inline = extern struct {
    const Self = @This();

    len: u32,
    content: [12]u8,

    pub fn data(self: *const Self) []const u8 {
        return self.content[0..self.len];
    }
};

const Remote = extern struct {
    const Self = @This();

    len: u32,
    prefix: [4]u8,
    buf_idx: u32,
    offset: u32,
};

const View = extern union {
    const Self = @This();

    inline_: Inline,
    remote: Remote,

    pub fn length(self: Self) usize {
        return @intCast(self.inline_.len);
    }

    pub fn is_inline(self: Self) bool {
        return self.length() <= 12;
    }

    pub fn as_remote(self: Self) ?Remote {
        return if (!self.is_inline())
            self.remote
        else
            null;
    }

    pub fn as_inline(self: Self) ?Inline {
        return if (self.is_inline())
            self.inline_
        else
            null;
    }
};

comptime {
    if (@sizeOf(Inline) != @sizeOf(Remote)) {
        @compileError("Remote and Inline must have the same size");
    }

    if (@sizeOf(Inline) != @sizeOf(u128)) {
        @compileError("Inline type must by 16 bytes, got " ++ @sizeOf(Inline));
    }

    if (@sizeOf(Remote) != @sizeOf(u128)) {
        @compileError("Remote type must by 16 bytes, got " ++ @sizeOf(Remote));
    }

    if (@sizeOf(View) != @sizeOf(u128)) {
        @compileError("View type must by 16 bytes, got " ++ @sizeOf(Remote));
    }
}

pub fn VarBinView(comptime V: type) type {
    comptime switch (V) {
        types.StringType, types.BinaryType => {},
        else => @compileError("unsupported VarbinView array value type: " ++ @typeName(V)),
    };

    return struct {
        const Self = @This();
        const alignment = std.mem.Alignment.@"64";

        views: std.array_list.Aligned(View, alignment),
        data: std.ArrayList(std.array_list.Aligned(u8, alignment)),
        nulls: ?BitBuffer = null,

        pub const empty: Self = .{
            .views = .empty,
            .data = .empty,
        };

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
            return self.views.items.len;
        }

        pub fn value(self: *const Self, idx: usize) []const u8 {
            const view = self.views.items[idx];
            if (view.as_inline()) |inline_| {
                return inline_.data();
            } else if (view.as_remote()) |remote| {
                const length = remote.len;
                const offset = remote.offset;

                std.debug.assert(self.data.items.len > remote.buf_idx);
                const buff = self.data.items[remote.buf_idx];

                std.debug.assert(buff.items.len >= offset + length);
                return buff.items[offset .. offset + length];
            } else {
                unreachable;
            }
        }

        pub fn data_type(_: Self) DataType {
            return comptime switch (V) {
                types.BinaryType => DataType.binary_view,
                types.StringType => DataType.utf8view,
                else => @compileError("unsupported VarbinView array value type: " ++ @typeName(V)),
            };
        }
    };
}

test "inlined data" {
    const i = Inline{
        .len = 12,
        .content = "AAAAAAAAAAAA".*,
    };

    const data = i.data();
    try testing.expectEqual(12, data.len);
    try testing.expectEqualStrings(data, "AAAAAAAAAAAA");
}

test "data type" {
    try testing.expectEqual(VarBinView(types.BinaryType).empty.data_type(), DataType.binary_view);
    try testing.expectEqual(VarBinView(types.StringType).empty.data_type(), DataType.utf8view);
}
