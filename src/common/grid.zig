const std = @import("std");

pub fn Grid(comptime T: type) type {
    return struct {
        data: std.ArrayList(T),
        width: usize,
        height: usize,

        pub const Container = std.ArrayList(T);
        const Self: type = @This();

        pub fn mapToX(self: Self, index: isize) !isize {
            if (index < 0 or index >= self.len()) return error.OutOfBounds;
            return @rem(index, @as(isize, @intCast(self.width)));
        }

        pub fn mapToY(self: Self, index: isize) !isize {
            if (index < 0 or index >= self.len()) return error.OutOfBounds;
            return @divFloor(index, @as(isize, @intCast(self.width)));
        }

        pub fn get(self: Self, x: isize, y: isize) ?T {
            if (x < 0 or x >= self.width) return null;
            if (y < 0 or y >= self.height) return null;

            return self.data.items[@as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x))];
        }

        pub fn len(self: Self) usize {
            return self.height * self.width;
        }
    };
}
