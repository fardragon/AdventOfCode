const std = @import("std");
const common_input = @import("common").input;

const Turn = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,
};

const Game = struct {
    id: u32,
    turns: std.ArrayList(Turn),
};

fn parseGame(allocator: std.mem.Allocator, input: []const u8) !Game {
    var it = std.mem.splitScalar(u8, input, ':');

    var game_slice = it.first();

    const game_id_ptr = std.mem.indexOfScalar(u8, game_slice, ' ').?;
    const game_id = try std.fmt.parseInt(u32, game_slice[game_id_ptr + 1 ..], 10);

    var turns = std.mem.splitScalar(u8, it.next().?, ';');

    var turns_list = std.ArrayList(Turn).empty;
    errdefer {
        turns_list.deinit(allocator);
    }

    while (turns.next()) |turn| {
        var parsed_turn = Turn{};
        var results = std.mem.splitScalar(u8, turn, ',');

        while (results.next()) |result| {
            var parts = std.mem.splitScalar(u8, result[1..], ' ');

            const count_str = parts.first();
            const count = try std.fmt.parseInt(u8, count_str, 10);

            const colour = parts.next().?;

            if (std.mem.eql(u8, colour, "red")) {
                parsed_turn.red = count;
            } else if (std.mem.eql(u8, colour, "green")) {
                parsed_turn.green = count;
            } else if (std.mem.eql(u8, colour, "blue")) {
                parsed_turn.blue = count;
            } else {
                unreachable;
            }
        }
        try turns_list.append(allocator, parsed_turn);
    }

    return Game{
        .id = game_id,
        .turns = turns_list,
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Game) {
    var result = std.ArrayList(Game).empty;
    errdefer {
        for (result.items) |*item| {
            item.turns.deinit(allocator);
        }
        result.deinit(allocator);
    }

    for (input) |game| {
        var g = try parseGame(allocator, game);
        errdefer {
            g.turns.deinit(allocator);
        }

        try result.append(allocator, g);
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var games = try parseInput(allocator, input);
    defer {
        for (games.items) |*game| {
            game.turns.deinit(allocator);
        }
        games.deinit(allocator);
    }

    var result: u64 = 0;

    games_loop: for (games.items) |game| {
        for (game.turns.items) |turn| {
            if ((turn.red > 12) or (turn.green > 13) or (turn.blue > 14)) {
                continue :games_loop;
            }
        }
        result += game.id;
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var games = try parseInput(allocator, input);
    defer {
        for (games.items) |*game| {
            game.turns.deinit(allocator);
        }
        games.deinit(allocator);
    }

    var result: u64 = 0;

    for (games.items) |game| {
        var r = game.turns.items[0].red;
        var g = game.turns.items[0].green;
        var b = game.turns.items[0].blue;

        for (game.turns.items[1..]) |turn| {
            if (turn.red > r) {
                r = turn.red;
            }

            if (turn.green > g) {
                g = turn.green;
            }

            if (turn.blue > b) {
                b = turn.blue;
            }
        }

        result += (@as(u64, r) * g * b);
    }

    return result;
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

test "parse game test" {
    const test_input = "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue";

    var result = try parseGame(std.testing.allocator, test_input);
    defer {
        result.turns.deinit(std.testing.allocator);
    }

    try std.testing.expectEqual(@as(u32, 2), result.id);
    try std.testing.expectEqual(@as(usize, 3), result.turns.items.len);

    try std.testing.expectEqual(@as(u8, 0), result.turns.items[0].red);
    try std.testing.expectEqual(@as(u8, 2), result.turns.items[0].green);
    try std.testing.expectEqual(@as(u8, 1), result.turns.items[0].blue);

    try std.testing.expectEqual(@as(u8, 1), result.turns.items[1].red);
    try std.testing.expectEqual(@as(u8, 3), result.turns.items[1].green);
    try std.testing.expectEqual(@as(u8, 4), result.turns.items[1].blue);

    try std.testing.expectEqual(@as(u8, 0), result.turns.items[2].red);
    try std.testing.expectEqual(@as(u8, 1), result.turns.items[2].green);
    try std.testing.expectEqual(@as(u8, 1), result.turns.items[2].blue);
}

test "solve part 1 test" {
    const test_input = [_][]const u8{
        "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
        "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue",
        "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red",
        "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
        "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 8), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
        "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue",
        "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red",
        "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
        "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2286), result);
}
