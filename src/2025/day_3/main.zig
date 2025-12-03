const std = @import("std");
const common_input = @import("common").input;

const Battery = u8;
const BatteryBank = std.ArrayList(Battery);

fn parseBanks(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(BatteryBank) {
    var banks: std.ArrayList(BatteryBank) = try .initCapacity(allocator, input.len);
    errdefer {
        for (banks.items) |*bank| {
            bank.deinit(allocator);
        }
        banks.deinit(allocator);
    }

    for (input) |line| {
        var bank: BatteryBank = try .initCapacity(allocator, line.len);
        errdefer bank.deinit(allocator);

        for (line) |batteryChar| {
            std.debug.assert(std.ascii.isDigit(batteryChar));
            const batteryValue = batteryChar - '0';
            bank.appendAssumeCapacity(batteryValue);
        }

        banks.appendAssumeCapacity(bank);
    }

    return banks;
}

fn powerOnBank(comptime K: usize, bank: *const BatteryBank) !u64 {
    std.debug.assert(bank.items.len >= K);

    var indexes: [K]usize = undefined;
    for (0..K) |i| {
        indexes[i] = i;
    }

    for (1..bank.items.len) |ix| {
        for (0..K) |digit| {
            const required_remaining = K - (digit + 1);

            if (ix + required_remaining >= bank.items.len) {
                continue;
            }

            if (digit > 0 and ix <= indexes[digit - 1]) {
                continue;
            }

            if (bank.items[ix] > bank.items[indexes[digit]]) {
                indexes[digit] = ix;

                var offset: usize = 1;
                for (digit + 1..K) |next_digit| {
                    indexes[next_digit] = ix + offset;
                    offset += 1;
                }
                break;
            }
        }
    }

    var power: u64 = 0;
    for (0..K) |i| {
        power = power + bank.items[indexes[i]] * try std.math.powi(u64, 10, (K - 1) - @as(u64, i));
    }

    return power;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var banks = try parseBanks(allocator, input);
    defer {
        for (banks.items) |*bank| {
            bank.deinit(allocator);
        }
        banks.deinit(allocator);
    }

    for (banks.items) |bank| {
        score += try powerOnBank(2, &bank);
    }

    return score;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var score: u64 = 0;
    var banks = try parseBanks(allocator, input);
    defer {
        for (banks.items) |*bank| {
            bank.deinit(allocator);
        }
        banks.deinit(allocator);
    }

    for (banks.items) |bank| {
        score += try powerOnBank(12, &bank);
    }

    return score;
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
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 357), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    };
    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 3121910778619), result);
}
