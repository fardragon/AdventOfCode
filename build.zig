const std = @import("std");

fn buildDay(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize_options: *const std.builtin.Mode,
    common_module: *std.Build.Module,
    all_tests_step: *std.Build.Step,
    comptime year: []const u8,
    comptime name: []const u8,
) void {
    const path = "src/" ++ year ++ "/" ++ name;
    const full_name = year ++ "_" ++ name;

    const exe = b.addExecutable(.{
        .name = full_name,
        .root_source_file = b.path(path ++ "/main.zig"),
        .target = target.*,
        .optimize = optimize_options.*,
    });
    exe.root_module.addImport("common", common_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.cwd = b.path(path);

    const run_step = b.step("run_" ++ year ++ "_" ++ name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path(path ++ "/main.zig"),
        .target = target.*,
        .optimize = optimize_options.*,
    });
    unit_tests.root_module.addImport("common", common_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    run_unit_tests.cwd = b.path(path);

    const test_step = b.step("test_" ++ year ++ "_" ++ name, "Run " ++ name ++ " unit tests");
    test_step.dependOn(&run_unit_tests.step);
    all_tests_step.dependOn(&run_unit_tests.step);
}

fn buildYear(
    b: *std.Build,
    target: *const std.Build.ResolvedTarget,
    optimize_options: *const std.builtin.Mode,
    common_module: *std.Build.Module,
    all_tests_step: *std.Build.Step,
    comptime year: u16,
    comptime days: u8,
) void {
    const year_buf = std.fmt.comptimePrint("{}", .{year});
    inline for (1..(days + 1)) |day| {
        const day_buf = std.fmt.comptimePrint("{}", .{day});
        buildDay(
            b,
            target,
            optimize_options,
            common_module,
            all_tests_step,
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
    });

    const run_all_tests_step = b.step("test_all", "Run all tests");

    buildYear(b, &target, &optimize, common_module, run_all_tests_step, 2023, 25);
    buildYear(b, &target, &optimize, common_module, run_all_tests_step, 2024, 18);
}
