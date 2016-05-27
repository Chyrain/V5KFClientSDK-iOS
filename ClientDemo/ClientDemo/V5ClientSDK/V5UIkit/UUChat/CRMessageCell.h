//
//  UUMessageCell.h
//  UUChatDemoForTextVoicePicture
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 uyiuyao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CRMessageContentButton.h"
#import "CRStatusView.h"
#import "CRImageAvatarBrowser.h"
#import "CRSingleArticleView.h"
#import "CRMultiArticleView.h"

@class CRMessageFrame;
@class CRMessageCell;

@protocol CRMessageCellDelegate <NSObject>
@optional
- (void)cellDidClick:(CRMessageCell *)cell messageType:(KV5MessageType)type direction:(KV5MessageDir)dir;
- (void)cellDidLongClick:(CRMessageCell *)cell messageType:(KV5MessageType)type direction:(KV5MessageDir)dir;
- (void)cellLinkDidClick:(CRMessageCell *)cell linkType:(V5KZLinkType)linkType link:(NSString *)link;
- (void)cellLinkDidLongClick:(CRMessageCell *)cell linkType:(V5KZLinkType)linkType link:(NSString *)link;
- (void)resendDidClick:(CRMessageCell *)cell;
- (void)cellDidMediaLoadFailed:(CRMessageCell *)cell willRetry:(BOOL)retry;
@end


@interface CRMessageCell : UITableViewCell

// cell中的view
@property (nonatomic, retain) UIImageView *avatarImage;
@property (nonatomic, retain) UILabel *labelTime;
@property (nonatomic, retain) CRStatusView *statusView;
@property (nonatomic, retain) CRMessageContentButton *btnContent;
@property (nonatomic, retain) CRSingleArticleView *singleArticle;
@property (nonatomic, retain) CRMultiArticleView *multiArticles;

@property (nonatomic, retain) CRMessageFrame *messageFrame;
@property (nonatomic, assign) id<CRMessageCellDelegate> delegate;


@end

