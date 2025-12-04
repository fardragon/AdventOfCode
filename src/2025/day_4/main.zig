const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Map = common.grid.Grid(u8);

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !Map {
    var map: Map = Map{
        .data = try .initCapacity(allocator, input.len * input[0].len),
        .width = input[0].len,
        .height = input.len,
    };
    errdefer map.data.deinit(allocator);

    for (input) |line| {
        map.data.appendSliceAssumeCapacity(line);
    }

    return map;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var map = try parseMap(allocator, input);
    defer map.data.deinit(allocator);

    for (0..map.len()) |ix| {
        if (map.data.items[ix] != '@') continue;

        const x, const y = try map.mapToXY(@intCast(ix));
        const possible_neighbours: [8]struct { isize, isize } = .{
            .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
            .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
            .{ 0, 1 },   .{ 1, 1 },
        };

        var local_score: u8 = 0;
        for (possible_neighbours) |pn| {
            const xd, const yd = pn;
            if (map.get(x + xd, y + yd)) |n| {
                if (n == '@') {
                    local_score += 1;
                }
            }
        }
        if (local_score < 4) {
            score += 1;
        }
    }
    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var map = try parseMap(allocator, input);
    defer map.data.deinit(allocator);

    var rolls_to_remove: std.ArrayList(usize) = try .initCapacity(allocator, map.len());
    defer rolls_to_remove.deinit(allocator);

    while (true) {
        defer rolls_to_remove.clearRetainingCapacity();

        for (0..map.len()) |ix| {
            if (map.data.items[ix] != '@') continue;

            const x, const y = try map.mapToXY(@intCast(ix));
            const possible_neighbours: [8]struct { isize, isize } = .{
                .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
                .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
                .{ 0, 1 },   .{ 1, 1 },
            };

            var local_score: u8 = 0;
            for (possible_neighbours) |pn| {
                const xd, const yd = pn;
                if (map.get(x + xd, y + yd)) |n| {
                    if (n == '@') {
                        local_score += 1;
                    }
                }
            }
            if (local_score < 4) {
                rolls_to_remove.appendAssumeCapacity(ix);
            }
        }

        if (rolls_to_remove.items.len == 0) {
            break;
        } else {
            for (rolls_to_remove.items) |ix| {
                map.data.items[ix] = '.';
                score += 1;
            }
        }
    }

    return score;
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
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 13), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 43), result);
}
