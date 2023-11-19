const std = @import("std");
const net = std.net;

const ParsingError = error{InvalidMethod};

const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,

    pub fn from(s: []const u8) !Method {
        if (std.mem.eql(u8, s, "GET")) return .GET;
        if (std.mem.eql(u8, s, "POST")) return .POST;
        if (std.mem.eql(u8, s, "PUT")) return .PUT;
        if (std.mem.eql(u8, s, "PATCH")) return .PATCH;
        if (std.mem.eql(u8, s, "DELETE")) return .DELETE;
        return ParsingError.InvalidMethod;
    }
};

pub const Context = struct {
    method: Method,
    uri: []const u8,
    version: []const u8,
    headers: std.StringHashMap([]const u8),
    stream: net.Stream,

    pub fn body(self: *Context) net.Stream.Reader {
        return self.stream.reader();
    }

    pub fn response(self: *Context) net.Stream.Writer {
        return self.stream.writer();
    }

    pub fn debug(self: *Context) void {
        std.debug.print("Method: {}\nURI: {s}\nVersion: {s}\n", .{ self.method, self.uri, self.version });
        var headers_iter = self.headers.iterator();
        while (headers_iter.next()) |header| {
            std.debug.print("{s}: {s}\n", .{ header.key_ptr.*, header.value_ptr.* });
        }
    }

    pub fn init(allocator: std.mem.Allocator, stream: net.Stream) !Context {
        // method, uri, ver etc etc
        var line = try stream.reader().readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
        line = line[0..line.len];
        var line_iter = std.mem.split(u8, line, " ");

        const method = line_iter.next().?;
        const uri = line_iter.next().?;
        const version = line_iter.next().?;

        var headers = std.StringHashMap([]const u8).init(allocator);

        // headers
        while (true) {
            var next_line = try stream.reader().readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
            next_line = next_line[0..next_line.len];

            if (next_line.len == 1 and next_line[0] == '\r')
                break;

            var next_line_iter = std.mem.split(u8, next_line, ":");
            const key = next_line_iter.next().?;
            var value = next_line_iter.next().?;

            if (value[0] == ' ')
                value = value[1..];

            try headers.put(key, value);
        }

        return Context{
            .method = try Method.from(method),
            .uri = uri,
            .version = version,
            .headers = headers,
            .stream = stream,
        };
    }
};
