//
//  V5UndefinedMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5UndefinedMessage.h"

@implementation V5UndefinedMessage

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        _data = data;
    }
    return self;
}

- (NSString *)toJSONString {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.data
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
