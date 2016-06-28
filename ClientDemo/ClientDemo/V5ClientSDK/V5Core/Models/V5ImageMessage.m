//
//  V5ImageMessage.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5ImageMessage.h"
#import <UIKit/UIKit.h>

@implementation V5ImageMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messageType = MessageType_Image;
    }
    return self;
}

- (instancetype)initWithPicUrl:(NSString *)picUrl mediaId:(NSString *)mediaId {
    self = [self init];
    if (self) {
        _image = nil;
        _picUrl = picUrl;
        _mediaId = mediaId;
        self.messageType = MessageType_Image;
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [self init];
    if (self) {
        _image = image;
        _picUrl = nil;
        _mediaId = nil;
        self.messageType = MessageType_Image;
    }
    
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        id picUrl = [data objectForKey:@"pic_url"];
        if (picUrl && ![picUrl isEqual:[NSNull null]]) {
            _picUrl = picUrl;
        } else {
            _picUrl = nil;
        }
        id mediaId = [data objectForKey:@"media_id"];
        if (mediaId && ![mediaId isEqual:[NSNull null]]) {
            _mediaId = mediaId;
        } else {
            _mediaId = nil;
        }
    }
    return self;
}

- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    // 加入本类属性
    if (self.picUrl != nil) {
        [mutableDic setObject:self.picUrl forKey:@"pic_url"];
    }
    if (self.mediaId != nil) {
        [mutableDic setObject:self.mediaId forKey:@"media_id"];
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

- (NSData *)getImageData {
    if (!self.image) {
        return nil;
    }
    NSData *data = UIImageJPEGRepresentation(self.image, 0.6);
    return data;
}

@end
