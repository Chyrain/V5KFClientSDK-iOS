//
//  V5HttpExecutor.h
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/14.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface V5HttpExecutor : NSObject<NSURLConnectionDataDelegate> {
    
}

@property (nonatomic, strong) NSMutableData *resultData;
@property (nonatomic, strong) void (^finishCallbackBlock)(NSString *);

/**
 *  异步POST请求
 *
 *  @param urlStr  请求地址
 *  @param headers HTTP自定义包头字段
 *  @param params  post的内容
 *  @param block   结束回调block
 */
+ (void)postDataWithUrl:(NSString *)urlStr httpHeader:(NSDictionary *)headers httpBody:(NSData *)body callbackBlock:(void (^)(NSString *))block;

/**
 *  异步GET请求
 *
 *  @param urlStr  请求地址
 *  @param headers HTTP自定义包头字段
 *  @param block   结束回调block
 */
+ (void)getDataWithUrl:(NSString *)urlStr httpHeader:(NSDictionary *)headers callbackBlock:(void (^)(NSString *))block;


@end
