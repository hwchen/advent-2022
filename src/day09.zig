//! improvements:
//! - Use math.clamp instead of moving towards zero w/ `sign`
//! - Only need to check for dx or dy == 2 and then clamp, don't need pre-check on dx or dy == 1 or 0

const std = @import("std");
const util = @import("util.zig");
const data = @embedFile("input/day09.txt");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Set = util.Set;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const out = try run(data, alloc);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(input: []const u8, alloc: Allocator) !struct { part01: usize, part02: usize } {
    var part01_head = Point{ 0, 0 };
    var part01_tail = Point{ 0, 0 };
    var part01_trail = Set(Point).init(alloc);
    defer part01_trail.deinit();

    var part02_rope = [_]Point{.{ 0, 0 }} ** 10;
    var part02_trail = Set(Point).init(alloc);
    defer part02_trail.deinit();

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        const num_steps = try std.fmt.parseInt(isize, line[2..], 10);
        const dir: Point = switch (line[0]) {
            'U' => .{ 0, 1 },
            'D' => .{ 0, -1 },
            'L' => .{ -1, 0 },
            'R' => .{ 1, 0 },
            else => unreachable,
        };

        var i: isize = 0;
        while (i < num_steps) : (i += 1) {
            // part01
            part01_head += dir;
            try update_tail(part01_head, &part01_tail);
            try part01_trail.put(part01_tail, {});

            // part02, rope is 10 knots long
            part02_rope[0] += dir;
            var idx: usize = 0;
            while (idx < 9) : (idx += 1) {
                try update_tail(part02_rope[idx], &part02_rope[idx + 1]);
            }
            try part02_trail.put(part02_rope[9], {});
        }
    }

    return .{ .part01 = part01_trail.count(), .part02 = part02_trail.count() };
}

const Point = @Vector(2, isize);

/// Returns the direction the tail moved.
fn update_tail(head: Point, tail: *Point) !void {
    const abs = std.math.absInt;
    const sign = std.math.sign;

    const dif = head - tail.*;

    // touching (overlap or diagonal count), do nothing
    // touching = all elements in dif btwn -1 and 1
    if (try abs(dif[0]) <= 1 and try abs(dif[1]) <= 1) return;

    // If there's a diagonal separation, move into same row/col
    // Then the dif that's 2, close space to head.
    // (Having both as 2 is not a possible state)
    const tail_move = Point{
        if (try abs(dif[0]) == 2) dif[0] - sign(dif[0]) * 1 else dif[0],
        if (try abs(dif[1]) == 2) dif[1] - sign(dif[1]) * 1 else dif[1],
    };
    tail.* += tail_move;
}

test "test_day09" {
    const input =
        \\R 4
        \\U 4
        \\L 3
        \\D 1
        \\R 4
        \\D 1
        \\L 5
        \\R 2
    ;

    const out = try run(input, std.testing.allocator);
    try expectEqual(out.part01, 13);
    try expectEqual(out.part02, 1);
}

test "test_day09_part02" {
    const input =
        \\R 5
        \\U 8
        \\L 8
        \\D 3
        \\R 17
        \\D 10
        \\L 25
        \\U 20
    ;

    const out = try run(input, std.testing.allocator);
    try expectEqual(out.part02, 36);
}
