//
//  UpdateNetManager.h
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/3/9.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "BaseNetManager.h"
#import "VersionModel.h"

@interface UpdateNetManager : BaseNetManager
/**
 *  获取当前最新版本
 *
 *  @param complete 回调
 *
 *  @return 任务
 */
+ (NSURLSessionDataTask *)latestVersionWithCompletionHandler:(void(^)(VersionModel *model))complete;
/**
 *  下载最新版本
 *
 *  @param version  版本号
 *  @param progress 回调的进度
 *  @param complete 回调
 *
 *  @return 任务
 */
+ (NSURLSessionDownloadTask *)downLatestVersionWithVersion:(NSString *)version progress:(void (^)(NSProgress *downloadProgress))progress completionHandler:(void(^)(NSURL *filePath, DanDanPlayErrorModel *error))complete;
/**
 *  下载补丁
 *
 *  @param version  版本
 *  @param hash     补丁的md5
 *  @param complete 回调
 *
 *  @return 任务
 */
+ (NSURLSessionDownloadTask *)downPatchWithVersion:(NSString *)version hash:(NSString *)hash completionHandler:(void(^)(NSURL *filePath, DanDanPlayErrorModel *error))complete;
@end
