const std = @import("std");
const common_input = @import("common").input;
const intcode = @import("intcode");

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    std.debug.assert(input.len == 1);
    var memory = try intcode.parseMemory(allocator, input[0]);
    defer memory.deinit(allocator);

    memory.items[1] = 12;
    memory.items[2] = 2;

    var output = try intcode.runProgram(allocator, memory.items, null);
    defer output.deinit(allocator);

    return @intCast(memory.items[0]);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    std.debug.assert(input.len == 1);
    var memory = try intcode.parseMemory(allocator, input[0]);
    defer memory.deinit(allocator);

    var fresh_memory = try memory.clone(allocator);
    defer fresh_memory.deinit(allocator);

    for (0..100) |noun| {
        for (0..100) |verb| {
            @memcpy(fresh_memory.items, memory.items);
            fresh_memory.items[1] = @intCast(noun);
            fresh_memory.items[2] = @intCast(verb);

            var output = try intcode.runProgram(allocator, fresh_memory.items, null);
            defer output.deinit(allocator);

            if (fresh_memory.items[0] == 19690720) {
                return 100 * noun + verb;
            }
        }
    }

    return error.NoResult;
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
