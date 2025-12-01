const std = @import("std");
const common_input = @import("common").input;

fn getCalibrationValue(input: []const u8, allow_text_digits: bool) u8 {
    var left_digit: u8 = 0;
    var right_digit: u8 = 0;

    for (input, 0..) |value, i| {
        if (std.ascii.isDigit(value)) {
            if (left_digit == 0) {
                left_digit = value - '0';
            }

            right_digit = value - '0';
        } else if (allow_text_digits) {
            const digits = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

            for (digits, 1..) |digit, digit_index| {
                if (std.mem.startsWith(u8, input[i..], digit)) {
                    if (left_digit == 0) {
                        left_digit = @intCast(digit_index);
                    }
                    right_digit = @intCast(digit_index);
                }
            }
        }
    }
    return left_digit * 10 + right_digit;
}

fn solvePart1(input: []const []const u8) u64 {
    var sum: u64 = 0;

    for (input) |value| {
        sum += getCalibrationValue(value, false);
    }

    return sum;
}

fn solvePart2(input: []const []const u8) u64 {
    var sum: u64 = 0;

    for (input) |value| {
        sum += getCalibrationValue(value, true);
    }

    return sum;
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

    std.debug.print("Part 1 solution: {d}\n", .{solvePart1(input.items)});
    std.debug.print("Part 2 solution: {d}\n", .{solvePart2(input.items)});
}

test "solve part 1 test" {
    const test_input = [_][]const u8{ "1abc2", "pqr3stu8vwx", "a1b2c3d4e5f", "treb7uchet" };

    const result = solvePart1(&test_input);

    try std.testing.expectEqual(@as(u64, 142), result);
}

test "solve part 2 test" {
    {
        const test_input = [_][]const u8{ "two1nine", "eightwothree", "abcone2threexyz", "xtwone3four", "4nineeightseven2", "zoneight234", "7pqrstsixteen" };
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 281), result);
    }

    {
        const test_input = [_][]const u8{"eighthree"};
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 83), result);
    }

    {
        const test_input = [_][]const u8{"sevenine"};
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 79), result);
    }

    {
        const test_input = [_][]const u8{"oneight"};
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 18), result);
    }

    {
        const test_input = [_][]const u8{"3gngzkpkgrf"};
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 33), result);
    }

    {
        const test_input = [_][]const u8{"v6"};
        const result = solvePart2(&test_input);
        try std.testing.expectEqual(@as(u64, 66), result);
    }
}
