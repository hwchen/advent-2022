const std = @import("std");
const data = @embedFile("input/day10.txt");
const expectEqual = std.testing.expectEqual;

// required to print if release-fast
pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const out = try run(data);
    std.log.info("part 01: {d}, part02: {d}", .{ out.part01, out.part02 });
}

fn run(input: []const u8) !struct { part01: isize, part02: isize } {
    var part01: i64 = 0;

    var cpu = Cpu{};

    var lines = std.mem.tokenize(u8, input, "\n");
    while (lines.next()) |line| {
        const inst = try Instruction.from_str(line);
        cpu.loadInstruction(inst);

        while (true) {
            if (@mod(cpu.cycle_count, 40) == 20) {
                part01 += cpu.cycle_count * cpu.register;
            }

            if (cpu.advanceCycle()) |_| {} else break;
        }
        cpu.finishInstruction();
    }

    return .{ .part01 = part01, .part02 = 0 };
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
    try expectEqual(out.part02, 0);
}
