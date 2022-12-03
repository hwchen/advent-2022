//! Switching on the round instead of each side's move seems to be sweet spot in readability.
//! Using arithmetic is harder to understand, switching on both moves creates more nesting
//! which is harder to understand.
//!
//! If there were more variations, then using arithmetic would probably be better, with lots
//! of comments explaining.

const std = @import("std");
const data = @embedFile("input/day02.txt");
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
        const round = std.meta.stringToEnum(Round, line).?;

        // scores are result_score + move_score
        part01 += switch (round) {
            .@"A X" => 3 + 1,
            .@"A Y" => 6 + 2,
            .@"A Z" => 0 + 3,
            .@"B X" => 0 + 1,
            .@"B Y" => 3 + 2,
            .@"B Z" => 6 + 3,
            .@"C X" => 6 + 1,
            .@"C Y" => 0 + 2,
            .@"C Z" => 3 + 3,
        };

        // scores are result_score + move_score
        part02 += switch (round) {
            .@"A X" => 0 + 3,
            .@"A Y" => 3 + 1,
            .@"A Z" => 6 + 2,
            .@"B X" => 0 + 1,
            .@"B Y" => 3 + 2,
            .@"B Z" => 6 + 3,
            .@"C X" => 0 + 2,
            .@"C Y" => 3 + 3,
            .@"C Z" => 6 + 1,
        };
    }

    return .{ .part01 = part01, .part02 = part02 };
}

const Round = enum {
    @"A X",
    @"A Y",
    @"A Z",
    @"B X",
    @"B Y",
    @"B Z",
    @"C X",
    @"C Y",
    @"C Z",
};

test "part01" {
    const input =
        \\A Y
        \\B X
        \\C Z
    ;

    try expectEqual(run(input).part01, 15);
}

test "part02" {
    const input =
        \\A Y
        \\B X
        \\C Z
    ;

    try expectEqual(run(input).part02, 12);
}
