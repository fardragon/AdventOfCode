const std = @import("std");
const common_input = @import("common").input;
const CacheKeyType = struct { u64, usize };

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(u64) {
    if (input.len != 1) return error.MalformedInput;
    var stones = std.ArrayList(u64).empty;

    errdefer stones.deinit(allocator);

    var split = std.mem.splitScalar(u8, input[0], ' ');

    while (split.next()) |number| {
        try stones.append(allocator, try std.fmt.parseInt(u64, number, 10));
    }

    return stones;
}

fn blinkWithCache(cache: *std.AutoHashMap(CacheKeyType, u64), stone: u64, blinks: usize) !u64 {
    const cache_key = .{ stone, blinks };

    if (cache.get(cache_key)) |cached| return cached;

    var result: ?u64 = null;
    if (blinks == 0) {
        result = 1;
    } else if (stone == 0) {
        result = try blinkWithCache(cache, 1, blinks - 1);
    } else {
        const digits = std.math.log10(stone) + 1;
        if (digits % 2 == 0) {
            const divisor = try std.math.powi(u64, 10, digits / 2);
            result = try blinkWithCache(cache, stone / divisor, blinks - 1) + try blinkWithCache(cache, stone % divisor, blinks - 1);
        } else {
            result = try blinkWithCache(cache, stone * 2024, blinks - 1);
        }
    }

    try cache.put(cache_key, result.?);
    return result.?;
}

fn blink(allocator: std.mem.Allocator, stones: []const u64, blinks: u64) !u64 {
    var stones_count: u64 = 0;

    var cache = std.AutoHashMap(CacheKeyType, u64).init(allocator);
    defer cache.deinit();

    for (stones) |stone| {
        stones_count += try blinkWithCache(&cache, stone, blinks);
    }

    return stones_count;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var stones = try parseInput(allocator, input);
    defer stones.deinit(allocator);

    return try blink(allocator, stones.items, 25);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var stones = try parseInput(allocator, input);
    defer stones.deinit(allocator);

    return try blink(allocator, stones.items, 75);
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
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "125 17",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 55312), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "125 17",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 65601038650482), result);
}
