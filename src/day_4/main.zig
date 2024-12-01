const std = @import("std");
const common_input = @import("common").input;

const Card = struct {
    winning_numbers: std.ArrayList(u8),
    numbers: std.AutoHashMap(u8, void),
    instances: u32,
};

fn parseCard(allocator: std.mem.Allocator, input: []const u8) !Card {
    var it = std.mem.splitScalar(u8, input, ':');

    _ = it.first();
    var card_split = std.mem.splitScalar(u8, it.next().?, '|');
    const winning_numbers = card_split.first();
    const numbers = card_split.next().?;

    var winning_numbers_list = std.ArrayList(u8).init(allocator);
    errdefer {
        winning_numbers_list.deinit();
    }

    var winning_numbers_split = std.mem.splitScalar(u8, winning_numbers, ' ');

    while (winning_numbers_split.next()) |str| {
        if (str.len == 0) continue;

        const parsed_number = try std.fmt.parseInt(u8, str, 10);
        try winning_numbers_list.append(parsed_number);
    }

    var numbers_set = std.AutoHashMap(u8, void).init(allocator);
    errdefer {
        numbers_set.deinit();
    }

    var numbers_split = std.mem.splitScalar(u8, numbers, ' ');
    while (numbers_split.next()) |str| {
        if (str.len == 0) continue;

        const parsed_number = try std.fmt.parseInt(u8, str, 10);
        try numbers_set.put(parsed_number, {});
    }

    return Card{
        .winning_numbers = winning_numbers_list,
        .numbers = numbers_set,
        .instances = 1,
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Card) {
    var result = std.ArrayList(Card).init(allocator);
    errdefer {
        for (result.items) |*item| {
            item.numbers.deinit();
            item.winning_numbers.deinit();
        }
        result.deinit();
    }

    for (input) |card| {
        var c = try parseCard(allocator, card);
        errdefer {
            c.numbers.deinit();
            c.winning_numbers.deinit();
        }

        try result.append(c);
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const cards = try parseInput(allocator, input);
    defer {
        for (cards.items) |*card| {
            card.numbers.deinit();
            card.winning_numbers.deinit();
        }
        cards.deinit();
    }

    var result: u64 = 0;

    for (cards.items) |card| {
        var card_result: u64 = 0;
        for (card.winning_numbers.items) |winning_number| {
            if (card.numbers.contains(winning_number)) {
                if (card_result == 0) {
                    card_result = 1;
                } else {
                    card_result *= 2;
                }
            }
        }

        result += card_result;
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const cards = try parseInput(allocator, input);
    defer {
        for (cards.items) |*card| {
            card.numbers.deinit();
            card.winning_numbers.deinit();
        }
        cards.deinit();
    }

    var result: u64 = 0;

    for (cards.items, 0..) |card, index| {
        var card_result: u64 = 0;
        for (card.winning_numbers.items) |winning_number| {
            if (card.numbers.contains(winning_number)) {
                card_result += 1;
            }
        }

        for (0..card_result) |i| {
            const copy_card_index = i + index + 1;
            cards.items[copy_card_index].instances += card.instances;
        }
        result += card.instances;
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
        "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53",
        "Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19",
        "Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1",
        "Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83",
        "Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36",
        "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 13), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53",
        "Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19",
        "Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1",
        "Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83",
        "Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36",
        "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 30), result);
}
