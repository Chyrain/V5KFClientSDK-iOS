//
//  V5KZLinkLabel.h
//  LinkTest
//
//  Created by joywii on 14/12/8.
//  Edit by chyrain on 15/12/23.
//  Copyright (c) 2015年 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSAttributedString+V5Emotion.h"

// 链接类型
typedef NS_ENUM(NSInteger, V5KZLinkType) {
    V5KZLinkTypeNone = 0,         //非链接的普通文本
    V5KZLinkTypeUserHandle,       //用户昵称  eg: @kingzwt
    V5KZLinkTypeHashTag,          //内容标签  eg: #hello
    V5KZLinkTypeURL,              //链接地址  eg: http://www.baidu.com
    V5KZLinkTypePhoneNumber,      //电话号码  eg: 13888888888
    V5KZLinkTypeHTMLHref,         //HTML超链接 eg:<a href="http://www.baidu.com"></a>
    V5KZLinkTypeArticleURL        //图文链接
};

// 可用于识别的链接类型
typedef NS_OPTIONS(NSUInteger, V5KZLinkDetectionTypes) {
    V5KZLinkDetectionTypeUserHandle  = (1 << 0),
    V5KZLinkDetectionTypeHashTag     = (1 << 1),
    V5KZLinkDetectionTypeURL         = (1 << 2),
    V5KZLinkDetectionTypePhoneNumber = (1 << 3),
    V5KZLinkDetectionTypeHTMLHref    = (1 << 4),
    
    V5KZLinkDetectionTypeNone        = 0,
    V5KZLinkDetectionTypeAll         = NSUIntegerMax
};

typedef void (^V5KZLinkHandler)(V5KZLinkType linkType, NSString *string);

@interface V5KZLinkLabel : UILabel <NSLayoutManagerDelegate>

@property (nonatomic, assign, getter = isAutomaticLinkDetectionEnabled) BOOL automaticLinkDetectionEnabled;
@property (nonatomic, strong) UIColor *linkColor;
@property (nonatomic, strong) UIColor *linkHighlightColor;
@property (nonatomic, strong) UIColor *linkBackgroundColor;
@property (nonatomic, assign) NSUnderlineStyle linkUnderlineStyle;
@property (nonatomic, assign) V5KZLinkDetectionTypes linkDetectionTypes;
@property (nonatomic, copy) V5KZLinkHandler linkTapHandler;
@property (nonatomic, copy) V5KZLinkHandler linkLongPressHandler;

@property (nonatomic, strong) NSAttributedString *V5KZAttributedString;

@end
