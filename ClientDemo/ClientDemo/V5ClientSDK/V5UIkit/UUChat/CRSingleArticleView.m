//
//  CRSingleArticleView.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRSingleArticleView.h"
#import "V5ImageLoader.h"

@interface CRSingleArticleView () {
    UILabel *bottomMore;
}

@end

@implementation CRSingleArticleView

- (instancetype)initWithFrame:(CGRect)_frame_ {
    self = [super initWithFrame:_frame_];
    if (self) {
        // 圆角边框,背景色
        ViewBorderRadius(self, ArticleBGRadius, 1.0, [UIColor clearColor]);
        [self setBackgroundColor:ArticleBGNormalColor forState:UIControlStateNormal];
        [self setBackgroundColor:ArticleBGHighlightColor forState:UIControlStateHighlighted];
        
        // 标题
        self.articleTitle = [[UILabel alloc] init];
        self.articleTitle.font = ArticleTitleFont;
        self.articleTitle.textColor = ArticleTitleColor;
        self.articleTitle.text = V5LocalStr(@"v5_title_eg", @"标题");
        self.articleTitle.numberOfLines = 1;
        [self addSubview:self.articleTitle];
        
        // 图片
        self.articlePic = [[UIImageView alloc] init];
        self.articlePic.layer.masksToBounds  = YES;
        self.articlePic.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.articlePic];
        
        // 简介
        self.articleDesc = [[UILabel alloc] init];
        self.articleDesc.font = ArticleDescFont;
        self.articleDesc.textColor = ArticleDescColor;
        self.articleDesc.numberOfLines = 0;
        [self addSubview:self.articleDesc];
        
        // 详情
        bottomMore = [[UILabel alloc] init];
        bottomMore.font = ArticleMoreFont;
        bottomMore.textColor = ArticleMoreColor;
        bottomMore.text = V5LocalStr(@"v5_view_more", @"查看全文");
        [self addSubview:bottomMore];
        
        self.articleClickHandler = ^(NSString *url) {};
    }
    return self;
}

- (void)contentWithArticle:(V5Article *)article {
    [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongClick:)]];
    [self addTarget:self action:@selector(contentClick) forControlEvents:UIControlEventTouchUpInside];
    self.article = article;
    self.articleTitle.text = article.title;
    self.articleDesc.text = article.desc;
    if (article.picUrl) {
        [V5ImageLoader setImageView:self.articlePic
                            withURL:article.picUrl
                   placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
                       failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]];
    }
    
    CGFloat currentY = 0;
    CGSize size = [V5LocalStr(@"v5_title_eg", @"标题") sizeWithAttributes:@{NSFontAttributeName : self.articleTitle.font}];
    CGRect frame = CGRectMake(ArticleFrameMargin, ArticleFrameMargin, ArticleContentW - 2*ArticleFrameMargin, size.height);
    self.articleTitle.frame = frame;
    
    if (article.picUrl) {
        currentY = ArticleFrameMargin + size.height + ArticleInnerMargin;
        frame.origin.y = currentY;
        frame.size.height = ArticleImageHeight;
    } else {
        currentY = ArticleFrameMargin + size.height;
        frame.size.height = 0;
    }
    self.articlePic.frame = frame;
    
    currentY = currentY + frame.size.height + ArticleInnerMargin;
    CGRect rect = [article.desc boundingRectWithSize:CGSizeMake(ArticleContentW - 2*ArticleFrameMargin, MAXFLOAT)
                                             options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                          attributes:@{NSFontAttributeName : self.articleDesc.font}
                                             context:nil];
    size = rect.size;
    frame.origin.y = currentY;
    frame.size.height = size.height;
    self.articleDesc.frame = frame;
    
    currentY = currentY + size.height + ArticleInnerMargin;
    size = [bottomMore.text sizeWithAttributes:@{NSFontAttributeName : bottomMore.font}];
    frame.origin.y = currentY;
    frame.size.height = size.height;
    bottomMore.frame = frame;
    
    currentY = currentY + size.height + ArticleFrameMargin;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, currentY);
}

- (void)contentClick {
    if (self.article.url) {
        self.articleClickHandler(self.article.url);
    }
}

- (void)contentLongClick:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer && (recognizer.state != UIGestureRecognizerStateBegan)) {
        return;
    }
    if (self.article.url) {
        self.articleLongClickHandler(self.article.url);
    }
}

@end
