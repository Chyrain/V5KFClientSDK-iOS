//
//  NSString+URL.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "NSString+V5URL.h"

V5KW_FIX_CATEGORY_BUG_M(NSString_V5URL)
@implementation NSString (V5URL)

/**
 *  URL UTF-8编码
 *
 *  @return URL编码转换后的字符串
 */
- (NSString *)URLEncodedString
{
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)self,
                                            (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                            NULL,
                                            kCFStringEncodingUTF8));
    return encodedString;
}
@end
