const std = @import("std");
const data = @embedFile("input/day04.txt");
const expectEqual = std.testing.expectEqual;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const out = run(data);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(input: []const u8) struct { part01: u64, part02: u64 } {
    var part01: u64 = 0;
    var part02: u64 = 0;

    // part 01
    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        const pair = parsePair(line);
        const overlap_union = pair.elf_1 | pair.elf_2;
        const overlap_intersection = pair.elf_1 & pair.elf_2;
        if (@popCount(overlap_union) <= @max(@popCount(pair.elf_1), @popCount(pair.elf_2))) {
            part01 += 1;
        }
        if (@popCount(overlap_intersection) > 0) {
            part02 += 1;
        }
    }

    return .{ .part01 = part01, .part02 = part02 };
}

/// 100 possible zones
const Assignment = u100;

const Pair = struct {
    elf_1: u100,
    elf_2: u100,
};

fn parsePair(s: []const u8) Pair {
    var pair_iter = std.mem.split(u8, s, ",");
    return Pair{
        .elf_1 = parseAssignment(pair_iter.next().?),
        .elf_2 = parseAssignment(pair_iter.next().?),
    };
}

fn parseAssignment(s: []const u8) Assignment {
    var section_range = std.mem.split(u8, s, "-");
    const start = std.fmt.parseInt(u7, section_range.next().?, 10) catch unreachable;
    const end = std.fmt.parseInt(u7, section_range.next().?, 10) catch unreachable;

    var assignment: u100 = 0;
    var idx: u7 = start;
    while (idx <= end) : (idx += 1) {
        assignment |= @as(u100, 1) << idx;
    }

    return assignment;
}

test "test_day_03" {
    const input =
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    ;

    const out = run(input);
    try expectEqual(out.part01, 2);
    try expectEqual(out.part02, 4);
}
