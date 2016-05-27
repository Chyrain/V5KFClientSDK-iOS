//
//  UUMessageContentButton.h
//  BloodSugarForDoc
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIButton+V5AFNetworking.h"
#import "V5KZLinkLabel.h"

@interface CRMessageContentButton : UIButton

// bubble imgae
@property (nonatomic, retain) UIImageView *backImageView;

// rich text content
@property (nonatomic, retain) V5KZLinkLabel *richLabel;

// audio
@property (nonatomic, retain) UIView *voiceBackView;
@property (nonatomic, retain) UILabel *second;
@property (nonatomic, retain) UIImageView *voice;
@property (nonatomic, retain) UIActivityIndicatorView *indicator;

@property (nonatomic, assign) BOOL isMyMessage;


- (void)benginLoadVoice;
- (void)didLoadVoiceFailed;
- (void)didLoadVoice;

- (void)startPlay;
- (void)stopPlay;

@end
