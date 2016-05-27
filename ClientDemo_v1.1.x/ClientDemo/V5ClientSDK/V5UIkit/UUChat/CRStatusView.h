//
//  CRStatusView.h
//  V5KF SDK
//
//  Created by chyrain on 15/12/23.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V5Macros.h"

typedef void (^ResendClickHandler)(void);
@interface CRStatusView : UIView

@property (nonatomic, assign) KV5MessageSendStatus status;
@property (nonatomic, strong) UIButton *statusImage;
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicator;
@property (nonatomic, copy) ResendClickHandler resendClick;

@end
