const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Map = common.grid.Grid(u8);

fn parseMap(allocator: std.mem.Allocator, input: []const []const u8) !struct { Map, isize } {
    var map: Map = Map{
        .data = try .initCapacity(allocator, input.len * input[0].len),
        .width = input[0].len,
        .height = input.len,
    };
    errdefer map.data.deinit(allocator);

    for (input) |line| {
        map.data.appendSliceAssumeCapacity(line);
    }

    const starting_position = std.mem.indexOfScalar(u8, input[0], 'S') orelse return error.MalformedInput;
    map.data.items[starting_position] = '.';

    return .{ map, @as(isize, @intCast(starting_position)) };
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map, const starting_position = try parseMap(allocator, input);
    defer map.data.deinit(allocator);

    var currentBeams: std.ArrayList(isize) = try .initCapacity(allocator, map.width);
    defer currentBeams.deinit(allocator);
    var nextBeams: common.AutoHashSet(isize) = .init(allocator);
    defer nextBeams.deinit();

    currentBeams.appendAssumeCapacity(starting_position);

    var row: isize = 0;
    var splits: usize = 0;
    while (row < map.height - 1) : (row += 1) {
        for (currentBeams.items) |beam_pos| {
            const below_pos = try map.mapToIndex(beam_pos, row + 1);
            switch (map.data.items[@intCast(below_pos)]) {
                '.' => {
                    try nextBeams.put(beam_pos);
                },
                '^' => {
                    const left_beam = beam_pos - 1;
                    const right_beam = beam_pos + 1;
                    if (left_beam < 0 or left_beam >= map.width or right_beam < 0 or right_beam >= map.width) {
                        return error.MalformedInput;
                    }
                    try nextBeams.put(left_beam);
                    try nextBeams.put(right_beam);
                    splits += 1;
                },
                else => return error.MalformedInput,
            }
        }
        currentBeams.clearRetainingCapacity();
        var it = nextBeams.iterator();
        while (it.next()) |val| {
            currentBeams.appendAssumeCapacity(val.*);
        }
        nextBeams.clearRetainingCapacity();
    }

    return splits;
}

fn addBeam(allocator: std.mem.Allocator, beams: *std.AutoHashMapUnmanaged(isize, usize), position: isize, power: usize) !void {
    const entry = try beams.getOrPut(allocator, position);
    if (entry.found_existing) {
        entry.value_ptr.* += power;
    } else {
        entry.value_ptr.* = power;
    }
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var map, const starting_position = try parseMap(allocator, input);
    defer map.data.deinit(allocator);

    var currentBeams: std.ArrayList(struct { isize, usize }) = .empty;
    defer currentBeams.deinit(allocator);
    var nextBeams: std.AutoHashMapUnmanaged(isize, usize) = .empty;
    defer nextBeams.deinit(allocator);

    try currentBeams.append(allocator, .{ starting_position, 1 });

    var row: isize = 0;
    while (row < map.height - 1) : (row += 1) {
        for (currentBeams.items) |beam| {
            const beam_pos, const power = beam;
            const below_pos = try map.mapToIndex(beam_pos, row + 1);
            switch (map.data.items[@intCast(below_pos)]) {
                '.' => try addBeam(allocator, &nextBeams, beam_pos, power),

                '^' => {
                    const left_beam = beam_pos - 1;
                    const right_beam = beam_pos + 1;
                    if (left_beam < 0 or left_beam >= map.width or right_beam < 0 or right_beam >= map.width) {
                        return error.MalformedInput;
                    }
                    try addBeam(allocator, &nextBeams, left_beam, power);
                    try addBeam(allocator, &nextBeams, right_beam, power);
                },
                else => return error.MalformedInput,
            }
        }
        currentBeams.clearRetainingCapacity();
        var it = nextBeams.iterator();
        while (it.next()) |entry| {
            try currentBeams.append(allocator, .{ entry.key_ptr.*, entry.value_ptr.* });
        }
        nextBeams.clearRetainingCapacity();
    }

    var timelimes: u64 = 0;
    for (currentBeams.items) |beam| {
        _, const power = beam;
        timelimes += @as(u64, power);
    }
    return timelimes;
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
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        ".......S.......",
        "...............",
        ".......^.......",
        "...............",
        "......^.^......",
        "...............",
        ".....^.^.^.....",
        "...............",
        "....^.^...^....",
        "...............",
        "...^.^...^.^...",
        "...............",
        "..^...^.....^..",
        "...............",
        ".^.^.^.^.^...^.",
        "...............",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 21), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        ".......S.......",
        "...............",
        ".......^.......",
        "...............",
        "......^.^......",
        "...............",
        ".....^.^.^.....",
        "...............",
        "....^.^...^....",
        "...............",
        "...^.^...^.^...",
        "...............",
        "..^...^.....^..",
        "...............",
        ".^.^.^.^.^...^.",
        "...............",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 40), result);
}
