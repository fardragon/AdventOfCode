const std = @import("std");
const common = @import("common");
const common_input = common.input;
const Direction = common.Direction;

const Field = enum {
    Empty,
    Wall,
};

const Grid = common.grid.Grid(Field);
const Map = struct {
    map: Grid,
    start: isize,
    end: isize,

    fn deinit(self: Map) void {
        self.map.data.deinit();
    }
};

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !Map {
    const expected_width = input[0].len;

    var data = Grid.Container.init(allocator);
    errdefer data.deinit();

    var instructions = std.ArrayList(Direction).init(allocator);
    errdefer instructions.deinit();

    var start: ?isize = null;
    var end: ?isize = null;

    for (input, 0..) |line, ix| {
        _ = ix; // autofix
        if (line.len != expected_width) return error.MalformedInput;

        for (line) |char| {
            switch (char) {
                '.' => try data.append(Field.Empty),
                '#' => try data.append(Field.Wall),
                'S' => {
                    try data.append(Field.Empty);
                    start = @intCast(data.items.len - 1);
                },
                'E' => {
                    try data.append(Field.Empty);
                    end = @intCast(data.items.len - 1);
                },
                else => return error.MalformedInput,
            }
        }
    }

    return Map{
        .map = Grid{
            .data = data,
            .height = input.len,
            .width = expected_width,
        },
        .start = start.?,
        .end = end.?,
    };
}

const DistanceKey = struct { isize, Direction };
const StartCondition = DistanceKey;
const QueueItem = struct { distance: u64, position: isize, direction: Direction };
fn queueCompareFn(_: void, a: QueueItem, b: QueueItem) std.math.Order {
    return std.math.order(a.distance, b.distance);
}

fn calculateDistances(allocator: std.mem.Allocator, map: Grid, starts: []const StartCondition) !std.AutoHashMap(DistanceKey, u64) {
    var distances = std.AutoHashMap(DistanceKey, u64).init(allocator);
    errdefer distances.deinit();

    var queue = std.PriorityQueue(QueueItem, void, queueCompareFn).init(allocator, {});
    defer queue.deinit();

    for (starts) |start| {
        const start_position, const start_direction = start;
        try distances.put(.{ start_position, start_direction }, 0);
        try queue.add(.{
            .distance = 0,
            .position = start_position,
            .direction = start_direction,
        });
    }

    while (queue.items.len > 0) {
        const current = queue.remove();
        if (distances.get(.{ current.position, current.direction })) |cached_distance| {
            if (cached_distance < current.distance) continue;
        }

        //try moving forward
        const current_x, const current_y = try map.mapToXY(current.position);
        const dir_x, const dir_y = current.direction.toOffset();
        const next_x, const next_y = .{ current_x + dir_x, current_y + dir_y };
        const next_position = try map.mapToIndex(next_x, next_y);
        if (map.get(next_x, next_y).? != Field.Wall) {
            const cache_result = try distances.getOrPut(.{ next_position, current.direction });

            if (!cache_result.found_existing or (cache_result.found_existing and cache_result.value_ptr.* > current.distance + 1)) {
                cache_result.value_ptr.* = current.distance + 1;
                try queue.add(.{
                    .distance = current.distance + 1,
                    .position = next_position,
                    .direction = current.direction,
                });
            }
        }

        // try turning
        const turns: [2]Direction = .{ current.direction.rotateCW(), current.direction.rotateCCW() };
        for (turns) |next_direction| {
            const cache_result = try distances.getOrPut(.{ current.position, next_direction });

            if (!cache_result.found_existing or (cache_result.found_existing and cache_result.value_ptr.* > current.distance + 1000)) {
                cache_result.value_ptr.* = current.distance + 1000;
                try queue.add(.{
                    .distance = current.distance + 1000,
                    .position = current.position,
                    .direction = next_direction,
                });
            }
        }
    }

    return distances;
}

fn findMinimalDistance(target: isize, distances: std.AutoHashMap(DistanceKey, u64)) ?u64 {
    var result: ?u64 = null;
    for (Direction.all()) |direction| {
        if (distances.get(.{ target, direction })) |possible_result| {
            if (result == null or result.? > possible_result) {
                result = possible_result;
            }
        }
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseMap(allocator, input);
    defer map.deinit();

    var distances = try calculateDistances(allocator, map.map, &[_]StartCondition{.{ map.start, Direction.Right }});
    defer distances.deinit();

    return findMinimalDistance(map.end, distances).?;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseMap(allocator, input);
    defer map.deinit();

    var distances_from_start = try calculateDistances(allocator, map.map, &[_]StartCondition{.{ map.start, Direction.Right }});
    defer distances_from_start.deinit();

    var distances_from_end = try calculateDistances(allocator, map.map, &[_]StartCondition{
        .{ map.end, Direction.Right },
        .{ map.end, Direction.Down },
        .{ map.end, Direction.Left },
        .{ map.end, Direction.Up },
    });
    defer distances_from_end.deinit();

    const optimal = findMinimalDistance(map.end, distances_from_start).?;

    var optimal_positions = common.AutoHashSet(isize).init(allocator);
    defer optimal_positions.deinit();

    for (0..map.map.data.items.len) |position| {
        if (map.map.data.items[position] == Field.Wall) continue;
        for (Direction.all()) |direction| {
            if (distances_from_start.get(.{ @intCast(position), direction })) |distance_from_start| {
                if (distances_from_end.get(.{ @intCast(position), direction.flip() })) |distance_from_end| {
                    if (distance_from_start + distance_from_end == optimal) {
                        try optimal_positions.put(@intCast(position));
                    }
                }
            }
        }
    }

    return optimal_positions.count();
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

const test_input_a = [_][]const u8{
    "###############",
    "#.......#....E#",
    "#.#.###.#.###.#",
    "#.....#.#...#.#",
    "#.###.#####.#.#",
    "#.#.#.......#.#",
    "#.#.#####.###.#",
    "#...........#.#",
    "###.#.#####.#.#",
    "#...#.....#.#.#",
    "#.#.#.###.#.#.#",
    "#.....#...#.#.#",
    "#.###.#.#.#.#.#",
    "#S..#.....#...#",
    "###############",
};

const test_input_b = [_][]const u8{
    "#################",
    "#...#...#...#..E#",
    "#.#.#.#.#.#.#.#.#",
    "#.#.#.#...#...#.#",
    "#.#.#.#.###.#.#.#",
    "#...#.#.#.....#.#",
    "#.#.#.#.#.#####.#",
    "#.#...#.#.#.....#",
    "#.#.#####.#.###.#",
    "#.#.#.......#...#",
    "#.#.###.#####.###",
    "#.#.#...#.....#.#",
    "#.#.#.#####.###.#",
    "#.#.#.........#.#",
    "#.#.#.#########.#",
    "#S#.............#",
    "#################",
};
test "solve part 1a test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input_a);

    try std.testing.expectEqual(@as(u64, 7036), result);
}

test "solve part 1b test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input_b);

    try std.testing.expectEqual(@as(u64, 11048), result);
}

test "solve part 2a test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input_a);

    try std.testing.expectEqual(@as(u64, 45), result);
}

test "solve part 2b test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input_b);

    try std.testing.expectEqual(@as(u64, 64), result);
}
