const std = @import("std");

pub const Module = struct {
    name: []const u8,
    descrption: []const u8,
};

pub const ModulesAvail = [_]Module{
    .{ .name = "exploit", .descrption = "Exploit modules for known vulns" },
    .{ .name = "scanner", .descrption = "Port and service scanners" },
    .{ .name = "rats", .descrption = "Remote Access Trojan" },
};

pub fn GetAllModules() []const Module {
    return ModulesAvail[0..];
}
