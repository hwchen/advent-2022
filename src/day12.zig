const std = @import("std");
const mem = std.mem;
const data = @embedFile("input/day12.txt");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const LinearFifo = std.fifo.LinearFifo;

const util = @import("util.zig");
const Grid = util.StaticGrid;
const Point = util.Point;
const Set = util.Set;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const out = try run(data, alloc);

    std.log.info("part 01: {d}, part02:{d}", .{ out[0], out[1] });
}

fn run(comptime input: []const u8, alloc: Allocator) !struct { u64, u64 } {
    const grid_size = comptime blk: {
        @setEvalBranchQuota(30_000);
        var lines = std.mem.tokenize(u8, input, "\n");
        var num_rows: usize = 0;
        var line_len: usize = 0;
        while (lines.next()) |line| {
            line_len = line.len;
            num_rows += 1;
        }

        break :blk .{ .X = line_len, .Y = num_rows };
    };
    const X = grid_size.X;
    const Y = grid_size.Y;

    // parse input into grid
    var grid: Grid(u8, X, Y) = undefined;

    var grid_idx: usize = 0;
    for (input) |c| {
        if (c != '\n') {
            grid.items[grid_idx] = c;
            grid_idx += 1;
        }
    }

    const part01 = try shortestPathLength('S', 'E', grid, .increase, alloc);
    const part02 = try shortestPathLength('E', 'a', grid, .decrease, alloc);

    return .{ part01, part02 };
}

fn shortestPathLength(start_value: u8, end_value: u8, grid: anytype, el_change: ElChange, alloc: Allocator) !usize {
    const X = @TypeOf(grid).X;
    const Y = @TypeOf(grid).Y;

    // bfs

    const start = @TypeOf(grid).indexFromRaw(mem.indexOf(u8, &grid.items, &.{start_value}).?);
    std.log.debug("start: {any}\n", .{start});
    std.log.debug("end_value: {any}\n", .{end_value});

    var queue = LinearFifo(Node, .Dynamic).init(alloc);
    defer queue.deinit();
    try queue.writeItem(Node{ .parent = 0, .point = start });

    var explored = Set(Point).init(alloc);
    defer explored.deinit();
    try explored.put(Point{ 0, 0 }, {});

    var parents = std.ArrayList(Node).init(alloc);
    defer parents.deinit();

    var target: ?Node = null;

    while (queue.count != 0) {
        const curr = queue.readItem().?;
        std.log.debug("{any}\n", .{curr});
        // There's an extra call to getPoint here
        if (grid.getPoint(curr.point) == end_value) {
            target = curr;
            break;
        }

        try parents.append(curr);

        for (directions) |direction| {
            const next_point = curr.point + direction;
            std.log.debug("  next point: {any}\n", .{next_point});

            std.log.debug("    checking oob\n", .{});

            // check if oob
            if (next_point[0] < 0 or
                next_point[0] >= X or
                next_point[1] < 0 or
                next_point[1] >= Y)
            {
                continue;
            }

            // check if gradient is +1
            const curr_el = norm_el(grid.getPoint(curr.point));
            const next_el = norm_el(grid.getPoint(next_point));
            std.log.debug("    checking elevation change: {c} -> {c}\n", .{ curr_el, next_el });
            switch (el_change) {
                .increase => if (@intCast(isize, next_el) - @intCast(isize, curr_el) > 1) continue,
                .decrease => if (@intCast(isize, curr_el) - @intCast(isize, next_el) > 1) continue,
            }

            std.log.debug("    checking explored\n", .{});
            // check if explored
            var entry = try explored.getOrPut(next_point);
            if (entry.found_existing) continue;

            std.log.debug("    write to queue\n", .{});

            try queue.writeItem(Node{
                .parent = parents.items.len - 1,
                .point = next_point,
            });
        }
    }

    // from target, count parents back.
    var num_steps: usize = 1;
    var node_idx = target.?.parent;
    while (node_idx != 0) {
        std.log.debug("{any}\n", .{parents.items[node_idx]});
        node_idx = parents.items[node_idx].parent;
        num_steps += 1;
    }
    std.log.debug("{any}\n", .{parents.items[0]});

    return num_steps;
}

fn norm_el(el: u8) u8 {
    return switch (el) {
        'S' => 'a',
        'E' => 'z',
        else => el,
    };
}

const Node = struct {
    parent: usize,
    point: Point,
};

/// UDLR in xy coords
/// 0,0 is in upper left
const directions = [_]Point{
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 1, 0 },
};

const ElChange = enum {
    increase,
    decrease,
};

test "test_day12" {
    const input =
        \\Sabqponm
        \\abcryxxl
        \\accszExk
        \\acctuvwj
        \\abdefghi
    ;

    const out = try run(input, std.testing.allocator);
    try expectEqual(out[0], 31);
    try expectEqual(out[1], 29);
}
