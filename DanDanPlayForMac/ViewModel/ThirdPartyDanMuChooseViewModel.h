//
//  ThirdPartyDanMuChooseViewModel.h
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/2/6.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "BaseViewModel.h"
#import "VideoInfoModel.h"
/**
 *  该类用于继承
 */
@class VideoInfoDataModel;
@interface ThirdPartyDanMuChooseViewModel : BaseViewModel
@property (strong, nonatomic) NSString *aid;
@property (strong, nonatomic) NSArray <VideoInfoDataModel *>*videos;

/**
 *  分集总数
 *
 *  @return 总数
 */
- (NSInteger)episodeCount;
/**
 *  当前行分集标题
 *
 *  @param index 当前行
 *
 *  @return 标题
 */
- (NSString *)episodeTitleWithIndex:(NSInteger)index;
/**
 *  当前行弹幕id
 *
 *  @param index 当前行
 *
 *  @return 弹幕id
 */
- (NSString *)danMuKuWithIndex:(NSInteger)index;
/**
 *  根据aid获取视频详情 主要是cid
 *
 *  @param complete 回调
 */
- (void)refreshCompletionHandler:(void(^)(NSError *error))complete;
/**
 *  下载第三方弹幕
 *
 *  @param index    下标
 *  @param complete 回调
 */
- (void)downThirdPartyDanMuWithIndex:(NSInteger)index completionHandler:(void(^)(id responseObj))complete;
/**
 *  根据aid初始化
 *
 *  @param aid 视频aid
 *
 *  @return self
 */
- (instancetype)initWithAid:(NSString *)aid;
@end
