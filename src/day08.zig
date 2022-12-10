//! part01 originally implemented as wavefront for each direction, then `|` them together.
//!
//! refactored to nested loops for part02

const std = @import("std");
const data = @embedFile("input/day08.txt");
const expectEqual = std.testing.expectEqual;
const util = @import("util.zig");
const Grid = util.StaticGrid;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const out = run(data);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(comptime input: []const u8) struct { part01: u64, part02: u64 } {
    // To avoid allocation, check grid size at comptime
    const grid_size = comptime blk: {
        @setEvalBranchQuota(30_000);
        var lines = std.mem.tokenize(u8, input, "\n");
        var num_rows: usize = 0;
        var line_len: usize = 0;
        while (lines.next()) |line| {
            line_len = line.len;
            num_rows += 1;
        }

        break :blk .{ .M = num_rows, .N = line_len };
    };
    const M = grid_size.M;
    const N = grid_size.N;

    // parse input into grid
    var grid: Grid(u8, M, N) = undefined;

    var grid_idx: usize = 0;
    for (input) |c| {
        if (c != '\n') {
            grid.items[grid_idx] = c;
            grid_idx += 1;
        }
    }

    // loop through to check each tree's view
    var views = blk: {
        var res: Grid(View, M, N) = undefined;

        var m: usize = 0;
        while (m < M) : (m += 1) {
            var n: usize = 0;
            while (n < N) : (n += 1) {
                var view: View = undefined;
                for (directions) |dir, i| {
                    const view_res = viewDistance(dir, m, n, grid);
                    view.view[i] = view_res[0];
                    if (view_res[1] == .oob) {
                        view.oob = .oob;
                    }
                }
                res.set(view, m, n);
            }
        }
        break :blk res;
    };

    // part 01 scoring
    const part01 = blk: {
        var res: usize = 0;

        for (views.items) |item| {
            // if any view is oob, it passed the edge
            if (item.oob == .oob) {
                res += 1;
            }
        }

        break :blk res;
    };

    // part02 scoring
    const part02 = blk: {
        var res: usize = 0;

        for (views.items) |item| {
            const view_sum = @reduce(.Mul, item.view);
            if (view_sum > res) {
                res = view_sum;
            }
        }
        break :blk res;
    };

    return .{ .part01 = part01, .part02 = part02 };
}

const Point = @Vector(2, isize);

/// UDLR
const View = struct {
    view: @Vector(4, usize),
    oob: Oob,
};

/// UDLR in xy coords (not mn matrix coords)
/// This is probably a mistake, to switch coords...
/// 0,0 is in upper left
const directions = [_]Point{
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 1, 0 },
};

const Oob = enum {
    oob,
    not_oob,
};

/// grid is of type Grid(u8, M, N)
fn viewDistance(dir: Point, m: usize, n: usize, grid: anytype) struct { usize, Oob } {
    const tree_height = grid.get(m, n);
    var tree_loc = Point{ @intCast(isize, n), @intCast(isize, m) } + dir;
    var idx: usize = 0;

    const M = @TypeOf(grid).M;
    const N = @TypeOf(grid).N;

    // check oob
    while (tree_loc[0] < N and tree_loc[0] >= 0 and tree_loc[1] < M and tree_loc[1] >= 0) {
        idx += 1;

        const tree_m = @intCast(usize, tree_loc[1]);
        const tree_n = @intCast(usize, tree_loc[0]);
        if (grid.get(tree_m, tree_n) >= tree_height) {
            return .{ idx, .not_oob };
        }

        tree_loc += dir;
    }

    // It's reached the edge, so oob
    return .{ idx, .oob };
}

test "test_day08" {
    const input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;

    const out = run(input);
    try expectEqual(out.part01, 21);
    try expectEqual(out.part02, 8);
}
