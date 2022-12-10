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
                    view[i] = viewDistance(dir, m, n, grid);
                }
                res.set(view, m, n);
            }
        }
        break :blk res;
    };

    // part 01 scoring
    const part01 = blk: {
        var res: usize = 0;

        var m: usize = 0;
        while (m < M) : (m += 1) {
            var n: usize = 0;
            while (n < N) : (n += 1) {
                const view = views.get(m, n);
                if (view[0] > m or view[1] > M - m - 1 or view[2] > n or view[3] > N - n - 1) {
                    res += 1;
                }
            }
        }
        break :blk res;
    };

    return .{ .part01 = part01, .part02 = 0 };
}

const Point = @Vector(2, isize);

/// UDLR
const View = @Vector(4, usize);

/// UDLR in xy coords (not mn matrix coords)
/// This is probably a mistake, to switch coords...
/// 0,0 is in upper left
const directions = [_]Point{
    .{ 0, -1 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 1, 0 },
};

/// grid is of type Grid(u8, M, N)
fn viewDistance(dir: Point, m: usize, n: usize, grid: anytype) usize {
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
            return idx;
        }

        tree_loc += dir;
    }

    // It's reached the edge, so give it an extra view so we know it's visible from outside
    return idx + 1;
}

test "test_day07" {
    const input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;

    const out = run(input);
    try expectEqual(out.part01, 21);
    try expectEqual(out.part02, 0);
}
