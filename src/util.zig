const std = @import("std");

// N is row idx, M is col idx
pub fn Grid(comptime M: comptime_int, comptime N: comptime_int) type {
    return struct {
        items: [M * N]u8,

        pub fn get(self: @This(), row: usize, col: usize) u8 {
            return self.items[M * row + col];
        }
    };
}

// N is row idx, M is col idx
pub fn BitGrid(comptime M: comptime_int, comptime N: comptime_int) type {
    return struct {
        bits: BitsType,

        const Self = @This();

        const BitsType = @Type(.{ .Int = .{
            .bits = M * N,
            .signedness = .unsigned,
        } });

        const ShiftType = @Type(.{ .Int = .{
            .bits = std.math.log2(M * N) + 1,
            .signedness = .unsigned,
        } });

        pub fn zero() Self {
            return .{ .bits = 0 };
        }

        pub fn set(self: *Self, m: usize, n: usize) void {
            const idx = @intCast(ShiftType, m * M + n);
            self.bits |= @as(BitsType, 1) << @intCast(ShiftType, idx);
        }
    };
}

pub fn Set(comptime T: type) type {
    return std.AutoHashMap(T, void);
}
