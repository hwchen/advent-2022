const std = @import("std");
const data = @embedFile("input/day08.txt");
const expectEqual = std.testing.expectEqual;
const util = @import("util.zig");
const Grid = util.Grid;
const BitGrid = util.BitGrid;

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

        break :blk .{ .N = num_rows, .M = line_len };
    };
    const N = grid_size.N;
    const M = grid_size.M;

    // parse input into grid
    var grid: Grid(N, M) = undefined;

    var grid_idx: usize = 0;
    for (input) |c| {
        if (c != '\n') {
            grid.items[grid_idx] = c;
            grid_idx += 1;
        }
    }

    // Check from visibility from each direction
    var viz_from_left = BitGrid(N, M).zero();
    var viz_from_right = BitGrid(N, M).zero();
    {
        var row_idx: usize = 0;
        while (row_idx < N) : (row_idx += 1) {
            var l_max_height: usize = 0;
            var r_max_height: usize = 0;
            var from_edge: usize = 0;
            while (from_edge < M) : (from_edge += 1) {
                const l_tree = grid.get(row_idx, from_edge);
                if (l_tree > l_max_height) {
                    viz_from_left.set(row_idx, from_edge);
                    l_max_height = l_tree;
                }

                const r_tree = grid.get(row_idx, M - from_edge - 1);
                if (r_tree > r_max_height) {
                    viz_from_right.set(row_idx, M - from_edge - 1);
                    r_max_height = r_tree;
                }
            }
        }
    }

    var viz_from_top = BitGrid(grid_size.N, grid_size.M).zero();
    var viz_from_bot = BitGrid(grid_size.N, grid_size.M).zero();
    {
        var col_idx: usize = 0;
        while (col_idx < M) : (col_idx += 1) {
            var t_max_height: usize = 0;
            var b_max_height: usize = 0;
            var from_edge: usize = 0;
            while (from_edge < N) : (from_edge += 1) {
                const t_tree = grid.get(from_edge, col_idx);
                if (t_tree > t_max_height) {
                    viz_from_top.set(from_edge, col_idx);
                    t_max_height = t_tree;
                }

                const b_tree = grid.get(N - from_edge - 1, col_idx);
                if (b_tree > b_max_height) {
                    viz_from_bot.set(N - from_edge - 1, col_idx);
                    b_max_height = b_tree;
                }
            }
        }
    }

    // Overlay visibility BitGrids for final result and count.
    const visibility = viz_from_left.bits | viz_from_right.bits | viz_from_top.bits | viz_from_bot.bits;

    var part01: usize = @popCount(visibility);
    var part02: usize = 0;

    return .{ .part01 = part01, .part02 = part02 };
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
