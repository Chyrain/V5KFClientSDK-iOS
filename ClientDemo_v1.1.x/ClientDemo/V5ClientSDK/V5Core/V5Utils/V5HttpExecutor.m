//
//  V5HttpExecutor.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/14.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5HttpExecutor.h"
#import "V5Macros.h"

@implementation V5HttpExecutor

@synthesize resultData, finishCallbackBlock;

+ (void)postDataWithUrl:(NSString *)urlStr httpHeader:(NSDictionary *)headers httpBody:(NSData *)body callbackBlock:(void (^)(NSString *))block {
    // 生成一个post请求回调委托对象（实现了<NSURLConnectionDataDelegate>协议）
    V5HttpExecutor *postExecutor = [[V5HttpExecutor alloc] init];
    postExecutor.finishCallbackBlock = block; // 绑定执行完成时的block
    
    NSURL *url = [NSURL URLWithString:urlStr]; // 生成NSURL对象
    // 生成Request请求对象（并设置它的缓存协议、网络请求超时配置）
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    
    [request setHTTPMethod:@"POST"]; // 设置为post请求
    [request setHTTPBody:body]; // 设置请求参数
    if (headers) { // 设置Http请求头
        for (NSString *key in headers) {
            [request setValue:headers[key] forHTTPHeaderField:key];
        }
    }
        
    // 执行请求连接
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:postExecutor
                                                    startImmediately:YES];
    V5Log(conn ? @"连接创建成功" : @"连接创建失败");
}

+ (void)getDataWithUrl:(NSString *)urlStr httpHeader:(NSDictionary *)headers callbackBlock:(void (^)(NSString *))block {
    // 生成一个post请求回调委托对象（实现了<NSURLConnectionDataDelegate>协议）
    V5HttpExecutor *postExecutor = [[V5HttpExecutor alloc] init];
    postExecutor.finishCallbackBlock = block; // 绑定执行完成时的block
    
    NSURL *url = [NSURL URLWithString:urlStr]; // 生成NSURL对象
    // 生成Request请求对象（并设置它的缓存协议、网络请求超时配置）
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    
    [request setHTTPMethod:@"GET"]; // 设置为post请求
    if (headers) { // 设置Http请求头
        for (NSString *key in headers) {
            [request setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    if ([request respondsToSelector:@selector(allHTTPHeaderFields)]) {
        NSDictionary *dictionary = [request allHTTPHeaderFields];
        V5Log(@"[network request]allHeaderFields:%@", [dictionary description]);
    }
    
    // 执行请求连接
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:postExecutor
                                                    startImmediately:YES];
    V5Log(conn ? @"连接创建成功" : @"连接创建失败");
}

/**
 *  接收到服务器回应的时回调
 *
 *  @param connection NSURLConnection对象
 *  @param response   NSURLResponse服务器应答
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    // 初始化NSMutableData对象（用于保存执行结果）
    if(!resultData) {
        resultData = [[NSMutableData alloc] init];
    } else {
        [resultData setLength:0];
    }
    
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [resp allHeaderFields];
        V5Log(@"[network response]allHeaderFields:%@", [dictionary description]);
    }
}

/**
 *  接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
 *
 *  @param connection NSURLConnection对象
 *  @param data       接收到的数据
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [resultData appendData:data]; // 追加结果
}

/**
 *  数据传完之后调用此方法
 *
 *  @param connection NSURLConnection对象
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // 把请求结果以UTF-8编码转换成字符串
    NSString *resultStr = [[NSString alloc] initWithData:[self resultData] encoding:NSUTF8StringEncoding];
    
    if (finishCallbackBlock) { // 如果设置了回调的block，直接调用
        finishCallbackBlock(resultStr);
    }
}

/**
 *  网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
 *
 *  @param connection NSURLConnection对象
 *  @param error      错误返回信息
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    V5Log(@"network error!!!: %@", [error localizedDescription]);
    
    if (finishCallbackBlock) { // 如果设置了回调的block，直接调用
        finishCallbackBlock(nil);
    }
}

@end
