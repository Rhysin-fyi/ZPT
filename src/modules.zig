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

pub fn LoadModules(modulename: []const u8, stdout: anytype, stdin: anytype, buf: []u8) !void {
    const LoadMods = ModulesAvail;

    var selectedModule = Module{
        .name = "",
        .descrption = "",
    };

    var found = false;
    for (LoadMods) |m| {
        if (std.mem.eql(u8, modulename, m.name)) {
            found = true;
            selectedModule = m;
            try stdout.print("Loading '{s}'\n", .{selectedModule.name});
            break;
        }
    }

    if (!found) {
        try stdout.print("Module name '{s}' not found \n", .{modulename});
    }

    while (found == true) {
        try stdout.print("zpt/{s}> ", .{selectedModule.name});
        const line = try stdin.readUntilDelimiterOrEof(buf, '\n');

        if (line == null) break;

        const input = std.mem.trim(u8, line.?, " \r\n");

        var parts = std.mem.tokenizeSequence(u8, input, " ");
        const splitLine = parts.next() orelse continue;

        if (std.mem.eql(u8, splitLine, "exit")) {
            try stdout.print("Exiting...\n", .{});
            break;
        } else if (std.mem.eql(u8, splitLine, "help")) {
            try stdout.print("Help: {s}\n", .{selectedModule.descrption});
        }
    }
}
