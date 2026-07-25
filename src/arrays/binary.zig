const std = @import("std");

const varbin = @import("../layouts/varbin.zig");
const varbinview = @import("../layouts/varbinview.zig");
const types = @import("../types.zig");

pub const BinaryArray = varbin.VariableBinary(i32, types.BinaryType);
pub const LargeBinaryArray = varbin.VariableBinary(i64, types.BinaryType);
pub const BinaryViewArray = varbinview.VarBinView(types.BinaryType);
