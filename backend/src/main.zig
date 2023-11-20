const std = @import("std");
const net = std.net;
const rq = @import("request.zig");
const libcoro = @import("libcoro");

fn handler(allocator: std.mem.Allocator, stream: net.Stream) !void {
    defer stream.close();

    var context = try rq.Context.init(allocator, stream);
    context.debug();

    try context.response(rq.Status.OK, null, "Hello, World!");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const stack = try libcoro.stackAlloc(allocator, null);
    defer allocator.free(stack);

    var stream_server = net.StreamServer.init(.{});
    defer stream_server.close();

    const address = try net.Address.resolveIp("127.0.0.1", 8080);
    try stream_server.listen(address);

    var frames = std.ArrayList(libcoro.FrameT(handler, .{})).init(allocator);
    while (true) {
        const conn = try stream_server.accept();
        frames.append(try libcoro.xasync(handler, .{ allocator, conn.stream }, stack));
    }
}
