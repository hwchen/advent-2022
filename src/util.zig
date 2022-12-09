const std = @import("std");

// N is row idx, M is col idx
pub fn Grid(comptime N: comptime_int, comptime M: comptime_int) type {
    return struct {
        items: [N * M]u8,

        pub fn get(self: @This(), row: usize, col: usize) u8 {
            return self.items[N * row + col];
        }
    };
}

// N is row idx, M is col idx
pub fn BitGrid(comptime N: comptime_int, comptime M: comptime_int) type {
    return struct {
        bits: BitsType,

        const Self = @This();

        const BitsType = @Type(.{ .Int = .{
            .bits = N * M,
            .signedness = .unsigned,
        } });

        const ShiftType = @Type(.{ .Int = .{
            .bits = std.math.log2(N * M) + 1,
            .signedness = .unsigned,
        } });

        pub fn zero() Self {
            return .{ .bits = 0 };
        }

        pub fn set(self: *Self, n: usize, m: usize) void {
            const idx = @intCast(ShiftType, n * N + m);
            self.bits |= @as(BitsType, 1) << @intCast(ShiftType, idx);
        }
    };
}
