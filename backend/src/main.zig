const std = @import("std");
const net = std.net;
const rq = @import("request.zig");

pub fn handler(allocator: std.mem.Allocator, stream: net.Stream) !void {
    defer stream.close();

    var context = try rq.Context.init(allocator, stream);
    context.debug();
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
