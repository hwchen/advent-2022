const std = @import("std");
const data = @embedFile("input/day05.txt");
const Allocator = std.mem.Allocator;
const expectEqualSlices = std.testing.expectEqualSlices;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const out = try run(data, alloc);
    defer {
        alloc.free(out.part01);
        alloc.free(out.part02);
    }
    std.log.info("part 01: {s}, part02: {s}", .{ out.part01, out.part02 });
}

fn run(input: []const u8, alloc: Allocator) !Solution {
    var part01: []const u8 = "";
    var part02: []const u8 = "";

    const parsed_header = try parseHeader(input, alloc);
    var stacks01 = parsed_header.stacks;
    var stacks02 = try copyStacks(stacks01, alloc);
    defer {
        for (stacks01.items) |stack| stack.deinit();
        for (stacks02.items) |stack| stack.deinit();
        stacks01.deinit();
        stacks02.deinit();
    }

    var lines = std.mem.tokenize(u8, parsed_header.remainder, "\n");
    while (lines.next()) |line| {
        var move_iter = std.mem.tokenize(u8, line, " movefromto");
        const n = try std.fmt.parseInt(usize, move_iter.next().?, 10);
        const from = try std.fmt.parseInt(usize, move_iter.next().?, 10);
        const to = try std.fmt.parseInt(usize, move_iter.next().?, 10);

        // part01
        {
            var idx: usize = 0;
            while (idx < n) : (idx += 1) {
                const crate = stacks01.items[from].pop();
                try stacks01.items[to].append(crate);
            }
        }

        // part02
        {
            const pop_start = stacks02.items[from].items.len - n;
            try stacks02.items[to].appendSlice(stacks02.items[from].items[pop_start..]);
            stacks02.items[from].shrinkRetainingCapacity(pop_start);
        }
    }

    part01 = try writeStacksTop(stacks01, alloc);
    part02 = try writeStacksTop(stacks02, alloc);

    return .{ .part01 = part01, .part02 = part02 };
}

const Solution = struct {
    part01: []const u8,
    part02: []const u8,
};

const Stack = std.ArrayList(u8);

// in problem, stacks are 1-idx, so just ignore the 0 idx
const Stacks = std.ArrayList(Stack);

/// Caller frees
fn copyStacks(stacks: Stacks, alloc: Allocator) !Stacks {
    var res = Stacks.init(alloc);
    for (stacks.items) |*stack| {
        try res.append(try stack.clone());
    }

    return res;
}

/// Caller must free
fn writeStacksTop(stacks: Stacks, alloc: Allocator) ![]const u8 {
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();
    var writer = buf.writer();

    // ignore 0 idx
    var idx: usize = 1;
    while (idx < stacks.items.len) : (idx += 1) {
        const stack = stacks.items[idx];
        const stack_top = stack.items[stack.items.len - 1];
        try writer.writeByte(stack_top);
    }

    return buf.toOwnedSlice();
}

/// Takes whole input
///
/// Returns
/// - Stacks state as defined in header
/// - Moves input in original string form (input, but skipped past header)
fn parseHeader(input: []const u8, alloc: Allocator) !struct { stacks: Stacks, remainder: []const u8 } {
    const header_end = std.mem.indexOf(u8, input, "\n\n").?;
    const header = input[0..header_end];
    const remainder = input[header_end + 2 ..];

    const last_line_idx = std.mem.lastIndexOf(u8, header, "\n").? + 1;
    const last_line = header[last_line_idx..];
    const line_len = last_line.len;

    // Add one, since it's 1-idx
    const n_stacks = blk: {
        var it = std.mem.tokenize(u8, last_line, " ");
        var n: usize = 0;
        while (it.next()) |chars| {
            const c = chars[0];
            if (c != ' ') {
                n += 1;
            }
        }
        break :blk n;
    };

    var stacks = Stacks.init(alloc);
    var idx: usize = 0;
    while (idx < n_stacks + 1) : (idx += 1) {
        try stacks.append(Stack.init(alloc));
    }

    // for each line, for each field
    var lines = std.mem.tokenize(u8, header[0..last_line_idx], "\n");
    while (lines.next()) |line| {
        var line_idx: usize = 1;
        var stack_idx: usize = 1;
        while (line_idx < line_len) : ({
            line_idx += 4;
            stack_idx += 1;
        }) {
            const c = line[line_idx];
            if (c != ' ') {
                try stacks.items[stack_idx].append(c);
            }
        }
    }

    // hard to do reverse iterator in zig
    for (stacks.items) |stack| std.mem.reverse(u8, stack.items);

    return .{ .stacks = stacks, .remainder = remainder };
}

test "test_day_05" {
    const input =
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    ;

    const out = try run(input, std.testing.allocator);
    defer {
        std.testing.allocator.free(out.part01);
        std.testing.allocator.free(out.part02);
    }
    try expectEqualSlices(u8, out.part01, "CMZ");
    try expectEqualSlices(u8, out.part02, "MCD");
}
