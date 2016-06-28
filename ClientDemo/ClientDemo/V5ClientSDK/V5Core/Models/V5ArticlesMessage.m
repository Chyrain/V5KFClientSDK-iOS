//
//  V5ArticlesMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5ArticlesMessage.h"

@implementation V5ArticlesMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messageType = MessageType_Articles;
    }
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        NSArray *articlesArray = [data objectForKey:@"articles"];
        if (articlesArray != nil) {
            if (nil == _articles) {
                _articles = [NSMutableArray new];
            }
            for (NSDictionary *dic in articlesArray) {
                V5Article *article = [[V5Article alloc] initWithJSON:dic];
                [_articles addObject:article];
            }
        }
    }
    return self;
}

- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    // 加入本类属性
    if (self.articles != nil) {
        NSMutableArray *articlesArray = [NSMutableArray new];
        for (V5Article *article in self.articles) {
            NSMutableDictionary *dic = [NSMutableDictionary new];
            [article addPropertyToJSONObject:dic];
            [articlesArray addObject:dic];
        }
        [mutableDic setObject:articlesArray forKey:@"articles"];
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableDic
                                                       options:JSON_OPTION
                                                         error:&error];
    if ([jsonData length] > 0 && error == nil) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        return jsonString;
    } else {
        return nil;
    }
}

@end
