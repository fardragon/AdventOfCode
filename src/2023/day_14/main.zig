const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Platform = struct {
    map: std.ArrayList(u8),
    width: usize,
    height: usize,

    fn mapToX(self: Platform, index: usize) usize {
        return index % self.width;
    }

    fn mapToY(self: Platform, index: usize) usize {
        return index / self.width;
    }

    fn mapToIndex(self: Platform, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn deinit(self: *Platform, allocator: std.mem.Allocator) void {
        self.map.deinit(allocator);
    }

    fn tiltNorth(self: *Platform) void {
        for (0..self.width) |column| {
            for (1..self.height) |row| {
                const ix = self.mapToIndex(column, row);
                if (self.map.items[ix] != 'O') continue;

                var free_spaces_up: u8 = 0;

                var check_row = row;
                while (check_row > 0) {
                    if (self.map.items[self.mapToIndex(column, check_row - 1)] != '.') break;

                    free_spaces_up += 1;
                    check_row -= 1;
                }

                if (free_spaces_up > 0) {
                    self.map.items[self.mapToIndex(column, row - free_spaces_up)] = 'O';
                    self.map.items[ix] = '.';
                }
            }
        }
    }

    fn rotateCW(self: *Platform, allocator: std.mem.Allocator) !void {
        var new_map = try self.map.clone(allocator);
        errdefer new_map.deinit();
        for (0..self.height) |i| {
            for (0..self.width) |j| {
                const new_i = j;
                const new_j = self.height - 1 - i;

                const new_ix = new_i * self.width + new_j;
                new_map.items[new_ix] = self.map.items[i * self.width + j];
            }
        }

        self.map.deinit(allocator);
        self.map = new_map;

        const old_height = self.height;
        self.height = self.width;
        self.width = old_height;
    }

    fn cycle(self: *Platform, allocator: std.mem.Allocator) !void {
        inline for (0..4) |_| {
            self.tiltNorth();
            try self.rotateCW(allocator);
        }
    }

    fn debugPrint(self: Platform) void {
        for (0..self.height) |y| {
            const row_start = self.mapToIndex(0, y);
            const row_end = self.mapToIndex(self.width, y);

            std.debug.print("{s}\n", .{self.map.items[row_start..row_end]});
        }
    }

    fn calculateLoad(self: Platform) u64 {
        var load: u64 = 0;

        for (self.map.items, 0..) |item, ix| {
            if (item == 'O') {
                const row = self.mapToY(ix);
                load += (self.height - row);
            }
        }

        return load;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Platform {
    var result = Platform{
        .map = std.ArrayList(u8).empty,
        .width = input[0].len,
        .height = input.len,
    };

    errdefer result.deinit(allocator);

    for (input) |line| {
        try result.map.appendSlice(allocator, line);
    }

    return result;
}

const Cache = struct {
    const CacheKey = struct { pattern: []const u8 };

    const CacheKeyContext = struct {
        pub fn hash(_: CacheKeyContext, key: CacheKey) u64 {
            var h = std.hash.Wyhash.init(0);
            h.update(key.pattern);
            return h.final();
        }

        pub fn eql(_: CacheKeyContext, a: CacheKey, b: CacheKey) bool {
            return std.mem.eql(u8, a.pattern, b.pattern);
        }
    };

    map: std.HashMap(CacheKey, u64, CacheKeyContext, std.hash_map.default_max_load_percentage),
    allocator: std.mem.Allocator,

    const Self = @This();
    fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .map = std.HashMap(CacheKey, u64, CacheKeyContext, std.hash_map.default_max_load_percentage).init(allocator),
            .allocator = allocator,
        };
    }

    fn put(self: *Self, pattern: []const u8, value: u64) !void {
        const entry_pattern = try self.allocator.dupe(u8, pattern);

        const key = Self.CacheKey{
            .pattern = entry_pattern,
        };

        try self.map.put(key, value);
    }

    fn get(self: *const Self, pattern: []const u8) ?u64 {
        const key = Self.CacheKey{
            .pattern = pattern,
        };

        return self.map.get(key);
    }

    fn deinit(self: *Self) void {
        var keys_it = self.map.keyIterator();
        while (keys_it.next()) |key| {
            self.allocator.free(key.*.pattern);
        }
        self.map.deinit();
    }
};

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var platform = try parseInput(allocator, input);
    defer platform.deinit(allocator);

    platform.tiltNorth();

    return platform.calculateLoad();
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var platform = try parseInput(allocator, input);
    defer platform.deinit(allocator);

    var cache = Cache.init(allocator);
    defer cache.deinit();

    var cycles: u64 = 0;
    var period_len: ?u64 = null;

    while (cycles < 10_000) : (cycles += 1) {
        if (cache.get(platform.map.items)) |cycle_start| {
            period_len = cycles - cycle_start;
            break;
        } else {
            try cache.put(platform.map.items, cycles);
        }

        try platform.cycle(allocator);
    }

    if (period_len) |period| {
        const remaining_cycles = (1_000_000_000 - cycles) % period;
        for (0..remaining_cycles) |_| {
            try platform.cycle(allocator);
        }
    } else {
        unreachable;
    }

    return platform.calculateLoad();
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    var allocator = gpa.allocator();

    defer _ = gpa.deinit();

    var input = try common_input.readFileInput(allocator, "input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit(allocator);
    }

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "O....#....",
        "O.OO#....#",
        ".....##...",
        "OO.#O....O",
        ".O.....O#.",
        "O.#..O.#.#",
        "..O..#O..O",
        ".......O..",
        "#....###..",
        "#OO..#....",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 136), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "O....#....",
        "O.OO#....#",
        ".....##...",
        "OO.#O....O",
        ".O.....O#.",
        "O.#..O.#.#",
        "..O..#O..O",
        ".......O..",
        "#....###..",
        "#OO..#....",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 64), result);
}
