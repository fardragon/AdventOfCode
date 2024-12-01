const std = @import("std");
const common_input = @import("common").input;

const Pattern = struct {
    map: std.ArrayList(u8),
    columns: usize,
    rows: usize,

    fn mapToX(self: Pattern, index: usize) usize {
        return index % self.columns;
    }

    fn mapToY(self: Pattern, index: usize) usize {
        return index / self.columns;
    }

    fn mapToIndex(self: Pattern, x: usize, y: usize) usize {
        return y * self.columns + x;
    }

    fn deinit(self: *Pattern) void {
        self.map.deinit();
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Pattern) {
    var result = std.ArrayList(Pattern).init(allocator);
    errdefer {
        for (result.items) |*pattern| {
            pattern.deinit();
        }
        result.deinit();
    }

    var current_pattern: ?Pattern = null;
    errdefer {
        if (current_pattern) |*pattern| {
            pattern.deinit();
        }
    }

    for (input) |line| {
        if (current_pattern) |*pattern| {
            if (line.len > 0) {
                if (line.len != pattern.columns) unreachable;
                try pattern.map.appendSlice(line);
                pattern.rows += 1;
            } else {
                try result.append(pattern.*);
                current_pattern = null;
            }
        } else {
            if (line.len == 0) unreachable;
            current_pattern = Pattern{
                .map = std.ArrayList(u8).init(allocator),
                .columns = line.len,
                .rows = 0,
            };
            try current_pattern.?.map.appendSlice(line);
            current_pattern.?.rows += 1;
        }
    }

    // append last pattern
    try result.append(current_pattern.?);

    return result;
}

fn solvePattern(pattern: Pattern, fix_smudge: bool) !u64 {

    // check vertical symmetry lines
    for (1..pattern.columns) |first_right_column| {
        const left_columns = first_right_column;
        const right_columns = pattern.columns - left_columns;
        const columns_to_compare = @min(left_columns, right_columns);

        var left = left_columns - 1;
        var right = left_columns;

        var diffs: u64 = 0;
        for (0..columns_to_compare) |_| {
            for (0..pattern.rows) |y| {
                const l_index = pattern.mapToIndex(left, y);
                const r_index = pattern.mapToIndex(right, y);

                if (pattern.map.items[l_index] != pattern.map.items[r_index]) {
                    diffs += 1;
                }
            }
            left = if (left == 0) 0 else left - 1;
            right += 1;
        }

        if ((diffs == 0 and !fix_smudge) or (diffs == 1 and fix_smudge)) return left_columns;
    }

    // check horizontal symmetry lines
    for (1..pattern.rows) |first_bottom| {
        const top_rows = first_bottom;
        const bottom_rows = pattern.rows - first_bottom;
        const rows_to_compare = @min(bottom_rows, top_rows);

        var top = top_rows - 1;
        var bottom = top_rows;

        var diffs: u64 = 0;
        for (0..rows_to_compare) |_| {
            for (0..pattern.columns) |x| {
                const t_index = pattern.mapToIndex(x, top);
                const b_index = pattern.mapToIndex(x, bottom);

                if (pattern.map.items[t_index] != pattern.map.items[b_index]) {
                    diffs += 1;
                }
            }
            top = if (top == 0) 0 else top - 1;
            bottom += 1;
        }

        if ((diffs == 0 and !fix_smudge) or (diffs == 1 and fix_smudge)) return 100 * top_rows;
    }

    return error.NotSolvable;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var patterns = try parseInput(allocator, input);
    defer {
        for (patterns.items) |*pattern| {
            pattern.deinit();
        }
        patterns.deinit();
    }

    var result: u64 = 0;

    for (patterns.items) |pattern| {
        result += try solvePattern(pattern, false);
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var patterns = try parseInput(allocator, input);
    defer {
        for (patterns.items) |*pattern| {
            pattern.deinit();
        }
        patterns.deinit();
    }

    var result: u64 = 0;

    for (patterns.items) |pattern| {
        result += try solvePattern(pattern, true);
    }

    return result;
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
    const test_input = [_][]const u8{
        "#.##..##.",
        "..#.##.#.",
        "##......#",
        "##......#",
        "..#.##.#.",
        "..##..##.",
        "#.#.##.#.",
        "",
        "#...##..#",
        "#....#..#",
        "..##..###",
        "#####.##.",
        "#####.##.",
        "..##..###",
        "#....#..#",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 405), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "#.##..##.",
        "..#.##.#.",
        "##......#",
        "##......#",
        "..#.##.#.",
        "..##..##.",
        "#.#.##.#.",
        "",
        "#...##..#",
        "#....#..#",
        "..##..###",
        "#####.##.",
        "#####.##.",
        "..##..###",
        "#....#..#",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 400), result);
}
