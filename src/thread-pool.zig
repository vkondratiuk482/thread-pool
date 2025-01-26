const std = @import("std");

const Task = *const fn () void;

const Options = struct {
    threads_count: ?u8 = null,
    allocator: std.mem.Allocator,
};

const ThreadPoolError = error{
    Stopped,
};

pub const ThreadPool = struct {
    stopped: bool,
    threads: []std.Thread,
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,
    condition: std.Thread.Condition,
    task_queue: std.DoublyLinkedList(Task),

    const Self = @This();

    pub fn init(options: Options) !*ThreadPool {
        const thread_count = options.threads_count orelse optimalThreadCount();

        const threads = try options.allocator.alloc(std.Thread, thread_count);
        errdefer options.allocator.free(threads);

        const pool = try options.allocator.create(ThreadPool);
        errdefer options.allocator.destroy(pool);

        pool.* = ThreadPool{
            .threads = threads,
            .mutex = .{},
            .condition = .{},
            .task_queue = .{},
            .stopped = false,
            .allocator = options.allocator,
        };

        for (0..thread_count) |i| {
            threads[i] = try std.Thread.spawn(.{}, worker, .{pool});
        }

        return pool;
    }

    pub fn spawn(self: *Self, task: Task) !void {
        const node = try self.allocator.create(std.DoublyLinkedList(Task).Node);
        node.*.data = task;

        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.stopped) {
            self.allocator.destroy(node);
            return ThreadPoolError.Stopped;
        }

        self.task_queue.append(node);
        self.condition.signal();
    }

    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        self.stopped = true;
        self.mutex.unlock();

        self.condition.broadcast();

        for (self.threads) |thread| {
            thread.join();
        }
        self.allocator.free(self.threads);
    }

    fn worker(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        while (true) {
            while (self.task_queue.popFirst()) |unwrapped| {
                self.mutex.unlock();
                defer self.mutex.lock();

                unwrapped.data();
                self.allocator.destroy(unwrapped);
            }

            if (self.stopped) {
                break;
            }

            self.condition.wait(&self.mutex);
        }
    }

    fn optimalThreadCount() u64 {
        return @max(1, std.Thread.getCpuCount() catch 1);
    }
};
