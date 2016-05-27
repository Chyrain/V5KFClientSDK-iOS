//
//  CRInputMoreView.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/28.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "CRInputMoreView.h"
#import "CRConfigMcros.h"

@interface CRInputMoreView () {
    NSMutableArray *subviewArray;
    UILabel *supportLabel;
}

@end

@implementation CRInputMoreView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.backgroundColor = InputBGColor;
    }
    return self;
}

- (void)setImageArray:(NSArray *)imageArray nameArray:(NSArray *)nameArray {
    [self clearViews];
    
    // Main_Screen_Width / 8 >= 60 ? (Main_Screen_Width / 8 > 84 ? 8 : 6) : 4;
    // [修改]未更新到pod 1.1.2
    NSUInteger numEachRow = Main_Screen_Width / 80;
    if (numEachRow > 8) {
        numEachRow = 8;
    } else if (Main_Screen_Width / 8 < 60) {
        numEachRow = 4;
    }
    CGFloat imageWidth = (Main_Screen_Width - (InputMoreHPadding)*(numEachRow + 1))/numEachRow;
    //V5Log(@"imageWidth:%f", imageWidth);
    for(int i=0;i<imageArray.count;i++) {
        int clo = i % numEachRow;
        int lin = i / numEachRow;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

        btn.frame = CGRectMake(InputMoreHPadding + (InputMoreHPadding+imageWidth)*clo,20.0+(InputMoreVPadding+imageWidth)*lin, imageWidth, imageWidth);
        btn.tag = i;
        [btn setBackgroundImage:[UIImage imageNamed:imageArray[i]] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(InputMoreHPadding + (InputMoreHPadding+imageWidth)*clo,
                                                                   btn.frame.origin.y + imageWidth,
                                                                   imageWidth,
                                                                   20)];
        label.textColor = InputMoreLabelColor;
        label.font = InputMoreLabelFont;
        label.text = nameArray[i];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        [self addSubview:btn];
        [subviewArray addObject:label];
        [subviewArray addObject:btn];
    }
    
    // 调整moreView大小
    CGRect newFrame = self.frame;
    CGFloat maxHeight = (InputMoreVPadding+imageWidth) * 2 + 30;
    if (numEachRow > 4) {
        newFrame.size.height = (imageArray.count / numEachRow + 1) * (InputMoreVPadding+imageWidth) + 30;
        if (newFrame.size.height > maxHeight) {
            newFrame.size.height = maxHeight;
        }
    } else {
        newFrame.size.height = maxHeight;
    }
    
    V5Log(@"newFrame.size.height:%f numEachRow:%lu Main_Screen_Width:%f", newFrame.size.height, (unsigned long)numEachRow, Main_Screen_Width);
    self.frame = newFrame;
    
    if (!supportLabel) {
        supportLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, newFrame.size.height - 25, Main_Screen_Width, 25)];
        [self addSubview:supportLabel];
        supportLabel.text = V5LocalStr(@"v5_support_info", @"由V5KF提供技术支持");
        supportLabel.font = InputSupportLabelFont;
        supportLabel.textColor = InputSupportLabelColor;
        supportLabel.textAlignment = NSTextAlignmentCenter;
    }
    supportLabel.frame = CGRectMake(0, newFrame.size.height - 25, Main_Screen_Width, 25);
}

- (void)selectImage:(UIButton *)btn {
    if(self.delegate){
        [self.delegate didselectImageView:btn.tag];
    }
}

- (void)clearViews {
    if (subviewArray) {
        for (UIView *itemView in subviewArray) {
            [itemView removeFromSuperview];
        }
        [subviewArray removeAllObjects];
    } else {
        subviewArray = [NSMutableArray array];
    }
}

@end
