const std = @import("std");
const common = @import("common");
const common_input = common.input;
const Grid = common.grid.Grid(u8);

fn parseGrid(allocator: std.mem.Allocator, input: []const []const u8) !Grid {
    const expected_width = input[0].len;

    var data = Grid.Container.init(allocator);
    errdefer data.deinit();

    for (input) |line| {
        if (line.len != expected_width) return error.MalformedInput;

        try data.appendSlice(line);
    }

    return Grid{
        .data = data,
        .height = input.len,
        .width = expected_width,
    };
}

fn checkXMAS(grid: Grid, starting_point: isize, x_dir: i8, y_dir: i8) !bool {
    const xmas = "XMAS";
    var expected_ix: usize = 0;

    var x_pos = try grid.mapToX(starting_point);
    var y_pos = try grid.mapToY(starting_point);

    while (true) {
        if (grid.get(x_pos, y_pos)) |val| {
            if (val != xmas[expected_ix]) break;
            expected_ix += 1;
        } else {
            break;
        }

        if (expected_ix == xmas.len) return true;

        x_pos += x_dir;
        y_pos += y_dir;
    }

    return false;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var xmas_count: u64 = 0;

    const grid = try parseGrid(allocator, input);
    defer grid.data.deinit();

    const directions: [3]i8 = .{ -1, 0, 1 };

    for (0..grid.len()) |starting_point| {
        for (directions) |x_dir| {
            for (directions) |y_dir| {
                if (x_dir == 0 and y_dir == 0) continue;
                if (try checkXMAS(grid, @intCast(starting_point), x_dir, y_dir)) xmas_count += 1;
            }
        }
    }

    return xmas_count;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var xmas_count: u64 = 0;

    const grid = try parseGrid(allocator, input);
    defer grid.data.deinit();

    for (0..grid.len()) |starting_point| {
        if (grid.data.items[starting_point] == 'A') {
            const x_pos = try grid.mapToX(@intCast(starting_point));
            const y_pos = try grid.mapToY(@intCast(starting_point));

            const top_left = grid.get(x_pos - 1, y_pos - 1);
            const top_right = grid.get(x_pos + 1, y_pos - 1);
            const bottom_left = grid.get(x_pos - 1, y_pos + 1);
            const bottom_right = grid.get(x_pos + 1, y_pos + 1);

            if (top_left == null or top_right == null or bottom_left == null or bottom_right == null) continue;

            if (((top_left.? == 'M' and bottom_right.? == 'S') or (top_left.? == 'S' and bottom_right.? == 'M')) and ((top_right.? == 'M' and bottom_left.? == 'S') or (top_right.? == 'S' and bottom_left.? == 'M'))) {
                xmas_count += 1;
            }
        }
    }

    return xmas_count;
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

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 18), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 9), result);
}
