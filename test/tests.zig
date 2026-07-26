const std = @import("std");
const arrowz = @import("arrowz");
const na = @cImport({
    @cInclude("nanoarrow_zig.h");
});

test "nanoarrow initializes an int32 schema" {
    var schema: na.ArrowSchema = undefined;

    try std.testing.expectEqual(
        na.NANOARROW_OK,
        na.ArrowSchemaInitFromType(&schema, na.NANOARROW_TYPE_INT32),
    );
    defer schema.release.?(&schema);

    try std.testing.expectEqualStrings("i", std.mem.span(schema.format));
}

test "create array" {
    var array: na.ArrowArray = undefined;

    try std.testing.expectEqual(
        na.NANOARROW_OK,
        na.ArrowArrayInitFromType(&array, na.NANOARROW_TYPE_INT32),
    );
    defer array.release.?(&array);

    try std.testing.expectEqual(@as(i64, 0), array.length);
}
