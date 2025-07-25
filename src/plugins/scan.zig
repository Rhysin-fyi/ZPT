const Interface = @import("handler.zig").Interface;
const Option = @import("handler.zig").Option;



const default_option = [_]Option  {
    .{ .key = "RHOST", .value = "127.0.0.1", .help = "Help menu" },
    .{ .key = "RPORT", .value = "4444", .help = "Help 2 menu" },
};

const set_default = Interface{
    .name = "NAME",
    .value = "42",
    .help = "This is a default handler interface.",
};


export fn GetOptions( x : u8 ) callconv(.C) *Option{

    return @constCast(&default_option[x]);
}

export fn GetLn () callconv(.C) u8{
    return default_option.len;
}


export fn SetDefault() callconv(.C) *Interface {
    return @constCast(&set_default);
}


