const std = @import("std");
const common_input = @import("common").input;
const KeyPosition = struct { i8, i8 };

fn doorKeypad(character: u8) !KeyPosition {
    return switch (character) {
        '7' => .{ 0, 0 },
        '8' => .{ 1, 0 },
        '9' => .{ 2, 0 },
        '4' => .{ 0, 1 },
        '5' => .{ 1, 1 },
        '6' => .{ 2, 1 },
        '1' => .{ 0, 2 },
        '2' => .{ 1, 2 },
        '3' => .{ 2, 2 },
        '0' => .{ 1, 3 },
        'A' => .{ 2, 3 },
        else => return error.InvalidCharacter,
    };
}

fn robotKeypad(character: u8) !KeyPosition {
    return switch (character) {
        '^' => .{ 1, 0 },
        'A' => .{ 2, 0 },
        '<' => .{ 0, 1 },
        'v' => .{ 1, 1 },
        '>' => .{ 2, 1 },
        else => return error.InvalidCharacter,
    };
}

const CacheKey = struct {
    sequence: []const u8,
    depth: u8,
};

const CacheKeyContext = struct {
    pub fn hash(_: CacheKeyContext, key: CacheKey) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(key.sequence);
        h.update(std.mem.asBytes(&key.depth));

        const hs = h.final();
        return hs;
    }

    pub fn eql(_: CacheKeyContext, a: CacheKey, b: CacheKey) bool {
        return (a.depth == b.depth) and std.mem.eql(u8, a.sequence, b.sequence);
    }
};

const CacheType = std.HashMap(CacheKey, u64, CacheKeyContext, std.hash_map.default_max_load_percentage);

fn permute(allocator: std.mem.Allocator, str: []u8, ix: usize, results: *std.ArrayList(std.ArrayList(u8))) !void {
    if (ix == str.len - 1) {
        var result = try std.ArrayList(u8).initCapacity(allocator, str.len);
        result.appendSliceAssumeCapacity(str);
        results.appendAssumeCapacity(result);
        return;
    }

    for (ix..str.len) |i| {
        std.mem.swap(u8, &str[ix], &str[i]);
        try permute(allocator, str, ix + 1, results);
        std.mem.swap(u8, &str[ix], &str[i]);
    }
}

fn getAllPermutations(allocator: std.mem.Allocator, string: []const u8) !std.ArrayList(std.ArrayList(u8)) {
    const mutable_string = try allocator.dupe(u8, string);
    defer allocator.free(mutable_string);

    const permutations_count: usize = @intFromFloat(std.math.gamma(f64, @as(f64, @floatFromInt(string.len + 1))));
    var permutations = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, permutations_count);

    errdefer {
        for (permutations.items) |*permutation| {
            permutation.deinit(allocator);
        }
        permutations.deinit(allocator);
    }

    try permute(allocator, mutable_string, 0, &permutations);

    return permutations;
}

fn validate_path(start_position: KeyPosition, depth: u8, path: []const u8) bool {
    var current_x, var current_y = start_position;

    for (path) |direction| {
        current_x, current_y = switch (direction) {
            '^' => .{ current_x, current_y - 1 },
            'v' => .{ current_x, current_y + 1 },
            '<' => .{ current_x - 1, current_y },
            '>' => .{ current_x + 1, current_y },
            'A' => .{ current_x, current_y },
            else => unreachable,
        };

        if (depth == 0 and current_x == 0 and current_y == 3) return false;
        if (depth != 0 and current_x == 0 and current_y == 0) return false;
    }

    return true;
}

fn solveRecursive(allocator: std.mem.Allocator, cache: *CacheType, sequence: []const u8, depth: u8, depth_limit: u8) !u64 {
    const cache_key = CacheKey{
        .sequence = try allocator.dupe(u8, sequence),
        .depth = depth,
    };
    errdefer allocator.free(cache_key.sequence);

    if (cache.get(cache_key)) |cache_hit| {
        allocator.free(cache_key.sequence);
        return cache_hit;
    }

    var current_x, var current_y = if (depth == 0) try doorKeypad('A') else try robotKeypad('A');

    var total_moves: u64 = 0;
    for (sequence) |char| {
        const next_x, const next_y = if (depth == 0) try doorKeypad(char) else try robotKeypad(char);

        var valid_paths = std.ArrayList(std.ArrayList(u8)).empty;
        defer {
            for (valid_paths.items) |*item| {
                item.deinit(allocator);
            }
            valid_paths.deinit(allocator);
        }

        if (current_x == next_x and current_y == next_y) {
            try valid_paths.append(allocator, std.ArrayList(u8).empty);
            try valid_paths.items[0].append(allocator, 'A');
        } else {
            const dx, const dy = .{ next_x - current_x, next_y - current_y };
            var path_template = try std.ArrayList(u8).initCapacity(allocator, @abs(dx) + @abs(dy));
            defer path_template.deinit(allocator);

            if (dx > 0) path_template.appendNTimesAssumeCapacity('>', @abs(dx)) else path_template.appendNTimesAssumeCapacity('<', @abs(dx));
            if (dy > 0) path_template.appendNTimesAssumeCapacity('v', @abs(dy)) else path_template.appendNTimesAssumeCapacity('^', @abs(dy));

            var all_path_permutations = try getAllPermutations(allocator, path_template.items);
            defer {
                for (all_path_permutations.items) |*item| {
                    item.deinit(allocator);
                }
                all_path_permutations.deinit(allocator);
            }

            //validate paths
            for (all_path_permutations.items) |path| {
                if (validate_path(.{ current_x, current_y }, depth, path.items)) {
                    var valid_path = try path.clone(allocator);
                    try valid_path.append(allocator, 'A');
                    try valid_paths.append(allocator, valid_path);
                }
            }
        }

        if (depth == depth_limit) {
            var shortest_path: ?u64 = null;
            for (valid_paths.items) |path| {
                if (shortest_path == null or path.items.len < shortest_path.?) {
                    shortest_path = path.items.len;
                }
            }
            total_moves += shortest_path.?;
        } else {
            var shortest_sub_path: ?u64 = null;
            for (valid_paths.items) |path| {
                const sub_path_length = try solveRecursive(allocator, cache, path.items, depth + 1, depth_limit);
                if (shortest_sub_path == null or sub_path_length < shortest_sub_path.?) {
                    shortest_sub_path = sub_path_length;
                }
            }
            total_moves += shortest_sub_path.?;
        }

        current_x, current_y = .{ next_x, next_y };
    }

    try cache.put(cache_key, total_moves);
    return total_moves;
}

fn solve(allocator: std.mem.Allocator, codes: []const []const u8, depth_limit: u8) !u64 {
    var cache = CacheType.init(allocator);
    defer {
        var ix = cache.keyIterator();
        while (ix.next()) |key| {
            allocator.free(key.sequence);
        }
        cache.deinit();
    }
    var result: u64 = 0;

    for (codes) |code| {
        const code_prefix = try std.fmt.parseInt(u64, code[0 .. code.len - 1], 10);

        result += ((try solveRecursive(allocator, &cache, code, 0, depth_limit)) * code_prefix);
    }
    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    return try solve(allocator, input, 2);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    return try solve(allocator, input, 25);
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
        "029A",
        "980A",
        "179A",
        "456A",
        "379A",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 126384), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "029A",
        "980A",
        "179A",
        "456A",
        "379A",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 154115708116294), result);
}
