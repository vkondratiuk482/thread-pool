# Thread Pool

The main idea is to get familiar with multithreading & implement ThreadPool from scratch

### Techniques

Thread-safety is achieved with:

* Mutex - locking access to shared data and preventing race conditions
* Conditional variables - wait / signal threads in order to prevent CPU burning (with endless while loops)

### Initialization

Unlike the implementation from the standard library, this one doesn't need to be explicitly initialized with `undefined` before calling the constructor, so this:

```zig
var pool: Pool = undefined;
_ = try pool.init(opt);
defer pool.deinit();
```

Becomes this

```zig
var pool = try ThreadPool.init(opt);
defer pool.deinit();
```

### Deinitialization

Deinitialization signals all threads to stop processing new tasks after they finish the current pile in the queue. Then we wait for each thread to finish processing and eventually break the loop and die

### TODO

* According to [the thread on Zig forum](https://ziggit.dev/t/locking-allocations/8172/2) it seems that not all heap allocations are thread-safe

### References
* std implementation - https://github.com/ziglang/zig/blob/master/lib/std/Thread/Pool.zig
* useful video to get more familiar with the topic - https://youtu.be/FMNnusHqjpw?si=gX0EQrx8FInyIb8Y
