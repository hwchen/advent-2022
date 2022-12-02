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

    // Use split, not tokenize, to get the empty line.
    var lines = std.mem.tokenize(u8, input, "\n");

    while (lines.next()) |line| {
        var cols = std.mem.tokenize(u8, line, " ");

        const opp_move = Move.from_char(cols.next().?[0]);
        const col_2 = cols.next().?[0];

        // part 01
        {
            const my_move = Move.from_char(col_2);
            // add score for winner
            switch (my_move) {
                .rock => switch (opp_move) {
                    .rock => part01 += 3,
                    .paper => {},
                    .scissors => part01 += 6,
                },
                .paper => switch (opp_move) {
                    .rock => part01 += 6,
                    .paper => part01 += 3,
                    .scissors => {},
                },
                .scissors => switch (opp_move) {
                    .rock => {},
                    .paper => part01 += 6,
                    .scissors => part01 += 3,
                },
            }

            // add score for move played
            part01 += my_move.score();
        }

        // part 02
        {
            // col_2 is now the selected strategy
            switch (col_2) {
                'X' => {
                    // lose:
                    // get 0 points plus move score
                    switch (opp_move) {
                        .rock => part02 += Move.scissors.score(),
                        .paper => part02 += Move.rock.score(),
                        .scissors => part02 += Move.paper.score(),
                    }
                },
                'Y' => {
                    // draw:
                    // get 3 points plus move score (which is same as opp move)
                    part02 += opp_move.score() + 3;
                },
                'Z' => {
                    // win:
                    // get 6 points plus move score
                    switch (opp_move) {
                        .rock => part02 += Move.paper.score(),
                        .paper => part02 += Move.scissors.score(),
                        .scissors => part02 += Move.rock.score(),
                    }

                    part02 += 6;
                },
                else => unreachable,
            }
        }
    }

    return .{ .part01 = part01, .part02 = part02 };
}

const Move = enum {
    rock,
    paper,
    scissors,

    fn from_char(c: u8) Move {
        return switch (c) {
            'A', 'X' => .rock,
            'B', 'Y' => .paper,
            'C', 'Z' => .scissors,
            else => unreachable,
        };
    }

    fn score(self: Move) u64 {
        return switch (self) {
            .rock => 1,
            .paper => 2,
            .scissors => 3,
        };
    }
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
