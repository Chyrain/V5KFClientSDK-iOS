//
//  UITableView+Scroll.h
//  DoctorClient
//
//  Created by weqia on 14-5-3.
//  Copyright (c) 2014年 xhb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V5FixCategoryBug.h"

V5KW_FIX_CATEGORY_BUG_H(UITableView_V5Scroll)
@interface UITableView (V5Scroll)
-(void)scrollToBottom;
-(void)scrollToBottom:(BOOL)animation;
@end
