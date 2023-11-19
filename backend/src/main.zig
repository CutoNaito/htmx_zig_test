const std = @import("std");
const net = std.net;

pub fn main() !void {
    var stream_server = net.StreamServer.init(.{});
    defer stream_server.close();
    const address = try net.Address.resolveIp("127.0.0.1", 8080);
    try stream_server.listen(address);

    while (true) {
        const conn = try stream_server.accept();
        try handler(conn.stream);
    }
}

fn handler(stream: net.Stream) !void {
    defer stream.close();
    try stream.writer().print("Hello world\n", .{});
}
