const std = @import("std");
const common = @import("common");
const common_input = common.input;
const Grid = common.grid.Grid(u8);

fn parseGrid(allocator: std.mem.Allocator, input: []const []const u8) !Grid {
    const expected_width = input[0].len;

    var data = Grid.Container.empty;
    errdefer data.deinit(allocator);

    for (input) |line| {
        if (line.len != expected_width) return error.MalformedInput;

        try data.appendSlice(allocator, line);
    }

    return Grid{
        .data = data,
        .height = input.len,
        .width = expected_width,
    };
}

fn floodFill(allocator: std.mem.Allocator, grid: Grid, starting_field: isize) !struct { u64, u64, common.AutoHashSet(isize) } {
    var area: u64 = 0;
    var perimeter: u64 = 0;

    const plant = grid.data.items[@intCast(starting_field)];

    var fields_to_visit = common.AutoHashSet(isize).init(allocator);
    defer fields_to_visit.deinit();

    var garden_plots = common.AutoHashSet(isize).init(allocator);
    errdefer garden_plots.deinit();

    try fields_to_visit.put(starting_field);

    while (fields_to_visit.count() > 0) {
        const current_field_ix = ix: {
            var ix = fields_to_visit.iterator();
            break :ix ix.next().?.*;
        };

        _ = fields_to_visit.remove(current_field_ix);

        try garden_plots.put(current_field_ix);

        area += 1;

        const x, const y = try grid.mapToXY(current_field_ix);

        const dirs: [4]struct { isize, isize } = .{
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, 0 },
            .{ -1, 0 },
        };

        for (dirs) |dir| {
            const x_diff, const y_diff = dir;
            const x_new = x + x_diff;
            const y_new = y + y_diff;
            if (grid.get(x_new, y_new)) |candidate| {
                if (candidate == plant) {
                    const new_ix = try grid.mapToIndex(x_new, y_new);
                    if (!garden_plots.contains(new_ix)) {
                        try fields_to_visit.put(new_ix);
                    }
                } else {
                    perimeter += 1;
                }
            } else {
                perimeter += 1;
            }
        }
    }

    return .{ area, perimeter, garden_plots };
}

fn countCorners(grid: Grid, plots: common.AutoHashSet(isize)) u64 {
    var corners: u64 = 0;

    var plot_it = plots.iterator();

    while (plot_it.next()) |plot| {
        const x, const y = grid.mapToXY(plot.*) catch unreachable;

        const top = plots.contains(grid.mapToIndex(x, y - 1) catch -1);
        const bottom = plots.contains(grid.mapToIndex(x, y + 1) catch -1);

        const left = plots.contains(grid.mapToIndex(x - 1, y) catch -1);
        const right = plots.contains(grid.mapToIndex(x + 1, y) catch -1);

        if (!top) {
            if (!left) corners += 1;
            if (!right) corners += 1;
        }

        if (!bottom) {
            if (!left) corners += 1;
            if (!right) corners += 1;
        }

        if (top) {
            if (left) {
                if (!plots.contains(grid.mapToIndex(x - 1, y - 1) catch -1)) {
                    corners += 1;
                }
            }

            if (right) {
                if (!plots.contains(grid.mapToIndex(x + 1, y - 1) catch -1)) {
                    corners += 1;
                }
            }
        }

        if (bottom) {
            if (left) {
                if (!plots.contains(grid.mapToIndex(x - 1, y + 1) catch -1)) {
                    corners += 1;
                }
            }

            if (right) {
                if (!plots.contains(grid.mapToIndex(x + 1, y + 1) catch -1)) {
                    corners += 1;
                }
            }
        }
    }

    return corners;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var grid = try parseGrid(allocator, input);
    defer grid.data.deinit(allocator);

    var visited_fields = common.AutoHashSet(isize).init(allocator);
    defer visited_fields.deinit();

    var fence_cost: u64 = 0;

    for (0..grid.data.items.len) |ix| {
        if (visited_fields.contains(@intCast(ix))) continue;

        const area, const perimeter, var plots = try floodFill(allocator, grid, @intCast(ix));
        defer plots.deinit();
        try visited_fields.merge_from(plots);

        fence_cost += (area * perimeter);
    }

    return fence_cost;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var grid = try parseGrid(allocator, input);
    defer grid.data.deinit(allocator);

    var visited_fields = common.AutoHashSet(isize).init(allocator);
    defer visited_fields.deinit();

    var fence_cost: u64 = 0;

    for (0..grid.data.items.len) |ix| {
        if (visited_fields.contains(@intCast(ix))) continue;

        const area, _, var plots = try floodFill(allocator, grid, @intCast(ix));
        defer plots.deinit();
        try visited_fields.merge_from(plots);

        const corners = countCorners(grid, plots);
        fence_cost += (area * corners);
    }

    return fence_cost;
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

test "solve part 1a test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "AAAA",
        "BBCD",
        "BBCC",
        "EEEC",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 140), result);
}

test "solve part 1b test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "OOOOO",
        "OXOXO",
        "OOOOO",
        "OXOXO",
        "OOOOO",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 772), result);
}

test "solve part 1c test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "RRRRIICCFF",
        "RRRRIICCCF",
        "VVRRRCCFFF",
        "VVRCCCJFFF",
        "VVVVCJJCFE",
        "VVIVCCJJEE",
        "VVIIICJJEE",
        "MIIIIIJJEE",
        "MIIISIJEEE",
        "MMMISSJEEE",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 1930), result);
}

test "solve part 2a test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "AAAA",
        "BBCD",
        "BBCC",
        "EEEC",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 80), result);
}

test "solve part 2b test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "EEEEE",
        "EXXXX",
        "EEEEE",
        "EXXXX",
        "EEEEE",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 236), result);
}

test "solve part 2c test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "AAAAAA",
        "AAABBA",
        "AAABBA",
        "ABBAAA",
        "ABBAAA",
        "AAAAAA",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 368), result);
}

test "solve part 2d test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "RRRRIICCFF",
        "RRRRIICCCF",
        "VVRRRCCFFF",
        "VVRCCCJFFF",
        "VVVVCJJCFE",
        "VVIVCCJJEE",
        "VVIIICJJEE",
        "MIIIIIJJEE",
        "MIIISIJEEE",
        "MMMISSJEEE",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 1206), result);
}
