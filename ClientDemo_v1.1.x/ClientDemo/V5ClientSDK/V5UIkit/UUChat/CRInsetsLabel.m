//
//  CRInsetsLabel.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/26.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRInsetsLabel.h"

@implementation CRInsetsLabel

- (instancetype)initWithFrame:(CGRect)frame andInsets:(UIEdgeInsets)insets {
    self = [super initWithFrame:frame];
    if (self) {
        self.insets = insets;
    }
    return self;
}

- (instancetype)initWithInsets:(UIEdgeInsets)insets {
    self = [super init];
    if (self) {
        self.insets = insets;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

@end
