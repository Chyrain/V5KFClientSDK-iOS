//
//  CRMessageFrame.h
//  V5KF SDK
//
//  Created by chyrain on 15-12-22.
//  Copyright (c) 2015年 v5kf. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CRConfigMcros.h"

// 单、多图文点击处理
typedef void (^CRArticleClickHandler)(NSString *url);

@class V5Message;

@interface CRMessageFrame : NSObject

@property (nonatomic, assign) CGRect timeF;
@property (nonatomic, assign) CGRect contentF;
@property (nonatomic, assign) CGRect avatarF; // 头像
@property (nonatomic, assign) CGRect statusF;

@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, strong) V5Message *message;
@property (nonatomic, strong) NSString *strTime;
@property (nonatomic, assign) BOOL showTime;

//决定是否显示对话双方的头像
@property (nonatomic, assign) BOOL showAvatar;
//头像圆角
@property (nonatomic, assign) CGFloat avatarRadius;
//决定显示气泡的属性：左右，背景色
@property (nonatomic, assign) BOOL cellOnRight;
//加载图片失败的重试次数
@property (nonatomic, assign) NSUInteger imageRetryCounter;
@property (nonatomic, assign) BOOL isDownloadingMessage; // 状态：是否正在加载消息

/**
 *  更新内部view的frame
 */
- (void)updateFrame;

@end
