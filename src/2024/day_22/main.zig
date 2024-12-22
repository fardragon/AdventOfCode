const std = @import("std");
const common = @import("common");
const common_input = common.input;

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(u64) {
    var data = try std.ArrayList(u64).initCapacity(allocator, input.len);
    errdefer data.deinit();

    for (input) |line| {
        data.appendAssumeCapacity(try std.fmt.parseInt(u64, line, 10));
    }

    return data;
}

fn mix(a: u64, b: u64) u64 {
    return a ^ b;
}

fn prune(a: u64) u64 {
    return @mod(a, 16777216);
}

fn nextSecret(number: u64) u64 {
    const s1 = prune(mix(number, number * 64));
    const s2 = prune(mix(s1, @divFloor(s1, 32)));
    const s3 = prune(mix(s2, s2 * 2048));
    return s3;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var buyers = try parseInput(allocator, input);
    defer buyers.deinit();

    for (0..2000) |_| {
        for (buyers.items) |*buyer| {
            buyer.* = nextSecret(buyer.*);
        }
    }

    var result: u64 = 0;
    for (buyers.items) |buyer| {
        result += buyer;
    }
    return result;
}

fn testBuyingSequence(sequence: []const i8, buyers_diffs: []const std.AutoHashMap([4]i8, u64)) u64 {
    var result: u64 = 0;

    var cache_key: [4]i8 = undefined;
    std.mem.copyForwards(i8, &cache_key, sequence);

    for (buyers_diffs) |diffs| {
        if (diffs.get(cache_key)) |price| {
            result += price;
        }
    }

    return result;
}

fn priceDiff(a: u64, b: u64) i8 {
    return @truncate(@as(i64, @intCast(a)) - @as(i64, @intCast(b)));
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var buyers = try parseInput(allocator, input);
    defer buyers.deinit();

    var buyers_diffs = try std.ArrayList(std.AutoHashMap([4]i8, u64)).initCapacity(allocator, buyers.items.len);
    defer {
        for (buyers_diffs.items) |*diffs| {
            diffs.deinit();
        }
        buyers_diffs.deinit();
    }

    for (buyers.items) |buyer| {
        var prices: [2000]u64 = undefined;

        var diffs = std.AutoHashMap([4]i8, u64).init(allocator);
        try diffs.ensureTotalCapacity(2000);
        errdefer diffs.deinit();

        var secret = buyer;
        for (0..2000) |ix| {
            const current_price = @mod(secret, 10);
            prices[ix] = current_price;

            if (ix >= 4) {
                const diff: [4]i8 = .{
                    priceDiff(prices[ix - 3], prices[ix - 4]),
                    priceDiff(prices[ix - 2], prices[ix - 3]),
                    priceDiff(prices[ix - 1], prices[ix - 2]),
                    priceDiff(prices[ix], prices[ix - 1]),
                };

                const cache_hit = diffs.getOrPutAssumeCapacity(diff);
                if (!cache_hit.found_existing) {
                    cache_hit.value_ptr.* = prices[ix];
                }
            }

            secret = nextSecret(secret);
        }

        buyers_diffs.appendAssumeCapacity(diffs);
    }

    var sequence: [4]i8 = .{ -9, -9, -9, -9 };

    var result: ?u64 = null;
    while (sequence[0] <= 9) : (sequence[0] += 1) {
        sequence[1] = -9;
        while (sequence[1] <= 9) : (sequence[1] += 1) {
            sequence[2] = -9;
            while (sequence[2] <= 9) : (sequence[2] += 1) {
                sequence[3] = -9;
                while (sequence[3] <= 9) : (sequence[3] += 1) {
                    const sequence_result = testBuyingSequence(&sequence, buyers_diffs.items);
                    if (result == null or (sequence_result > result.?)) {
                        result = sequence_result;
                    }
                }
            }
        }
    }

    return result.?;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

    const input = try common_input.readFileInput(allocator, "input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit();
    }

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

test "testMix" {
    try std.testing.expectEqual(@as(u64, 37), mix(42, 15));
}

test "testPrune" {
    try std.testing.expectEqual(@as(u64, 16113920), prune(100000000));
}

test "testNextSecret" {
    try std.testing.expectEqual(@as(u64, 15887950), nextSecret(123));
    try std.testing.expectEqual(@as(u64, 16495136), nextSecret(15887950));
    try std.testing.expectEqual(@as(u64, 527345), nextSecret(16495136));
    try std.testing.expectEqual(@as(u64, 704524), nextSecret(527345));
    try std.testing.expectEqual(@as(u64, 1553684), nextSecret(704524));
    try std.testing.expectEqual(@as(u64, 12683156), nextSecret(1553684));
    try std.testing.expectEqual(@as(u64, 11100544), nextSecret(12683156));
    try std.testing.expectEqual(@as(u64, 12249484), nextSecret(11100544));
    try std.testing.expectEqual(@as(u64, 7753432), nextSecret(12249484));
    try std.testing.expectEqual(@as(u64, 5908254), nextSecret(7753432));
}

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "1",
        "10",
        "100",
        "2024",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 37327623), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "1",
        "2",
        "3",
        "2024",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 23), result);
}
