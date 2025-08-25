const std = @import("std");
const common_input = @import("common").input;
const intcode = @import("intcode");

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !i64 {
    std.debug.assert(input.len == 1);
    var memory = try intcode.parseMemory(allocator, input[0]);
    defer memory.deinit(allocator);

    var output = try intcode.runProgram(allocator, memory.items, &.{1});

    defer output.deinit(allocator);

    if (!std.mem.allEqual(intcode.T, output.items[0 .. output.items.len - 1], 0)) {
        std.debug.print("Output: {any}\r\n", .{output.items});
        return error.FailedTestProgram;
    }

    return output.items[output.items.len - 1];
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !i64 {
    std.debug.assert(input.len == 1);
    var memory = try intcode.parseMemory(allocator, input[0]);
    defer memory.deinit(allocator);

    var output = try intcode.runProgram(allocator, memory.items, &.{5});
    defer output.deinit(allocator);

    if (!std.mem.allEqual(intcode.T, output.items[0 .. output.items.len - 1], 0)) {
        std.debug.print("Output: {any}\r\n", .{output.items});
        return error.FailedTestProgram;
    }

    return output.items[output.items.len - 1];
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    var allocator = debug_allocator.allocator();

    defer _ = debug_allocator.deinit();

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
