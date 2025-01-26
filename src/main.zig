const std = @import("std");
const ThreadPool = @import("thread-pool.zig").ThreadPool;

fn log() void {
    std.debug.print("Hello from the thread\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var threadPool = try ThreadPool.init(.{ .allocator = allocator, .threads_count = 10 });
    defer threadPool.deinit();

    try threadPool.spawn(log);
    try threadPool.spawn(log);
    try threadPool.spawn(log);

    std.time.sleep(2000 * std.time.ns_per_ms);
}
