//
//  V5Article.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/3.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5Article.h"

@implementation V5Article

- (instancetype)initWithTitle:(NSString *)title
                       picUrl:(NSString *)picUrl
                          url:(NSString *)url
                         desc:(NSString *)desc {
    self = [super init];
    if (self) {
        _title = title;
        _picUrl = picUrl;
        _url = url;
        _desc = desc;
    }
    
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)data {
    self = [super init];
    if (self) {
        id title = [data objectForKey:@"title"];
        if (title && ![title isEqual:[NSNull null]]) {
            _title = title;
        }
        id pic = [data objectForKey:@"pic_url"];
        if (pic && ![pic isEqual:[NSNull null]]) {
            _picUrl = pic;
        }
        id url = [data objectForKey:@"url"];
        if (url && ![url isEqual:[NSNull null]]) {
            _url = url;
        }
        id desc = [data objectForKey:@"description"];
        if (desc && ![desc isEqual:[NSNull null]]) {
            _desc = desc;
        }
    }
    return self;
}

- (void)addPropertyToJSONObject:(NSMutableDictionary *)JSONObj {
    if (nil != JSONObj) {
        if (self.title != nil) {
            [JSONObj setObject:self.title forKey:@"title"];
        }
        if (self.picUrl != nil) {
            [JSONObj setObject:self.picUrl forKey:@"pic_url"];
        }
        if (self.url != nil) {
            [JSONObj setObject:self.url forKey:@"url"];
        }
        if (self.desc != nil) {
            [JSONObj setObject:self.desc forKey:@"description"];
        }
    }
}

@end
