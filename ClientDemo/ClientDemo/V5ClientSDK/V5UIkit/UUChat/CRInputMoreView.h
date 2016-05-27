//
//  CRInputMoreView.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/28.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CRMoreViewDelegate <NSObject>

- (void)didselectImageView:(NSInteger)index;

@end

@interface CRInputMoreView : UIView
@property (nonatomic,strong) NSArray *imageArray;
@property (nonatomic,weak)id <CRMoreViewDelegate> delegate;
- (void)setImageArray:(NSArray *)imageArray nameArray:(NSArray *)nameArray;
@end
