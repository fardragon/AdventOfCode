const std = @import("std");
const common_input = @import("common").input;

fn validateInstruction(maybe_instruction: []const u8) !u64 {
    var ins = maybe_instruction;
    if (!std.mem.startsWith(u8, ins, "mul(")) return 0;
    ins = ins[4..];

    const comma = std.mem.indexOfScalar(u8, ins, ',');
    if (comma == null) return 0;
    if (comma.? < 1 or comma.? > 3) {
        return 0;
    }

    const closing_bracket = std.mem.indexOfScalar(u8, ins, ')');
    if (closing_bracket == null) return 0;
    if (closing_bracket.? - comma.? > 4) return 0;

    const left_num = try std.fmt.parseInt(u64, ins[0..comma.?], 10);
    const right_num = try std.fmt.parseInt(u64, ins[comma.? + 1 .. closing_bracket.?], 10);

    return left_num * right_num;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    _ = allocator; // autofix

    var result: u64 = 0;

    for (input) |line| {
        var line_pos: usize = 0;

        while (true) {
            if (std.mem.indexOf(u8, line[line_pos..], "mul(")) |possible_mul| {
                result += try validateInstruction(line[line_pos + possible_mul ..]);
                line_pos += possible_mul + 1;
            } else {
                break;
            }
        }
    }
    return result;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    _ = allocator; // autofix

    var result: u64 = 0;
    var enabled = true;

    for (input) |line| {
        var line_pos: usize = 0;

        while (true) {
            if (enabled) {
                const maybe_mul = std.mem.indexOf(u8, line[line_pos..], "mul(");
                const maybe_disable = std.mem.indexOf(u8, line[line_pos..], "don't()");

                if (maybe_disable) |disable| {
                    if (maybe_mul) |possible_mul| {
                        if (disable < possible_mul) {
                            enabled = false;
                            line_pos += disable + 1;
                        } else {
                            result += try validateInstruction(line[line_pos + possible_mul ..]);
                            line_pos += possible_mul + 1;
                        }
                    } else {
                        enabled = false;
                        line_pos += disable + 1;
                    }
                } else if (maybe_mul) |possible_mul| {
                    result += try validateInstruction(line[line_pos + possible_mul ..]);
                    line_pos += possible_mul + 1;
                } else {
                    break;
                }
            } else {
                if (std.mem.indexOf(u8, line[line_pos..], "do()")) |maybe_enable| {
                    enabled = true;
                    line_pos += maybe_enable + 1;
                } else {
                    break;
                }
            }
        }
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
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 161), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 48), result);
}
