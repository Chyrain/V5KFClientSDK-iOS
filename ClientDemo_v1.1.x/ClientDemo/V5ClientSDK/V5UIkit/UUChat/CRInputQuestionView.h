//
//  CRInputQuestionView.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/28.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CRQuestionViewDelegate <NSObject>

- (void)didSelectedQuestion:(NSString *)question;

@end

@interface CRInputQuestionView : UIView<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UILabel *headLabel;
@property (nonatomic, strong) UITableView *contentTableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray *questionArray;
@property (nonatomic,weak)id <CRQuestionViewDelegate> delegate;

@end
