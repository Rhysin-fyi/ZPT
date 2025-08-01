const std = @import("std");
const Allocator = std.mem.Allocator;

// usage:
// var foo = CommandParser.init(allocator, stdin);
// defer foo.deinit();
// const command = foo.parseInputEnum(<enum_type>) catch |err| {};
// const arg1 = foo.parseNext() orelse null;
pub const CommandParser = struct {
    allocator: Allocator,
    stdin: std.fs.File.Reader,
    buf: ?[]u8 = null,
    user_tokens: std.mem.TokenIterator(u8, std.mem.DelimiterType.sequence) = undefined,

    const Self = @This();

    pub fn init(allocator: Allocator, stdin: std.fs.File.Reader) Self {
        return Self{
            .allocator = allocator,
            .stdin = stdin,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.buf) |safe_buf| {
            self.allocator.free(safe_buf);
        }
    }

    pub fn parseInputEnum(self: *Self, comptime T: type) !T {
        return std.meta.stringToEnum(T, try self.parseInput()) orelse return error.StringToEnumFailed;
    }

    pub fn parseNextEnum(self: *Self, comptime T: type) !T {
        return std.meta.stringToEnum(
            T,
            self.parseNext() orelse return error.NoMoreArgs,
        ) orelse return error.StringToEnumFailed;
    }

    pub fn parseInput(self: *Self) ![]const u8 {
        self.buf = try self.allocator.alloc(u8, 1024);
        const line = try self.stdin.readUntilDelimiterOrEof(self.buf.?, '\n') orelse return error.ReadError;
        const input = std.mem.trim(u8, line, "\r\n");

        self.user_tokens = std.mem.tokenizeSequence(u8, input, " ");
        return self.user_tokens.next() orelse return error.NoMoreArgs;
    }

    pub fn parseNext(self: *Self) ?[]const u8 {
        return self.user_tokens.next() orelse null;
    }
};
