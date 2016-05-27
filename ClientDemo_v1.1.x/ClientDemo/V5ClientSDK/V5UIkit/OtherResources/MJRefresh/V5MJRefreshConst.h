//
//  V5MJRefreshConst.h
//  V5MJRefresh
//
//  Created by mj on 14-1-3.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "V5Macros.h"

#ifdef DEBUG
#define V5MJLog(...) NSLog(__VA_ARGS__)
#else
#define V5MJLog(...)
#endif

// 文字颜色
#define V5MJRefreshLabelTextColor [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1.0]

extern const CGFloat V5MJRefreshViewHeight;
extern const CGFloat V5MJRefreshAnimationDuration;

extern NSString *const V5MJRefreshBundleName;

extern NSString *const V5MJRefreshFooterPullToRefresh;
extern NSString *const V5MJRefreshFooterReleaseToRefresh;
extern NSString *const V5MJRefreshFooterRefreshing;

extern NSString *const V5MJRefreshHeaderPullToRefresh;
extern NSString *const V5MJRefreshHeaderReleaseToRefresh;
extern NSString *const V5MJRefreshHeaderRefreshing;
extern NSString *const V5MJRefreshHeaderTimeKey;

extern NSString *const V5MJRefreshContentOffset;
extern NSString *const V5MJRefreshContentSize;