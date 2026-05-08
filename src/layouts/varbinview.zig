const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const BitBuffer = @import("bit.zig").BitBuffer;

const Inline = extern struct {
    const Self = @This();

    len: u32,
    content: [12]u8,

    pub fn data(self: *const Self) []const u8 {
        const length: usize = @intCast(self.len);
        std.debug.assert(length <= self.content.len);

        return self.content[0..length];
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

    pub fn as_remote(self: Self) ?Remote {
        return if (self.length() > 12)
            self.remote
        else
            null;
    }

    pub fn as_inline(self: Self) ?Inline {
        return if (self.length() <= 12)
            self.inline_
        else
            null;
    }
};

comptime {
    if (@sizeOf(Inline) != @sizeOf(u128)) {
        @compileError("Inline type must by 16 bytes, got " ++ @sizeOf(Inline));
    }

    if (@sizeOf(Remote) != @sizeOf(u128)) {
        @compileError("Remote type must by 16 bytes, got " ++ @sizeOf(Remote));
    }

    if (@sizeOf(View) != @sizeOf(u128)) {
        @compileError("View type must by 16 bytes, got " ++ @sizeOf(Remote));
    }

    if (@sizeOf(Inline) != @sizeOf(Remote)) {
        @compileError("Remote and Inline must have the same size");
    }
}

pub fn VarBinView() type {
    return struct {
        const Self = @This();
        const alignment = std.mem.Alignment.@"64";

        views: std.array_list.Aligned(View, alignment),
    };
}

test "inline_data" {
    const i = Inline{
        .len = 12,
        .content = "AAAAAAAAAAAA".*,
    };

    const data = i.data();
    try testing.expectEqual(@as(usize, 12), data.len);
    try testing.expect(mem.eql(u8, data, "AAAAAAAAAAAA"));
}
