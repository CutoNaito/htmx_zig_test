const std = @import("std");
const net = std.net;

// tohle pak rozdelim nejak XDDD
const ParsingError = error{InvalidMethod};

const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,

    pub fn from(s: []const u8) !Method {
        switch (true) {
            std.mem.eql(u8, s, "GET") => return .GET, // this is cool i love it i love you zig
            std.mem.eql(u8, s, "POST") => return .POST,
            std.mem.eql(u8, s, "PUT") => return .PUT,
            std.mem.eql(u8, s, "PATCH") => return .PATCH,
            std.mem.eql(u8, s, "DELETE") => return .DELETE,
            else => ParsingError.InvalidMethod,
        }
    }
};

const Request = struct {
    method: []const u8,
    uri: []const u8,
    version: []const u8,
    headers: std.StringHashMap([]const u8),
    body: net.Stream.reader(),

    pub fn debug(self: *Request) void {
        std.debug.print("Method: {s}\nURI: {s}\nVersion: {s}\n", .{ self.method, self.uri, self.version });
        var headers_iter = self.headers.iterator();
        while (headers_iter.next) |header| {
            std.debug.print("{s}: {s}\n", .{ header.key, header.value });
        }
    }
};

fn handler(allocator: std.mem.Allocator, stream: net.Stream) !void {
    defer stream.close();

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

    std.debug.print("Method: {s}\nURI: {s}\nVersion: {s}\nHeaders:{}\n", .{ method, uri, version, headers });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    var stream_server = net.StreamServer.init(.{});
    defer stream_server.close();
    const address = try net.Address.resolveIp("127.0.0.1", 8080);
    try stream_server.listen(address);

    while (true) {
        const conn = try stream_server.accept();
        try handler(allocator, conn.stream);
    }
}
