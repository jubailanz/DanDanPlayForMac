//
//  JHPlayerItem.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/4/21.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "JHPlayerItem.h"

@implementation JHPlayerItem
- (instancetype)initWithURL:(NSURL *)URL {
    if (self = [super initWithURL:URL]) {
        [self addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([self.delegate respondsToSelector:@selector(JHPlayerItem:bufferStartTime:bufferOnceTime:)]) {
        CMTimeRange range = self.loadedTimeRanges.firstObject.CMTimeRangeValue;
        [self.delegate JHPlayerItem:self bufferStartTime:CMTimeGetSeconds(range.start) bufferOnceTime:CMTimeGetSeconds(range.duration)];
    }
}

- (void)dealloc {
    if (self.loadedTimeRanges.firstObject) {
        [self removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
}
@end
