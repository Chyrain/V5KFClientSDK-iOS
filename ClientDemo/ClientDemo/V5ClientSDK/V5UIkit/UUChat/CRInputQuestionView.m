//
//  CRInputQuestionView.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/28.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRInputQuestionView.h"
#import "CRConfigMcros.h"

#define HeaderLabelH  20.0

@interface CRInputQuestionView () {
    NSMutableArray *selectedArray;
}

@end

@implementation CRInputQuestionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = InputBGColor;
        CGRect contentFrame = self.frame;
        if (contentFrame.size.height > kEnglishKeyboardHeight) {
            contentFrame.size.height = kEnglishKeyboardHeight;
        }
        self.frame = contentFrame;
        
        self.headLabel = [[UILabel alloc] initWithFrame:CGRectMake(ChatContentMargin, 0, self.frame.size.width, HeaderLabelH)];
        self.headLabel.textColor = [UIColor grayColor];
        self.headLabel.font = SYSTEMFONT(12.0);
        self.headLabel.text = V5LocalStr(@"v5_relative_question:", @"相关问题:");
        [self addSubview:self.headLabel];
        
        contentFrame = self.bounds;
        contentFrame.origin.y = HeaderLabelH;
        contentFrame.size.height = self.frame.size.height - HeaderLabelH;
        self.contentTableView = [[UITableView alloc] initWithFrame:contentFrame style:UITableViewStylePlain];
        self.contentTableView.delegate = self;
        self.contentTableView.dataSource = self;
        self.contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.contentTableView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.contentTableView];
        
        contentFrame.origin.y = self.frame.size.height / 3;
        contentFrame.size.height = 50;
        self.emptyLabel = [[UILabel alloc] initWithFrame:contentFrame];
        self.emptyLabel.textAlignment = NSTextAlignmentCenter;
        self.emptyLabel.text = V5LocalStr(@"v5_content_empty", @"空的哟～");
        self.emptyLabel.font = SYSTEMFONT(16.0);
        self.emptyLabel.textColor = [UIColor lightGrayColor];
        self.emptyLabel.hidden = YES;
        [self addSubview:self.emptyLabel];
    }
    return self;
}

- (void)setQuestionArray:(NSArray *)questionArray {
    _questionArray = questionArray;
    selectedArray = [NSMutableArray arrayWithCapacity:[questionArray count]];
    for (NSInteger i = 0; i < [questionArray count]; i++) {
        [selectedArray addObject:@(NO)];
    }
    
    //重绘frame
    CGRect frame = self.frame;
    frame.size.width = Main_Screen_Width;
    self.frame = frame;
    frame = self.bounds;
    frame.origin.y = HeaderLabelH;
    frame.size.height = self.frame.size.height - HeaderLabelH;
    self.contentTableView.frame = frame;
    frame.origin.y = self.frame.size.height / 3;
    frame.size.height = 50;
    self.emptyLabel.frame = frame;
    
    if (!questionArray || [questionArray count] == 0) {
        self.contentTableView.hidden = YES;
        self.emptyLabel.hidden = NO;
    } else {
        self.contentTableView.hidden = NO;
        self.emptyLabel.hidden = YES;
        [self.contentTableView reloadData];
    }
}

#pragma mark ------ UITableViewDataSource ------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.questionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"myCellID"];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = InputQuesTextFont;
        cell.textLabel.textColor = InputQuesTextColor;
    }
    cell.textLabel.text = self.questionArray[indexPath.row];
    if ([selectedArray[indexPath.row] isEqual:@(YES)]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark ------ UITableViewDelegate ------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 36.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    if ([selectedArray[indexPath.row] isEqual:@(YES)]) { // 已选中则取消选中
        [cell setSelected:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        selectedArray[indexPath.row] = @(NO);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedQuestion:)]) {
            [self.delegate didSelectedQuestion:@""];
        }
        return;
    }
    // 设置为选中
    selectedArray[indexPath.row] = @(YES);
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedQuestion:)]) {
        [self.delegate didSelectedQuestion:self.questionArray[indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 取消选中
    selectedArray[indexPath.row] = @(NO);
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

@end
