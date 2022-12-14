const std = @import("std");

pub const Point = @Vector(2, isize);

pub fn StaticGrid(comptime T: type, comptime X_: comptime_int, comptime Y_: comptime_int) type {
    return struct {
        items: [X * Y]T,

        pub const X = X_;
        pub const Y = Y_;

        const Self = @This();

        pub fn get(self: Self, x: usize, y: usize) T {
            return self.items[Y * y + x];
        }

        pub fn set(self: *Self, elem: T, x: usize, y: usize) void {
            self.items[Y * y + x] = elem;
        }

        pub fn getPoint(self: Self, pt: Point) T {
            return self.items[X * @intCast(usize, pt[1]) + @intCast(usize, pt[0])];
        }

        pub fn indexFromRaw(raw_idx: usize) Point {
            const x = @intCast(isize, raw_idx % Self.X);
            const y = @intCast(isize, raw_idx / Self.X);
            return Point{ x, y };
        }
    };
}

pub fn BitGrid(comptime X: comptime_int, comptime Y: comptime_int) type {
    return struct {
        bits: BitsType,

        const Self = @This();

        const BitsType = @Type(.{ .Int = .{
            .bits = X * Y,
            .signedness = .unsigned,
        } });

        const ShiftType = @Type(.{ .Int = .{
            .bits = std.math.log2(X * Y) + 1,
            .signedness = .unsigned,
        } });

        pub fn zero() Self {
            return .{ .bits = 0 };
        }

        pub fn set(self: *Self, x: usize, y: usize) void {
            const idx = @intCast(ShiftType, y * Y + x);
            self.bits |= @as(BitsType, 1) << @intCast(ShiftType, idx);
        }
    };
}

pub fn Set(comptime T: type) type {
    return std.AutoHashMap(T, void);
}
