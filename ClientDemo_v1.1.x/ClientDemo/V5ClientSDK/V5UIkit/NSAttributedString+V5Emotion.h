//
//  NSAttributedString+Emotion.h
//  LinkTest
//
//  Created by joywii on 14/12/9.
//  Edit by chyrain on 15/12/23.
//  Copyright (c) 2015年 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "V5FixCategoryBug.h"

V5KW_FIX_CATEGORY_BUG_H(NSAttributedString_V5Emotion)

@interface V5KZTextAttachment : NSTextAttachment
@property (nonatomic,assign) NSRange  range;
@end

@interface NSAttributedString (V5Emotion)

//----------------------------------------实例方法---------------------------------------------------
/*
 * 返回绘制NSAttributedString所需要的区域
 */
- (CGRect)boundsWithSize:(CGSize)size;

//----------------------------------------静态方法---------------------------------------------------
/*
 * 返回绘制文本需要的区域
 */
+ (CGRect)boundsForString:(NSString *)string size:(CGSize)size attributes:(NSDictionary *)attrs;

/*
 * 返回Emotion替换过的 NSAttributedString
 */
+ (NSAttributedString *)emotionAttributedStringFrom:(NSString *)string attributes:(NSDictionary *)attrs;

@end
