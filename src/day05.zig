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

    var stdout = std.io.getStdOut();
    var wtr = stdout.writer();

    try run(data, alloc, wtr);
}

fn run(input: []const u8, alloc: Allocator, wtr: anytype) !void {
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
            for (0..n) |_| {
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

    try writeStacks(stacks01, wtr);
    try wtr.writeByte('\n');
    try writeStacks(stacks02, wtr);
}

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

fn writeStacks(stacks: Stacks, wtr: anytype) !void {
    // ignore 0 idx
    for (1..stacks.items.len) |idx| {
        const stack = stacks.items[idx];
        const stack_top = stack.items[stack.items.len - 1];
        try wtr.writeByte(stack_top);
    }
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

    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();
    var wtr = buf.writer();

    try run(input, std.testing.allocator, wtr);
    try expectEqualSlices(u8, buf.items, "CMZ\nMCD");
}
