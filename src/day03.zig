//! See https://github.com/SpexGuy/Advent2022/blob/main/src/day03.zig for example of using bitsets.
//! In the same implementation, see an interesting way to turn
//! ```
//! []const T, 3 -> []const [3] T
//! ```

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

    // part 01
    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        var half_idx = line.len / 2;
        var rucksack_1 = line[0..half_idx];
        var rucksack_2 = line[half_idx..];

        blk: {
            for (0..rucksack_1.len) |i| {
                for (0..rucksack_2.len) |j| {
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

    // part 02
    // No alloc, nested loops. Is there a better way w/out alloc?
    var groups = GroupsIterator{ .working_slice = input };
    while (try groups.next()) |group| {
        blk: {
            var i: usize = 0;
            while (i < group.ruck_0.len) : (i += 1) {
                var j: usize = 0;
                while (j < group.ruck_1.len) : (j += 1) {
                    var k: usize = 0;
                    while (k < group.ruck_2.len) : (k += 1) {
                        if (group.ruck_0[i] == group.ruck_1[j] and group.ruck_1[j] == group.ruck_2[k]) {
                            switch (group.ruck_0[i]) {
                                'a'...'z' => part02 += group.ruck_0[i] - 96,
                                'A'...'Z' => part02 += group.ruck_0[i] - 64 + 26,
                                else => unreachable,
                            }
                            break :blk;
                        }
                    }
                }
            }
        }
    }

    return .{ .part01 = part01, .part02 = part02 };
}

const GroupsIterator = struct {
    working_slice: []const u8,

    /// Groups in input are exact, so don't handle errors.
    fn next(self: *GroupsIterator) !?Group {
        if (self.working_slice.len == 0) {
            return null;
        }

        const end_0 = std.mem.indexOf(u8, self.working_slice, "\n").?;
        const ruck_0 = self.working_slice[0..end_0];
        self.working_slice = self.working_slice[end_0 + 1 ..];

        const end_1 = std.mem.indexOf(u8, self.working_slice, "\n").?;
        const ruck_1 = self.working_slice[0..end_1];
        self.working_slice = self.working_slice[end_1 + 1 ..];

        // Last line may not have `\n`.
        const maybe_end_2 = std.mem.indexOf(u8, self.working_slice, "\n");
        const ruck_2 = blk: {
            if (maybe_end_2) |end| {
                const r2 = self.working_slice[0..end];
                self.working_slice = self.working_slice[end + 1 ..];
                break :blk r2;
            } else {
                const r2 = self.working_slice[0..];
                self.working_slice = self.working_slice[self.working_slice.len..];
                break :blk r2;
            }
        };

        const res = Group{
            .ruck_0 = ruck_0,
            .ruck_1 = ruck_1,
            .ruck_2 = ruck_2,
        };
        return res;
    }
};

const Group = struct {
    ruck_0: []const u8,
    ruck_1: []const u8,
    ruck_2: []const u8,
};

test "test_day_03" {
    const input =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    ;

    const out = run(input);
    try expectEqual(out.part01, 157);
    try expectEqual(out.part02, 70);
}
