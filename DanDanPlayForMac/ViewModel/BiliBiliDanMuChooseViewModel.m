//
//  BiliBiliDanMuChooseViewModel.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/2/5.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "BiliBiliDanMuChooseViewModel.h"
#import "DanMuNetManager.h"

@implementation BiliBiliDanMuChooseViewModel

- (void)refreshCompletionHandler:(void(^)(NSError *error))complete{
    if (!self.aid) {
        complete(nil);
        return;
    }
    
    [DanMuNetManager getBiliBiliDanMuWithParameters:@{@"aid":self.aid} completionHandler:^(BiliBiliVideoInfoModel *responseObj, NSError *error) {
        self.videos = responseObj.videos;
        complete(error);
    }];
}

- (void)downThirdPartyDanMuWithIndex:(NSInteger)index completionHandler:(void(^)(id responseObj))complete{
    NSString *danMuKuID = [self danMuKuWithIndex: index];
    if (!danMuKuID){
        complete(nil);
        return;
    }
    
    [DanMuNetManager downThirdPartyDanMuWithParameters:@{@"danmuku":danMuKuID, @"provider":@"bilibili"} completionHandler:^(id responseObj, NSError *error) {
        complete(responseObj);
    }];
}
@end
