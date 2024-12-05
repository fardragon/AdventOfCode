pub const input = @import("input.zig");
pub const grid = @import("grid.zig");
pub const parsing = @import("parsing.zig");
const std = @import("std");

pub fn Pair(comptime FirstType: type, comptime SecondType: type) type {
    return struct {
        first: FirstType,
        second: SecondType,
    };
}

pub const String = struct {
    str: []u8,
    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, str: []const u8) !Self {
        return Self{
            .str = try allocator.dupe(u8, str),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.str);
    }
};
