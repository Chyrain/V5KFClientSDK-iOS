//
//  VIPhotoView.h
//  VIPhotoViewDemo
//
//  Created by Vito on 1/7/15.
//  Copyright (c) 2015 vito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface V5VIPhotoView : UIScrollView

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;

- (instancetype)initWithFrame:(CGRect)frame andImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;

@end
