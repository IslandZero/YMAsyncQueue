# YMAsyncQueue
YMAsyncQueue is a util class to execute block-based async methods serially.

# Prerequisite

YMAsyncQueue uses `__nonnull` annotation and Objective-C generic classes, thus Xcode 7+ is required.

# Usage

* Create a instance
* Queue blocks using `-run:name:`
* Invoke `releaseBlock` once block finished

Queue will run all queued blocks serially

```objective-c
self.queue = [[YMAsyncQueue alloc] init];

[queue run:^(YMAsyncQueueReleaseBlock releaseBlock){
  [self doSomethingAsyncWithComplete:^{
    // Invoke releaseBlock after complete thus next block queued could run
    releaseBlock();
  }];
} name:@"BLOCK_1"]
```

# License

See `LICENSE` file
