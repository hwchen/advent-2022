const std = @import("std");
const mem = std.mem;
const data = @embedFile("input/day11.txt");
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const parseInt = std.fmt.parseInt;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const out = try run(data, alloc);

    std.log.info("part 01: {d}, part02:{d}", .{ out[0], out[1] });
}

fn run(comptime input: []const u8, alloc: Allocator) !struct { usize, usize } {
    const num_monkeys = comptime blk: {
        @setEvalBranchQuota(10_000);
        var res: usize = 0;
        var monkeys = mem.split(u8, input, "\n\n");
        while (monkeys.next()) |_| {
            res += 1;
        }

        break :blk res;
    };

    // parse

    var queues = [_]ArrayList(usize){undefined} ** num_monkeys;
    for (queues) |*queue| {
        queue.* = ArrayList(usize).init(alloc);
    }
    defer for (queues) |queue| queue.deinit();
    var operations = [_]Operation{undefined} ** num_monkeys;
    var tests = [_]Test{undefined} ** num_monkeys;

    var monkeys_init = mem.split(u8, input, "\n\n");
    var idx: usize = 0;
    while (monkeys_init.next()) |monkey_init_lines| {
        var monkey_init = mem.tokenize(u8, monkey_init_lines, "\n");
        _ = monkey_init.next().?; // skip header

        var starting_items_it = mem.tokenize(u8, monkey_init.next().?[18..], ", ");
        while (starting_items_it.next()) |item| {
            try queues[idx].append(try std.fmt.parseInt(usize, item, 10));
        }

        var operation_str = monkey_init.next().?;
        var op_char = operation_str[23];
        var operation_rhs = std.fmt.parseInt(usize, operation_str[25..], 10) catch null;
        const operation = Operation{
            .op = Operation.Op.from_char(op_char),
            .rhs = operation_rhs,
        };
        operations[idx] = operation;

        var tst = Test{
            .divisible_by = try parseInt(usize, monkey_init.next().?[21..], 10),
            .if_true = try parseInt(usize, monkey_init.next().?[29..], 10),
            .if_false = try parseInt(usize, monkey_init.next().?[30..], 10),
        };
        tests[idx] = tst;

        idx += 1;
    }

    //std.debug.print("{d}\n", .{num_monkeys});
    //std.debug.print("{any}\n", .{queues});
    //std.debug.print("{any}\n", .{operations});
    //std.debug.print("{any}\n", .{tests});

    // run program
    var inspections = [_]usize{0} ** num_monkeys;

    var round: usize = 0;
    while (round < 20) : (round += 1) {
        var monkey: usize = 0;
        while (monkey < num_monkeys) : (monkey += 1) {
            for (queues[monkey].items) |q_item| {
                const worry_level = operations[monkey].exec(q_item) / 3;
                const item_to_monkey = tests[monkey].exec(worry_level);
                try queues[item_to_monkey].append(worry_level);
                inspections[monkey] += 1;
            }
            queues[monkey].clearRetainingCapacity();
        }
    }

    std.sort.sort(usize, &inspections, {}, std.sort.desc(usize));
    //std.debug.print("{any}\n", .{inspections});

    return .{ inspections[0] * inspections[1], 0 };
}

// Is there a way to do this currying w/ fn pointers?
const Operation = struct {
    op: Op,
    rhs: ?usize,

    pub fn exec(self: Operation, old: usize) usize {
        switch (self.op) {
            .mul => if (self.rhs) |rhs| {
                return old * rhs;
            } else {
                return old * old;
            },
            .add => if (self.rhs) |rhs| {
                return old + rhs;
            } else {
                return old + old;
            },
        }
    }

    pub const Op = enum {
        add,
        mul,

        fn from_char(c: u8) Op {
            return switch (c) {
                '+' => .add,
                '*' => .mul,
                else => unreachable,
            };
        }
    };
};

const Test = struct {
    divisible_by: usize,
    if_true: usize,
    if_false: usize,

    pub fn exec(self: Test, x: usize) usize {
        return if (x % self.divisible_by == 0)
            self.if_true
        else
            self.if_false;
    }
};

test "test_day11" {
    const input =
        \\Monkey 0:
        \\  Starting items: 79, 98
        \\  Operation: new = old * 19
        \\  Test: divisible by 23
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 3
        \\
        \\Monkey 1:
        \\  Starting items: 54, 65, 75, 74
        \\  Operation: new = old + 6
        \\  Test: divisible by 19
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 0
        \\
        \\Monkey 2:
        \\  Starting items: 79, 60, 97
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 1
        \\    If false: throw to monkey 3
        \\
        \\Monkey 3:
        \\  Starting items: 74
        \\  Operation: new = old + 3
        \\  Test: divisible by 17
        \\    If true: throw to monkey 0
        \\    If false: throw to monkey 1
    ;

    const out = try run(input, std.testing.allocator);
    try expectEqual(out[0], 10605);
    try expectEqual(out[1], 0);
}
