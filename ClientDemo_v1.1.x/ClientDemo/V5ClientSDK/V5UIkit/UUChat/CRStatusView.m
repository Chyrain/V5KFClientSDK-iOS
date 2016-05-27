//
//  CRStatusView.m
//  V5KF SDK
//
//  Created by chyrain on 15/12/23.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRStatusView.h"
#import "CRMessageFrame.h"

@implementation CRStatusView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.resendClick = ^(void){};
        self.statusImage = [[UIButton alloc] init];
        self.sendingIndicator = [[UIActivityIndicatorView alloc] init];
        [self.statusImage setImage:[UIImage imageNamed:IMGFILE(@"v5_chat_resend")]
                          forState:UIControlStateNormal];
        self.statusImage.hidden = YES;
        self.sendingIndicator.hidden = YES;
        self.sendingIndicator.color = [UIColor grayColor];
        [self.statusImage addTarget:self action:@selector(clickResendImage) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.statusImage];
        [self addSubview:self.sendingIndicator];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.statusImage = [[UIButton alloc] init];
        self.sendingIndicator = [[UIActivityIndicatorView alloc] init];
        [self.statusImage setImage:[UIImage imageNamed:IMGFILE(@"v5_chat_resend")]
                          forState:UIControlStateNormal];
        self.statusImage.hidden = YES;
        self.sendingIndicator.hidden = YES;
        self.sendingIndicator.color = [UIColor grayColor];
        [self.statusImage addTarget:self action:@selector(clickResendImage) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setStatus:(KV5MessageSendStatus)status {
    _status = status;
    [self updateViewWithStatus:status];
}


- (void)clickResendImage {
    self.resendClick();
}

/**
 *  更新发送状态
 *
 *  @param status 消息发送状态
 */
- (void)updateViewWithStatus:(KV5MessageSendStatus)status {
    self.statusImage.frame = self.bounds;
    self.sendingIndicator.frame = self.bounds;
    if (self.sendingIndicator.isAnimating) {
        [self.sendingIndicator stopAnimating];
    }
    switch (status) {
        case MessageSendStatus_Unknown:
        case MessageSendStatus_Arrived:
            self.statusImage.hidden = YES;
            self.sendingIndicator.hidden = YES;
            break;
        case MessageSendStatus_Sending:
            self.statusImage.hidden = YES;
            self.sendingIndicator.hidden = NO;
            [self.sendingIndicator startAnimating];
            break;
        case MessageSendStatus_Failure:
            self.statusImage.hidden = NO;
            self.sendingIndicator.hidden = YES;
            break;
        default:
            break;
    }
}

@end
