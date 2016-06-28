//
//  V5ImageLoader.h
//  mcss
//
//  Created by chyrain on 16/6/2.
//  Copyright © 2016年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImageView+V5AFNetworking.h"
#import "UIButton+V5AFNetworking.h"

typedef void(^V5ImageCompletionBlock)(UIImage *image, NSError *error, NSString *imageURL);

@interface V5ImageLoader : NSObject

// 使用默认的placeholderImage、failureImage和completedBlock
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url;

// 使用默认的completedBlock和failureImage
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder;

// 使用默认的completedBlock
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage;

// 使用默认的placeholderImage和failureImage
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url completed:(V5ImageCompletionBlock)completedBlock;

// 全部参数自定义
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage completed:(V5ImageCompletionBlock)completedBlock;

// 设置按钮背景图片，全部参数自定义
+ (void)setButton:(UIButton *)button withBackgroundImageURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage complete:(V5ImageCompletionBlock)completeBlock;
@end
