const std = @import("std");
const common = @import("common");
const common_input = common.input;

const Device = struct {
    name: [3]u8,
    outputs: std.ArrayList([3]u8),

    fn deinit(self: *Device, allocator: std.mem.Allocator) void {
        self.outputs.deinit(allocator);
    }
};

fn parseDevice(allocator: std.mem.Allocator, input: []const u8) !Device {
    var outputs: std.ArrayList([3]u8) = .empty;
    errdefer outputs.deinit(allocator);

    var it = std.mem.splitScalar(u8, input[5..], ' ');

    var buf: [3]u8 = undefined;
    while (it.next()) |output| {
        @memcpy(&buf, output[0..3]);
        try outputs.append(allocator, buf);
    }

    @memcpy(&buf, input[0..3]);

    return .{
        .name = buf,
        .outputs = outputs,
    };
}

fn parseDevices(allocator: std.mem.Allocator, input: []const []const u8) !std.ArrayList(Device) {
    var devices: std.ArrayList(Device) = try .initCapacity(allocator, input.len);
    errdefer {
        for (devices.items) |*device| {
            device.deinit(allocator);
        }
        devices.deinit(allocator);
    }

    for (input) |line| {
        devices.appendAssumeCapacity(try parseDevice(allocator, line));
    }

    return devices;
}

fn findDevice(devices: []const Device, name: [3]u8) !*const Device {
    for (devices) |*device| {
        if (std.mem.eql(u8, &device.name, name[0..3])) return device;
    }
    return error.LogicError;
}

const Cache = std.AutoHashMap([3]u8, u64);

fn solveInner(allocator: std.mem.Allocator, devices: []const Device, current: [3]u8, target: [3]u8, cache: *Cache) !u64 {
    if (std.mem.eql(u8, &current, &target)) {
        return 1;
    }

    if (std.mem.eql(u8, &current, "out")) {
        return 0;
    }

    if (cache.get(current[0..3].*)) |val| {
        return val;
    }

    const current_device = try findDevice(devices, current);

    var score: u64 = 0;
    for (current_device.outputs.items) |output| {
        score += try solveInner(allocator, devices, output, target, cache);
    }

    try cache.put(current[0..3].*, score);
    return score;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var devices = try parseDevices(allocator, input);
    defer {
        for (devices.items) |*device| {
            device.deinit(allocator);
        }
        devices.deinit(allocator);
    }

    var cache: Cache = .init(allocator);
    defer cache.deinit();

    return solveInner(allocator, devices.items, "you"[0..3].*, "out"[0..3].*, &cache);
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var devices = try parseDevices(allocator, input);
    defer {
        for (devices.items) |*device| {
            device.deinit(allocator);
        }
        devices.deinit(allocator);
    }

    var cache: Cache = .init(allocator);
    defer cache.deinit();

    const svr_fft = try solveInner(allocator, devices.items, "svr"[0..3].*, "fft"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    const fft_dac = try solveInner(allocator, devices.items, "fft"[0..3].*, "dac"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    const dac_out = try solveInner(allocator, devices.items, "dac"[0..3].*, "out"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    const svr_dac = try solveInner(allocator, devices.items, "svr"[0..3].*, "dac"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    const dac_fft = try solveInner(allocator, devices.items, "dac"[0..3].*, "fft"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    const fft_out = try solveInner(allocator, devices.items, "fft"[0..3].*, "out"[0..3].*, &cache);
    cache.clearRetainingCapacity();

    return svr_fft * fft_dac * dac_out + svr_dac * dac_fft * fft_out;
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
        "aaa: you hhh",
        "you: bbb ccc",
        "bbb: ddd eee",
        "ccc: ddd eee fff",
        "ddd: ggg",
        "eee: out",
        "fff: out",
        "ggg: out",
        "hhh: ccc fff iii",
        "iii: out",
    };

    const result = try solvePart1(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 5), result);
}

test "solve part 2 test" {
    const allocator = std.testing.allocator;
    const test_input = [_][]const u8{
        "svr: aaa bbb",
        "aaa: fft",
        "fft: ccc",
        "bbb: tty",
        "tty: ccc",
        "ccc: ddd eee",
        "ddd: hub",
        "hub: fff",
        "eee: dac",
        "dac: fff",
        "fff: ggg hhh",
        "ggg: out",
        "hhh: out",
    };

    const result = try solvePart2(allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 2), result);
}
