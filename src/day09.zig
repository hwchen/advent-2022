const std = @import("std");
const data = @embedFile("input/day09.txt");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Set = std.AutoHashMap(Point, void);

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
    var head = Point{ 0, 0 };
    var tail = Point{ 0, 0 };
    var trail = Set.init(alloc);
    defer trail.deinit();

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
            try update_step(dir, &head, &tail);
            try trail.put(tail, {});
        }
    }

    return .{ .part01 = trail.count(), .part02 = 0 };
}

const Point = @Vector(2, isize);

fn update_step(dir: Point, head: *Point, tail: *Point) !void {
    const abs = std.math.absInt;

    head.* += dir;
    const dif = head.* - tail.*;

    // touching (overlap or diagonal count), do nothing
    // touching = all elements in dif btwn -1 and 1
    if (try abs(dif[0]) <= 1 and try abs(dif[1]) <= 1) return;

    // If there's a diagonal separation, move into same row/col
    // (one of the dif elements must be 2; shift the other col
    if (try abs(dif[0]) == 2) tail.* += Point{ 0, dif[1] };
    if (try abs(dif[1]) == 2) tail.* += Point{ dif[0], 0 };

    // move towards head
    tail.* += dir;
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
    try expectEqual(out.part02, 0);
}
