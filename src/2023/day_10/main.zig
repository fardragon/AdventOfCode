const std = @import("std");
const common_input = @import("common").input;

const Puzzle = struct {
    pipes: std.ArrayList(u8),
    width: usize,
    height: usize,
    starting_point: usize,

    fn mapToX(self: Puzzle, index: usize) usize {
        return index % self.width;
    }

    fn mapToY(self: Puzzle, index: usize) usize {
        return index / self.width;
    }

    fn mapToIndex(self: Puzzle, x: usize, y: usize) usize {
        return y * self.width + x;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !Puzzle {
    var result = Puzzle{
        .pipes = std.ArrayList(u8).empty,
        .width = input[0].len,
        .height = input.len,
        .starting_point = undefined,
    };

    errdefer result.pipes.deinit(allocator);

    for (input) |line| {
        try result.pipes.appendSlice(allocator, line);
    }

    // find and replace starting position
    for (result.pipes.items, 0..) |pipe, ix| {
        if (pipe == 'S') {
            result.starting_point = ix;
            break;
        }
    }

    const startX = result.mapToX(result.starting_point);
    const startY = result.mapToY(result.starting_point);

    var left = false;
    var right = false;
    var up = false;
    var down = false;

    if (startX > 0) {
        const left_neighbour = result.pipes.items[result.mapToIndex(startX - 1, startY)];
        left = (left_neighbour == '-' or left_neighbour == 'L' or left_neighbour == 'F');
    }

    if (startX < result.width - 2) {
        const right_neighbour = result.pipes.items[result.mapToIndex(startX + 1, startY)];
        right = (right_neighbour == '-' or right_neighbour == '7' or right_neighbour == 'J');
    }

    if (startY > 0) {
        const up_neighbour = result.pipes.items[result.mapToIndex(startX, startY - 1)];
        up = (up_neighbour == '|' or up_neighbour == '7' or up_neighbour == 'F');
    }

    if (startY < result.height - 2) {
        const down_neighbour = result.pipes.items[result.mapToIndex(startX, startY + 1)];
        down = (down_neighbour == '|' or down_neighbour == 'L' or down_neighbour == 'J');
    }

    if ((@as(u8, @intFromBool(left)) + @intFromBool(right) + @intFromBool(up) + @intFromBool(down)) == 2) {
        if (up and down) {
            result.pipes.items[result.starting_point] = '|';
        } else if (right and left) {
            result.pipes.items[result.starting_point] = '-';
        } else if (up and right) {
            result.pipes.items[result.starting_point] = 'L';
        } else if (up and left) {
            result.pipes.items[result.starting_point] = 'J';
        } else if (down and left) {
            result.pipes.items[result.starting_point] = '7';
        } else if (down and right) {
            result.pipes.items[result.starting_point] = 'F';
        } else {
            unreachable;
        }
    } else {
        unreachable;
    }

    return result;
}

const Direction = enum {
    up,
    down,
    left,
    right,
};

fn pickStartingDirection(puzzle: Puzzle) Direction {
    const starting_pipe = puzzle.pipes.items[puzzle.starting_point];
    if (starting_pipe == '|' or starting_pipe == '7' or starting_pipe == 'F') {
        return .up;
    } else if (starting_pipe == '-' or starting_pipe == 'J') {
        return .right;
    } else if (starting_pipe == 'L') {
        return .left;
    } else {
        unreachable;
    }
}

const StepResult = struct {
    new_position: usize,
    new_direction: Direction,
};

fn step(puzzle: Puzzle, position: usize, direction: Direction) StepResult {
    var new_direction = direction;
    switch (puzzle.pipes.items[position]) {
        '|' => {},
        '-' => {},
        '7' => {
            if (direction == .up) {
                new_direction = .left;
            } else if (direction == .right) {
                new_direction = .down;
            }
        },
        'F' => {
            if (direction == .up) {
                new_direction = .right;
            } else if (direction == .left) {
                new_direction = .down;
            }
        },
        'J' => {
            if (direction == .down) {
                new_direction = .left;
            } else if (direction == .right) {
                new_direction = .up;
            }
        },
        'L' => {
            if (direction == .down) {
                new_direction = .right;
            } else if (direction == .left) {
                new_direction = .up;
            }
        },
        else => unreachable,
    }

    const new_position = switch (new_direction) {
        .down => position + puzzle.width,
        .up => position - puzzle.width,
        .left => position - 1,
        .right => position + 1,
    };

    return StepResult{ .new_position = new_position, .new_direction = new_direction };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.pipes.deinit(allocator);

    var steps: u64 = 0;

    // pick starting direction
    var direction = pickStartingDirection(puzzle);
    var position = puzzle.starting_point;

    while (true) {
        const step_result = step(puzzle, position, direction);

        position = step_result.new_position;
        direction = step_result.new_direction;

        steps += 1;
        if (position == puzzle.starting_point) break;
    }

    return steps / 2;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var puzzle = try parseInput(allocator, input);
    defer puzzle.pipes.deinit(allocator);

    // pick starting direction
    var direction = pickStartingDirection(puzzle);
    var position = puzzle.starting_point;

    var mainLoopPipes = std.AutoHashMap(usize, void).init(allocator);
    defer mainLoopPipes.deinit();

    // walk the main loop to get its points
    while (true) {
        const step_result = step(puzzle, position, direction);

        position = step_result.new_position;
        direction = step_result.new_direction;

        try mainLoopPipes.put(position, {});
        if (position == puzzle.starting_point) break;
    }

    // walk the map from left to right counting walls that belong to the main loop
    var enclosed_tiles: usize = 0;
    for (0..puzzle.height) |y| {
        var enclosed = false;
        var wall_count: usize = 0;
        var previous_symbol: u8 = ' ';
        for (0..puzzle.width) |x| {
            const current_position = puzzle.mapToIndex(x, y);

            const is_part_of_main_loop = mainLoopPipes.contains(current_position);
            const current_symbol = puzzle.pipes.items[current_position];

            if (is_part_of_main_loop and current_symbol != '-') {
                wall_count += 1;

                if ((current_symbol == 'J' and previous_symbol == 'F') or (current_symbol == '7' and previous_symbol == 'L')) {
                    wall_count -= 1;
                }
                previous_symbol = current_symbol;

                enclosed = (wall_count % 2 == 1);
            }

            if (enclosed and !is_part_of_main_loop) {
                enclosed_tiles += 1;
            }
        }
    }

    return enclosed_tiles;
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
        ".....",
        ".S-7.",
        ".|.|.",
        ".L-J.",
        ".....",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4), result);
}

test "solve part 1 test 2" {
    const test_input = [_][]const u8{
        "..F7.",
        ".FJ|.",
        "SJ.L7",
        "|F--J",
        "LJ...",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 8), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "...........",
        ".S-------7.",
        ".|F-----7|.",
        ".||.....||.",
        ".||.....||.",
        ".|L-7.F-J|.",
        ".|..|.|..|.",
        ".L--J.L--J.",
        "...........",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4), result);
}

test "solve part 2 test 2" {
    const test_input = [_][]const u8{
        "..........",
        ".S------7.",
        ".|F----7|.",
        ".||....||.",
        ".||....||.",
        ".|L-7F-J|.",
        ".|..||..|.",
        ".L--JL--J.",
        "..........",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4), result);
}

test "solve part 2 test 3" {
    const test_input = [_][]const u8{
        ".F----7F7F7F7F-7....",
        ".|F--7||||||||FJ....",
        ".||.FJ||||||||L7....",
        "FJL7L7LJLJ||LJ.L-7..",
        "L--J.L7...LJS7F-7L7.",
        "....F-J..F7FJ|L7L7L7",
        "....L7.F7||L7|.L7L7|",
        ".....|FJLJ|FJ|F7|.LJ",
        "....FJL-7.||.||||...",
        "....L---J.LJ.LJLJ...",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 8), result);
}

test "solve part 2 test 4" {
    const test_input = [_][]const u8{
        "FF7FSF7F7F7F7F7F---7",
        "L|LJ||||||||||||F--J",
        "FL-7LJLJ||||||LJL-77",
        "F--JF--7||LJLJ7F7FJ-",
        "L---JF-JLJ.||-FJLJJ7",
        "|F|F-JF---7F7-L7L|7|",
        "|FFJF7L7F-JF7|JL---7",
        "7-L-JL7||F7|L7F-7F7|",
        "L.L7LFJ|||||FJL7||LJ",
        "L7JLJL-JLJLJL--JLJ.L",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 10), result);
}
