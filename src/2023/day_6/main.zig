const std = @import("std");
const common_input = @import("common").input;

const Race = struct {
    time: u64,
    distance: u64,
};

fn splitLine(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u64) {
    var results = std.ArrayList(u64).empty;
    errdefer results.deinit(allocator);

    {
        var it = std.mem.splitScalar(u8, input, ':');
        _ = it.first();
        var times_split = std.mem.splitScalar(u8, it.next().?, ' ');

        while (times_split.next()) |time_str| {
            if (time_str.len == 0) continue;
            const parsed_time = try std.fmt.parseInt(u64, time_str, 10);
            try results.append(allocator, parsed_time);
        }
    }

    return results;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Race) {
    var times = try splitLine(allocator, input[0]);
    defer times.deinit(allocator);

    var distances = try splitLine(allocator, input[1]);
    defer distances.deinit(allocator);

    var races = std.ArrayList(Race).empty;
    errdefer races.deinit(allocator);

    for (times.items, distances.items) |time, distance| {
        try races.append(
            allocator,
            Race{
                .time = time,
                .distance = distance,
            },
        );
    }

    return races;
}

fn solveRace(race: Race) u64 {
    var result: u64 = 0;
    for (1..race.time) |button_hold| {
        const distance = (race.time - button_hold) * button_hold;
        if (distance > race.distance) result += 1;
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var races = try parseInput(allocator, input);
    defer races.deinit(allocator);

    var result: u64 = 1;

    for (races.items) |race| {
        result *= solveRace(race);
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var races = try parseInput(allocator, input);
    defer races.deinit(allocator);

    var final_race = Race{
        .distance = 0,
        .time = 0,
    };

    // combine races
    for (races.items) |race| {
        const time_length = std.math.log10_int(race.time) + 1;
        final_race.time = final_race.time * try std.math.powi(u64, 10, time_length) + race.time;

        const distance_length = std.math.log10_int(race.distance) + 1;
        final_race.distance = final_race.distance * try std.math.powi(u64, 10, distance_length) + race.distance;
    }

    return solveRace(final_race);
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
        "Time:      7  15   30",
        "Distance:  9  40  200",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 288), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "Time:      7  15   30",
        "Distance:  9  40  200",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 71503), result);
}
