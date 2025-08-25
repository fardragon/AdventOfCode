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

        for (line) |c| {
            try data.append(allocator, c - '0');
        }
    }

    return Grid{
        .data = data,
        .height = input.len,
        .width = expected_width,
    };
}

fn checkTrail(grid: Grid, x: isize, y: isize, trails: *std.AutoHashMap(isize, u64)) !void {
    const current_elevation = grid.get(x, y).?;

    if (current_elevation == 9) {
        const put_result = try trails.getOrPut(try grid.mapToIndex(x, y));
        if (put_result.found_existing) {
            put_result.value_ptr.* += 1;
        } else {
            put_result.value_ptr.* = 1;
        }
    } else {
        const dirs: [4]struct { isize, isize } = .{
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, 0 },
            .{ -1, 0 },
        };

        for (dirs) |dir| {
            const x_diff, const y_diff = dir;
            if (grid.get(x + x_diff, y + y_diff)) |candidate| {
                if (candidate == current_elevation + 1) try checkTrail(grid, x + x_diff, y + y_diff, trails);
            }
        }
    }
}

fn checkTrailHead(allocator: std.mem.Allocator, grid: Grid, x: isize, y: isize) !std.AutoHashMap(isize, u64) {
    var trails = std.AutoHashMap(isize, u64).init(allocator);
    errdefer trails.deinit();

    try checkTrail(grid, x, y, &trails);

    return trails;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var trailheads: u64 = 0;

    var grid = try parseGrid(allocator, input);
    defer grid.data.deinit(allocator);

    for (0..grid.len()) |starting_point| {
        if (grid.data.items[starting_point] == 0) {
            const x, const y = try grid.mapToXY(@intCast(starting_point));
            var trails = try checkTrailHead(allocator, grid, x, y);
            defer trails.deinit();
            trailheads += @intCast(trails.count());
        }
    }

    return trailheads;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var distinctTrails: u64 = 0;

    var grid = try parseGrid(allocator, input);
    defer grid.data.deinit(allocator);

    for (0..grid.len()) |starting_point| {
        if (grid.data.items[starting_point] == 0) {
            const x, const y = try grid.mapToXY(@intCast(starting_point));
            var trails = try checkTrailHead(allocator, grid, x, y);
            defer trails.deinit();

            var ix = trails.valueIterator();

            while (ix.next()) |t| {
                distinctTrails += t.*;
            }
        }
    }

    return distinctTrails;
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

const test_input = [_][]const u8{
    "89010123",
    "78121874",
    "87430965",
    "96549874",
    "45678903",
    "32019012",
    "01329801",
    "10456732",
};

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart1(allocator, &test_input);
    try std.testing.expectEqual(@as(u64, 36), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const result = try solvePart2(allocator, &test_input);
    try std.testing.expectEqual(@as(u64, 81), result);
}
