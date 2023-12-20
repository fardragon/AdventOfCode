const std = @import("std");
const common = @import("common");
const common_input = common.input;
const String = common.String;

const Pulse = struct {
    source: []const u8,
    level: bool,
    destination: []const u8,
};

const BroadcastBehaviour = struct {
    fn pulse(allocator: std.mem.Allocator, new_source: []const u8, level: bool, targets: []const []const u8) !std.ArrayList(Pulse) {
        var result = std.ArrayList(Pulse).init(allocator);
        errdefer result.deinit();

        for (targets) |target| {
            try result.append(Pulse{
                .source = new_source,
                .level = level,
                .destination = target,
            });
        }

        return result;
    }
};

const FlipFlopBehaviour = struct {
    level: bool = false,

    fn pulse(self: *FlipFlopBehaviour, allocator: std.mem.Allocator, new_source: []const u8, level: bool, targets: []const []const u8) !std.ArrayList(Pulse) {
        var result = std.ArrayList(Pulse).init(allocator);
        errdefer result.deinit();

        if (!level) {
            self.level = !self.level;

            for (targets) |target| {
                try result.append(Pulse{
                    .source = new_source,
                    .level = self.level,
                    .destination = target,
                });
            }
        }

        return result;
    }
};

const ConjunctionBehaviour = struct {
    sources: std.StringArrayHashMap(bool),
    hash: std.bit_set.IntegerBitSet(64) = std.bit_set.IntegerBitSet(64).initEmpty(),

    fn pulse(self: *ConjunctionBehaviour, allocator: std.mem.Allocator, source: []const u8, new_source: []const u8, level: bool, targets: []const []const u8) !std.ArrayList(Pulse) {
        var result = std.ArrayList(Pulse).init(allocator);
        errdefer result.deinit();

        try self.sources.put(source, level);
        if (level) {
            self.update_hash(source);
        }

        var all_high = true;
        for (self.sources.values()) |val| {
            all_high = all_high and val;
        }

        for (targets) |target| {
            try result.append(Pulse{
                .source = new_source,
                .level = !all_high,
                .destination = target,
            });
        }

        return result;
    }

    fn update_hash(self: *ConjunctionBehaviour, source: []const u8) void {
        const index = self.sources.getIndex(source).?;
        self.hash.set(index);
    }

    fn link_input(self: *ConjunctionBehaviour, input: []const u8) !void {
        try self.sources.put(input, false);
    }

    fn deinit(self: *ConjunctionBehaviour) void {
        self.sources.deinit();
    }
};

const OutputBehaviour = struct {
    counter: u64 = 0,

    fn pulse(self: *OutputBehaviour, allocator: std.mem.Allocator, level: bool) !std.ArrayList(Pulse) {
        if (!level) {
            self.counter += 1;
        }
        return std.ArrayList(Pulse).init(allocator);
    }
};

const ModuleBehaviour = union(enum) {
    broadcast: BroadcastBehaviour,
    flip_flop: FlipFlopBehaviour,
    conjunction: ConjunctionBehaviour,
    output: OutputBehaviour,
};

const Module = struct {
    targets: std.ArrayList([]const u8),
    behaviour: ModuleBehaviour,

    fn deinit(self: *Module) void {
        self.targets.deinit();

        switch (self.behaviour) {
            .broadcast => {},
            .flip_flop => {},
            .conjunction => |*behaviour| {
                behaviour.deinit();
            },
            .output => {},
        }
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const []const u8) !std.StringArrayHashMap(Module) {
    var result = std.StringArrayHashMap(Module).init(allocator);
    errdefer {
        for (result.values()) |*module| {
            module.deinit();
        }
        result.deinit();
    }

    for (input) |line| {
        var it = std.mem.splitSequence(u8, line, " -> ");

        var name = it.first();

        var outputs = std.ArrayList([]const u8).init(allocator);
        errdefer outputs.deinit();

        var outputs_it = std.mem.splitSequence(u8, it.next().?, ", ");

        while (outputs_it.next()) |o| {
            if (o[0] == ' ') @panic("Parsing error");
            try outputs.append(o);
        }

        if (std.mem.eql(u8, name, "broadcaster")) {
            try result.putNoClobber("broadcaster", Module{ .targets = outputs, .behaviour = ModuleBehaviour{ .broadcast = BroadcastBehaviour{} } });
        } else if (name[0] == '%') {
            try result.putNoClobber(name[1..], Module{ .targets = outputs, .behaviour = ModuleBehaviour{ .flip_flop = FlipFlopBehaviour{} } });
        } else if (name[0] == '&') {
            try result.putNoClobber(name[1..], Module{
                .targets = outputs,
                .behaviour = ModuleBehaviour{
                    .conjunction = ConjunctionBehaviour{ .sources = std.StringArrayHashMap(bool).init(allocator) },
                },
            });
        } else unreachable;
    }

    var it = result.iterator();
    while (it.next()) |entry| {
        for (entry.value_ptr.*.targets.items) |output_name| {
            if (result.getPtr(output_name)) |output| {
                switch (output.behaviour) {
                    .broadcast => {},
                    .flip_flop => {},
                    .conjunction => |*behaviour| {
                        try behaviour.link_input(entry.key_ptr.*);
                    },
                    .output => {},
                }
            } else {
                try result.putNoClobber(output_name, Module{
                    .targets = std.ArrayList([]const u8).init(allocator),
                    .behaviour = ModuleBehaviour{ .output = OutputBehaviour{} },
                });
            }
        }
    }

    return result;
}

const PushResult = common.Pair(u64, u64);

fn pushButton(allocator: std.mem.Allocator, modules: *std.StringArrayHashMap(Module)) !PushResult {
    var result = PushResult{ .first = 0, .second = 0 };

    var pulses = std.ArrayList(Pulse).init(allocator);
    defer pulses.deinit();

    try pulses.append(Pulse{
        .source = "button",
        .level = false,
        .destination = "broadcaster",
    });

    while (pulses.items.len > 0) {
        var pulse = pulses.orderedRemove(0);
        // std.debug.print("{s} {} -> {s}\n", .{ pulse.source, pulse.level, pulse.destination });

        if (pulse.level) {
            result.second += 1;
        } else {
            result.first += 1;
        }

        var module = modules.getPtr(pulse.destination).?;
        var new_pulses = switch (module.behaviour) {
            .broadcast => |_| try BroadcastBehaviour.pulse(allocator, pulse.destination, pulse.level, module.*.targets.items),
            .flip_flop => |*behaviour| try behaviour.pulse(allocator, pulse.destination, pulse.level, module.*.targets.items),
            .conjunction => |*behaviour| try behaviour.pulse(allocator, pulse.source, pulse.destination, pulse.level, module.*.targets.items),
            .output => |*behaviour| try behaviour.pulse(allocator, pulse.level),
        };
        defer new_pulses.deinit();

        try pulses.appendSlice(new_pulses.items);
    }
    return result;
}

fn solvePart1(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var modules = try parseInput(allocator, input);
    defer {
        for (modules.values()) |*module| {
            module.deinit();
        }
        modules.deinit();
    }

    var lows: u64 = 0;
    var highs: u64 = 0;

    for (0..1000) |_| {
        var partial = try pushButton(allocator, &modules);

        lows += partial.first;
        highs += partial.second;
    }

    return lows * highs;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const []const u8) !u64 {
    var modules = try parseInput(allocator, input);
    defer {
        for (modules.values()) |*module| {
            module.deinit();
        }
        modules.deinit();
    }

    var counter: u64 = 0;
    var product: u64 = 1;

    var seen = std.bit_set.IntegerBitSet(64).initEmpty();

    var rx_module = modules.getPtr("rx").?;

    // find rx input
    var rx_source: ?*Module = null;
    for (modules.values()) |*module| {
        for (module.targets.items) |target| {
            if (std.mem.eql(u8, target, "rx")) {
                rx_source = module;
            }
        }
    }

    if (rx_source == null) @panic("No RX source");

    while (true) {
        if (rx_module.*.behaviour.output.counter != 0) {
            break;
        }

        _ = try pushButton(allocator, &modules);
        counter += 1;

        if (!rx_source.?.behaviour.conjunction.hash.eql(seen)) {
            seen = rx_source.?.behaviour.conjunction.hash;
            product *= counter;

            if (seen.count() == rx_source.?.behaviour.conjunction.sources.keys().len) {
                return product;
            }
        }
    }

    return counter;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 16, .verbose_log = false }){};

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

test "solve part 1 test A" {
    const test_input = [_][]const u8{
        "broadcaster -> a, b, c",
        "%a -> b",
        "%b -> c",
        "%c -> inv",
        "&inv -> a",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 32000000), result);
}

test "solve part 1 test B" {
    const test_input = [_][]const u8{
        "broadcaster -> a",
        "%a -> inv, con",
        "&inv -> b",
        "%b -> con",
        "&con -> output",
    };

    const result = try solvePart1(std.testing.allocator, &test_input);

    try std.testing.expectEqual(@as(u64, 11687500), result);
}
