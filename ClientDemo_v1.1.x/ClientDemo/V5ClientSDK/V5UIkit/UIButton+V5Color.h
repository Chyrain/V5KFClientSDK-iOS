//
//  UIButton+Color.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/25.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V5FixCategoryBug.h"

V5KW_FIX_CATEGORY_BUG_H(UIButton_V5Color)
@interface UIButton (V5Color)

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state;
+ (UIImage *)imageWithColor:(UIColor *)color;

@end
