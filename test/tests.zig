const std = @import("std");
const arrowz = @import("arrowz");
const na = @import("nanoarrow").c;

test "nanoarrow initializes an int32 schema" {
    var schema: na.ArrowSchema = undefined;

    try std.testing.expectEqual(
        0,
        na.ArrowSchemaInitFromType(&schema, na.NANOARROW_TYPE_INT32),
    );
    defer schema.release.?(&schema);

    try std.testing.expectEqualStrings("i", std.mem.span(schema.format));
}

test "create array" {
    var array: na.ArrowArray = undefined;

    try std.testing.expectEqual(
        0,
        na.ArrowArrayInitFromType(&array, na.NANOARROW_TYPE_INT32),
    );
    defer array.release.?(&array);

    try std.testing.expectEqual(@as(i64, 0), array.length);
}

test "type equality" {
    const t1 = na.NANOARROW_TYPE_INT32;
    const t2 = na.NANOARROW_TYPE_INT32;
    const t3 = na.NANOARROW_TYPE_INT64;

    try std.testing.expectEqualStrings(std.mem.span(na.NanoarrowZigTypeString(t1)), std.mem.span(na.NanoarrowZigTypeString(t2)));
    try std.testing.expect(na.NanoarrowZigTypeString(t2) != na.NanoarrowZigTypeString(t3));
}
