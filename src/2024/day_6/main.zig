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
    guard: isize,

    fn clone(self: Map, allocator: std.mem.Allocator) !Map {
        return Map{
            .map = try self.map.clone(allocator),
            .guard = self.guard,
        };
    }
};

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !Map {
    const expected_width = input[0].len;

    var data = Grid.Container.empty;
    errdefer data.deinit(allocator);

    var guard: ?isize = null;

    for (input) |line| {
        if (line.len != expected_width) return error.MalformedInput;

        for (line) |char| {
            switch (char) {
                '.' => try data.append(allocator, Field.Empty),
                '#' => try data.append(allocator, Field.Wall),
                '^' => {
                    try data.append(allocator, Field.Empty);
                    guard = @intCast(data.items.len - 1);
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
        .guard = guard.?,
    };
}

fn moveGuard(x: isize, y: isize, direction: Direction) struct { isize, isize } {
    const offX, const offY = direction.toOffset();
    return .{ x + offX, y + offY };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseMap(allocator, input);
    defer map.map.data.deinit(allocator);

    var guard_direction = Direction.Up;
    var guard_x, var guard_y = try map.map.mapToXY(map.guard);

    var visited_fields = std.AutoHashMap(isize, void).init(allocator);
    defer visited_fields.deinit();

    while (true) {
        const guard_index = try map.map.mapToIndex(guard_x, guard_y);
        try visited_fields.put(guard_index, {});

        const next_guard_x, const next_guard_y = moveGuard(guard_x, guard_y, guard_direction);

        if (map.map.get(next_guard_x, next_guard_y)) |next_field| {
            guard_x, guard_y, guard_direction = switch (next_field) {
                .Empty => .{ next_guard_x, next_guard_y, guard_direction },
                .Wall => .{ guard_x, guard_y, guard_direction.rotateCW() },
            };
        } else break;
    }

    return visited_fields.count();
}

fn detectMapLoop(allocator: std.mem.Allocator, map: Map) !bool {
    var guard_direction = Direction.Up;
    var guard_x, var guard_y = try map.map.mapToXY(map.guard);

    var visited_fields = std.AutoArrayHashMap(struct { isize, Direction }, void).init(allocator);
    defer visited_fields.deinit();

    while (true) {
        const guard_index = try map.map.mapToIndex(guard_x, guard_y);

        const put_result = try visited_fields.getOrPutValue(.{ guard_index, guard_direction }, {});
        if (put_result.found_existing) {
            return true;
        }
        const next_guard_x, const next_guard_y = moveGuard(guard_x, guard_y, guard_direction);

        if (map.map.get(next_guard_x, next_guard_y)) |next_field| {
            guard_x, guard_y, guard_direction = switch (next_field) {
                .Empty => .{ next_guard_x, next_guard_y, guard_direction },
                .Wall => .{ guard_x, guard_y, guard_direction.rotateCW() },
            };
        } else break;
    }

    return false;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map = try parseMap(allocator, input);
    defer map.map.data.deinit(allocator);

    var result: u64 = 0;
    for (0..map.map.len()) |new_obstacle_ix| {
        // std.debug.print("Processing ix: {d}\n\r", .{new_obstacle_ix});
        if (@as(isize, @intCast(new_obstacle_ix)) == map.guard) continue;
        if (map.map.data.items[new_obstacle_ix] == .Wall) continue;

        var new_map = try map.clone(allocator);
        defer new_map.map.data.deinit(allocator);

        new_map.map.data.items[new_obstacle_ix] = .Wall;
        if (try detectMapLoop(allocator, new_map)) result += 1;
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
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items)});
}

const test_input = [_][]const u8{
    "....#.....",
    ".........#",
    "..........",
    "..#.......",
    ".......#..",
    "..........",
    ".#..^.....",
    "........#.",
    "#.........",
    "......#...",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 41), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6), result);
}
