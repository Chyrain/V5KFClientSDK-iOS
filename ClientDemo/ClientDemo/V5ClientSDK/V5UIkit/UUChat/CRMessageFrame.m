//
//  CRMessageFrame.m
//  V5KF SDK
//
//  Created by chyrain on 15-12-22.
//  Copyright (c) 2015年 v5kf. All rights reserved.
//

#import "CRMessageFrame.h"
#import "V5Message.h"
#import "NSDate+V5Utils.h"


@implementation CRMessageFrame

- (void)setMessage:(V5Message *)message{
    _message = message;
    
    self.strTime = [NSDate changeTimeIntervalToString:message.createTime];
    
    switch (message.direction) {
        case MessageDir_ToCustomer:
        case MessageDir_FromRobot:
            self.cellOnRight = NO;
            break;
            
        case MessageDir_ToWorker:
            self.cellOnRight = YES;
            break;
            
        default:
            self.cellOnRight = NO;
            break;
    }
    
    [self updateFrame];
}

- (void)updateFrame {
    CGFloat screenW = Main_Screen_Width;
    // 1、计算时间的位置
    if (_showTime) {
        CGFloat timeY = ChatMargin;
        CGRect timeRect = [_strTime boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : ChatTimeFont} context:nil];
        
        CGFloat timeX = (screenW - timeRect.size.width) / 2;
        _timeF = CGRectMake(timeX,
                            timeY,
                            timeRect.size.width + ChatTimeMarginW,
                            timeRect.size.height + ChatTimeMarginH);
    }
    
    // 2、计算起始位置
    CGFloat iconX = ChatMargin;
    if (_message.direction == MessageDir_ToWorker) {
        iconX = screenW - ChatMargin - (self.showAvatar ? ChatIconWH : 0); // 是否显示头像
    }
    CGFloat iconY = CGRectGetMaxY(_timeF) + ChatMargin;
    // 头像frame
    _avatarF = CGRectMake(iconX, iconY, ChatIconWH, ChatIconWH);
    
    // 3、计算内容位置
    CGFloat contentX = ChatMargin + (self.showAvatar ? ChatIconWH + AvatarMargin : 0); // 取消头像
    CGFloat contentY = iconY;
    
    // 根据消息类型获得内容大小
    CGSize contentSize;
    switch (_message.messageType) {
        case MessageType_Location:
            contentSize = CGSizeMake(ChatPicWH, ChatPicWH);
            break;
            
        case MessageType_Image:
            contentSize = CGSizeMake(ChatPicWH, ChatPicWH);
            break;
            
        case MessageType_Voice:
            contentSize = CGSizeMake(60, 20);
            break;
            
//        case MessageType_Articles:
//            contentSize = 
//            break;
            
        case MessageType_Text:
        default: {
            CGRect contentRect = [[_message getDefaultContent] boundingRectWithSize:CGSizeMake(ChatContentW - (self.showAvatar ? ChatIconWH : 0), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : ChatContentFont} context:nil];
            
            contentSize = contentRect.size;
        }
            break;
    }
    if (_message.direction == MessageDir_ToWorker) { // self.cellOnRight
        contentX = iconX - contentSize.width - ChatContentLeft - ChatContentRight - (self.showAvatar ? AvatarMargin : 0);
    }
    _contentF = CGRectMake(contentX,
                           contentY,
                           contentSize.width + ChatContentLeft + ChatContentRight,
                           contentSize.height + ChatContentTop + ChatContentBottom);
    
    // 计算状态显示位置
    if (_message.direction == MessageDir_ToWorker) {
        _statusF = CGRectMake(contentX - ChatStatusWH - 3,
                              contentY + (_contentF.size.height - ChatStatusWH)/ 2,
                              ChatStatusWH,
                              ChatStatusWH);
    } else {
        _statusF = CGRectMake(contentX + 3,
                              contentY + (_contentF.size.height - ChatStatusWH)/ 2,
                              ChatStatusWH,
                              ChatStatusWH);
    }
    
    _cellHeight = CGRectGetMaxY(_contentF) + ChatMargin;
}

@end
