//
//  CRMultiArticleView.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/24.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRMultiArticleView.h"
#include "UIImageView+V5AFNetworking.h"

@implementation CRHeaderArticleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setBackgroundColor:ArticleBGNormalColor forState:UIControlStateNormal];
        [self setBackgroundColor:ArticleBGHighlightColor forState:UIControlStateHighlighted];
        
        CGFloat width = ArticleContentW - 2*ArticlesInnerMargin;
        CGFloat height = ArticlesImageHeight;
        CGRect picFrame = CGRectMake(ArticlesInnerMargin, ArticlesInnerMargin, width, height);
        self.headerPic = [[UIImageView alloc] initWithFrame:picFrame];
        [self addSubview:self.headerPic];
        
        self.headerTitle = [[CRInsetsLabel alloc] init];
        self.headerTitle.font = ArticlesHeaderTextFont;
        self.headerTitle.textColor = ArticlesHeaderTextColor;
        self.headerTitle.backgroundColor = ArticlesHeaderBGColor;
        // UILabel文本边距
        [self.headerTitle setInsets:ArticlesHeaderLabelInsets];
        
        CGSize size = [V5LocalStr(@"v5_title_eg", @"标题") sizeWithAttributes:@{NSFontAttributeName : self.headerTitle.font}];
        height = size.height + ArticlesInnerMargin;
        CGRect titleFrame = CGRectMake(ArticlesInnerMargin, picFrame.size.height + ArticlesInnerMargin - height, width, height);
        self.headerTitle.frame = titleFrame;
        [self addSubview:self.headerTitle];
        
        self.frame = CGRectMake(0, 0, ArticleContentW, picFrame.size.height + 2*ArticlesInnerMargin);
    }
    
    return self;
}

- (void)contentWithArticle:(V5Article *)article {
    self.headerTitle.text = article.title;
    [self.headerPic setImageWithURL:[NSURL URLWithString:article.picUrl]
                                     placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
                                         failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]];
}

@end

@implementation CRItemArticleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setBackgroundColor:ArticleBGNormalColor forState:UIControlStateNormal];
        [self setBackgroundColor:ArticleBGHighlightColor forState:UIControlStateHighlighted];
        
        CGFloat width = ArticleContentW - 2*ArticleInnerMargin - ArticlesInnerMargin - ArticlesPicWH;
        CGFloat height = ArticlesPicWH;
        self.itemTitle = [[UILabel alloc] initWithFrame:CGRectMake(ArticleInnerMargin,
                                                                   ArticlesInnerMargin,
                                                                   width,
                                                                   height)];
        self.itemTitle.font = ArticlesTitleFont;
        self.itemTitle.textColor = ArticlesTitleColor;
        self.itemTitle.numberOfLines = 0;
        [self addSubview:self.itemTitle];
        
        CGRect picFrame = CGRectMake(ArticleContentW - ArticlesPicWH - ArticlesInnerMargin,
                                     ArticlesInnerMargin,
                                     ArticlesPicWH,
                                     ArticlesPicWH);
        self.itemPic = [[UIImageView alloc] initWithFrame:picFrame];
        [self addSubview:self.itemPic];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                0.25,
                                                                ArticleContentW,
                                                                ArticlesLineHeight/([UIScreen mainScreen].scale))];
        line.backgroundColor = ArticlesLineColor;
        [self addSubview:line];
    }
    
    return self;
}

- (void)contentWithArticle:(V5Article *)article {
    self.article = article;
    if (!article.picUrl) {
        self.itemTitle.frame = CGRectMake(ArticleInnerMargin,
                                          ArticlesInnerMargin,
                                          ArticleContentW - 2*ArticleInnerMargin,
                                          ArticlesPicWH);
        self.itemPic.frame = CGRectNull;
    } else {
        [self.itemPic setImageWithURL:[NSURL URLWithString:article.picUrl]
                     placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
                         failureImage:[UIImage imageNamed:IMGFILE(@"v5_empty_img")]];
    }
    self.itemTitle.text = article.title;
}

@end

@implementation CRMultiArticleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 圆角边框,背景色
        ViewBorderRadius(self, ArticleBGRadius, 1.0, [UIColor clearColor]);
        self.backgroundColor = [UIColor whiteColor];
        
        self.articleClickHandler = ^(NSString *url) {};
    }
    
    return self;
}

- (void)contentWithArticles:(NSArray<V5Article *> *)articles {
    if (!articles || [articles count] < 1) {
        return;
    }
    [self clearViews];
    
    V5Article *article = [articles objectAtIndex:0];
    if (!self.headerArticleView) {
        self.headerArticleView = [[CRHeaderArticleView alloc] init];
        [self.headerArticleView addTarget:self action:@selector(contentClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.headerArticleView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongClick:)]];
        [self addSubview:self.headerArticleView];
    }
    [self.headerArticleView contentWithArticle:article];
    
    CGFloat currentY = self.headerArticleView.frame.origin.y + self.headerArticleView.frame.size.height;
    for (NSInteger i = 1; i < [articles count]; i++) {
        article = [articles objectAtIndex:i];
        CGRect itemFrame = CGRectMake(0, currentY, ArticleContentW, ArticlesPicWH + 2*ArticlesInnerMargin);
        CRItemArticleView *item = [[CRItemArticleView alloc] initWithFrame:itemFrame];
        [item contentWithArticle:article];
        [item addTarget:self action:@selector(contentClick:) forControlEvents:UIControlEventTouchUpInside];
        [item addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongClick:)]];
        [self addSubview:item];
        [self.itemArticleViewArray addObject:item];
        currentY = currentY + itemFrame.size.height;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, currentY);
}

- (void)clearViews {
    if (self.itemArticleViewArray) {
        for (CRItemArticleView *itemView in self.itemArticleViewArray) {
            [itemView removeFromSuperview];
        }
        [self.itemArticleViewArray removeAllObjects];
    } else {
        self.itemArticleViewArray = [NSMutableArray array];
    }
}

- (void)contentClick:(id)sender {
    if ([sender isKindOfClass:[CRHeaderArticleView class]]) {
        if (((CRHeaderArticleView *)sender).article.url) {
            self.articleClickHandler(((CRHeaderArticleView *)sender).article.url);
        }
    } else if ([sender isKindOfClass:[CRItemArticleView class]]) {
        if (((CRItemArticleView *)sender).article.url) {
            self.articleClickHandler(((CRItemArticleView *)sender).article.url);
        }
    }
}

- (void)contentLongClick:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer && (recognizer.state != UIGestureRecognizerStateBegan)) {
        return;
    }
    if ([recognizer.view isKindOfClass:[CRHeaderArticleView class]]) {
        if (((CRHeaderArticleView *)recognizer.view).article.url) {
            self.articleLongClickHandler(((CRHeaderArticleView *)recognizer.view).article.url);
        }
    } else if ([recognizer.view isKindOfClass:[CRItemArticleView class]]) {
        if (((CRItemArticleView *)recognizer.view).article.url) {
            self.articleLongClickHandler(((CRItemArticleView *)recognizer.view).article.url);
        }
    }
}

@end
