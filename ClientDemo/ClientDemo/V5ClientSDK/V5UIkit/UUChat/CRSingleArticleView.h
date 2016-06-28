//
//  CRSingleArticleView.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIButton+V5Color.h"
#import "CRMessageFrame.h"
#import "V5Article.h"

@class V5Article;

@interface CRSingleArticleView : UIButton

@property (nonatomic, strong) UILabel       *articleTitle;
@property (nonatomic, strong) UIImageView   *articlePic;
@property (nonatomic, strong) UILabel       *articleDesc;

@property (nonatomic, strong) V5Article *article;
@property (nonatomic, copy) CRArticleClickHandler articleClickHandler;
@property (nonatomic, copy) CRArticleClickHandler articleLongClickHandler;

- (void)contentWithArticle:(V5Article *)article;

@end
