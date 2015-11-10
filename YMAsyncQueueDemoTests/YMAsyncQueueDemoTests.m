//
//  YMAsyncQueueDemoTests.m
//  YMAsyncQueueDemoTests
//
//  Created by 琰珂 郭 on 15/11/9.
//  Copyright © 2015年 IslandZERO. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Specta/Specta.h>

#import "YMAsyncQueue.h"

static inline void dispatch_main_after(NSTimeInterval delay, void(^ __nonnull block)()) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

SpecBegin(YMAsyncQueue)

__block YMAsyncQueue* _queue;

beforeEach(^{
  _queue = [YMAsyncQueue new];
});

describe(@"basic usage", ^{
  it(@"should work", ^{

    __block NSInteger value = 0;

    [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      dispatch_main_after(1, ^{
        value = 1;
        releaseBlock();
      });
    } name:@"BLOCK_1"];

    [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      XCTAssertEqual(value, 1);
      dispatch_main_after(1, ^{
        value = 2;
        releaseBlock();
      });
    } name:@"BLOCK_2"];

    waitUntil(^(DoneCallback done) {
      [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
        XCTAssertEqual(value, 2);
        dispatch_main_after(1, ^{
          releaseBlock();
          done();
        });
      } name:@"BLOCK_FINAL"];
    });

  });
});

describe(@"with maxlength", ^{
  it(@"should not queue after exceed", ^{
    _queue.maxLength = 1;

    BOOL success = [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      dispatch_main_after(1, releaseBlock);
    } name:@"BLOCK_1"];

    XCTAssertEqual(success, YES);

    BOOL success2= [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      dispatch_main_after(1, releaseBlock);
    } name:@"BLOCK_2"];

    XCTAssertEqual(success2,NO);
  });
});

describe(@"with timeout", ^{
  it(@"should bypass on timeout", ^{
    _queue.timeout = 2;

    __block NSInteger value = 0;

    [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      dispatch_main_after(1, ^{
        value = 1;
      });
    } name:@"BLOCK_1"];

    [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
      dispatch_main_after(1, ^{
        value = 2;
        releaseBlock();
      });
    }];

    dispatch_main_after(1.5, ^{
      XCTAssert(value == 1);
    });

    dispatch_main_after(2.5, ^{
      XCTAssert(value == 1);
    });

    dispatch_main_after(3.5, ^{
      XCTAssert(value == 2);
    });

    waitUntil(^(DoneCallback done) {
      [_queue run:^(YMAsyncQueueReleaseBlock  _Nonnull releaseBlock) {
        dispatch_main_after(1, ^{
          done();
          releaseBlock();
        });
      }];
    });
  });
});

SpecEnd
