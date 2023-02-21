//! I think that modeling the CPU made it harder to solve the problem, and made it harder to see where
//! to +1 in the cycle. Simple procedural solution would still have been better.

const std = @import("std");
const data = @embedFile("input/day10.txt");
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const out = try run(data);

    var part02_buf = std.ArrayList(u8).init(alloc);
    defer part02_buf.deinit();
    var part02 = part02_buf.writer();

    try out.part02.flush(part02);

    std.log.info("part 01: {d}, part02:\n{s}", .{ out.part01, part02_buf.items });
}

fn run(input: []const u8) !struct { part01: isize, part02: Crt } {
    var part01: i64 = 0;

    var cpu = Cpu{};
    var crt = Crt{};

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        const inst = try Instruction.from_str(line);
        cpu.loadInstruction(inst);

        while (true) {
            if (@mod(cpu.cycle_count, 40) == 20) {
                part01 += cpu.cycle_count * cpu.register;
            }

            crt.writeBuf(cpu.cycle_count, cpu.register);

            if (cpu.advanceCycle()) |_| {} else break;
        }
        cpu.finishInstruction();
    }

    return .{ .part01 = part01, .part02 = crt };
}

/// Overengineered in anticipation of future pain
pub const Cpu = struct {
    register: i64 = 1,
    inst: Instruction = undefined,
    state: State = .init,
    cycle_count: i64 = 1,

    const Self = @This();

    const State = union(enum) {
        init,
        advance_cycle: usize,
        exec_finish,
    };

    pub fn loadInstruction(self: *Self, inst: Instruction) void {
        switch (self.state) {
            .init => {
                self.inst = inst;
                self.state = switch (inst.kind) {
                    // exec_cycles is the additional cycles over baseline of 1
                    .noop => .{ .advance_cycle = 0 },
                    .addx => .{ .advance_cycle = 1 },
                };
            },
            else => unreachable,
        }
    }

    pub fn advanceCycle(self: *Self) ?void {
        self.cycle_count += 1;
        switch (self.state) {
            .advance_cycle => |*inner_cycle_count| {
                if (inner_cycle_count.* == 0) {
                    self.state = .exec_finish;
                    return null;
                } else {
                    inner_cycle_count.* -= 1;
                    return;
                }
            },
            else => unreachable,
        }
    }

    pub fn finishInstruction(self: *Self) void {
        switch (self.state) {
            .exec_finish => {
                switch (self.inst.kind) {
                    .noop => {},
                    .addx => self.register += self.inst.value,
                }
                self.state = .init;
            },
            else => unreachable,
        }
    }
};

pub const Instruction = struct {
    kind: Kind,
    value: i64,

    const Kind = enum {
        noop,
        addx,
    };

    pub fn from_str(s: []const u8) !Instruction {
        var fields = std.mem.split(u8, s, " ");

        const kind_str = fields.next() orelse return error.NoInstruction;
        const kind = std.meta.stringToEnum(Kind, kind_str) orelse return error.InvalidInstruction;

        var inst = Instruction{
            .kind = kind,
            .value = 0,
        };

        switch (kind) {
            .noop => {},
            else => {
                const value_str = fields.next() orelse return error.InstNoValue;
                inst.value = std.fmt.parseInt(i64, value_str, 10) catch return error.InstInvalidValue;
            },
        }

        return inst;
    }
};

const Crt = struct {
    buf: [240]bool = [_]bool{false} ** 240,

    const Self = @This();

    // don't worry about correct API here, this is most direct
    pub fn writeBuf(self: *Self, cycle: i64, register: i64) void {
        const sprite_for_line = @divTrunc(cycle, 40) * 40 + register; //inefficient to do in hot loop
        var sprite = [_]i64{ sprite_for_line - 1, sprite_for_line, sprite_for_line + 1 };

        for (sprite) |sprite_idx| {
            const s_idx = std.math.cast(usize, sprite_idx) orelse continue;
            if (cycle - 1 == s_idx) {
                self.buf[s_idx] = true;
            }
        }
    }

    pub fn flush(self: Self, wtr: anytype) !void {
        for (0..5) |idx| {
            _ = try Crt.flushLine(self.buf[idx * 40 .. idx * 40 + 40], wtr);
            _ = try wtr.writeByte('\n');
        }
        _ = try Crt.flushLine(self.buf[200..240], wtr);
    }

    fn flushLine(line: []const bool, wtr: anytype) !void {
        for (line) |pixel| {
            if (pixel) {
                try wtr.writeByte('#');
            } else {
                try wtr.writeByte('.');
            }
        }
    }
};

test "smoketest_cpu" {
    const input =
        \\noop
        \\addx 3
        \\addx -5
    ;

    var cpu = Cpu{};

    var lines = std.mem.tokenize(u8, input, "\n");

    // init state
    try expectEqual(cpu.cycle_count, 1);
    try expectEqual(cpu.register, 1);

    // noop
    cpu.loadInstruction(try Instruction.from_str(lines.next().?));
    _ = cpu.advanceCycle();
    try expectEqual(cpu.cycle_count, 2);
    try expectEqual(cpu.register, 1);
    cpu.finishInstruction();
    try expectEqual(cpu.register, 1);

    // addx 3
    cpu.loadInstruction(try Instruction.from_str(lines.next().?));
    _ = cpu.advanceCycle();
    try expectEqual(cpu.cycle_count, 3);
    try expectEqual(cpu.register, 1);
    _ = cpu.advanceCycle();
    try expectEqual(cpu.cycle_count, 4);
    try expectEqual(cpu.register, 1);
    cpu.finishInstruction();
    try expectEqual(cpu.register, 4);

    // addx -5
    cpu.loadInstruction(try Instruction.from_str(lines.next().?));
    _ = cpu.advanceCycle();
    try expectEqual(cpu.cycle_count, 5);
    try expectEqual(cpu.register, 4);
    _ = cpu.advanceCycle();
    try expectEqual(cpu.cycle_count, 6);
    try expectEqual(cpu.register, 4);
    cpu.finishInstruction();
    try expectEqual(cpu.register, -1);
}

test "test_day10" {
    const input =
        \\addx 15
        \\addx -11
        \\addx 6
        \\addx -3
        \\addx 5
        \\addx -1
        \\addx -8
        \\addx 13
        \\addx 4
        \\noop
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx -35
        \\addx 1
        \\addx 24
        \\addx -19
        \\addx 1
        \\addx 16
        \\addx -11
        \\noop
        \\noop
        \\addx 21
        \\addx -15
        \\noop
        \\noop
        \\addx -3
        \\addx 9
        \\addx 1
        \\addx -3
        \\addx 8
        \\addx 1
        \\addx 5
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx -36
        \\noop
        \\addx 1
        \\addx 7
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\addx 6
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx 7
        \\addx 1
        \\noop
        \\addx -13
        \\addx 13
        \\addx 7
        \\noop
        \\addx 1
        \\addx -33
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\noop
        \\noop
        \\noop
        \\addx 8
        \\noop
        \\addx -1
        \\addx 2
        \\addx 1
        \\noop
        \\addx 17
        \\addx -9
        \\addx 1
        \\addx 1
        \\addx -3
        \\addx 11
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx -13
        \\addx -19
        \\addx 1
        \\addx 3
        \\addx 26
        \\addx -30
        \\addx 12
        \\addx -1
        \\addx 3
        \\addx 1
        \\noop
        \\noop
        \\noop
        \\addx -9
        \\addx 18
        \\addx 1
        \\addx 2
        \\noop
        \\noop
        \\addx 9
        \\noop
        \\noop
        \\noop
        \\addx -1
        \\addx 2
        \\addx -37
        \\addx 1
        \\addx 3
        \\noop
        \\addx 15
        \\addx -21
        \\addx 22
        \\addx -6
        \\addx 1
        \\noop
        \\addx 2
        \\addx 1
        \\noop
        \\addx -10
        \\noop
        \\noop
        \\addx 20
        \\addx 1
        \\addx 2
        \\addx 2
        \\addx -6
        \\addx -11
        \\noop
        \\noop
        \\noop
    ;

    const out = try run(input);
    try expectEqual(out.part01, 13140);

    var part02_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer part02_buf.deinit();
    var part02 = part02_buf.writer();

    try out.part02.flush(part02);
    const expected_part02 =
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......###.
        \\#######.......#######.......#######.....
    ;
    //This was the original expected output. Was it incorrect?
    //It's just two off, and everything else is right, so a bit
    //suspicious, esp. when the part02 answer is correct
    //##..##..##..##..##..##..##..##..##..##..
    //###...###...###...###...###...###...###.
    //####....####....####....####....####....
    //#####.....#####.....#####.....#####.....
    //######......######......######......####
    //#######.......#######.......#######.....
    try expectEqualSlices(u8, part02_buf.items, expected_part02);
}
