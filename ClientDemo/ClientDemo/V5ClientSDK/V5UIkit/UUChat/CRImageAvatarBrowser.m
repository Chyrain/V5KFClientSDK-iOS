//
//  UUAVAudioPlayer.m
//  BloodSugarForDoc
//
//  Created by shake on 14-9-1.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import "CRImageAvatarBrowser.h"
#import "V5VIPhotoView.h"
#import "NSString+V5URL.h"
#import "V5Macros.h"
#import "V5ImageLoader.h"

static UIImageView *orginImageView;
static UIView *backgroundView;
@implementation CRImageAvatarBrowser

+ (void)showImage:(UIImageView *)avatarImageView withURL:(NSString *)url {
    UIImage *image=avatarImageView.image;
    orginImageView = avatarImageView;
    orginImageView.alpha = 1;
    UIWindow *window=[UIApplication sharedApplication].keyWindow;
    backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    CGRect oldframe=[avatarImageView convertRect:avatarImageView.bounds toView:window];
    backgroundView.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.7];
    backgroundView.alpha=0;
    
    V5VIPhotoView *photoView = [[V5VIPhotoView alloc] initWithFrame:oldframe andImage:image];
    photoView.autoresizingMask = (1 << 6) -1;
    photoView.tag = 1;
    
    [backgroundView addSubview:photoView];
    [window addSubview:backgroundView];
    
    if (USE_THUMBNAIL && url) {
        [V5ImageLoader setImageView:photoView.imageView
                            withURL:[url URLEncodedString]
                   placeholderImage:image
                       failureImage:nil
                          completed:^(UIImage *image, NSError *error, NSString *imageURL) {
                              if (image && error == nil) { // success
                                  V5Log(@"加载大图完成：%@", url);
                                  V5VIPhotoView *photoView=(V5VIPhotoView *)[backgroundView viewWithTag:1];
                                  [photoView setImage:image];
                              } else { // failure
                                  
                              }
                          }];
    }
    
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];
    
    [UIView animateWithDuration:0.3 animations:^{
        photoView.frame = CGRectMake(0, 0, Main_Screen_Width, Main_Screen_Height);
        orginImageView.alpha = 1;
        backgroundView.alpha=1;
    } completion:^(BOOL finished) {
        
    }];
}

+ (void)hideImage:(UITapGestureRecognizer*)tap{
    //UIView *backgroundView=tap.view;
    if (backgroundView == nil || orginImageView == nil) {
        return;
    }
    V5VIPhotoView *photoView=(V5VIPhotoView *)[backgroundView viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        photoView.frame=[orginImageView convertRect:orginImageView.bounds toView:[UIApplication sharedApplication].keyWindow];
        orginImageView.alpha = 1;
        backgroundView.alpha=0;
    } completion:^(BOOL finished) {
        orginImageView.alpha = 1;
        backgroundView.alpha=0;
        [backgroundView removeFromSuperview];
        orginImageView = nil;
        backgroundView = nil;
    }];
}

+ (void)hideImage {
    if (orginImageView != nil && backgroundView != nil) {
        V5VIPhotoView *photoView=(V5VIPhotoView *)[backgroundView viewWithTag:1];
        [UIView animateWithDuration:0.3 animations:^{
            photoView.frame=[orginImageView convertRect:orginImageView.bounds toView:[UIApplication sharedApplication].keyWindow];
            orginImageView.alpha = 1;
            backgroundView.alpha=0;
        } completion:^(BOOL finished) {
            orginImageView.alpha = 1;
            backgroundView.alpha=0;
            [backgroundView removeFromSuperview];
            orginImageView = nil;
            backgroundView = nil;
        }];
    }
}

@end
