const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Spring = struct {
    pattern: common.String,
    numbers: std.ArrayList(u8),

    fn deinit(self: *Spring, allocator: std.mem.Allocator) void {
        self.pattern.deinit();
        self.numbers.deinit(allocator);
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Spring) {
    var result = std.ArrayList(Spring).empty;

    errdefer {
        for (result.items) |*spring| {
            spring.deinit(allocator);
        }
        result.deinit(allocator);
    }

    for (input) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var pattern = try common.String.init(allocator, it.first());
        errdefer pattern.deinit();

        var numbers = std.ArrayList(u8).empty;
        errdefer numbers.deinit(allocator);
        var numbers_it = std.mem.splitScalar(u8, it.next().?, ',');

        while (numbers_it.next()) |number_str| {
            try numbers.append(allocator, try std.fmt.parseUnsigned(u8, number_str, 10));
        }

        try result.append(
            allocator,
            Spring{
                .pattern = pattern,
                .numbers = numbers,
            },
        );
    }

    return result;
}

const Cache = struct {
    const CacheKey = struct {
        pattern: []const u8,
        numbers: []const u8,
    };

    const CacheKeyContext = struct {
        pub fn hash(ctx: CacheKeyContext, key: CacheKey) u64 {
            _ = ctx;
            var h = std.hash.Wyhash.init(0);
            h.update(key.pattern);
            h.update(key.numbers);
            return h.final();
        }

        pub fn eql(ctx: CacheKeyContext, a: CacheKey, b: CacheKey) bool {
            _ = ctx;
            return std.mem.eql(u8, a.pattern, b.pattern) and std.mem.eql(u8, a.numbers, b.numbers);
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

    fn put(self: *Self, pattern: []const u8, numbers: []const u8, value: u64) !void {
        const entry_pattern = try self.allocator.dupe(u8, pattern);
        const entry_numbers = try self.allocator.dupe(u8, numbers);

        const key = Self.CacheKey{
            .pattern = entry_pattern,
            .numbers = entry_numbers,
        };

        try self.map.put(key, value);
    }

    fn get(self: *const Self, pattern: []const u8, numbers: []const u8) ?u64 {
        const key = Self.CacheKey{
            .pattern = pattern,
            .numbers = numbers,
        };

        return self.map.get(key);
    }

    fn deinit(self: *Self) void {
        var keys_it = self.map.keyIterator();
        while (keys_it.next()) |key| {
            self.allocator.free(key.*.pattern);
            self.allocator.free(key.*.numbers);
        }
        self.map.deinit();
    }
};

fn countArrangements(allocator: std.mem.Allocator, pattern: []const u8, numbers: []const u8, cache: *Cache) !u64 {
    if (pattern.len == 0 and numbers.len == 0) {
        return 1;
    }
    if (pattern.len == 0) return 0;

    if (cache.get(pattern, numbers)) |cached_val| {
        return cached_val;
    }

    // prune impossible branches
    var sum: u64 = 0;
    for (numbers) |num| {
        sum += num;
    }
    if (numbers.len > 0 and pattern.len < (sum + numbers.len - 1)) {
        try cache.put(pattern, numbers, 0);
        return 0;
    }

    if (pattern[0] == '.') {
        const result = try countArrangements(allocator, pattern[1..], numbers, cache);
        try cache.put(pattern, numbers, result);
        return result;
    }

    if (pattern[0] == '?') {
        var pattern_with_broken = try allocator.dupe(u8, pattern);
        defer allocator.free(pattern_with_broken);
        pattern_with_broken[0] = '#';

        const result = try countArrangements(allocator, pattern[1..], numbers, cache) + try countArrangements(allocator, pattern_with_broken, numbers, cache);
        try cache.put(pattern, numbers, result);
        return result;
    }

    if (pattern[0] == '#') {
        if (numbers.len == 0) {
            // no more numbers to replace
            try cache.put(pattern, numbers, 0);
            return 0;
        }

        const next_number = numbers[0];

        const next_dot = if (std.mem.indexOfScalar(u8, pattern, '.')) |index| index else pattern.len;

        if (next_dot < next_number) {
            // not enough # and ? to proceed
            try cache.put(pattern, numbers, 0);
            return 0;
        }

        // advance next_number symbols
        const remaining_pattern = pattern[next_number..];
        if (remaining_pattern.len == 0) {
            const result = try countArrangements(allocator, remaining_pattern, numbers[1..], cache);
            try cache.put(pattern, numbers, result);
            return result;
        }

        if (remaining_pattern[0] == '#') {
            try cache.put(pattern, numbers, 0);
            return 0;
        }

        // first symbol is either a '.' or '?' that's assumed to be a dot
        const result = try countArrangements(allocator, remaining_pattern[1..], numbers[1..], cache);
        try cache.put(pattern, numbers, result);
        return result;
    }

    unreachable;
}

fn solve(allocator: std.mem.Allocator, input: std.ArrayList(Spring)) !u64 {
    var result: u64 = 0;
    var cache = Cache.init(allocator);
    defer cache.deinit();

    for (input.items) |spring| {
        result += try countArrangements(allocator, spring.pattern.str, spring.numbers.items, &cache);
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var springs = try parseInput(allocator, input);
    defer {
        for (springs.items) |*spring| spring.deinit(allocator);
        springs.deinit(allocator);
    }
    return solve(allocator, springs);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var springs = try parseInput(allocator, input);
    defer {
        for (springs.items) |*spring| spring.deinit(allocator);
        springs.deinit(allocator);
    }

    //unfold input
    var unfolded_springs = std.ArrayList(Spring).empty;
    defer {
        for (unfolded_springs.items) |*spring| spring.deinit(allocator);
        unfolded_springs.deinit(allocator);
    }

    for (springs.items) |spring| {
        const new_pattern = try std.fmt.allocPrint(
            allocator,
            "{s}?{s}?{s}?{s}?{s}",
            .{ spring.pattern.str, spring.pattern.str, spring.pattern.str, spring.pattern.str, spring.pattern.str },
        );
        defer allocator.free(new_pattern);

        var new_numbers = std.ArrayList(u8).empty;
        errdefer new_numbers.deinit(allocator);

        for (0..5) |_| {
            try new_numbers.appendSlice(allocator, spring.numbers.items);
        }

        try unfolded_springs.append(
            allocator,
            Spring{
                .pattern = try common.String.init(allocator, new_pattern),
                .numbers = new_numbers,
            },
        );
    }

    return solve(allocator, unfolded_springs);
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

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
        "???.### 1,1,3",
        ".??..??...?##. 1,1,3",
        "?#?#?#?#?#?#?#? 1,3,1,6",
        "????.#...#... 4,1,1",
        "????.######..#####. 1,6,5",
        "?###???????? 3,2,1",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 21), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "???.### 1,1,3",
        ".??..??...?##. 1,1,3",
        "?#?#?#?#?#?#?#? 1,3,1,6",
        "????.#...#... 4,1,1",
        "????.######..#####. 1,6,5",
        "?###???????? 3,2,1",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 525152), result);
}
