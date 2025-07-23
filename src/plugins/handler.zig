const std = @import("std");

pub const Interface = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
    help: [*:0]const u8,
    ptr: *Zigface,
};

pub const Zigface = struct {
    name: []const u8 = "Heisenberg",
    age: u32 = 30,

    pub fn sayMyName(self: Zigface) void {
        std.debug.print("{s}\n", .{self.name});
    }

    pub fn happyBirthday(self: *Zigface) void {
        self.age += 1;
        std.debug.print("happy birthday!, you are now {d} years old!\n", .{self.age});
    }
};
