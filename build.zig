// to get this to compile for looping over days, needed:
// - const days to be comptime
// - for to be inline (why?)
// - comptimePrint

const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const days = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };

    inline for (days) |day| {
        const day_string = comptime std.fmt.comptimePrint("day{:0>2}", .{day});

        const exe = b.addExecutable(.{
            .name = day_string,
            .root_source_file = .{ .path = "src/" ++ day_string ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(day_string, "Run" ++ day_string);
        run_step.dependOn(&run_cmd.step);
    }
}
