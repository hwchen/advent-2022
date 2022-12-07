const std = @import("std");
const data = @embedFile("input/day07.txt");
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.StringHashMap;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const out = try run(data, alloc);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(input: []const u8, alloc: Allocator) !struct { part01: u64, part02: u64 } {

    // While navigating the tree, curr dir + all parent dirs
    var ctx = ArrayList([]const u8).init(alloc);
    defer ctx.deinit();

    // Running totals of each dir size
    var dir_totals = HashMap(u64).init(alloc);
    defer {
        var key_iter = dir_totals.keyIterator();
        while (key_iter.next()) |key_ptr| {
            alloc.free(key_ptr.*);
        }
        dir_totals.deinit();
    }

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        switch (line[0]) {
            // command, either ls or cd
            '$' => switch (line[2]) {
                'l' => {}, // ls, just skip command
                'c' => switch (line[5]) {
                    '.' => _ = ctx.pop(),
                    else => {
                        // cd: init dir total and add to ctx stack
                        const dirname = line[5..];
                        try ctx.append(dirname);

                        // hashmap calls free on keys
                        const full_path = try fullPath(ctx.items, alloc);
                        try dir_totals.put(full_path, 0);
                    },
                },
                else => unreachable,
            },
            // dir, with `dir dirname` structure. Skip, init dir on cd
            'd' => {},
            else => {
                var split_idx = std.mem.indexOf(u8, line, " ").?;
                const filesize = try std.fmt.parseInt(u64, line[0..split_idx], 10);
                // file, w/ `n filename` structure
                var idx: usize = 0;
                while (idx < ctx.items.len) : (idx += 1) {
                    const full_path = try fullPath(ctx.items[0 .. idx + 1], alloc);
                    defer alloc.free(full_path);
                    var total = dir_totals.getPtr(full_path).?;
                    total.* += filesize;
                }
            },
        }
    }

    var part01: usize = 0;
    var part02: usize = std.math.maxInt(usize);

    const root_size = dir_totals.get("//").?;
    const free_space = 70_000_000 - root_size;

    var totals_it = dir_totals.valueIterator();
    while (totals_it.next()) |total| {
        if (total.* <= 100000) {
            part01 += total.*;
        }

        if (total.* <= part02 and free_space + total.* > 30_000_000) {
            part02 = total.*;
        }
    }

    return .{ .part01 = part01, .part02 = part02 };
}

// caller fress
fn fullPath(ctx: []const []const u8, alloc: Allocator) ![]const u8 {
    var buf = ArrayList(u8).init(alloc);
    for (ctx) |sub_path| {
        try buf.append('/');
        try buf.appendSlice(sub_path);
    }
    return buf.toOwnedSlice();
}

test "test_day07" {
    const input =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;

    const out = try run(input, std.testing.allocator);
    try expectEqual(out.part01, 95437);
    try expectEqual(out.part02, 24933642);
}
