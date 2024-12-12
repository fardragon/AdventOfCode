const std = @import("std");

pub fn AutoHashSet(comptime K: type) type {
    return struct {
        const Self = @This();
        const InternalType = std.AutoHashMap(K, void);

        internal: InternalType,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .internal = InternalType.init(allocator),
            };
        }

        pub fn contains(self: Self, key: K) bool {
            return self.internal.contains(key);
        }

        pub fn put(self: *Self, key: K) std.mem.Allocator.Error!void {
            return self.internal.put(key, {});
        }

        pub fn deinit(self: *Self) void {
            return self.internal.deinit();
        }

        pub fn count(self: Self) InternalType.Size {
            return self.internal.count();
        }

        pub fn iterator(self: Self) InternalType.KeyIterator {
            return self.internal.keyIterator();
        }

        pub fn remove(self: *Self, key: K) bool {
            return self.internal.remove(key);
        }

        pub fn merge_from(self: *Self, other: Self) std.mem.Allocator.Error!void {
            var it = other.iterator();

            while (it.next()) |val| {
                try self.put(val.*);
            }
        }
    };
}
