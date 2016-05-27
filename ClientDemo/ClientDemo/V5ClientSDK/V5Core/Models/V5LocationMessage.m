//
//  V5LocationMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5LocationMessage.h"

@implementation V5LocationMessage

/**
 *  初始化位置消息
 *
 *  @param x     纬度
 *  @param y     经度
 *
 *  @return 位置消息对象
 */
- (instancetype)initWithLatitude:(double)x longitude:(double)y {
    self = [self init];
    if (self) {
        _x = x;
        _y = y;
        _scale = 0;
        _label = nil;
        self.messageType = MessageType_Location;
    }
    
    return self;
}

/**
 *  初始化位置消息
 *
 *  @param x     纬度
 *  @param y     经度
 *  @param scale 精度
 *  @param label 标签
 *
 *  @return 位置消息对象
 */
- (instancetype)initWithLatitude:(double)x longitude:(double)y scale:(double)scale label:(NSString *)label {
    self = [self initWithLatitude:x longitude:y];
    if (self) {
        _scale = scale;
        _label = label;
    }
    
    return self;
}

/**
 *  使用JSON字符串初始化消息对象
 *
 *  @param data JSON字典对象
 *
 *  @return 文本消息对象实例
 */
- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        id x = [data objectForKey:@"x"];
        if (x && ![x isEqual:[NSNull null]]) {
            _x = [x doubleValue];
        } else {
            _x = 0;
        }
        id y = [data objectForKey:@"y"];
        if (y && ![y isEqual:[NSNull null]]) {
            _y = [y doubleValue];
        } else {
            _y = 0;
        }
        id scale = [data objectForKey:@"scale"];
        if (scale && ![scale isEqual:[NSNull null]]) {
            _scale = [scale doubleValue];
        } else {
            _scale = 0;
        }
        id label = [data objectForKey:@"label"];
        if (label && ![label isEqual:[NSNull null]]) {
            _label = label;
        } else {
            _label = nil;
        }
    }
    return self;
}


/**
 *  转JSON格式字符串
 *
 *  @return JSON字符串
 */
- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    // 加入本类属性
    if (self.label != nil) {
        [mutableDic setObject:self.label forKey:@"label"];
    }
    if (self.scale != 0) {
        [mutableDic setObject:@(self.scale) forKey:@"scale"];
    }
    [mutableDic setObject:@(self.x) forKey:@"x"];
    [mutableDic setObject:@(self.y) forKey:@"y"];
    
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
