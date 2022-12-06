const std = @import("std");
const data = @embedFile("input/day06.txt");
const expectEqual = std.testing.expectEqual;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const out = run(data);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(input: []const u8) struct { part01: u64, part02: u64 } {
    const part01 = indexOfStart(input, 4);
    const part02 = indexOfStart(input, 14);

    return .{ .part01 = part01, .part02 = part02 };
}

fn isUniqueChars(win: []const u8) bool {
    var bitset = @as(u26, 0);
    for (win) |c| {
        bitset |= @as(u26, 1) << @intCast(u5, c - 97);
    }

    return @popCount(bitset) == win.len;
}

fn indexOfStart(msg: []const u8, marker_size: usize) u64 {
    var idx: usize = 0;
    while (idx < msg.len - marker_size) : (idx += 1) {
        if (isUniqueChars(msg[idx .. idx + marker_size])) {
            return idx + marker_size;
        }
    }

    unreachable;
}

test "test_day06" {
    const input = "nppdvjthqldpwncqszvftbrmjlhg";

    const out = run(input);
    try expectEqual(out.part01, 6);
    try expectEqual(out.part02, 23);
}
