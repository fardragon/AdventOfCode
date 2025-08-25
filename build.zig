const std = @import("std");

fn buildDay(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize_options: *const std.builtin.OptimizeMode,
    common_module: *std.Build.Module,
    intcode_module: *std.Build.Module,
    all_tests_step: *std.Build.Step,
    check_step: *std.Build.Step,
    comptime year: []const u8,
    comptime name: []const u8,
) void {
    const path = "src/" ++ year ++ "/" ++ name;
    std.fs.cwd().access(path, .{}) catch return;

    const full_name = year ++ "_" ++ name;

    const module = b.createModule(.{
        .root_source_file = b.path(path ++ "/main.zig"),
        .target = target.*,
        .optimize = optimize_options.*,
    });
    module.addImport("common", common_module);
    if (std.mem.eql(u8, year, "2019")) {
        module.addImport("intcode", intcode_module);
    }

    const exe = b.addExecutable(.{
        .name = full_name,
        .root_module = module,
    });
    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = full_name,
        .root_module = module,
    });
    check_step.dependOn(&exe_check.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.cwd = b.path(path);

    const run_step = b.step("run_" ++ year ++ "_" ++ name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_module = module,
        .name = "test_" ++ year ++ "_" ++ name,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.cwd = b.path(path);

    const test_step = b.step("test_" ++ year ++ "_" ++ name, "Run " ++ name ++ " unit tests");
    test_step.dependOn(&run_unit_tests.step);
    all_tests_step.dependOn(&run_unit_tests.step);
}

fn buildYear(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize_options: *const std.builtin.OptimizeMode,
    common_module: *std.Build.Module,
    intcode_module: *std.Build.Module,
    all_tests_step: *std.Build.Step,
    check_step: *std.Build.Step,
    comptime year: u16,
) void {
    @setEvalBranchQuota(5_000);
    const year_buf = std.fmt.comptimePrint("{d}", .{year});
    inline for (1..26) |day| {
        const day_buf = std.fmt.comptimePrint("{d}", .{day});
        buildDay(
            b,
            target,
            optimize_options,
            common_module,
            intcode_module,
            all_tests_step,
            check_step,
            year_buf,
            "day_" ++ day_buf,
        );
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const common_module = b.createModule(.{
        .root_source_file = b.path("src/common/common.zig"),
        .target = target,
        .optimize = optimize,
    });

    const intcode_module = b.createModule(.{
        .root_source_file = b.path("src/intcode/machine.zig"),
        .target = target,
        .optimize = optimize,
    });

    intcode_module.addImport("common", common_module);

    const intcode_tests = b.addTest(.{ .root_module = intcode_module });
    const run_intcode_tests = b.addRunArtifact(intcode_tests);

    const run_all_tests_step = b.step("test", "Run all tests");
    run_all_tests_step.dependOn(&run_intcode_tests.step);
    const check_step = b.step("check", "Build on save check");

    buildYear(b, &target, &optimize, common_module, intcode_module, run_all_tests_step, check_step, 2019);
    buildYear(b, &target, &optimize, common_module, intcode_module, run_all_tests_step, check_step, 2023);
    buildYear(b, &target, &optimize, common_module, intcode_module, run_all_tests_step, check_step, 2024);
}
