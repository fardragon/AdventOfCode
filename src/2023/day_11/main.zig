const std = @import("std");
const common = @import("common");
const Point = common.Pair(i64, i64);
const GalaxyPair = common.Pair(i64, i64);

const GalaxyMap = struct {
    map: std.ArrayList(u8),
    width: usize,
    height: usize,

    fn mapToX(self: GalaxyMap, index: usize) usize {
        return index % self.width;
    }

    fn mapToY(self: GalaxyMap, index: usize) usize {
        return index / self.width;
    }

    fn mapToIndex(self: GalaxyMap, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn getGalaxies(self: GalaxyMap, allocator: std.mem.Allocator) !std.AutoArrayHashMap(i64, Point) {
        var result = std.AutoArrayHashMap(i64, Point).init(allocator);
        errdefer result.deinit();

        var galaxy_index: i64 = 1;
        for (self.map.items, 0..) |map_item, index| {
            if (map_item == '#') {
                try result.put(galaxy_index, Point{ .first = @intCast(self.mapToX(index)), .second = @intCast(self.mapToY(index)) });
                galaxy_index += 1;
            }
        }

        return result;
    }

    fn getEmptyColumns(self: GalaxyMap, allocator: std.mem.Allocator) !std.AutoHashMap(i64, void) {
        var result = std.AutoHashMap(i64, void).init(allocator);
        errdefer result.deinit();

        for (0..self.width) |column| {
            var is_empty = true;

            for (0..self.height) |row| {
                if (self.map.items[self.mapToIndex(column, row)] != '.') {
                    is_empty = false;
                    break;
                }
            }

            if (is_empty) {
                try result.put(@as(i64, @intCast(column)), {});
            }
        }
        return result;
    }

    fn getEmptyRows(self: GalaxyMap, allocator: std.mem.Allocator) !std.AutoHashMap(i64, void) {
        var result = std.AutoHashMap(i64, void).init(allocator);
        errdefer result.deinit();

        for (0..self.height) |row| {
            var is_empty = true;

            for (0..self.width) |column| {
                if (self.map.items[self.mapToIndex(column, row)] != '.') {
                    is_empty = false;
                    break;
                }
            }

            if (is_empty) {
                try result.put(@as(i64, @intCast(row)), {});
            }
        }
        return result;
    }

    fn deinit(self: *GalaxyMap, allocator: std.mem.Allocator) void {
        self.map.deinit(allocator);
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !GalaxyMap {
    var result = GalaxyMap{
        .map = std.ArrayList(u8).empty,
        .width = input[0].len,
        .height = input.len,
    };

    errdefer result.deinit(allocator);

    for (input) |line| {
        try result.map.appendSlice(allocator, line);
    }

    return result;
}

fn solve(allocator: std.mem.Allocator, input: []const []const u8, expansion_coefficient: u64) !u64 {
    var galaxy_map = try parseInput(allocator, input);
    defer galaxy_map.deinit(allocator);

    var galaxies = try galaxy_map.getGalaxies(allocator);
    defer galaxies.deinit();

    // generate galaxy pairs
    var pairs = std.ArrayList(GalaxyPair).empty;
    defer pairs.deinit(allocator);

    for (galaxies.keys(), 0..) |source_galaxy, source_galaxy_ix| {
        for (source_galaxy_ix..galaxies.keys().len) |target_galaxy_ix| {
            if (source_galaxy_ix == target_galaxy_ix) continue;
            try pairs.append(
                allocator,
                GalaxyPair{
                    .first = source_galaxy,
                    .second = galaxies.keys()[target_galaxy_ix],
                },
            );
        }
    }

    var empty_columns = try galaxy_map.getEmptyColumns(allocator);
    defer empty_columns.deinit();

    var empty_rows = try galaxy_map.getEmptyRows(allocator);
    defer empty_rows.deinit();

    var result: u64 = 0;

    for (pairs.items) |galaxy_pair| {
        const source_position = galaxies.get(galaxy_pair.first).?;
        const destination_position = galaxies.get(galaxy_pair.second).?;

        const vertical_direction: i8 = if (destination_position.second > source_position.second) 1 else -1;
        const horizontal_direction: i8 = if (destination_position.first > source_position.first) 1 else -1;

        var current_position = source_position;

        var vertical_distance: u64 = 0;
        var horizontal_distance: u64 = 0;

        while (current_position.first != destination_position.first) {
            current_position.first += horizontal_direction;
            if (empty_columns.contains(current_position.first)) {
                horizontal_distance += expansion_coefficient;
            } else {
                horizontal_distance += 1;
            }
        }

        while (current_position.second != destination_position.second) {
            current_position.second += vertical_direction;

            if (empty_rows.contains(current_position.second)) {
                vertical_distance += expansion_coefficient;
            } else {
                vertical_distance += 1;
            }
        }
        result += (horizontal_distance + vertical_distance);
    }

    return result;
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    var allocator = gpa.allocator();

    defer _ = gpa.deinit();

    var input = try common.input.readFileInput(allocator, "input.txt");
    defer {
        for (input.items) |item| {
            allocator.free(item);
        }
        input.deinit(allocator);
    }

    std.debug.print("Part 1 solution: {d}\n", .{try solve(allocator, input.items, 2)});
    std.debug.print("Part 2 solution: {d}\n", .{try solve(allocator, input.items, 1000000)});
}

test "solve part 1" {
    const test_input = [_][]const u8{
        "...#......",
        ".......#..",
        "#.........",
        "..........",
        "......#...",
        ".#........",
        ".........#",
        "..........",
        ".......#..",
        "#...#.....",
    };

    const result = try solve(std.testing.allocator, &test_input, 2);

    try std.testing.expectEqual(@as(u64, 374), result);
}

test "solve part 2 a" {
    const test_input = [_][]const u8{
        "...#......",
        ".......#..",
        "#.........",
        "..........",
        "......#...",
        ".#........",
        ".........#",
        "..........",
        ".......#..",
        "#...#.....",
    };

    const result = try solve(std.testing.allocator, &test_input, 10);

    try std.testing.expectEqual(@as(u64, 1030), result);
}

test "solve part 2 b" {
    const test_input = [_][]const u8{
        "...#......",
        ".......#..",
        "#.........",
        "..........",
        "......#...",
        ".#........",
        ".........#",
        "..........",
        ".......#..",
        "#...#.....",
    };

    const result = try solve(std.testing.allocator, &test_input, 100);

    try std.testing.expectEqual(@as(u64, 8410), result);
}
