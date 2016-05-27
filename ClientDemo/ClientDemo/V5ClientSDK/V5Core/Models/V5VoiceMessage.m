//
//  V5VoiceMessage.m
//  mcss
//
//  Created by chyrain on 16/4/11.
//  Copyright © 2016年 V5KF. All rights reserved.
//

#import "V5VoiceMessage.h"
#import "V5Macros.h"
#import "V5ClientAgent.h"
#import "V5Util.h"

@implementation V5VoiceMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messageType = MessageType_Voice;
    }
    return self;
}

- (instancetype)initWithFormat:(NSString *)format mediaId:(NSString *)mediaId url:(NSString *)url {
    self = [self init];
    if (self) {
        _local_url = nil;
        _format = format;
        _media_id = mediaId;
        _url = url;
    }
    
    return self;
}

- (instancetype)initWithLocalURL:(NSString *)localPath format:(NSString *)format {
    self = [self init];
    if (self) {
        _local_url = localPath;
        _format = format;
        _media_id = nil;
    }
    
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super initWithJSON:data];
    if (self) {
        id fmt = [data objectForKey:@"format"];
        if (fmt && ![fmt isEqual:[NSNull null]]) {
            _format = fmt;
        } else {
            _format = nil;
        }
        id mediaId = [data objectForKey:@"media_id"];
        if (mediaId && ![mediaId isEqual:[NSNull null]]) {
            _media_id = mediaId;
        } else {
            _media_id = nil;
        }
        id url = [data objectForKey:@"url"];
        if (url && ![url isEqual:[NSNull null]]) {
            _url = url;
        } else {
            _url = nil;
        }
        if ([data objectForKey:@"match"]) {
            _match = [[data objectForKey:@"match"] integerValue];
        }
    }
    return self;
}

- (void)parseMessageContent:(NSDictionary *)jsonContent {
    id fmt = [jsonContent objectForKey:@"format"];
    if (fmt && ![fmt isEqual:[NSNull null]]) {
        _format = fmt;
    } else {
        _format = nil;
    }
    id mediaId = [jsonContent objectForKey:@"media_id"];
    if (mediaId && ![mediaId isEqual:[NSNull null]]) {
        _media_id = mediaId;
    } else {
        _media_id = nil;
    }
    id url = [jsonContent objectForKey:@"url"];
    if (url && ![url isEqual:[NSNull null]]) {
        _url = url;
    } else {
        _url = nil;
    }
    if ([jsonContent objectForKey:@"match"]) {
        _match = [[jsonContent objectForKey:@"match"] integerValue];
    }
}

- (NSString *)toJSONString {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:5];
    [self addPropertyToJSONObject:mutableDic]; // 加入父类属性
    
    // 加入本类属性
    if (self.format != nil) {
        [mutableDic setObject:self.format forKey:@"format"];
    }
    if (self.media_id != nil) {
        [mutableDic setObject:self.media_id forKey:@"media_id"];
    }
    if (self.url != nil) {
        [mutableDic setObject:self.url forKey:@"url"];
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

//- (void)addPropertyToJSONObject:(NSMutableDictionary *)JSONObj {
//    // 加入基类属性
//    [super addPropertyToJSONObject:JSONObj];
//    // 加入本类属性
//    if (self.format != nil) {
//        [JSONObj setObject:self.format forKey:@"format"];
//    }
//    if (self.media_id != nil) {
//        [JSONObj setObject:self.media_id forKey:@"media_id"];
//    }
//    if (self.url != nil) {
//        [JSONObj setObject:self.url forKey:@"url"];
//    }
//}

- (NSString *)local_url {
    if (_local_url) {
        return _local_url;
    }
    return [V5Util getWAVVoicePath:self];
}

- (CGFloat)voiceLength {
    if (_voiceLength > 0) {
        return _voiceLength;
    }
    return [V5Util getVoiceDurationOnPath:self.local_url];
}

// 获得amr语音数据
- (NSData *)getVoiceData {
    NSString *path = [V5Util getAMRVoicePath:self];
    if (path == nil) { // 待发送的本地语音(已转换为amr)
        path = [self.local_url stringByReplacingOccurrencesOfString:@".wav" withString:@".amr"];
    }
    if (path) {
        return [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
    } else {
        return nil;
    }
}

@end
