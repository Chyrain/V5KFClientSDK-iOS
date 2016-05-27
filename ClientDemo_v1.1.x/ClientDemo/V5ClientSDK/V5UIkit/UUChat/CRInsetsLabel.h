//
//  CRInsetsLabel.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/26.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CRInsetsLabel : UILabel

@property (nonatomic) UIEdgeInsets insets;

- (instancetype)initWithFrame:(CGRect)frame andInsets:(UIEdgeInsets)insets;
- (instancetype)initWithInsets:(UIEdgeInsets)insets;

@end
