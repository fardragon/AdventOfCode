const std = @import("std");
const common_input = @import("common").input;

fn calculateFuel(mass: u64) u64 {
    return @divFloor(mass, 3) - 2;
}

fn calculateFuel2(mass: u64) u64 {
    var fuel: u64 = 0;

    var current_mass = mass;
    while (true) {
        current_mass = @divFloor(current_mass, 3);
        if (current_mass <= 2) break;
        fuel += current_mass - 2;
        current_mass -= 2;
    }

    return fuel;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    _ = allocator; // autofix
    var total_fuel: u64 = 0;

    for (input) |line| {
        const mass = std.fmt.parseInt(u64, line, 10) catch return error.InvalidInput;
        total_fuel += calculateFuel(mass);
    }

    return total_fuel;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    _ = allocator; // autofix
    var total_fuel: u64 = 0;

    for (input) |line| {
        const mass = std.fmt.parseInt(u64, line, 10) catch return error.InvalidInput;
        total_fuel += calculateFuel2(mass);
    }

    return total_fuel;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GPA.allocator();

    defer _ = GPA.deinit();

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

test calculateFuel {
    try std.testing.expectEqual(2, calculateFuel(12));
    try std.testing.expectEqual(2, calculateFuel(14));
    try std.testing.expectEqual(654, calculateFuel(1969));
    try std.testing.expectEqual(33583, calculateFuel(100756));
}

test calculateFuel2 {
    try std.testing.expectEqual(2, calculateFuel2(14));
    try std.testing.expectEqual(966, calculateFuel2(1969));
    try std.testing.expectEqual(50346, calculateFuel2(100756));
}

test "solve part 1 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "12",
        "15",
        "1969",
        "100756",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 34242), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "14",
        "1969",
        "100756",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 51314), result);
}
