const std = @import("std");
const data = @embedFile("input/day03.txt");
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

    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var half_idx = line.len / 2;
        var rucksack_1 = line[0..half_idx];
        var rucksack_2 = line[half_idx..];

        blk: {
            var i: usize = 0;
            while (i < rucksack_1.len) : (i += 1) {
                var j: usize = 0;
                while (j < rucksack_2.len) : (j += 1) {
                    if (rucksack_1[i] == rucksack_2[j]) {
                        switch (rucksack_1[i]) {
                            'a'...'z' => part01 += rucksack_1[i] - 96,
                            'A'...'Z' => part01 += rucksack_1[i] - 64 + 26,
                            else => unreachable,
                        }
                        break :blk;
                    }
                }
            }
        }
    }

    return .{ .part01 = part01, .part02 = part02 };
}

test "part01" {
    const input =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    ;

    try expectEqual(run(input).part01, 157);
}

test "part02" {
    const input =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    ;

    try expectEqual(run(input).part02, 0);
}
