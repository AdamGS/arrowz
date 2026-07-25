const std = @import("std");

const varbin = @import("../layouts/varbin.zig");
const varbinview = @import("../layouts/varbinview.zig");
const types = @import("../types.zig");

pub const Utf8Array = varbin.VariableBinary(i32, types.StringType);
pub const LargeUtf8Array = varbin.VariableBinary(i64, types.StringType);
pub const Utf8ViewArray = varbinview.VarBinView(types.StringType);
