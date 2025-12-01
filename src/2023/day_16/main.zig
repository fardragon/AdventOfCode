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

    return result;
}

const Direction = enum {
    up,
    down,
    left,
    right,
};

const BeamState = struct {
    position: usize,
    direction: Direction,
};

const BeamResult = common.Pair(?BeamState, ?BeamState);

fn moveUp(puzzle: Puzzle, current_state: BeamState) ?BeamState {
    const x = puzzle.mapToX(current_state.position);
    const y = puzzle.mapToY(current_state.position);

    if (y > 0) {
        return BeamState{
            .position = puzzle.mapToIndex(x, y - 1),
            .direction = .up,
        };
    } else {
        return null;
    }
}

fn moveDown(puzzle: Puzzle, current_state: BeamState) ?BeamState {
    const x = puzzle.mapToX(current_state.position);
    const y = puzzle.mapToY(current_state.position);

    if (y + 1 < puzzle.height) {
        return BeamState{
            .position = puzzle.mapToIndex(x, y + 1),
            .direction = .down,
        };
    } else {
        return null;
    }
}

fn moveRight(puzzle: Puzzle, current_state: BeamState) ?BeamState {
    const x = puzzle.mapToX(current_state.position);

    if (x + 1 < puzzle.width) {
        return BeamState{
            .position = current_state.position + 1,
            .direction = .right,
        };
    } else {
        return null;
    }
}

fn moveLeft(puzzle: Puzzle, current_state: BeamState) ?BeamState {
    const x = puzzle.mapToX(current_state.position);

    if (x > 0) {
        return BeamState{
            .position = current_state.position - 1,
            .direction = .left,
        };
    } else {
        return null;
    }
}

fn step(puzzle: Puzzle, current_state: BeamState) BeamResult {
    const current = puzzle.grid.items[current_state.position];
    var first_result: ?BeamState = null;
    var second_result: ?BeamState = null;

    switch (current) {
        '.' => {
            switch (current_state.direction) {
                .left => {
                    first_result = moveLeft(puzzle, current_state);
                },
                .right => {
                    first_result = moveRight(puzzle, current_state);
                },
                .up => {
                    first_result = moveUp(puzzle, current_state);
                },
                .down => {
                    first_result = moveDown(puzzle, current_state);
                },
            }
        },
        '|' => {
            switch (current_state.direction) {
                .left, .right => {
                    first_result = moveUp(puzzle, current_state);
                    second_result = moveDown(puzzle, current_state);
                },
                .up => {
                    first_result = moveUp(puzzle, current_state);
                },
                .down => {
                    first_result = moveDown(puzzle, current_state);
                },
            }
        },
        '-' => {
            switch (current_state.direction) {
                .left => {
                    first_result = moveLeft(puzzle, current_state);
                },
                .right => {
                    first_result = moveRight(puzzle, current_state);
                },
                .down, .up => {
                    first_result = moveLeft(puzzle, current_state);
                    second_result = moveRight(puzzle, current_state);
                },
            }
        },
        '\\' => {
            switch (current_state.direction) {
                .left => {
                    first_result = moveUp(puzzle, current_state);
                },
                .right => {
                    first_result = moveDown(puzzle, current_state);
                },
                .up => {
                    first_result = moveLeft(puzzle, current_state);
                },
                .down => {
                    first_result = moveRight(puzzle, current_state);
                },
            }
        },
        '/' => {
            switch (current_state.direction) {
                .left => {
                    first_result = moveDown(puzzle, current_state);
                },
                .right => {
                    first_result = moveUp(puzzle, current_state);
                },
                .up => {
                    first_result = moveRight(puzzle, current_state);
                },
                .down => {
                    first_result = moveLeft(puzzle, current_state);
                },
            }
        },
        else => unreachable,
    }

    return BeamResult{
        .first = first_result,
        .second = second_result,
    };
}

fn solve(allocator: std.mem.Allocator, puzzle: Puzzle, initial_beam: BeamState) !u64 {
    var beams = std.ArrayList(BeamState).empty;
    defer beams.deinit(allocator);

    try beams.append(allocator, initial_beam);

    var cache = std.AutoHashMap(BeamState, void).init(allocator);
    defer cache.deinit();

    while (true) {
        if (beams.items.len == 0) break;

        var new_beams = std.ArrayList(BeamState).empty;
        errdefer new_beams.deinit(allocator);

        for (beams.items) |beam| {
            if (cache.contains(beam)) {
                continue;
            } else {
                try cache.put(beam, {});
            }

            const result = step(puzzle, beam);

            if (result.first) |new_beam| {
                try new_beams.append(allocator, new_beam);
            }

            if (result.second) |new_beam| {
                try new_beams.append(allocator, new_beam);
            }
        }

        beams.deinit(allocator);
        beams = new_beams;
    }

    //calculate result
    var result_counter = std.AutoArrayHashMap(usize, void).init(allocator);
    defer result_counter.deinit();

    var cache_it = cache.keyIterator();

    while (cache_it.next()) |cache_entry| {
        try result_counter.put(cache_entry.position, {});
    }

    return result_counter.values().len;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    return solve(allocator, puzzle, BeamState{ .position = 0, .direction = .right });
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.deinit(allocator);

    var max_energy: u64 = 0;

    // left and right edges
    for (0..puzzle.height) |y| {
        const left_result = try solve(allocator, puzzle, BeamState{
            .position = puzzle.mapToIndex(0, y),
            .direction = .right,
        });

        const right_result = try solve(allocator, puzzle, BeamState{
            .position = puzzle.mapToIndex(puzzle.width - 1, y),
            .direction = .left,
        });

        max_energy = @max(max_energy, @max(left_result, right_result));
    }

    // top and bottom edges
    for (0..puzzle.width) |x| {
        const top_result = try solve(allocator, puzzle, BeamState{
            .position = puzzle.mapToIndex(x, 0),
            .direction = .down,
        });

        const bottom_result = try solve(allocator, puzzle, BeamState{
            .position = puzzle.mapToIndex(x, puzzle.height - 1),
            .direction = .up,
        });

        max_energy = @max(max_energy, @max(top_result, bottom_result));
    }

    return max_energy;
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
    const test_input = [_][]const u8{
        ".|...\\....",
        "|.-.\\.....",
        ".....|-...",
        "........|.",
        "..........",
        ".........\\",
        "..../.\\\\..",
        ".-.-/..|..",
        ".|....-|.\\",
        "..//.|....",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 46), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        ".|...\\....",
        "|.-.\\.....",
        ".....|-...",
        "........|.",
        "..........",
        ".........\\",
        "..../.\\\\..",
        ".-.-/..|..",
        ".|....-|.\\",
        "..//.|....",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 51), result);
}
