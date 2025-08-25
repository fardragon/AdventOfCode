const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Puzzle = struct {
    grid: std.ArrayList(u8),
    width: usize,
    height: usize,

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
    };

    errdefer result.deinit(allocator);

    for (input) |line| {
        try result.grid.appendSlice(allocator, line);
    }

    for (result.grid.items) |*item| {
        item.* = try std.fmt.parseInt(u8, &.{item.*}, 10);
    }

    return result;
}

const Direction = enum {
    up,
    down,
    left,
    right,

    fn cw(self: Direction) Direction {
        return switch (self) {
            .up => .right,
            .right => .down,
            .down => .left,
            .left => .up,
        };
    }

    fn ccw(self: Direction) Direction {
        return switch (self) {
            .up => .left,
            .left => .down,
            .down => .right,
            .right => .up,
        };
    }
};

const Position = common.Pair(usize, usize);

const State = struct {
    pos: Position,
    dir: Direction,
    steps: usize,
    hasTurned: bool,
};

const StateLoss = struct {
    state: State,
    loss: u64,

    fn lessThanOrder(_: void, a: StateLoss, b: StateLoss) std.math.Order {
        return std.math.order(a.loss, b.loss);
    }
};

fn nextStates(allocator: std.mem.Allocator, state: State, puzzle: Puzzle, min_straight: u64, max_straight: u64) !std.ArrayList(State) {
    var result = std.ArrayList(State).empty;
    errdefer result.deinit(allocator);

    const pos = state.pos;
    var dir = state.dir;

    if (!state.hasTurned and state.steps >= min_straight) {
        try result.append(allocator, State{ .pos = pos, .dir = dir.cw(), .steps = 0, .hasTurned = true });
        try result.append(allocator, State{ .pos = pos, .dir = dir.ccw(), .steps = 0, .hasTurned = true });
    }
    if (state.steps < max_straight) {
        const new_pos: ?Position = switch (dir) {
            .down => if (pos.second < puzzle.height - 1) Position{ .first = pos.first, .second = pos.second + 1 } else null,
            .up => if (pos.second > 0) Position{ .first = pos.first, .second = pos.second - 1 } else null,
            .left => if (pos.first > 0) Position{ .first = pos.first - 1, .second = pos.second } else null,
            .right => if (pos.first < puzzle.width - 1) Position{ .first = pos.first + 1, .second = pos.second } else null,
        };

        if (new_pos) |np| {
            try result.append(
                allocator,
                State{
                    .pos = np,
                    .dir = dir,
                    .steps = state.steps + 1,
                    .hasTurned = false,
                },
            );
        }
    }

    return result;
}

fn solve(allocator: std.mem.Allocator, puzzle: Puzzle, min_straight: u64, max_straight: u64) !u64 {
    var seen = std.AutoHashMap(State, u64).init(allocator);
    defer seen.deinit();

    var fringe = std.PriorityQueue(StateLoss, void, StateLoss.lessThanOrder).init(allocator, {});
    defer fringe.deinit();

    try fringe.add(StateLoss{ .loss = 0, .state = State{
        .pos = Position{ .first = 0, .second = 0 },
        .dir = .right,
        .steps = 0,
        .hasTurned = false,
    } });

    while (fringe.removeOrNull()) |stateLoss| {
        if (seen.get(stateLoss.state)) |loss| {
            if (loss <= stateLoss.loss) {
                continue;
            }
        }

        const pos = stateLoss.state.pos;
        if (pos.first == (puzzle.width - 1) and pos.second == (puzzle.height - 1) and stateLoss.state.steps >= min_straight) {
            return stateLoss.loss;
        }

        try seen.put(stateLoss.state, stateLoss.loss);

        var nexts = try nextStates(allocator, stateLoss.state, puzzle, min_straight, max_straight);
        defer nexts.deinit(allocator);
        for (nexts.items) |state| {
            const loss = puzzle.grid.items[puzzle.mapToIndex(state.pos.first, state.pos.second)];
            const nextLoss = stateLoss.loss + if (state.hasTurned) 0 else loss;
            try fringe.add(StateLoss{ .state = state, .loss = nextLoss });
        }
    }
    unreachable;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    return solve(allocator, puzzle, 0, 3);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    return solve(allocator, puzzle, 4, 10);
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
        "2413432311323",
        "3215453535623",
        "3255245654254",
        "3446585845452",
        "4546657867536",
        "1438598798454",
        "4457876987766",
        "3637877979653",
        "4654967986887",
        "4564679986453",
        "1224686865563",
        "2546548887735",
        "4322674655533",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 102), result);
}

test "solve part 2 test A" {
    const test_input = [_][]const u8{
        "2413432311323",
        "3215453535623",
        "3255245654254",
        "3446585845452",
        "4546657867536",
        "1438598798454",
        "4457876987766",
        "3637877979653",
        "4654967986887",
        "4564679986453",
        "1224686865563",
        "2546548887735",
        "4322674655533",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 94), result);
}

test "solve part 2 test B" {
    const test_input = [_][]const u8{
        "111111111111",
        "999999999991",
        "999999999991",
        "999999999991",
        "999999999991",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 71), result);
}
