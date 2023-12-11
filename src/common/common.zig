pub const input = @import("input.zig");

pub fn Pair(comptime FirstType: type, comptime SecondType: type) type {
    return struct {
        first: FirstType,
        second: SecondType,
    };
}
