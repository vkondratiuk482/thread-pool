const std = @import("std");

const Task = *const fn (str: []const u8) void;

const Options = struct {
    threads_count: ?u8 = null,
    allocator: std.mem.Allocator,
};

const optimal_thread_count = @max(1, std.Thread.getCpuCount() catch 1);

pub const ThreadPool = struct {
    threads: []std.Thread,
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,
    condition: std.Thread.Condition,
    task_queue: std.SinglyLinkedList(Task),

    const Self = @This();

    // we need to init the pool with undefined
    // and then call the constructor passing the reference
    // so that we can pass the pointer to the pool while spawning threads
    pub fn init(pool: *Self, options: Options) ThreadPool {
        const thread_count = options.threads_count orelse optimal_thread_count;

        const threads = try options.allocator.alloc(std.Thread, thread_count);
        errdefer options.allocator.free(threads);

        for (0..thread_count) |i| {
            threads[i] = std.Thread.spawn(.{}, worker, .{pool});
        }

        return ThreadPool{
            .threads = threads,
            .mutex = .{},
            .condition = .{},
            .task_queue = .{},
            .allocator = options.allocator,
        };
    }

    pub fn deinit(self: *Self) void  {
        for (self.threads) |thread| {
            thread.join();
        }
        self.allocator.free(self.threads);
    }

    fn worker(self: *Self) void {}
};
