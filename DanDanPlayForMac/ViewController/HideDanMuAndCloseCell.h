//
//  HideDanMuAndCloseCell.h
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/2/11.
//  Copyright © 2016年 JimHuang. All rights reserved.
//
#import <Cocoa/Cocoa.h>

@interface HideDanMuAndCloseCell : NSView
@property (copy, nonatomic) void(^closeBlock)();
@property (copy, nonatomic) void(^selectBlock)(NSInteger num, NSInteger status);
@end
