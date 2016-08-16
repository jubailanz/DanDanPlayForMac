//
//  DanMuNetManager.m
//  DanWanPlayer
//
//  Created by JimHuang on 15/12/24.
//  Copyright © 2015年 JimHuang. All rights reserved.
//

#import "DanMuNetManager.h"
#import "DanMuModel.h"
#import "VideoInfoModel.h"
#import "DanMuDataFormatter.h"
#import "NSData+DanDanPlay.h"
#import "ParentDanmaku.h"
#import "NSString+Tools.h"

#import "AFHTTPDataResponseSerializer.h"

@implementation DanMuNetManager
+ (NSURLSessionDataTask *)GETWithProgramId:(NSString *)programId completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
    if (![UserDefaultManager turnOnFastMatch]) {
        //没开启快速匹配功能 直接进入匹配界面
       return [self GETThirdPartyDanmakuWithProgramId:programId completionHandler:complete];
    }
    
    return [self downOfficialDanmakuWithProgramId:programId completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
            //如果返回的对象不为空 说明有官方弹幕库 同时开启了快速匹配 直接返回 否则请求第三方弹幕库
            if ([responseObj count]) {
                complete(responseObj, error);
            }
            else {
                [self GETThirdPartyDanmakuWithProgramId:programId completionHandler:complete];
            }
    }];
}

+ (id)downOfficialDanmakuWithProgramId:(NSString *)programId completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
    if (!programId.length) {
        complete(nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeDanmakuNoExist]);
        return nil;
    }
    //找缓存
    id cache = [self danmakuCacheWithDanmakuID:programId provider:DanDanPlayDanmakuSourceOfficial isCache:NO];
    if (cache) {
        cache = [DanMuDataFormatter dicWithObj:[DanMuModel yy_modelWithDictionary: cache].comments source:DanDanPlayDanmakuSourceOfficial];
        //找用户发送缓存
        id userCache = [self danmakuCacheWithDanmakuID:programId provider:DanDanPlayDanmakuSourceOfficial isCache:YES];
        if (userCache) {
            userCache = [DanMuDataFormatter arrWithObj:userCache source:DanDanPlayDanmakuSourceCache];
            [userCache enumerateObjectsUsingBlock:^(ParentDanmaku * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSInteger time = obj.appearTime;
                if (!cache[@(time)]) {
                    cache[@(time)] = [NSMutableArray array];
                }
                [cache[@(time)] addObject:obj];
            }];
        }
        
        complete(cache, nil);
        return nil;
    }
    
    return [self GETWithPath:[@"http://acplay.net/api/v1/comment/" stringByAppendingString: programId] parameters:nil completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
        //写入缓存
        [self writeDanmakuCacheWithProvider:DanDanPlayDanmakuSourceOfficial danmakuID:programId responseObj:responseObj];
        complete([DanMuDataFormatter dicWithObj:[DanMuModel yy_modelWithDictionary: responseObj].comments source:DanDanPlayDanmakuSourceOfficial], error);
    }];
}

+ (id)downThirdPartyDanmakuWithDanmaku:(NSString *)danmaku provider:(DanDanPlayDanmakuSource)provider completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
    // danmaku:弹幕库id provider 提供者
    if (!danmaku.length) {
        complete(nil, [DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeDanmakuNoExist]);
        return nil;
    }
    
    //找缓存
    id cache = [self danmakuCacheWithDanmakuID:danmaku provider:provider isCache:NO];
    if (cache) {
        complete([DanMuDataFormatter dicWithObj:cache source:provider], nil);
        return nil;
    }
    
    if (provider == DanDanPlayDanmakuSourceBilibili) {
        NSString *path = [@"http://comment.bilibili.com/" stringByAppendingFormat:@"%@.xml", danmaku];
        return [self GETDataWithPath:path parameters:nil completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
            //写入缓存
            [self writeDanmakuCacheWithProvider:provider danmakuID:danmaku responseObj:responseObj];
            complete([DanMuDataFormatter dicWithObj:responseObj source:provider], error);
        }];
    }
    else if (provider == DanDanPlayDanmakuSourceAcfun) {
        NSString *path = [@"http://danmu.aixifan.com/" stringByAppendingString: danmaku];
        return [self GETWithPath:path parameters:nil completionHandler:^(NSArray <NSArray *>*responseObj, DanDanPlayErrorModel *error) {
            //写入缓存
            [self writeDanmakuCacheWithProvider:provider danmakuID:danmaku responseObj:responseObj];
            complete([DanMuDataFormatter dicWithObj:responseObj source:provider], error);
        }];
    }
    return nil;
}

+ (void)batchGETDanmakuInfoWithAids:(NSArray <NSString *>*)aids source:(DanDanPlayDanmakuSource)source completionHandler:(void(^)(NSArray *responseObjs, NSArray <NSURLSessionTask *>*tasks))complete {
    if (!aids.count) {
        complete(nil, nil);
        return;
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    if (source == DanDanPlayDanmakuSourceBilibili) {
        [aids enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [paths addObject:[self bilibiliDanmakuInfoRequestPathWithAid:obj page:@"1"]];
        }];
    }
    else if (source == DanDanPlayDanmakuSourceAcfun) {
        [aids enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [paths addObject:[self acfunDanmakuInfoRequestPathWithAid:obj]];
        }];
    }
    
    [self batchGETWithPaths:paths progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations, id *responseObj) {
        NSDictionary *dic = *responseObj;
        if (source == DanDanPlayDanmakuSourceBilibili) {
            *responseObj = dic[@"cid"];
        }
        else if (source == DanDanPlayDanmakuSourceAcfun) {
            *responseObj = dic[@"danmakuId"];
        }
    } completionBlock:^(NSArray *responseObjects, NSArray<NSURLSessionTask *> *tasks) {
        complete(responseObjects, tasks);
    }];
}

+ (void)batchDownDanmakuWithDanmakuIds:(NSArray <NSString *>*)danmakuIds
                                source:(DanDanPlayDanmakuSource)source
                         progressBlock:(void(^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations, id *responseObj))progressBlock
                     completionHandler:(void(^)(NSArray *responseObjs, NSArray <NSURLSessionTask *>*tasks))complete {
    if (!danmakuIds.count) {
        complete(nil, nil);
        return;
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    if (source == DanDanPlayDanmakuSourceBilibili) {
        [danmakuIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = [@"http://comment.bilibili.com/" stringByAppendingFormat:@"%@.xml", obj];
            [paths addObject:path];
        }];
    }
    else if (source == DanDanPlayDanmakuSourceAcfun) {
        [danmakuIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = [@"http://danmu.aixifan.com/" stringByAppendingString: obj];
            [paths addObject:[self acfunDanmakuInfoRequestPathWithAid:path]];
        }];
    }
    
    [self batchGETDataWithPaths:paths progressBlock:progressBlock completionBlock:^(NSArray *responseObjects, NSArray<NSURLSessionTask *> *tasks) {
        complete(responseObjects, tasks);
    }];
}

+ (NSURLSessionDataTask *)GETBiliBiliDanmakuWithAid:(NSString *)aid page:(NSUInteger)page completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
    //http://biliproxy.chinacloudsites.cn/av/46431/1?list=1
    return [self GETWithPath:[self bilibiliDanmakuInfoRequestPathWithAid:aid page:[NSString stringWithFormat:@"%lu", page]] parameters:nil completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
        complete([self pareBiliBiliVideoInfoModelWithDic:responseObj], error);
    }];
}

+ (NSURLSessionDataTask *)GETAcfunDanmakuWithAid:(NSString *)aid completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
    //http://www.talkshowcn.com/video/getVideo.aspx?id=435639 黑科技
    return [self GETWithPath:[self acfunDanmakuInfoRequestPathWithAid:aid] parameters:nil completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
        complete([self pareAcfunVideoInfoModelWithDic:responseObj], error);
    }];
}


+ (id)launchDanmakuWithModel:(DanMuDataModel *)model episodeId:(NSString *)episodeId completionHandler:(void(^)(DanDanPlayErrorModel *error))complete{
    if (!model || !episodeId.length) {
        complete([DanDanPlayErrorModel ErrorWithCode:DanDanPlayErrorTypeDanmakuNoExist]);
        return nil;
    }
    return [self PUTWithPath:[NSString stringWithFormat:@"http://acplay.net/api/v1/comment/%@?clientId=ddplaymac", episodeId] HTTPBody:[[[model launchDanmakuModel] yy_modelToJSONData] Encrypt] completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
        complete(error);
    }];
}

#pragma mark - 私有方法
/**
 *  获取第三方弹幕详情
 *
 *  @param parameters 参数字典
 *  @param complete   回调
 *
 *  @return 任务
 */
+ (id)GETThirdPartyDanmakuWithProgramId:(NSString *)programId completionHandler:(void(^)(id responseObj, DanDanPlayErrorModel *error))complete {
#warning TODO
    //http://acplay.net/api/v1/related/111240001
    
    NSString *path = [@"http://acplay.net/api/v1/related/" stringByAppendingString: programId];
    return [self GETWithPath:path parameters:nil completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSArray <NSDictionary *>*relateds = responseObj[@"Relateds"];
            NSMutableArray *paths = [NSMutableArray array];
            //装视频详情的字典
            NSMutableDictionary <NSString *, NSMutableArray *> *videoInfoDic = [NSMutableDictionary dictionary];
            for (NSDictionary *obj in relateds) {
                //视频提供者是a站
                if ([obj[@"Provider"] isEqualToString:@"Acfun.tv"]) {
                    [self acfunAidWithPath:obj[@"Url"] complectionHandler:^(NSString *aid, NSString *index) {
                        [paths addObject:[self acfunDanmakuInfoRequestPathWithAid:aid]];
                    }];
                    //视频提供者是b站
                }
                else if ([obj[@"Provider"] isEqualToString:@"BiliBili.com"]) {
                    [self bilibiliAidWithPath:obj[@"Url"] complectionHandler:^(NSString *aid, NSString *page) {
                        [paths addObject:[self bilibiliDanmakuInfoRequestPathWithAid:aid page:page]];
                    }];
                }
            }
            
            [self batchGETWithPaths:paths progressBlock:nil completionBlock:^(NSArray *responseObjects, NSArray<NSURLSessionTask *> *tasks) {
                [tasks enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSURLSessionTask class]]) {
                        if ([obj.currentRequest.URL.path containsString:@"biliproxy"]) {
                            if (!videoInfoDic[@"bilibili"]) {
                                videoInfoDic[@"bilibili"] = [NSMutableArray array];
                            }
                            BiliBiliVideoInfoModel *model = [self pareBiliBiliVideoInfoModelWithDic:responseObj];
                            if (model) {
                                [videoInfoDic[@"bilibili"] addObject:model];
                            }
                        }
                        else {
                            if (!videoInfoDic[@"acfun"]) {
                                videoInfoDic[@"acfun"] = [NSMutableArray array];
                            }
                            AcfunVideoInfoModel *model = [self pareAcfunVideoInfoModelWithDic:responseObj];
                            if (model) {
                                [videoInfoDic[@"acfun"] addObject:model];
                            }
                        }
                    }
                }];
                
                complete(videoInfoDic, error);
            }];
        }
    }];
    
    
//    return [self GETWithPath:[@"http://acplay.net/api/v1/related/" stringByAppendingString: parameters[@"id"]] parameters:nil completionHandler:^(NSDictionary *responseObj, DanDanPlayErrorModel *error) {
//        NSArray <NSDictionary *>*relateds = responseObj[@"Relateds"];
//        //装视频详情的字典
//        NSMutableDictionary <NSString *, NSMutableArray *> *videoInfoDic = [NSMutableDictionary dictionary];
//        NSMutableArray *requestArr = [NSMutableArray array];
//        
//        for (NSDictionary *obj in relateds) {
//            //视频提供者是a站
//            if ([obj[@"Provider"] isEqualToString:@"Acfun.tv"]) {
//                [requestArr addObject: [self GETAcfunDanMuWithParameters:[self acfunAidWithPath: obj[@"Url"]] completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
//                    if (!videoInfoDic[@"acfun"]) videoInfoDic[@"acfun"] = [NSMutableArray array];
//                    if (responseObj) [videoInfoDic[@"acfun"] addObject: responseObj];
//                }]];
//                //视频提供者是b站
//            }
//            else if ([obj[@"Provider"] isEqualToString:@"BiliBili.com"]){
//                [requestArr addObject: [self GETBiliBiliDanMuWithParameters:[self bilibiliAidWithPath: obj[@"Url"]] completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
//                    if (!videoInfoDic[@"bilibili"]) videoInfoDic[@"bilibili"] = [NSMutableArray array];
//                    if (responseObj) [videoInfoDic[@"bilibili"] addObject: responseObj];
//                }]];
//            }
//        }
//        
//        NSArray *operations = [AFURLConnectionOperation batchOfRequestOperations:requestArr progressBlock: nil completionBlock:^(NSArray *operations) {
//            complete(videoInfoDic, error);
//        }];
//        [[NSOperationQueue mainQueue] addOperations:@[operations.lastObject] waitUntilFinished:NO];
//    }];
}

/**
 *  获取b站视频av号 分集
 *
 *  @param path       路径
 *  @param completion 回调
 */
+ (void)bilibiliAidWithPath:(NSString *)path complectionHandler:(void(^)(NSString *aid, NSString *page))completion {
    //http://www.bilibili.com/video/av46431/index_2.html
    if (!path) {
        completion(nil, nil);
    }
    
    NSString *aid;
    NSString *index;
    NSArray *arr = [path componentsSeparatedByString:@"/"];
    for (NSString *obj in arr) {
        if ([obj hasPrefix: @"av"]) {
            aid = [obj substringFromIndex: 2];
        }
        else if ([obj hasPrefix: @"index"]) {
            index = [[obj componentsSeparatedByString: @"."].firstObject componentsSeparatedByString: @"_"].lastObject;
        }
    }
    completion(aid, index);
}
/**
 *  获取a站av号 分集
 *
 *  @param path url
 *
 *  @return av号 分集
 */
+ (void)acfunAidWithPath:(NSString *)path complectionHandler:(void(^)(NSString *aid, NSString *index))completion {
    if (!path) {
        completion(nil, nil);
    }
    
    NSString *aid;
    NSString *index;
    NSArray *arr = [[path componentsSeparatedByString: @"/"].lastObject componentsSeparatedByString:@"_"];
    if (arr.count == 2) {
        index = arr.lastObject;
        aid = [arr.firstObject substringFromIndex: 2];
    }
    completion(aid, index);
}

/**
 *  将弹幕写入缓存
 *
 *  @param provider    提供者
 *  @param danmakuID   弹幕id
 *  @param responseObj 弹幕内容
 */
+ (void)writeDanmakuCacheWithProvider:(DanDanPlayDanmakuSource)provider danmakuID:(NSString *)danmakuID responseObj:(id)responseObj {
    NSString *p = @"";
    
    switch (provider) {
        case DanDanPlayDanmakuSourceAcfun:
            p = @"acfun";
            break;
        case DanDanPlayDanmakuSourceBilibili:
            p = @"bilibili";
            break;
        case DanDanPlayDanmakuSourceOfficial:
            p = @"official";
            break;
        default:
            break;
    }
    
    //将弹幕写入缓存
    NSString *cachePath = [[UserDefaultManager cachePath] stringByAppendingPathComponent:p];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cachePath]) {
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [NSKeyedArchiver archiveRootObject:responseObj toFile:[cachePath stringByAppendingPathComponent:danmakuID]];
    });
}

/**
 *  拿到弹幕缓存
 *
 *  @param danmakuID 弹幕id
 *  @param provider  提供者
 *
 *  @return 弹幕缓存
 */
+ (id)danmakuCacheWithDanmakuID:(NSString *)danmakuID provider:(DanDanPlayDanmakuSource)provider isCache:(BOOL)isCache {
    NSString *providerStringValue = [ToolsManager stringValueWithDanmakuSource:provider];
    
    NSString *cachePath = [[UserDefaultManager cachePath] stringByAppendingPathComponent:[providerStringValue stringByAppendingPathComponent:!isCache ? danmakuID : [NSString stringWithFormat:@"%@_user", danmakuID]]];
    
    return [NSKeyedUnarchiver unarchiveObjectWithFile: cachePath];
}

/**
 *  转换 bilibili 视频模型
 *
 *  @param dic 字典模型
 *
 *  @return bilibili 视频模型
 */
+ (BiliBiliVideoInfoModel *)pareBiliBiliVideoInfoModelWithDic:(NSDictionary *)responseObj {
    if ([responseObj isKindOfClass:[NSDictionary class]] && responseObj.count) {
        NSDictionary *tempDic = responseObj[@"parts"];
        //包含分集的情况
        if (tempDic == nil) {
            NSString *title = responseObj[@"title"] ? responseObj[@"title"] : @"";
            NSString *danmaku = responseObj[@"cid"] ? responseObj[@"cid"] : @"";
            return [BiliBiliVideoInfoModel yy_modelWithDictionary: @{@"title":title, @"videos":@[@{@"title":title, @"danmaku":danmaku}]}];
        }
        else {
            NSArray *allSortedKeys = [tempDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
                return obj1.integerValue > obj2.integerValue;
            }];
            NSInteger danmaku = [responseObj[@"cid"] integerValue];
            NSMutableArray *videosArr = [NSMutableArray array];
            [allSortedKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [videosArr addObject:@{@"title":[NSString stringWithFormat:@"%@: %@", obj, tempDic[obj]], @"danmaku":[NSString stringWithFormat:@"%ld", danmaku + idx]}];
            }];
            return [BiliBiliVideoInfoModel yy_modelWithDictionary: @{@"title":responseObj[@"title"] ? responseObj[@"title"] : @"", @"videos":videosArr}];
        }
    }
    return nil;
}

/**
 *  转换 acfun 的视频模型
 *
 *  @param dic 字典模型
 *
 *  @return acfun 的视频模型
 */
+ (AcfunVideoInfoModel *)pareAcfunVideoInfoModelWithDic:(NSDictionary *)dic {
    //黑科技只解析单个视频的信息 故把字典封装成数组才可解析
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSString *title = dic[@"title"];
        if (!title.length) {
            return [AcfunVideoInfoModel yy_modelWithDictionary: @{@"videos":@[dic], @"title":title}];
        }
    }
    return nil;
}
/**
 *  bilibili 视频弹幕详情的路径
 *
 *  @param aid  视频 aid
 *  @param page 分页
 *
 *  @return 路径
 */
+ (NSString *)bilibiliDanmakuInfoRequestPathWithAid:(NSString *)aid page:(NSString *)page {
    if (!page.length || [page isEqualToString:@"0"]) {
        page = @"1";
    }
    return [NSString stringWithFormat:@"http://biliproxy.chinacloudsites.cn/av/%@/%@?list=1", aid, page];
}

 /**
 *  acfun 视频弹幕详情的路径
 *
 *  @param aid  视频 aid
 *
 *  @return 路径
 */
+ (NSString *)acfunDanmakuInfoRequestPathWithAid:(NSString *)aid {
    return [NSString stringWithFormat:@"http://www.talkshowcn.com/video/getVideo.aspx?id=%@", aid];
}

@end
