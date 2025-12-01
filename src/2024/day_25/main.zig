const std = @import("std");
const common = @import("common");
const common_input = common.input;

const PartWidth = 5;
const Lock = [PartWidth]u8;
const Key = [PartWidth]u8;

const PartLength = 7;

fn parseLock(input: []const []const u8) !Lock {
    if (input.len != PartLength) return error.InvalidLockSize;
    if (!std.mem.allEqual(u8, input[0], '#')) return error.InvalidLock;

    var lock: Lock = .{0} ** PartWidth;

    for (input[1..]) |line| {
        if (line.len != PartWidth) return error.InvalidLockWidth;

        for (line, 0..) |char, ix| {
            if (char == '#') lock[ix] += 1;
        }
    }

    return lock;
}

fn parseKey(input: []const []const u8) !Key {
    if (input.len != PartLength) return error.InvalidKeySize;
    if (!std.mem.allEqual(u8, input[input.len - 1], '#')) return error.InvalidKey;

    var key: Key = .{0} ** PartWidth;
    var it: isize = @intCast(input.len - 2);

    while (it >= 0) : (it -= 1) {
        const line = input[@intCast(it)];
        if (line.len != PartWidth) return error.InvalidKeyWidth;

        for (line, 0..) |char, ix| {
            if (char == '#') key[ix] += 1;
        }
    }
    return key;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !struct { std.ArrayList(Lock), std.ArrayList(Key) } {
    var locks = std.ArrayList(Lock).empty;
    errdefer locks.deinit(allocator);

    var keys = std.ArrayList(Key).empty;
    errdefer keys.deinit(allocator);

    var it: usize = 0;

    while (it < input.len) {
        if (input[it][0] == '#') {
            try locks.append(allocator, try parseLock(input[it .. it + PartLength]));
        } else if (input[it][0] == '.') {
            try keys.append(allocator, try parseKey(input[it .. it + PartLength]));
        } else return error.InvalidInput;

        it += (PartLength + 1);
    }

    return .{ locks, keys };
}

fn validateLockKeyPair(lock: Lock, key: Key) bool {
    for (0..PartWidth) |ix| {
        if (lock[ix] + key[ix] > (PartLength - 2)) return false;
    }
    return true;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var locks, var keys = try parseInput(allocator, input);
    defer {
        locks.deinit(allocator);
        keys.deinit(allocator);
    }

    var result: u64 = 0;

    for (locks.items) |lock| {
        for (keys.items) |key| {
            if (validateLockKeyPair(lock, key)) result += 1;
        }
    }

    return result;
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
}

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "#####",
        ".####",
        ".####",
        ".####",
        ".#.#.",
        ".#...",
        ".....",
        "",
        "#####",
        "##.##",
        ".#.##",
        "...##",
        "...#.",
        "...#.",
        ".....",
        "",
        ".....",
        "#....",
        "#....",
        "#...#",
        "#.#.#",
        "#.###",
        "#####",
        "",
        ".....",
        ".....",
        "#.#..",
        "###..",
        "###.#",
        "###.#",
        "#####",
        "",
        ".....",
        ".....",
        ".....",
        "#....",
        "#.#..",
        "#.#.#",
        "#####",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3), result);
}
