//
//  YMAsyncQueue.m
//  YMXian
//
//  Created by 琰珂 郭 on 15/10/12.
//  Copyright © 2015年 YANKE Guo. All rights reserved.
//

#import "YMAsyncQueue.h"

#pragma mark - YMAsyncQueue Utils

/**
 *  A block accepts no params and returns BOOL
 */
typedef BOOL(^YMAsyncQueueBOOLBlock) ();

/**
 *  If running on main thread, execute block immediately, else dispatch_async the block to main thread
 *
 *  @param block block to execute
 *
 */
static inline void dispatch_main_async_safe(void(^ __nonnull block)()) {
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

/**
 *  Shortcut to dispatch a block on main thread after delay
 *
 *  @param delay delay in NSTimeInterval
 *  @param block block to execute
 *
 */
static inline void dispatch_main_after(NSTimeInterval delay, void(^ __nonnull block)()) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

/**
 *  Accept a block named block2 as input, create a block named block1, no matter how many times block1 is invoked, invoke block2 only once
 *
 *  @param block2
 *
 *  @return block1 (return if it is the first time block2 invoked)
 */
static inline YMAsyncQueueBOOLBlock __nonnull YMAsyncQueueCreateOnceBlock(void(^ __nonnull block2)()) {
  //  Flag for invoked
  __block BOOL invoked = NO;

  //  Create the block
  return ^BOOL {
    if (invoked) {
      return NO;
    }
    invoked = YES;
    block2();
    return YES;
  };
}

#define YMAsyncQueueIsEpsilon(VALUE) (VALUE <= DBL_MIN)

#pragma mark - YMAsyncQueue

@interface YMAsyncQueue ()

/**
 *  Array of YMAsyncQueueBlock to be executed
 */
@property (nonatomic, strong) NSMutableArray<YMAsyncQueueBlock>*  queue;

/**
 *  Array of block names
 */
@property (nonatomic, strong) NSMutableArray<NSString*>*          blockNames;

/**
 *  A flag indicate whether queue is already running
 */
@property (nonatomic, assign) BOOL runningFlag;

@end

@implementation YMAsyncQueue

+ (instancetype)queue {
  return [[[self class] alloc] init];
}

- (instancetype)init {
  if (self = [super init]) {
    self.runningFlag = NO;
    self.maxLength = 0;
    self.queue = [NSMutableArray new];
    self.blockNames = [NSMutableArray new];
  }
  return self;
}

- (BOOL)run:(YMAsyncQueueBlock)block {
  return [self run:block name:nil];
}

- (BOOL)run:(YMAsyncQueueBlock)block name:(NSString *)name {
  //  Check if maxLength exceeded
  if (self.maxLength > 0 && self.queue.count > self.maxLength) { return NO; }

  //  Use pointer address as block name if name is nil
  if (name == nil) { name = [NSString stringWithFormat:@"%p", block]; }

  //  Add the block and its name
  [self.queue addObject:block];
  [self.blockNames addObject:name];

  NSLog(@"[YMAsyncQueue] block queued: %@", name);

  //  Run the queue
  [self runQueue];

  return YES;
}

- (void)runQueue {
  //  Check if the queue is already running
  if (self.runningFlag) {
    return;
  }

  //  Run the queue for real
  [self _runQueue];
}

- (void)_runQueue {
  //  Check if the queue is drain
  if (self.queue.count == 0) {
    //  Execute the drainBlock
    YMAsyncQueueDrainBlock drainBlock = self.drainBlock;
    if (drainBlock) { drainBlock(); }

    //  Clear the runningFlag and return
    self.runningFlag = NO;
    return;
  }

  //  Set the runningFlag
  self.runningFlag = YES;

  //  Execute the startBlock
  YMAsyncQueueStartBlock startBlock = self.startBlock;
  if (startBlock) { startBlock(); }

  //  Take out the block and its name
  YMAsyncQueueBlock block = [self.queue objectAtIndex:0];
  NSString* blockName     = [self.blockNames objectAtIndex:0];

  //  Put the current timeout to local variable
  NSTimeInterval timeout = self.timeout;

  //  Prepare the releaseBlock
  __weak typeof(self) _weak_self = self;
  YMAsyncQueueReleaseBlock releaseBlock = ^{
    dispatch_main_async_safe(^{
      __strong YMAsyncQueue* self = _weak_self;
      [self.queue removeObjectAtIndex:0];
      [self.blockNames removeObjectAtIndex:0];
      [self _runQueue];
    });
  };

  //  If there is a timeout set
  if (! YMAsyncQueueIsEpsilon(timeout)) {

    //  Create a once-block for releaseBlock
    YMAsyncQueueBOOLBlock block1 = YMAsyncQueueCreateOnceBlock(releaseBlock);

    //  invoke block1 for timeout
    dispatch_main_after(timeout, ^{
      if(block1()) {
        NSLog(@"[YMAsyncQueue] block expired: %@", blockName);
      }
    });

    //  invoke block2 for block execution
    dispatch_main_async_safe(^{
      block(^{
        if(block1()) {
          NSLog(@"[YMAsyncQueue] block releaseBlock called: %@", blockName);
        }
      });
    });

  } else {

    //  Execute the block, passing the releaseBlock in
    dispatch_main_async_safe(^{
      block(^{
        NSLog(@"[YMAsyncQueue] block releaseBlock called: %@", blockName);
        releaseBlock();
      });
    });

  }
}

@end
