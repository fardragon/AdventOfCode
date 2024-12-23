pub const input = @import("input.zig");
pub const grid = @import("grid.zig");
pub const parsing = @import("parsing.zig");
const custom_hash_set = @import("hash_set.zig");
pub const AutoHashSet = custom_hash_set.AutoHashSet;
pub const StringHashSet = custom_hash_set.StringHashSet;
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

    pub fn deinit(self: Self) void {
        self.allocator.free(self.str);
    }
};

pub const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn toOffset(self: Direction) struct { isize, isize } {
        return switch (self) {
            Direction.Left => .{ -1, 0 },
            Direction.Right => .{ 1, 0 },
            Direction.Up => .{ 0, -1 },
            Direction.Down => .{ 0, 1 },
        };
    }

    pub fn rotateCW(self: Direction) Direction {
        return switch (self) {
            .Up => .Right,
            .Right => .Down,
            .Down => .Left,
            .Left => .Up,
        };
    }

    pub fn rotateCCW(self: Direction) Direction {
        return switch (self) {
            .Up => .Left,
            .Left => .Down,
            .Down => .Right,
            .Right => .Up,
        };
    }

    pub fn flip(self: Direction) Direction {
        return self.rotateCW().rotateCW();
    }

    pub fn all() [4]Direction {
        return .{
            Direction.Up,
            Direction.Down,
            Direction.Left,
            Direction.Right,
        };
    }
};
