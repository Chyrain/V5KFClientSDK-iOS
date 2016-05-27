//
//  NSString+URL.h
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "V5FixCategoryBug.h"

V5KW_FIX_CATEGORY_BUG_H(NSString_V5URL)
@interface NSString (V5URL)

/**
 *  URL UTF-8编码
 *
 *  @return URL编码转换后的字符串
 */
- (NSString *)URLEncodedString;
@end
