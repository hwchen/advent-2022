const std = @import("std");

// N is row idx, M is col idx
pub fn StaticGrid(comptime T: type, comptime M_: comptime_int, comptime N_: comptime_int) type {
    return struct {
        items: [M * N]T,

        pub const M = M_;
        pub const N = N_;

        const Self = @This();

        pub fn get(self: Self, row: usize, col: usize) T {
            return self.items[M * row + col];
        }

        pub fn set(self: *Self, x: T, row: usize, col: usize) void {
            self.items[M * row + col] = x;
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
