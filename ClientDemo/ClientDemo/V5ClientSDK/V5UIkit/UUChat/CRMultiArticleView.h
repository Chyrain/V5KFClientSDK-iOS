//
//  CRMultiArticleView.h
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIButton+V5Color.h"
#import "CRInsetsLabel.h"
#include "CRMessageFrame.h"
#include "V5Article.h"

@class V5Article;

// 第一个图文
@interface CRHeaderArticleView : UIButton
@property (nonatomic, strong) CRInsetsLabel *headerTitle;
@property (nonatomic, strong) UIImageView   *headerPic;
@property (nonatomic, strong) V5Article     *article;
@end

// 后面的图文
@interface CRItemArticleView : UIButton
@property (nonatomic, strong) UILabel       *itemTitle;
@property (nonatomic, strong) UIImageView   *itemPic;
@property (nonatomic, strong) V5Article     *article;
- (void)contentWithArticle:(V5Article *)article;
@end

@interface CRMultiArticleView : UIView

@property (nonatomic, strong) CRHeaderArticleView *headerArticleView;
@property (nonatomic, strong) NSMutableArray<CRItemArticleView *> *itemArticleViewArray;

@property (nonatomic, copy) CRArticleClickHandler articleClickHandler;
@property (nonatomic, copy) CRArticleClickHandler articleLongClickHandler;

- (void)contentWithArticles:(NSArray<V5Article *> *)articles;

@end
