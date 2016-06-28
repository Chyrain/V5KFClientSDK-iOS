//
//  V5ImageLoader.m
//  mcss
//
//  Created by chyrain on 16/6/2.
//  Copyright © 2016年 V5KF. All rights reserved.
//

#import "V5ImageLoader.h"
#import "V5Macros.h"

@implementation V5ImageLoader

// 使用默认的placeholderImage、failureImage和completedBlock
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url {
    [self setImageView:imageView
               withURL:url
      placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
          failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]
             completed:^(UIImage *image, NSError *error, NSString *imageURL) {
                 // TODO
                 
             }];
}

// 使用默认的completedBlock和failureImage
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder {
    [self setImageView:imageView
               withURL:url
      placeholderImage:placeholder
          failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]
             completed:^(UIImage *image, NSError *error, NSString *imageURL) {
                 // TODO
                 
             }];
}

// 使用默认的completedBlock
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage {
    [self setImageView:imageView
               withURL:url
      placeholderImage:placeholder
          failureImage:failureImage
             completed:^(UIImage *image, NSError *error, NSString *imageURL) {
                 // TODO
                 
             }];
}

// 使用默认的placeholderImage和failureImage
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url completed:(V5ImageCompletionBlock)completedBlock {
    [self setImageView:imageView
               withURL:url
      placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
          failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]
             completed:completedBlock];
}

// 全部参数自定义
+ (void)setImageView:(UIImageView *)imageView withURL:(NSString *)url placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage completed:(V5ImageCompletionBlock)completedBlock {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    __weak __typeof(imageView)weakImageView = imageView;
    [imageView setImageWithURLRequest:request
                     placeholderImage:placeholder
                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                  V5Log(@"setImageWithURL<%@> -> completed", url);
                                  if (image) {
                                      [weakImageView setImage:image];
                                  } else if (placeholder) {
                                      [weakImageView setImage:placeholder];
                                  }
                                  if (completedBlock) {
                                      completedBlock(image, nil, url);
                                  }
                              }
                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                  V5Log(@"V5ImageLoader -> load image failed url:%@", url);
                                  if (failureImage != nil) {
                                      [weakImageView setImage:failureImage];
                                  } else if (placeholder != nil) {
                                      [weakImageView setImage:placeholder];
                                  }
                                  if (completedBlock) {
                                      completedBlock(nil, error, url);
                                  }
                              }];
}

// 设置按钮背景图片，全部参数自定义
+ (void)setButton:(UIButton *)button withBackgroundImageURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder failureImage:(UIImage *)failureImage complete:(V5ImageCompletionBlock)completedBlock {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    __weak __typeof(button)weakButton = button;
    [button setBackgroundImageForState:state
                        withURLRequest:request
                      placeholderImage:placeholder
                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                   V5Log(@"setBackgroundImage<%@> -> completed", url);
                                   if (image) {
                                       [weakButton setBackgroundImage:image forState:state];
                                   } else if (placeholder) {
                                       [weakButton setBackgroundImage:placeholder forState:state];
                                   }
                                   if (completedBlock) {
                                       completedBlock(image, nil, url);
                                   }
                               }
                               failure:^(NSError *error) {
                                   V5Log(@"V5ImageLoader -> load image failed url:%@", url);
                                   if (failureImage != nil) {
                                       [weakButton setBackgroundImage:failureImage forState:state];
                                   } else if (placeholder != nil) {
                                       [weakButton setBackgroundImage:placeholder forState:state];
                                   }
                                   if (completedBlock) {
                                       completedBlock(nil, error, url);
                                   }
                               }];
}

@end