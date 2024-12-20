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
};

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !Map {
    const expected_width = input[0].len;

    var data = Grid.Container.init(allocator);
    errdefer data.deinit();

    var start: ?isize = null;
    var end: ?isize = null;

    for (input) |line| {
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

const QueueItem = struct { distance: i64, position: isize };
fn queueCompareFn(_: void, a: QueueItem, b: QueueItem) std.math.Order {
    return std.math.order(a.distance, b.distance);
}

fn calculateDistances(allocator: std.mem.Allocator, map: Map) !std.AutoArrayHashMap(isize, i64) {
    var distances = std.AutoArrayHashMap(isize, i64).init(allocator);
    errdefer distances.deinit();

    var queue = std.PriorityQueue(QueueItem, void, queueCompareFn).init(allocator, {});
    defer queue.deinit();

    try distances.put(map.start, 0);
    try queue.add(.{
        .distance = 0,
        .position = map.start,
    });

    while (queue.items.len > 0) {
        const current = queue.remove();
        if (distances.get(current.position)) |cached_distance| {
            if (cached_distance < current.distance) continue;
        }
        //try moving
        const current_x, const current_y = try map.map.mapToXY(current.position);

        for (common.Direction.all()) |direction| {
            const dir_x, const dir_y = direction.toOffset();
            const next_x, const next_y = .{ current_x + dir_x, current_y + dir_y };
            if (map.map.get(next_x, next_y)) |next_field| {
                if (next_field == Field.Empty) {
                    const next_position = try map.map.mapToIndex(next_x, next_y);
                    const cache_result = try distances.getOrPut(next_position);

                    if (!cache_result.found_existing or (cache_result.found_existing and cache_result.value_ptr.* > current.distance + 1)) {
                        cache_result.value_ptr.* = current.distance + 1;
                        try queue.add(.{
                            .distance = current.distance + 1,
                            .position = next_position,
                        });
                    }
                }
            }
        }
    }

    return distances;
}

fn findCheats(distances: std.AutoArrayHashMap(isize, i64), grid: Grid, cheat_length: i8, savings_threshold: u64) u64 {
    var result: u64 = 0;

    var it1 = distances.iterator();
    while (it1.next()) |p| {
        var it2 = it1;
        while (it2.next()) |np| {
            if (p.key_ptr.* == np.key_ptr.*) continue;

            const px, const py = grid.mapToXY(p.key_ptr.*) catch unreachable;
            const npx, const npy = grid.mapToXY(np.key_ptr.*) catch unreachable;

            const cheat_cost: i64 = @intCast(@abs(px - npx) + @abs(py - npy));
            const initial_cost = np.value_ptr.* - p.value_ptr.*;

            if (cheat_cost <= cheat_length and (initial_cost - cheat_cost) >= savings_threshold) {
                result += 1;
            }
        }
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8, savings_threshold: u64) !u64 {
    const map = try parseMap(allocator, input);
    defer map.map.data.deinit();

    var distances = try calculateDistances(allocator, map);
    defer distances.deinit();

    return findCheats(distances, map.map, 2, savings_threshold);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8, savings_threshold: u64) !u64 {
    const map = try parseMap(allocator, input);
    defer map.map.data.deinit();

    var distances = try calculateDistances(allocator, map);
    defer distances.deinit();

    return findCheats(distances, map.map, 20, savings_threshold);
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

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items, 100)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items, 100)});
}

const test_input = [_][]const u8{
    "###############",
    "#...#...#.....#",
    "#.#.#.#.#.###.#",
    "#S#...#.#.#...#",
    "#######.#.#.###",
    "#######.#.#...#",
    "#######.#.###.#",
    "###..E#...#...#",
    "###.#######.###",
    "#...###...#...#",
    "#.#####.#.###.#",
    "#.#...#.#.#...#",
    "#.#.#.#.#.#.###",
    "#...#...#...###",
    "###############",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input, 2);

    try std.testing.expectEqual(@as(u64, 44), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input, 50);

    try std.testing.expectEqual(@as(u64, 285), result);
}
