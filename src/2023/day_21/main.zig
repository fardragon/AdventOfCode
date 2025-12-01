const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Position = common.Pair(usize, usize);

const Puzzle = struct {
    grid: std.ArrayList(u8),
    width: usize,
    height: usize,
    starting_position: usize,

    fn mapToX(self: Puzzle, index: usize) usize {
        return index % self.width;
    }

    fn mapToY(self: Puzzle, index: usize) usize {
        return index / self.width;
    }

    fn mapToIndex(self: Puzzle, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn deinit(self: *Puzzle, allocator: std.mem.Allocator) void {
        self.grid.deinit(allocator);
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Puzzle {
    var result = Puzzle{
        .grid = std.ArrayList(u8).empty,
        .width = input[0].len,
        .height = input.len,
        .starting_position = undefined,
    };

    errdefer result.deinit(allocator);

    for (input) |line| {
        try result.grid.appendSlice(allocator, line);
    }

    for (result.grid.items, 0..) |*field, ix| {
        if (field.* == 'S') {
            result.starting_position = ix;
            field.* = '.';
        }
    }

    return result;
}

fn generateNeighbours(puzzle: Puzzle, position: usize) [4]?usize {
    const x = puzzle.mapToX(position);
    const y = puzzle.mapToY(position);

    var neighbours: [4]?usize = .{ null, null, null, null };
    // try go up
    if (y > 0) {
        const new_pos = puzzle.mapToIndex(x, y - 1);
        neighbours[0] = new_pos;
    }

    // try go down
    if (y < puzzle.height - 1) {
        const new_pos = puzzle.mapToIndex(x, y + 1);
        neighbours[1] = new_pos;
    }

    // try go left
    if (x > 0) {
        const new_pos = puzzle.mapToIndex(x - 1, y);
        neighbours[2] = new_pos;
    }

    // try go right
    if (x < puzzle.width - 1) {
        const new_pos = puzzle.mapToIndex(x + 1, y);
        neighbours[3] = new_pos;
    }

    return neighbours;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8, max_steps: u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    const QueueState = common.Pair(usize, u8);

    var queue = std.ArrayList(QueueState).empty;
    defer queue.deinit(allocator);

    try queue.append(allocator, QueueState{ .first = puzzle.starting_position, .second = 0 });

    var targets: u64 = 0;

    var visited = std.AutoArrayHashMap(QueueState, void).init(allocator);
    defer visited.deinit();

    while (queue.pop()) |queue_item| {
        try visited.put(queue_item, {});

        const steps = queue_item.second;
        const position = queue_item.first;
        if (steps == max_steps) {
            targets += 1;
            continue;
        }

        const neighbours = generateNeighbours(puzzle, position);
        for (neighbours) |n_opt| {
            if (n_opt) |n| {
                if (puzzle.grid.items[n] == '.') {
                    const new_state = QueueState{ .first = n, .second = steps + 1 };
                    if (!visited.contains(new_state)) {
                        try queue.append(allocator, new_state);
                    }
                }
            }
        }
    }

    return targets;
}

const GridPosition = struct {
    x: i64,
    y: i64,
};

const BigPosition = struct {
    position: usize,
    grid: GridPosition,
};

fn generatePositions(allocator: std.mem.Allocator, puzzle: Puzzle, steps: u64) !std.AutoArrayHashMap(BigPosition, void) {
    var position_set = std.AutoArrayHashMap(BigPosition, void).init(allocator);
    errdefer position_set.deinit();

    const start = BigPosition{
        .position = puzzle.starting_position,
        .grid = GridPosition{ .x = 0, .y = 0 },
    };
    try position_set.put(start, {});

    const iterations = steps % puzzle.width + puzzle.width * 2;
    for (0..iterations) |_| {
        var new_positions = std.AutoArrayHashMap(BigPosition, void).init(allocator);
        errdefer new_positions.deinit();

        for (position_set.keys()) |big_position| {
            const neighbours = generateNeighbours(puzzle, big_position.position);
            for (neighbours) |n_opt| {
                if (n_opt) |n| {
                    if (puzzle.grid.items[n] == '.') {
                        const new_pos = BigPosition{
                            .position = n,
                            .grid = big_position.grid,
                        };
                        try new_positions.put(new_pos, {});
                    }
                }
            }

            const x = puzzle.mapToX(big_position.position);
            const y = puzzle.mapToY(big_position.position);

            if (x == 0) {
                const new_pos = BigPosition{
                    .position = puzzle.mapToIndex(puzzle.width - 1, y),
                    .grid = GridPosition{ .x = big_position.grid.x - 1, .y = big_position.grid.y },
                };
                try new_positions.put(new_pos, {});
            }

            if (x == puzzle.width - 1) {
                const new_pos = BigPosition{
                    .position = puzzle.mapToIndex(0, y),
                    .grid = GridPosition{ .x = big_position.grid.x + 1, .y = big_position.grid.y },
                };
                try new_positions.put(new_pos, {});
            }

            if (y == 0) {
                const new_pos = BigPosition{
                    .position = puzzle.mapToIndex(x, puzzle.height - 1),
                    .grid = GridPosition{ .x = big_position.grid.x, .y = big_position.grid.y - 1 },
                };
                try new_positions.put(new_pos, {});
            }

            if (y == puzzle.height - 1) {
                const new_pos = BigPosition{
                    .position = puzzle.mapToIndex(x, 0),
                    .grid = GridPosition{ .x = big_position.grid.x, .y = big_position.grid.y + 1 },
                };
                try new_positions.put(new_pos, {});
            }
        }

        position_set.deinit();
        position_set = new_positions;
    }

    return position_set;
}

// def get_big_positions_by_grid(big_positions: set[BigPosition]) -> dict[tuple[int, int], int]:
//     counts = defaultdict(int)
//     for position, big_x, big_y in big_positions:
//         counts[(big_x, big_y)] += 1
//     return counts

fn countPositions(allocator: std.mem.Allocator, big_positions: std.AutoArrayHashMap(BigPosition, void)) !std.AutoArrayHashMap(GridPosition, u64) {
    var result = std.AutoArrayHashMap(GridPosition, u64).init(allocator);
    errdefer result.deinit();

    for (big_positions.keys()) |big_position| {
        const entry = try result.getOrPut(big_position.grid);

        if (entry.found_existing) {
            entry.value_ptr.* += 1;
        } else {
            entry.value_ptr.* = 1;
        }
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8, steps: u64) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    var positions = try generatePositions(allocator, puzzle, steps);
    defer positions.deinit();

    var counts = try countPositions(allocator, positions);
    defer counts.deinit();

    const tip = counts.get(GridPosition{ .x = -2, .y = 0 }).? + counts.get(GridPosition{ .x = 2, .y = 0 }).? +
        counts.get(GridPosition{ .x = 0, .y = -2 }).? + counts.get(GridPosition{ .x = 0, .y = 2 }).?;

    const edgeA = counts.get(GridPosition{ .x = -2, .y = -1 }).? + counts.get(GridPosition{ .x = -2, .y = 1 }).? +
        counts.get(GridPosition{ .x = 2, .y = -1 }).? + counts.get(GridPosition{ .x = 2, .y = 1 }).?;

    const edgeB = counts.get(GridPosition{ .x = -1, .y = -1 }).? + counts.get(GridPosition{ .x = -1, .y = 1 }).? +
        counts.get(GridPosition{ .x = 1, .y = -1 }).? + counts.get(GridPosition{ .x = 1, .y = 1 }).?;

    const centerA = counts.get(GridPosition{ .x = 0, .y = 1 }).?;
    const centerB = counts.get(GridPosition{ .x = 0, .y = 0 }).?;

    const coeff = steps / puzzle.width;

    return tip + edgeA * coeff + edgeB * (coeff - 1) + centerA * coeff * coeff + centerB * (coeff - 1) * (coeff - 1);
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

    std.debug.print("Part 1 solution: {d}\n", .{try solvePart1(allocator, input.items, 64)});
    std.debug.print("Part 2 solution: {d}\n", .{try solvePart2(allocator, input.items, 26501365)});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "...........",
        ".....###.#.",
        ".###.##..#.",
        "..#.#...#..",
        "....#.#....",
        ".##..S####.",
        ".##..#...#.",
        ".......##..",
        ".##.#.####.",
        ".##..##.##.",
        "...........",
    };

    const result = try solvePart1(std.testing.allocator, &test_input, 6);

    try std.testing.expectEqual(@as(u64, 16), result);
}
