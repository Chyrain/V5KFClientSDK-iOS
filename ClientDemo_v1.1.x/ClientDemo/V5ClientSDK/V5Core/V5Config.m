//
//  V5Config.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/10.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5Config.h"
#import "V5Util.h"
#import "V5Macros.h"

@interface V5Config ()
@property (nonatomic, assign) NSUserDefaults *userData;
@end

@implementation V5Config
@synthesize visitor = _visitor;
@synthesize uid = _uid;
@synthesize deviceToken = _deviceToken;
@synthesize site = _site;
@synthesize account = _account;
@synthesize timestamp = _timestamp;
@synthesize expires = _expires;
@synthesize authorization = _authorization;
//@synthesize customContent = _customContent;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userData {
    self = [super init];
    if (self) {
        _userData = userData;
    }
    return self;
}

- (void)dealloc {
    self.userData = nil;
}

- (NSString *)uid {
    if (_uid) {
        return _uid;
    }
    _uid = [self.userData objectForKey:CFG_UID];
    return _uid;
}

- (void)setUid:(NSString *)uid {
    _uid = [NSString stringWithFormat:@"%@", uid];
    if (_uid) {
        NSString *localUid = [self.userData objectForKey:CFG_UID];
//        NSString *localUid = [NSString stringWithFormat:@"%@", [self.userData objectForKey:CFG_UID]];
        if (localUid && ![localUid isEqualToString:_uid]) { // 切换用户
            _visitor = nil;
            _authorization = nil;
            [self.userData removeObjectForKey:CFG_AUTH];
            [self.userData removeObjectForKey:CFG_VISITOR];
        }
        [self.userData setObject:_uid forKey:CFG_UID];
    }
}

- (void)setNickname:(NSString *)nickname {
    _nickname = [NSString stringWithFormat:@"%@", nickname];
}

- (void)setAvatar:(NSString *)avatar {
    _avatar = [NSString stringWithFormat:@"%@", avatar];
}

- (NSString *)visitor {
    if (_visitor) {
        return _visitor;
    }
    _visitor = [self.userData objectForKey:CFG_VISITOR];
    if (!_visitor) {
        if (self.uid) {
            _visitor = [V5Util md5:[self.uid stringByAppendingFormat:@"%@%@", self.account, self.site]];
        } else {
            _visitor = [V5Util md5:[[[UIDevice currentDevice].identifierForVendor UUIDString] stringByAppendingFormat:@"%@%@", self.account, self.site]];
        }
        [self.userData setObject:_visitor forKey:CFG_VISITOR];
    }
    return _visitor;
}

- (NSString *)deviceToken {
    if (_deviceToken) {
        return _deviceToken;
    }
    _deviceToken = [self.userData objectForKey:CFG_DEVICE_TOKEN];
    return _deviceToken;
}

- (void)setDeviceToken:(NSString *)deviceToken {
    _deviceToken = [NSString stringWithFormat:@"%@", deviceToken];
    if (_deviceToken) {
        [self.userData setObject:_deviceToken forKey:CFG_DEVICE_TOKEN];
    }
}

- (NSString *)site {
    if (_site) {
        return _site;
    }
    _site = [self.userData objectForKey:CFG_SITE_ID];
    return _site;
}

- (void)setSite:(NSString *)site {
    _site = [NSString stringWithFormat:@"%@", site];
    if (_site) {
        [self.userData setObject:_site forKey:CFG_SITE_ID];
    }
}

- (NSString *)account {
    if (_account) {
        return _account;
    }
    _account = [self.userData objectForKey:CFG_ACCOUNT];
    return _account;
}

- (void)setAccount:(NSString *)account {
    _account = [NSString stringWithFormat:@"%@", account];
    if (_account) {
        [self.userData setObject:_account forKey:CFG_ACCOUNT];
    }
}

- (long)timestamp {
    if (0 != _timestamp) {
        return _timestamp;
    }
    id time = [self.userData objectForKey:CFG_TIMESTAMP];
    if (time && ![time isEqual:[NSNull null]]) {
        _timestamp = [time longValue];
    }
    return _timestamp;
}

- (void)setTimestamp:(long)timestamp {
    _timestamp = timestamp;
    if (timestamp != 0) {
        [self.userData setObject:[NSNumber numberWithLong:timestamp]
                          forKey:CFG_TIMESTAMP];
    }
}

- (long)expires {
    if (0 != _expires) {
        return _expires;
    }
    id exp = [self.userData objectForKey:CFG_EXPIRES];
    if (exp && ![exp isEqual:[NSNull null]]) {
        _expires = [exp longValue];
    }
    return _expires;
}

- (void)setExpires:(long)expires {
    _expires = expires;
    if (expires != 0) {
        [self.userData setObject:[NSNumber numberWithLong:expires]
                          forKey:CFG_EXPIRES];
    }
}

- (NSString *)authorization {
    if (_authorization) {
        return _authorization;
    }
    _authorization = [self.userData objectForKey:CFG_AUTH];
    long current = time(NULL);
    if ((self.expires + self.timestamp) < (current - 3)) {
        return nil;
    } else {
        return _authorization;
    }
}

- (void)setAuthorization:(NSString *)authorization {
    _authorization = authorization;
    if (authorization) {
        [self.userData setObject:authorization forKey:CFG_AUTH];
    }
}

//- (NSDictionary *)customContent {
//    if (_customContent) {
//        return _customContent;
//    }
//    _customContent = [_userData objectForKey:CFG_CUSTOM_CONTENT];
//    return _customContent;
//}
//
//- (void)setCustomContent:(NSDictionary *)customContent {
//    _customContent = customContent;
//    if (customContent) {
//        [self.userData setObject:customContent forKey:CFG_CUSTOM_CONTENT];
//    }
//}

- (BOOL)pushEnable {
    if (_pushEnable) {
        return _pushEnable;
    }
    _pushEnable = [self.userData boolForKey:CFG_PUSH_ENABLE];
    return _pushEnable;
}

- (void)shouldUpdateUserInfo {
    _authorization = nil;
    _visitor = nil;
    [self.userData removeObjectForKey:CFG_AUTH];
    [self.userData removeObjectForKey:CFG_VISITOR];
}

@end
