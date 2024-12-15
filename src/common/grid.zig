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

        pub fn mapToXY(self: Self, index: isize) !struct { isize, isize } {
            if (index < 0 or index >= self.len()) return error.OutOfBounds;
            return .{
                @rem(index, @as(isize, @intCast(self.width))),
                @divFloor(index, @as(isize, @intCast(self.width))),
            };
        }

        pub fn mapToIndex(self: Self, x: isize, y: isize) !isize {
            if (x < 0 or x >= self.width) return error.OutOfBounds;
            if (y < 0 or y >= self.height) return error.OutOfBounds;

            return y * @as(isize, @intCast(self.width)) + x;
        }

        pub fn get(self: Self, x: isize, y: isize) ?T {
            if (x < 0 or x >= self.width) return null;
            if (y < 0 or y >= self.height) return null;

            return self.data.items[@as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x))];
        }

        pub fn set(self: *Self, x: isize, y: isize, value: T) !void {
            if (x < 0 or x >= self.width) return error.OutOfBounds;
            if (y < 0 or y >= self.height) return error.OutOfBounds;

            self.data.items[@as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x))] = value;
        }

        pub fn len(self: Self) usize {
            return self.height * self.width;
        }

        pub fn clone(self: Self) !Self {
            return Self{
                .data = try self.data.clone(),
                .width = self.width,
                .height = self.height,
            };
        }
    };
}
