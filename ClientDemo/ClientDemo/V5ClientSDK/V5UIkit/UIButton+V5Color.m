//
//  UIButton+Color.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/25.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "UIButton+V5Color.h"

V5KW_FIX_CATEGORY_BUG_M(UIButton_V5Color)
@implementation UIButton (V5Color)

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    [self setBackgroundImage:[UIButton imageWithColor:backgroundColor] forState:state];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
