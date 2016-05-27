//
//  UUMessageContentButton.m
//  BloodSugarForDoc
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import "CRMessageContentButton.h"
#import "V5Macros.h"

@implementation CRMessageContentButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //富文本
        self.richLabel = [[V5KZLinkLabel alloc] init];
        self.richLabel.automaticLinkDetectionEnabled = YES;
        self.richLabel.font = [UIFont systemFontOfSize:16];
        self.richLabel.backgroundColor = [UIColor clearColor];
        self.richLabel.textColor = [UIColor whiteColor];
        self.richLabel.numberOfLines = 0;
        self.richLabel.lineBreakMode = NSLineBreakByWordWrapping; //NSLineBreakByTruncatingTail;
        [self addSubview:self.richLabel];
        
        //图片
        self.backImageView = [[UIImageView alloc] init];
        self.backImageView.userInteractionEnabled = YES;
        self.backImageView.layer.cornerRadius = 5;
        self.backImageView.layer.masksToBounds  = YES;
        self.backImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.backImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.backImageView];
        
        //语音
        self.voiceBackView = [[UIView alloc] init];
        [self addSubview:self.voiceBackView];
        self.second = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 40, 30)];
        self.second.textAlignment = NSTextAlignmentCenter;
        self.second.font = [UIFont systemFontOfSize:14];
        self.voice = [[UIImageView alloc]initWithFrame:CGRectMake(45, 0, 20, 20)];
        self.voice.image = [UIImage imageNamed:IMGFILE(@"chat_animation_left_white3")];
        self.voice.animationImages = [NSArray arrayWithObjects:
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_blank")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white1")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white2")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white3")],nil];
        self.voice.animationDuration = 0.8;
        self.voice.animationRepeatCount = 0;
        self.indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.indicator.center=CGPointMake(55, 10);
        [self.voiceBackView addSubview:self.indicator];
        [self.voiceBackView addSubview:self.voice];
        [self.voiceBackView addSubview:self.second];
        
        self.backImageView.userInteractionEnabled = NO;
        self.voiceBackView.userInteractionEnabled = NO;
        self.second.userInteractionEnabled = NO;
        self.voice.userInteractionEnabled = NO;
        
        self.second.backgroundColor = [UIColor clearColor];
        self.voice.backgroundColor = [UIColor clearColor];
        self.voiceBackView.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

- (void)benginLoadVoice {
    self.voice.hidden = YES;
    [self.indicator startAnimating];
}

- (void)didLoadVoice {
    self.voice.hidden = NO;
    [self.indicator stopAnimating];
//    [self.voice startAnimating];
}

- (void)didLoadVoiceFailed {
    self.voice.hidden = NO;
    [self.indicator stopAnimating];
    //    [self.voice startAnimating];
    self.voice.image = [UIImage imageNamed:IMGFILE(@"v5_chat_resend")];
}

- (void)startPlay {
    [self.voice startAnimating];
}

-(void)stopPlay {
//    if(self.voice.isAnimating){
        [self.voice stopAnimating];
//    }
}

- (void)setIsMyMessage:(BOOL)isMyMessage {
    _isMyMessage = isMyMessage;
    if (isMyMessage) {
        self.backImageView.frame = CGRectMake(5, 5, 220, 220);
        self.voiceBackView.frame = CGRectMake(10, 10, 60, 35);
        self.indicator.center=CGPointMake(10, 10);
        self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.voice.frame = CGRectMake(0, 0, 20, 20);
        self.second.frame = CGRectMake(25, 0, 40, 20);
        self.second.textColor = [UIColor grayColor];
        self.voice.image = [UIImage imageNamed:IMGFILE(@"chat_animation_right_gray3")];
        self.voice.animationImages = [NSArray arrayWithObjects:
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_blank")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_right_gray1")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_right_gray2")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_right_gray3")],nil];
    } else {
        self.backImageView.frame = CGRectMake(15, 5, 220, 220);
        self.voiceBackView.frame = CGRectMake(15, 10, 60, 35);
        self.indicator.center=CGPointMake(55, 10);
        self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.voice.frame = CGRectMake(45, 0, 20, 20);
        self.second.frame = CGRectMake(0, 0, 40, 20);
        self.second.textColor = [UIColor whiteColor];
        self.voice.image = [UIImage imageNamed:IMGFILE(@"chat_animation_left_white3")];
        self.voice.animationImages = [NSArray arrayWithObjects:
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_blank")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white1")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white2")],
                                      [UIImage imageNamed:IMGFILE(@"chat_animation_left_white3")],nil];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
