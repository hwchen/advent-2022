const std = @import("std");
const data = @embedFile("input/day01.txt");
const expectEqual = std.testing.expectEqual;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const out = try run(data);
    std.log.info("part 01: {d}, part02: {d}", .{ out[2], out[0] + out[1] + out[2] });
}

fn run(input: []const u8) ![3]u64 {
    // Use split, not tokenize, to get the empty line.
    var lines = std.mem.split(u8, input, "\n");

    var max_elves: [3]u64 = .{0} ** 3;
    var curr_elf: u64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            // Start comparison from the largest total
            // Shift and insert at appropriate index
            if (curr_elf > max_elves[2]) {
                max_elves[0] = max_elves[1];
                max_elves[1] = max_elves[2];
                max_elves[2] = curr_elf;
            } else if (curr_elf > max_elves[1]) {
                max_elves[0] = max_elves[1];
                max_elves[1] = curr_elf;
            } else if (curr_elf > max_elves[0]) {
                max_elves[0] = curr_elf;
            }

            curr_elf = 0;
        } else {
            const x = try std.fmt.parseInt(u64, line, 10);
            curr_elf += x;
        }
    }

    return max_elves;
}

test "part01" {
    const input =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;

    try expectEqual((try run(input))[2], 24000);
}
