//
//  PlayerListViewController.h
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/7/18.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "BaseViewController.h"
#import "PlayViewModel.h"
/**
 *  播放列表控制器
 */
@interface PlayerListViewController : BaseViewController
@property (strong, atomic) PlayViewModel *vm;
@property (weak) IBOutlet NSTableView *tableView;
//删除行回调
@property (copy, nonatomic) void(^deleteRowCallBack)(NSUInteger row);
//双击一行回调
@property (copy, nonatomic) void(^doubleClickRowCallBack)(NSUInteger row);
@end
