//
//  V5ControlMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5ControlMessage.h"

@implementation V5ControlMessage

- (instancetype)initWithCode:(NSInteger)code
                        argc:(NSInteger)argc
                        argv:(NSString *)argv {
    self = [self init];
    if (self) {
        _code = code;
        _argc = argc;
        _argv = argv;
        self.messageType = MessageType_Control;
    }
    
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        id code = [data objectForKey:@"code"];
        if (code && ![code isEqual:[NSNull null]]) {
            _code = [code integerValue];
        } else {
            _code = 0;
        }
        id argc = [data objectForKey:@"argc"];
        if (argc && ![argc isEqual:[NSNull null]]) {
            _argc = [argc integerValue];
        } else {
            _argc = 0;
        }
        id argv = [data objectForKey:@"argv"];
        if (argv && ![argv isEqual:[NSNull null]]) {
            _argv = argv;
        } else {
            _argv = nil;
        }
    }
    return self;
}

- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    // 加入本类属性
    if (self.argc != 0) {
        [mutableDic setObject:@(self.argc) forKey:@"argc"];
        
        if (self.argv != nil) {
            [mutableDic setObject:self.argv forKey:@"argv"];
        }
    }
    [mutableDic setObject:@(self.code) forKey:@"code"];
    
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
