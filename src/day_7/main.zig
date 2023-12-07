const std = @import("std");
const common_input = @import("common").input;

const HandStrength = enum(u8) {
    Five = 7,
    Four = 6,
    Full = 5,
    Three = 4,
    TwoPair = 3,
    Pair = 2,
    High = 1,
};

const Hand = struct {
    cards: [5]u8,
    bid: u64,

    fn lessThan(use_joker: bool, lhs: Hand, rhs: Hand) bool {
        const lhs_classify = Hand.classifyHand(lhs.cards, use_joker);
        const rhs_classify = Hand.classifyHand(rhs.cards, use_joker);

        if (lhs_classify == rhs_classify) {
            for (0..5) |ix| {
                const lhs_classify_card = Hand.classifyCard(lhs.cards[ix], use_joker);
                const rhs_classify_card = Hand.classifyCard(rhs.cards[ix], use_joker);
                if (lhs_classify_card < rhs_classify_card) return true;
                if (rhs_classify_card < lhs_classify_card) return false;
            }
            unreachable;
        } else {
            return @intFromEnum(lhs_classify) < @intFromEnum(rhs_classify);
        }
    }

    fn classifyCard(card: u8, use_joker: bool) u8 {
        return switch (card) {
            'T' => 10,
            'J' => if (use_joker) 1 else 11,
            'Q' => 12,
            'K' => 13,
            'A' => 14,
            '2'...'9' => card - '0',
            else => unreachable,
        };
    }

    fn classifyHand(hand: [5]u8, use_joker: bool) HandStrength {
        var counter = [_]u8{0} ** 15;
        var has_joker = false;

        for (hand) |card| {
            counter[Hand.classifyCard(card, use_joker)] += 1;
            if (use_joker and card == 'J') has_joker = true;
        }

        var unique_cards: u8 = 0;
        for (counter) |c| {
            unique_cards += if (c > 0) 1 else 0;
        }

        if (use_joker and has_joker) {
            const replacements = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'Q', 'K', 'A' };
            var top_classification = HandStrength.High;

            for (replacements) |replacing_card| {
                var new_hand: [5]u8 = undefined;
                @memcpy(&new_hand, &hand);

                for (&new_hand) |*card| {
                    if (card.* == 'J') card.* = replacing_card;
                }

                const new_classification = Hand.classifyHand(new_hand, false);
                if (@intFromEnum(new_classification) > @intFromEnum(top_classification)) top_classification = new_classification;
            }

            return top_classification;
        } else {
            return switch (unique_cards) {
                1 => HandStrength.Five,
                2 => four: {
                    for (counter) |c| {
                        if (c == 4) break :four HandStrength.Four;
                    }
                    break :four HandStrength.Full;
                },
                3 => three: {
                    for (counter) |c| {
                        if (c == 3) break :three HandStrength.Three;
                    }
                    break :three HandStrength.TwoPair;
                },
                4 => HandStrength.Pair,
                5 => HandStrength.High,
                else => unreachable,
            };
        }
    }

    pub fn format(
        self: Hand,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Cards: ", .{});
        for (self.cards) |card| {
            try writer.print("{c}", .{card});
        }

        try writer.print(" Bid: {}", .{self.bid});
    }
};

fn parseCard(input: []const u8) !Hand {
    var it = std.mem.splitScalar(u8, input, ' ');

    var result = Hand{
        .cards = undefined,
        .bid = undefined,
    };

    const cards = it.first();
    if (cards.len == 5) {
        @memcpy(&result.cards, cards);
    } else {
        unreachable;
    }

    result.bid = try std.fmt.parseInt(u64, it.next().?, 10);

    return result;
}

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Hand) {
    var result = std.ArrayList(Hand).init(allocator);
    errdefer result.deinit();

    for (input) |line| {
        try result.append(try parseCard(line));
    }

    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const hands = try parseInput(allocator, input);
    defer hands.deinit();

    std.sort.heap(Hand, hands.items, false, Hand.lessThan);

    var result: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        result += (hand.bid * rank);
    }

    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    const hands = try parseInput(allocator, input);
    defer hands.deinit();

    std.sort.heap(Hand, hands.items, true, Hand.lessThan);

    var result: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        result += (hand.bid * rank);
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
        "32T3K 765",
        "T55J5 684",
        "KK677 28",
        "KTJJT 220",
        "QQQJA 483",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 6440), result);
}

test "solve part 2 test" {
    const test_input = [_][]const u8{
        "32T3K 765",
        "T55J5 684",
        "KK677 28",
        "KTJJT 220",
        "QQQJA 483",
    };

    const result = try solvePart2(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 5905), result);
}
