//
//  UUInputFunctionView.m
//  UUChatDemoForTextVoicePicture
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 uyiuyao. All rights reserved.
//

#import "CRInputFunctionView.h"
#import "CRInputMoreView.h"
#import "CRInputQuestionView.h"
#import "CRProgressHUD.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CRConfigMcros.h"
#import "V5ChatViewController.h"
#import "V5VoiceRecorder.h"
#import "V5ClientAgent.h"
#import "V5Util.h"

#define MAX_LIMIT_NUMS  1000 //来限制最大输入只能1000个字符

@interface CRInputFunctionView ()<UITextViewDelegate,CRMoreViewDelegate,CRQuestionViewDelegate,V5VoiceRecorderDelegate> {
    UILabel *placeHold;
    BOOL keyBoardShow;
    
    // 语音相关
    BOOL isbeginVoiceRecord;
    V5VoiceRecorder *voiceRecorder;
    NSInteger playTime;
    NSTimer *playTimer;
    BOOL enableRecord;
}
@end

@implementation CRInputFunctionView

- (id)initWithSuperVC:(UIViewController *)superVC
             delegate:(id<CRInputFunctionViewDelegate>)delegate
                frame:(CGRect)frame {
    self.superVC = superVC;
    self.delegate = delegate;
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = InputBGColor;
        enableRecord = YES;
        
        voiceRecorder = [[V5VoiceRecorder alloc] initWithDelegate:self];
        if (self.delegate && [self.delegate respondsToSelector:@selector(isCRInputFunctionViewEnableVoiceRecord:)]) {
            enableRecord = [self.delegate isCRInputFunctionViewEnableVoiceRecord:self];
        }
        
        if (ENABLE_VOICE_SEND && enableRecord) {
            //改变状态（语音、文字）
            self.btnChangeVoiceState = [UIButton buttonWithType:UIButtonTypeCustom];
            self.btnChangeVoiceState.frame = CGRectMake(InputHorizontalPadding,
                                                        self.frame.size.height - INPUT_BTN_H - InputVerticalPadding,
                                                        INPUT_BTN_H,
                                                        INPUT_BTN_H);
            isbeginVoiceRecord = NO;
            [self.btnChangeVoiceState setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_voice_normal")]
                                                forState:UIControlStateNormal];
            self.btnChangeVoiceState.titleLabel.font = [UIFont systemFontOfSize:12];
            [self.btnChangeVoiceState addTarget:self action:@selector(voiceRecord:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:self.btnChangeVoiceState];
            
            //语音录入键
            self.btnVoiceRecord = [UIButton buttonWithType:UIButtonTypeCustom];
            self.btnVoiceRecord.frame = CGRectMake(45, InputVerticalPadding, Main_Screen_Width-100, INPUT_BTN_H);
            self.btnVoiceRecord.hidden = YES;
            [self.btnVoiceRecord setBackgroundImage:[UIImage imageNamed:IMGFILE(@"chat_message_back")] forState:UIControlStateNormal];
            [self.btnVoiceRecord setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [self.btnVoiceRecord setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
            [self.btnVoiceRecord setTitle:V5LocalStr(@"v5_press_to_talk", @"按住说话") forState:UIControlStateNormal];
            [self.btnVoiceRecord setTitle:V5LocalStr(@"v5_release_to_send", @"松开发送") forState:UIControlStateHighlighted];
            [self.btnVoiceRecord addTarget:self action:@selector(beginRecordVoice:) forControlEvents:UIControlEventTouchDown];
            [self.btnVoiceRecord addTarget:self action:@selector(endRecordVoice:) forControlEvents:UIControlEventTouchUpInside];
            [self.btnVoiceRecord addTarget:self action:@selector(cancelRecordVoice:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
            [self.btnVoiceRecord addTarget:self action:@selector(RemindDragExit:) forControlEvents:UIControlEventTouchDragExit];
            [self.btnVoiceRecord addTarget:self action:@selector(RemindDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
            [self addSubview:self.btnVoiceRecord];
        }
        
        //发送消息/加号切换按钮
        self.btnSendMessage = [UIButton buttonWithType:UIButtonTypeCustom];
        self.btnSendMessage.frame = CGRectMake(Main_Screen_Width-45,
                                               self.frame.size.height - INPUT_BTN_H - InputVerticalPadding,
                                               INPUT_BTN_H,
                                               INPUT_BTN_H);
        self.isAbleToSendTextMessage = NO;
        [self.btnSendMessage setTitle:@"" forState:UIControlStateNormal];
        [self.btnSendMessage setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_add_normal")] forState:UIControlStateNormal];
        self.btnSendMessage.titleLabel.font = [UIFont systemFontOfSize:12];
        [self.btnSendMessage addTarget:self action:@selector(functionMoreClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btnSendMessage];
        
        //输入框
        self.TextViewInput = [[UITextView alloc]initWithFrame:CGRectMake(ENABLE_VOICE_SEND && enableRecord ? 45 : 5,
                                                                         InputVerticalPadding,
                                                                         Main_Screen_Width- (ENABLE_VOICE_SEND && enableRecord ? 100 : 60),
                                                                         INPUT_BTN_H)];// (5, 5, Main_Screen_Width-2*45, 35)
        self.TextViewInput.font = [UIFont systemFontOfSize:16];
        self.TextViewInput.layer.cornerRadius = 4;
        self.TextViewInput.layer.masksToBounds = YES;
        self.TextViewInput.delegate = self;
        self.TextViewInput.layer.borderWidth = 1;
        self.TextViewInput.layer.borderColor = [[[UIColor lightGrayColor] colorWithAlphaComponent:0.4] CGColor];
        self.TextViewInput.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        [self addSubview:self.TextViewInput];
        
        //输入框的提示语
        placeHold = [[UILabel alloc]initWithFrame:CGRectMake(5, 0, 200, INPUT_BTN_H)];
        placeHold.text = V5LocalStr(@"v5_input_hint", @"请在这里输入内容");
        placeHold.textColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8];
        [self.TextViewInput addSubview:placeHold];
        
        //分割线
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3].CGColor;
        
        //更多输入选项
        NSUInteger numEachRow = Main_Screen_Width / 8 > 72 ? 8 : 4;
        CGFloat imageWidth = (Main_Screen_Width - (InputMoreHPadding)*(numEachRow + 1))/numEachRow;
        CGFloat maxHeight = (InputMoreVPadding+imageWidth) * 2 + 30;
        self.moreView = [[CRInputMoreView alloc] initWithFrame:CGRectMake(0, INPUT_BAR_H, self.frame.size.width, maxHeight)];
        self.moreView.backgroundColor = InputBGColor;
        [(CRInputMoreView *)self.moreView setDelegate:self];
        self.moreView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        if (!self.imageArray) {
            self.imageArray = @[IMGFILE(@"v5_icon_ques"),
                                IMGFILE(@"v5_icon_relative_ques"),
                                IMGFILE(@"v5_icon_photo"),
                                IMGFILE(@"v5_icon_camera"),
                                IMGFILE(@"v5_icon_worker")];
        }
        if (!self.nameArray) {
            self.nameArray = @[V5LocalStr(@"v5_hot_question", @"常见问题"),
                               V5LocalStr(@"v5_relative_question", @"相关问题"),
                               V5LocalStr(@"v5_photo", @"图片"),
                               V5LocalStr(@"v5_camera", @"拍照"),
                               V5LocalStr(@"v5_worker", @"人工客服")];
        }
        [(CRInputMoreView *)self.moreView setImageArray:self.imageArray nameArray:self.nameArray];
        
        //添加通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardChange:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardChange:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(keyboardChange:)
//                                                     name:UIKeyboardDidHideNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(keyboardChange:)
//                                                     name:UIKeyboardDidShowNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGRect subFrame = self.TextViewInput.frame;
    subFrame.size.width = frame.size.width - (ENABLE_VOICE_SEND && enableRecord ? 100 : 60);
    self.TextViewInput.frame = subFrame;
    subFrame = self.btnSendMessage.frame;
    if (ENABLE_VOICE_SEND && enableRecord) {
        self.btnVoiceRecord.frame = CGRectMake(45, InputVerticalPadding, Main_Screen_Width-100, INPUT_BTN_H);
    }
    
    subFrame.origin.y = self.TextViewInput.frame.origin.y + self.TextViewInput.frame.size.height - INPUT_BTN_H;
    subFrame.origin.x = self.frame.size.width - 45;
    self.btnSendMessage.frame = subFrame;
    
    if (ENABLE_VOICE_SEND && enableRecord) {
        subFrame = self.btnChangeVoiceState.frame;
        subFrame.origin.y = self.TextViewInput.frame.origin.y + self.TextViewInput.frame.size.height - INPUT_BTN_H;
        self.btnChangeVoiceState.frame = subFrame;
    }
}

// 改变输入与录音状态
- (void)voiceRecord:(UIButton *)sender
{
    isbeginVoiceRecord = !isbeginVoiceRecord;
    if (isbeginVoiceRecord) {
        [self updateFrameOnState:CRInputBarState_VoiceRecord];
    }else{
        [self updateFrameOnState:CRInputBarState_TextInput];
    }
}

//切换更多输入模式 or 发送消息（文字图片）
- (void)functionMoreClick:(UIButton *)sender {
    if (self.isAbleToSendTextMessage) { //判断是发送状态还是更多输入功能状态
//        NSString *resultStr = [self.TextViewInput.text stringByReplacingOccurrencesOfString:@"   " withString:@""];
        NSString *resultStr = self.TextViewInput.text;
        BOOL sendOut = [self.delegate CRInputFunctionView:self sendMessage:resultStr]; // 发送文本消息回调
        if (sendOut) {
            self.TextViewInput.text = @"";
            [self textViewDidChange:self.TextViewInput];
        }
    } else {
        [self updateFrameOnState:CRInputBarState_MoreFunc];
//        [self.TextViewInput resignFirstResponder];
//        //V5Log(@"self.bottomShowType:%ld", (long)self.bottomShowType);
//        if (self.bottomShowType != BottomTypeMore) {
//            //显示moreView
//            if (keyBoardShow || self.bottomShowType != BottomTypeNone) {
//                [self showBottomViewType:BottomTypeMore withParams:nil animated:NO];
//            } else {
//                [self showBottomViewType:BottomTypeMore withParams:nil animated:YES];
//            }
//        } else {
//            //收起bottomView
//            [self showBottomViewType:BottomTypeNone withParams:nil];
//        }
    }
}

#pragma mark ------ Bottom View Controller ------
- (void)willShowBottomView:(UIView *)bottomView {
    if (![self.activeView isEqual:bottomView]) {
        CGFloat bottomHeight = bottomView ? bottomView.frame.size.height : 0;
        [self willShowBottomHeight:bottomHeight];
        
        if (bottomView) {
            CGRect rect = bottomView.frame;
            rect.origin.y = self.TextViewInput.frame.size.height + 2*InputVerticalPadding;
            bottomView.frame = rect;
            [self addSubview:bottomView];
            if ([bottomView isEqual:self.moreView]) {
                self.bottomShowType = BottomTypeMore;
            } else if ([bottomView isEqual:self.questionView]) {
                self.bottomShowType = BottomTypeRelativeQuestion;
            } else if ([bottomView isEqual:self.faceView]) {
                self.bottomShowType = BottomTypeFace;
            }
        } else {
            self.bottomShowType = BottomTypeNone;
        }
        if (self.activeView) {
            [self.activeView removeFromSuperview];
        }
        self.activeView = bottomView;
    }
}

- (void)willShowBottomHeight:(CGFloat)bottomHeight {
    CGRect fromFrame = self.frame;
    CGFloat toHeight = self.TextViewInput.frame.size.height + 2*InputVerticalPadding + bottomHeight;
    CGRect toFrame = CGRectMake(fromFrame.origin.x,
                                fromFrame.origin.y + (fromFrame.size.height - toHeight),
                                fromFrame.size.width,
                                toHeight);
    self.frame = toFrame;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:willChangeOriginY:)]) {
        [self.delegate CRInputFunctionView:self
                         willChangeOriginY:self.frame.origin.y];
    }
}

#pragma mark ------ CRMoreViewDelegate/CRQuestionViewDelegate ------
- (void)didselectImageView:(NSInteger)index {
    if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:selectMoreFunctionOfIndex:)]) {
        [self.delegate CRInputFunctionView:self selectMoreFunctionOfIndex:index];
    }
}

- (void)didSelectedQuestion:(NSString *)question {
    if (question && ![question isEqualToString:@""]) {
        self.TextViewInput.text = question;
        [self updatePlaceHoldAndSendBtnWithShow:self.TextViewInput.text.length > 0];
    } else {
        self.TextViewInput.text = @"";
        [self updatePlaceHoldAndSendBtnWithShow:self.TextViewInput.text.length > 0];
    }
    [self textViewDidChange:self.TextViewInput];
}

#pragma mark ------ TextViewDelegate 输入框代理 ------

- (void)textViewDidBeginEditing:(UITextView *)textView {
    placeHold.hidden = self.TextViewInput.text.length > 0;
}

- (void)textViewDidChange:(UITextView *)textView {
    //V5Log(@"[textViewDidChange]");
    [self updatePlaceHoldAndSendBtnWithShow:textView.text.length>0];
    
    // 多行文本输入动态改变底部高度
    CGSize InSize = CGSizeMake(CGRectGetWidth(textView.frame), 104.0);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = textView.textContainer.lineBreakMode;
    NSDictionary *dic = @{NSFontAttributeName:textView.font, NSParagraphStyleAttributeName:[paragraphStyle copy]};
    
    CGSize size =  [textView.text boundingRectWithSize:InSize
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:dic
                                               context:nil].size;
    size.height += 2*InputTextViewInnerPadding;
    if (size.height < INPUT_BTN_H) {
        size.height = INPUT_BTN_H;
    }
    //V5Log(@"[textViewDidChange] size.height:%f", size.height);
    if (size.height > textView.frame.size.height || size.height < textView.frame.size.height) {
        //加入动态计算高度
        CGRect frame = textView.frame;
        CGFloat heightChange = size.height - frame.size.height;
        frame.size.height = size.height;
        textView.frame = frame;
        
        //V5Log(@"textView.frame:%f", textView.frame.size.height);
        //调整parentView的frame并通知ChatViewController
        frame = self.frame;
        CGFloat bottomHeight = 0;
        if (self.activeView) {
            bottomHeight = self.activeView.frame.size.height;
        }
        frame.size.height = 2*InputVerticalPadding + textView.frame.size.height + bottomHeight;
        frame.origin.y = self.frame.origin.y - heightChange;
        // 更新发送按钮frame
        self.frame = frame;
        frame = self.btnSendMessage.frame;
        frame.origin.y = self.frame.size.height - bottomHeight - InputVerticalPadding - frame.size.height;
        self.btnSendMessage.frame = frame;
        // 更新语音键盘切换按钮frame
        frame = self.btnChangeVoiceState.frame;
        frame.origin.y = self.frame.size.height - bottomHeight - InputVerticalPadding - frame.size.height;
        self.btnChangeVoiceState.frame = frame;
        // 更新底部功能栏frame
        if (self.activeView) {
            frame = self.activeView.frame;
            frame.origin.y = frame.origin.y + heightChange;
            self.activeView.frame = frame;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:willChangeOriginY:)]) {
            [self.delegate CRInputFunctionView:self
                              willChangeOriginY:self.frame.origin.y];
        }
    }
}

/**
 *  输入框停止输入
 *
 *  @param textView 输入框UITextView
 */
- (void)textViewDidEndEditing:(UITextView *)textView {
    [self updatePlaceHoldAndSendBtnWithShow:self.TextViewInput.text.length>0];

}

//- (void)changeSendBtnWithShow:(BOOL)isMoreView {
//    self.isAbleToSendTextMessage = !isMoreView;
//    [self.btnSendMessage setTitle:isMoreView?@"":V5LocalStr(@"v5_send", @"发送") forState:UIControlStateNormal];
//    self.btnSendMessage.frame = RECT_CHANGE_width(self.btnSendMessage, isMoreView?35:40);
//    UIImage *image = [UIImage imageNamed:isMoreView?IMGFILE(@"v5_icon_add_normal"):IMGFILE(@"v5_chat_send_bg")];
//    [self.btnSendMessage setBackgroundImage:image forState:UIControlStateNormal];
//}

- (void)updatePlaceHoldAndSendBtnWithShow:(BOOL)sendWillShow {
    placeHold.hidden = sendWillShow;
    self.isAbleToSendTextMessage = sendWillShow;
    [self.btnSendMessage setTitle:sendWillShow?V5LocalStr(@"v5_send", @"发送"):@"" forState:UIControlStateNormal];
    self.btnSendMessage.frame = RECT_CHANGE_width(self.btnSendMessage, sendWillShow?40:35);
    UIImage *image = [UIImage imageNamed:sendWillShow?IMGFILE(@"v5_chat_send_bg"):IMGFILE(@"v5_icon_add_normal")];
    [self.btnSendMessage setBackgroundImage:image forState:UIControlStateNormal];
}

#pragma mark ------ 处理通知 ------

- (void)keyboardChange:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    [self.superVC.view layoutIfNeeded];
    
    // adjust position by ViewController's edgesForExtendedLayout
    CGFloat navbarOffset = self.superVC.view.frame.origin.y;
    //V5Log(@"[keyboardChange] %@ navbarOffset:%f", notification.name, navbarOffset);
    //V5Log(@"view.bounds:%@ table.frame:%@", NSStringFromCGRect(self.superVC.view.bounds), NSStringFromCGRect(((V5ChatViewController *)self.superVC).chatTableView.frame));
    if (notification.name == UIKeyboardWillShowNotification) {
        keyBoardShow = YES;
        // adjust CRInputFunctionView's originPoint
        CGRect newFrame = self.frame;
        newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height - navbarOffset;
        self.frame = newFrame;
        
        [self showBottomViewType:BottomTypeNone withParams:nil animated:NO];
    } else if (notification.name == UIKeyboardWillHideNotification) {
        keyBoardShow = NO;
        // adjust CRInputFunctionView's originPoint
        CGRect newFrame = self.frame;
        newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height - navbarOffset;
        self.frame = newFrame;
        // 结束输入
        [self updatePlaceHoldAndSendBtnWithShow:self.TextViewInput.text.length>0];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:willChangeOriginY:)]) {
            [self.delegate CRInputFunctionView:self willChangeOriginY:self.frame.origin.y];
        }
    }
//    else if (notification.name == UIKeyboardDidHideNotification) {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:willChangeOriginY:)]) {
//            [self.delegate CRInputFunctionView:self willChangeOriginY:self.frame.origin.y];
//        }
//    } else if (notification.name == UIKeyboardDidShowNotification) {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:willChangeOriginY:)]) {
//            [self.delegate CRInputFunctionView:self willChangeOriginY:self.frame.origin.y];
//        }
//    }
    
    [UIView commitAnimations];
}

#pragma mark - Add Picture
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (buttonIndex == 0) {
//        [self addCarema];
//    } else if (buttonIndex == 1){
//        [self openPicLibrary];
//    }
//}
//
//-(void)addCarema {
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//        picker.delegate = self;
//        picker.allowsEditing = YES;
//        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//        [self.superVC presentViewController:picker animated:YES completion:^{}];
//    } else {
//        // 如果没有提示用户
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"您的设备没有相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [alert show];
//    }
//}
//
//-(void)openPicLibrary {
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
//        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//        picker.delegate = self;
//        picker.allowsEditing = YES;
//        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        [self.superVC presentViewController:picker animated:YES completion:^{
//        }];
//    }
//}
//
//
//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    UIImage *editImage = [info objectForKey:UIImagePickerControllerEditedImage];
//    [self.superVC dismissViewControllerAnimated:YES completion:^{
//        [self.delegate CRInputFunctionView:self sendPicture:editImage];
//    }];
//}
//
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    [self.superVC dismissViewControllerAnimated:YES completion:nil];
//}
//
//-(void)dealloc{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

#pragma mark - V5RecorderDelegate

- (void)beginConvert
{
    // 录音开始转换为amr
    
}

// 回调录音资料(voicePath为wav文件路径)
- (void)endConvertWithPath:(NSString *)voicePath {
    V5VoiceMessage *voiceMsg = [[V5VoiceMessage alloc] initWithLocalURL:voicePath
                                                                 format:@"amr"];
    voiceMsg.voiceLength = [V5Util getVoiceDurationOnPath:voicePath];
    if (self.delegate && [self.delegate respondsToSelector:@selector(CRInputFunctionView:sendVoiceMessage:)]) {
        [self.delegate CRInputFunctionView:self sendVoiceMessage:voiceMsg];
    }
    [CRProgressHUD dismissWithSuccess:V5LocalStr(@"v5_success", @"成功")];
    
    //缓冲消失时间 (最好有block回调消失完成)
    self.btnVoiceRecord.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnVoiceRecord.enabled = YES;
    });
}

- (void)failRecordWithReason:(KV5VoiceRecordFailedReason)reason {
    if (reason == VoiceRecordFailedReason_TooShort) {
        [CRProgressHUD dismissWithSuccess:V5LocalStr(@"v5_too_short", @"太短")];
    } else {
        [CRProgressHUD dismissWithSuccess:V5LocalStr(@"v5_convert_failed", @"转换失败")];
    }
    
    //缓冲消失时间 (最好有block回调消失完成)
    self.btnVoiceRecord.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnVoiceRecord.enabled = YES;
    });
}


#pragma mark - 录音touch事件

- (void)beginRecordVoice:(UIButton *)button {
    long long voiceId = [[NSDate date] timeIntervalSince1970] * 1000; // 暂时以时间戳座位语音文件名，上传后替换为URL的MD5
    [voiceRecorder startRecordWithFile:[NSString stringWithFormat:@"%lld", voiceId]];
    playTime = 0;
    playTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countVoiceTime) userInfo:nil repeats:YES];
    [CRProgressHUD show];
}

- (void)endRecordVoice:(UIButton *)button {
    if (playTimer) {
        [voiceRecorder stopRecord];
        [playTimer invalidate];
        playTimer = nil;
    }
}

- (void)cancelRecordVoice:(UIButton *)button {
    if (playTimer) {
        [voiceRecorder cancelRecord];
        [playTimer invalidate];
        playTimer = nil;
    }
    [CRProgressHUD dismissWithError:V5LocalStr(@"v5_cancel", @"取消")];
}

- (void)RemindDragExit:(UIButton *)button {
    [CRProgressHUD changeSubTitle:V5LocalStr(@"v5_release_to_cancel", @"松开取消")];
}

- (void)RemindDragEnter:(UIButton *)button {
    [CRProgressHUD changeSubTitle:V5LocalStr(@"v5_slideup_to_cancel", @"上滑取消")];
}

- (void)countVoiceTime {
    playTime ++;
    if (playTime>=60) {
        [self endRecordVoice:nil];
    }
}

#pragma mark ------ bottomView显示隐藏 ------

/**
 *  更新底显示状态
 *
 *  @param state CRInputBarState
 */
- (void)updateFrameOnState:(CRInputBarState)state {
    switch (state) {
        case CRInputBarState_TextInput:
            self.btnVoiceRecord.hidden = YES;
            self.TextViewInput.hidden  = NO;
            [self.btnChangeVoiceState setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_voice_normal")] forState:UIControlStateNormal];
            isbeginVoiceRecord = NO;
            [self.TextViewInput becomeFirstResponder];
            // 如果有文字，更新内容
            if (self.TextViewInput.text.length > 0) {
                [self updatePlaceHoldAndSendBtnWithShow:YES];
                [self textViewDidChange:self.TextViewInput];
            }
            break;
            
        case CRInputBarState_VoiceRecord:
            self.btnVoiceRecord.hidden = NO;
            self.TextViewInput.hidden  = YES;
            // TextView取消焦点
            [self.TextViewInput resignFirstResponder];
            // 收起bottomView
            [self showBottomViewType:BottomTypeNone withParams:nil];
            [self.btnChangeVoiceState setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_softkeyboard_normal")] forState:UIControlStateNormal];
            isbeginVoiceRecord = YES;
            // 改变＋按钮
            self.isAbleToSendTextMessage = NO;
            [self.btnSendMessage setTitle:@"" forState:UIControlStateNormal];
            [self.btnSendMessage setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_add_normal")]
                                           forState:UIControlStateNormal];
            self.frame = CGRectMake(0, self.superVC.view.frame.size.height - INPUT_BAR_H, Main_Screen_Width, INPUT_BAR_H);
            self.btnChangeVoiceState.frame = CGRectMake(InputHorizontalPadding,
                                                        InputVerticalPadding,
                                                        INPUT_BTN_H,
                                                        INPUT_BTN_H);
            self.btnSendMessage.frame = CGRectMake(Main_Screen_Width-45,
                                                   InputVerticalPadding,
                                                   INPUT_BTN_H,
                                                   INPUT_BTN_H);
            break;
            
        case CRInputBarState_MoreFunc:
            [self updatePlaceHoldAndSendBtnWithShow:NO];
            if (ENABLE_VOICE_SEND && enableRecord) {
                if (!self.btnVoiceRecord.hidden || isbeginVoiceRecord == YES) {
                    [self.btnChangeVoiceState setBackgroundImage:[UIImage imageNamed:IMGFILE(@"v5_icon_voice_normal")] forState:UIControlStateNormal];
                    self.btnVoiceRecord.hidden = YES;
                    self.TextViewInput.hidden  = NO;
                    isbeginVoiceRecord = NO;
                }
            }
            [self.TextViewInput resignFirstResponder];
//            V5Log(@"self.bottomShowType:%ld", (long)self.bottomShowType);
            if (self.bottomShowType != BottomTypeMore) {
                //显示moreView
                if (keyBoardShow || self.bottomShowType != BottomTypeNone) {
                    [self showBottomViewType:BottomTypeMore withParams:nil animated:NO];
                } else {
                    [self showBottomViewType:BottomTypeMore withParams:nil animated:YES];
                }
            } else {
                //收起bottomView
                [self showBottomViewType:BottomTypeNone withParams:nil];
            }
            break;
    }
}

/**
 *  显示bottomView
 *
 *  @param viewType bottomView类型
 *  @param params   携带参数,imageArray\questionArray等参数
 */
- (void)showBottomViewType:(CRBottomViewType)viewType withParams:(id)params {
    [self showBottomViewType:viewType withParams:params animated:YES];
}

- (void)showBottomViewType:(CRBottomViewType)viewType withParams:(id)params animated:(BOOL)animated {
    V5Log(@"showBottomViewType:%ld", (long)viewType);
    NSString *title = V5LocalStr(@"v5_relative_question:", @"相关问题:");
    switch (viewType) {
        case BottomTypeNone:
            if (animated) {
                [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
                [UIView setAnimationDuration:KEYBAR_ANIM_DURATION];
            }
            [self willShowBottomView:nil];
            if (animated) {
                [UIView commitAnimations];
            }
            break;
            
        case BottomTypeHotQuestion:
            title = V5LocalStr(@"v5_hot_question:", @"常见问题:");
        case BottomTypeRelativeQuestion:
            [self.TextViewInput resignFirstResponder];
            //设置问题数据
            if (!self.questionView) {
                self.questionView = [[CRInputQuestionView alloc] initWithFrame:self.moreView.frame];
            }
            self.questionView.frame = self.moreView.frame;
            ((CRInputQuestionView *)self.questionView).delegate = self;
            [(CRInputQuestionView *)self.questionView setQuestionArray:params];
            ((CRInputQuestionView *)self.questionView).headLabel.text = title;
            self.questionView.backgroundColor = self.backgroundColor;
            [self willShowBottomView:self.questionView];
            break;
            
        case BottomTypeMore: {
            if (!self.moreView) {
                NSUInteger numEachRow = Main_Screen_Width / 8 > 72 ? 8 : 4;
                CGFloat imageWidth = (Main_Screen_Width - (InputMoreHPadding)*(numEachRow + 1))/numEachRow;
                CGFloat maxHeight = (InputMoreVPadding+imageWidth) * 2 + 30;
                self.moreView = [[CRInputMoreView alloc] initWithFrame:CGRectMake(0, INPUT_BAR_H, self.frame.size.width, maxHeight)];
                //self.moreView.backgroundColor = InputBGColor;
                [(CRInputMoreView *)self.moreView setDelegate:self];
                //self.moreView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
                //[(CRInputMoreView *)self.moreView setImageArray:self.imageArray nameArray:self.nameArray];
            }
            self.moreView.backgroundColor = self.backgroundColor;
            [(CRInputMoreView *)self.moreView setImageArray:self.imageArray nameArray:self.nameArray];
            [self.TextViewInput resignFirstResponder];
            CGRect moreFrame = self.moreView.frame;
            self.moreView.frame = CGRectZero;
            if (animated) {
                [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
                [UIView setAnimationDuration:KEYBAR_ANIM_DURATION];
            }
            self.moreView.frame = moreFrame;
            self.moreView.backgroundColor = self.backgroundColor;
            [self willShowBottomView:self.moreView];
            if (animated) {
                [UIView commitAnimations];
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  隐藏bottomView
 */
- (void)hideBottomView {
    V5Log(@"[hideBottomView]");
    [self showBottomViewType:BottomTypeNone withParams:nil animated:YES];
}

@end
