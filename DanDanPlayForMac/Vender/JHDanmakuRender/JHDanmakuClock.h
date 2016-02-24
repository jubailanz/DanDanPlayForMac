//
//  JHDanmakuClock.h
//  JHDanmakuRenderDemo
//
//  Created by JimHuang on 16/2/22.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^timeBlock)(NSTimeInterval time);

@interface JHDanmakuClock : NSObject
@property(nonatomic,assign)CGFloat speed;
+ (instancetype)clockWithHandler:(timeBlock)block;
- (void)setCurrentTime:(NSTimeInterval)currentTime;
- (void)start;
- (void)stop;
- (void)pause;
@end
