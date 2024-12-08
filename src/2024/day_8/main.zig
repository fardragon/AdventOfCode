const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Field = union(enum) {
    Empty: void,
    Antenna: u8,
};

const Grid = common.grid.Grid(Field);

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !Grid {
    const expected_width = input[0].len;

    var data = Grid.Container.init(allocator);
    errdefer data.deinit();

    for (input) |line| {
        if (line.len != expected_width) return error.MalformedInput;

        for (line) |char| {
            switch (char) {
                '.' => try data.append(Field.Empty),
                else => try data.append(Field{ .Antenna = char }),
            }
        }
    }

    return Grid{
        .data = data,
        .height = input.len,
        .width = expected_width,
    };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const map = try parseMap(allocator, input);
    defer map.data.deinit();

    var antinodes = std.AutoHashMap(isize, void).init(allocator);
    defer antinodes.deinit();

    for (map.data.items, 0..) |first_antenna, first_antenna_ix| {
        switch (first_antenna) {
            Field.Empty => continue,
            Field.Antenna => |first_freq| {
                for (map.data.items, 0..) |second_antenna, second_antenna_ix| {
                    if (first_antenna_ix == second_antenna_ix) continue;
                    switch (second_antenna) {
                        Field.Empty => continue,
                        Field.Antenna => |second_freq| {
                            if (first_freq == second_freq) {
                                const x1, const y1 = try map.mapToXY(@intCast(first_antenna_ix));
                                const xm, const ym = try map.mapToXY(@intCast(second_antenna_ix));

                                const x2 = 2 * xm - x1;
                                const y2 = 2 * ym - y1;

                                if (map.mapToIndex(x2, y2)) |antinode_ix| {
                                    try antinodes.put(antinode_ix, {});
                                } else |err| {
                                    switch (err) {
                                        error.OutOfBounds => continue,
                                        else => return err,
                                    }
                                }
                            }
                        },
                    }
                }
            },
        }
    }

    return antinodes.count();
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const map = try parseMap(allocator, input);
    defer map.data.deinit();

    var antinodes = std.AutoHashMap(isize, void).init(allocator);
    defer antinodes.deinit();

    for (map.data.items, 0..) |first_antenna, first_antenna_ix| {
        switch (first_antenna) {
            Field.Empty => continue,
            Field.Antenna => |first_freq| {
                for (map.data.items, 0..) |second_antenna, second_antenna_ix| {
                    if (first_antenna_ix == second_antenna_ix) continue;
                    switch (second_antenna) {
                        Field.Empty => continue,
                        Field.Antenna => |second_freq| {
                            if (first_freq == second_freq) {
                                const x1, const y1 = try map.mapToXY(@intCast(first_antenna_ix));
                                const xm, const ym = try map.mapToXY(@intCast(second_antenna_ix));

                                const x2 = 2 * xm - x1;
                                const y2 = 2 * ym - y1;

                                const xdiff = x2 - xm;
                                const ydiff = y2 - ym;

                                var xpos = xm;
                                var ypos = ym;

                                while (true) {
                                    if (map.mapToIndex(xpos, ypos)) |antinode_ix| {
                                        try antinodes.put(antinode_ix, {});
                                    } else |err| {
                                        switch (err) {
                                            error.OutOfBounds => break,
                                            else => return err,
                                        }
                                    }

                                    xpos += xdiff;
                                    ypos += ydiff;
                                }
                            }
                        },
                    }
                }
            },
        }
    }

    return antinodes.count();
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

test "solve part 1a test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "..........",
        "..........",
        "..........",
        "....a.....",
        "..........",
        ".....a....",
        "..........",
        "..........",
        "..........",
        "..........",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2), result);
}

test "solve part 1b test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "..........",
        "..........",
        "..........",
        "....a.....",
        "........a.",
        ".....a....",
        "..........",
        "..........",
        "..........",
        "..........",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 4), result);
}

test "solve part 1c test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "............",
        "........0...",
        ".....0......",
        ".......0....",
        "....0.......",
        "......A.....",
        "............",
        "............",
        "........A...",
        ".........A..",
        "............",
        "............",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 14), result);
}

test "solve part 2a test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "T.........",
        "...T......",
        ".T........",
        "..........",
        "..........",
        "..........",
        "..........",
        "..........",
        "..........",
        "..........",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 9), result);
}

test "solve part 2b test" {
    const allocator = std.testing.allocator;

    const test_input = [_][]const u8{
        "............",
        "........0...",
        ".....0......",
        ".......0....",
        "....0.......",
        "......A.....",
        "............",
        "............",
        "........A...",
        ".........A..",
        "............",
        "............",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 34), result);
}

test "solve part 2 test" {}
