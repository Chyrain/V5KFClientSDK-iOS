//
//  UUMessageCell.m
//  UUChatDemoForTextVoicePicture
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 uyiuyao. All rights reserved.
//

#import "CRMessageCell.h"
#import "CRMessageFrame.h"
#import "V5ImageLoader.h"
#import "V5Macros.h"
#import "NSString+V5URL.h"
#import "V5MBProgressHUD.h"
#import "CRAVAudioPlayer.h"
#import "V5Util.h"
#import "V5VoiceConverter.h"
#import "V5ClientAgent.h"

@interface CRMessageCell () <CRAVAudioPlayerDelegate> {
    CRAVAudioPlayer *audio;
    BOOL contentVoiceIsPlaying;
    
    NSDictionary *selectedLinkDic;
}
@end

@implementation CRMessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 语音相关
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CRAVAudioPlayerDidFinishPlay) name:@"VoicePlayHasInterrupt" object:nil];
        // 红外线感应监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sensorStateChange:)
                                                     name:UIDeviceProximityStateDidChangeNotification
                                                   object:nil];
        contentVoiceIsPlaying = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VoicePlayHasInterrupt"  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification  object:nil];
}

/**
 *  单击消息气泡动作
 */
- (void)btnContentClick {
//    V5Log(@"单击气泡:%@", [self.messageFrame.message getDefaultContent]);
    KV5MessageType type = self.messageFrame.message.messageType;
    KV5MessageDir direction = self.messageFrame.message.direction;
    
    // play audio
    if (type == MessageType_Voice) {
        V5VoiceMessage *voiceMessage = (V5VoiceMessage *)self.messageFrame.message;
        if (voiceMessage.local_url) {
            if(!contentVoiceIsPlaying) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"VoicePlayHasInterrupt" object:nil];
                contentVoiceIsPlaying = YES;
                audio = [CRAVAudioPlayer sharedInstance];
                audio.delegate = self;
                //[audio playSongWithUrl:voiceURL];
//                V5Log(@"play voice ...%@", voiceMessage.local_url);
                if (![V5Util isFileExists:voiceMessage.local_url]) { // 不存在则转换
                    BOOL convertRst = [V5VoiceConverter ConvertAmrToWav:[V5Util getAMRVoicePath:voiceMessage]
                                                            wavSavePath:voiceMessage.local_url];
                    if (!convertRst) {
                        V5Log(@"VoiceConverter -> failed %@ to %@", [V5Util getAMRVoicePath:voiceMessage], voiceMessage.local_url);
                    } else {
                        [V5Util deleteFileWithPath:[V5Util getAMRVoicePath:voiceMessage]];
                    }
                }
                
                BOOL played = [audio playSongWithFilePath:voiceMessage.local_url];
                contentVoiceIsPlaying = played;
                if (!played) {
                    self.messageFrame.message.state = MessageSendStatus_Failure;
                    self.statusView.status = MessageSendStatus_Failure;
                }
            } else {
                [self CRAVAudioPlayerDidFinishPlay];
            }
        } else {
            V5Log(@"play voice ... songData nil");
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(cellDidClick:messageType:direction:)]) {
            [self.delegate cellDidClick:self messageType:type direction:direction];
        }
    }
    
//    // play audio
//    if (type == MessageType_Voice) {
//        if(!contentVoiceIsPlaying) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"VoicePlayHasInterrupt" object:nil];
//            contentVoiceIsPlaying = YES;
//            audio = [UUAVAudioPlayer sharedInstance];
//            audio.delegate = self;
//            //[audio playSongWithUrl:voiceURL];
//            [audio playSongWithData:songData];
//        } else {
//            [self UUAVAudioPlayerDidFinishPlay];
//        }
//    }
//    // show the picture
//    else if (type == MessageType_Image || type == MessageType_Location) {
//        if (self.btnContent.backImageView) {
//            [UUImageAvatarBrowser showImage:self.btnContent.backImageView];
//        }
//        if ([self.delegate isKindOfClass:[UIViewController class]]) {
//            [[(UIViewController *)self.delegate view] endEditing:YES];
//        }
//    }
}

/**
 *  长按消息气泡动作
 *
 *  @param recognizer 长按手势
 */
- (void)btnContentLongClick:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer && ((recognizer.view != self.btnContent) || (recognizer.state != UIGestureRecognizerStateBegan))) {
        return;
    }
//    V5Log(@"长按气泡:%@", [self.messageFrame.message getDefaultContent]);
    KV5MessageType type = self.messageFrame.message.messageType;
    KV5MessageDir direction = self.messageFrame.message.direction;
    if ([self.delegate respondsToSelector:@selector(cellDidLongClick:messageType:direction:)]) {
        [self.delegate cellDidLongClick:self messageType:type direction:direction];
    }

    switch (type) {
        case MessageType_Image: {
            // show text and gonna copy that
            [self becomeFirstResponder];
            UIMenuController *menu = [UIMenuController sharedMenuController];
            UIMenuItem *saveItem = [[UIMenuItem alloc] initWithTitle:V5LocalStr(@"v5_save", @"保存") action:@selector(menuSave:)];
            [menu setMenuItems:[NSArray arrayWithObjects:saveItem, nil]];
            [menu setTargetRect:self.btnContent.frame inView:self];
            [menu setMenuVisible:YES animated:YES];
            break;
        }
            
        case MessageType_Text: {
            // show text and gonna copy that
            [self becomeFirstResponder];
            UIMenuController *menu = [UIMenuController sharedMenuController];
            UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:V5LocalStr(@"v5_copy", @"复制") action:@selector(menuCopy:)];
            [menu setMenuItems:[NSArray arrayWithObjects:copyItem, nil]];
            [menu setTargetRect:self.btnContent.frame inView:self];
            [menu setMenuVisible:YES animated:YES];
            break;
        }
        default:
            break;
    }
}

/**
 *  成为第一响应者
 *
 *  @return 是否
 */
- (BOOL)canBecomeFirstResponder {
    return YES;
}

/**
 *  MenuItem显示过滤
 *
 *  @param action 可执行的动作
 *  @param sender 动作发起者
 *
 *  @return 是否可执行此动作
 */
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(menuCopy:) || (action == @selector(menuSave:))) {
        return YES;
    }
    return NO;
}

/**
 *  复制
 *
 *  @param sender sender description
 */
- (void)menuCopy:(id)sender {
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = [self.messageFrame.message getDefaultContent];
}

/**
 *  保存图片
 *
 *  @param sender sender description
 */
- (void)menuSave:(id)sender {
    UIImageWriteToSavedPhotosAlbum(self.btnContent.backImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

/**
 *  保存图片回调
 *
 *  @param image 图片
 *  @param error 错误
 *  @param info  附加信息
 */
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)info {
    NSString *tips = nil;
    if (error) {
        tips = V5LocalStr(@"v5_picture_save_failure", @"保存图片失败");
    } else {
        tips = V5LocalStr(@"v5_picture_save_success", @"保存图片成功");
    }
    [self showToast:tips];
}

/**
 *  显示提示信息
 *
 *  @param str 提示内容
 */
- (void)showToast:(NSString *)str {
    __block V5MBProgressHUD *hud = [[V5MBProgressHUD alloc] initWithView:self];
    [self addSubview:hud];
    hud.labelText = str;
    hud.mode = V5MBProgressHUDModeText;
    //    hud.yOffset = 100.0f;
    [hud showAnimated:YES whileExecutingBlock:^{
        sleep(1);
    } completionBlock:^{
        [hud removeFromSuperview];
        hud = nil;
    }];
}

#pragma mark - 语音

- (void)CRAVAudioPlayerBeiginLoadVoice {
    [self.btnContent benginLoadVoice];
}

- (void)CRAVAudioPlayerBeiginPlay {
    // 开启红外线感应
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [self.btnContent startPlay];
}

- (void)CRAVAudioPlayerDidFinishPlay {
    // 关闭红外线感应
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    contentVoiceIsPlaying = NO;
    [self.btnContent stopPlay];
    [[CRAVAudioPlayer sharedInstance] stopSound];
}

#pragma mark ------- 设置各块内容 ------
/**
 *  加载时间标签
 */
- (void)loadLabelTime {
    if (!self.labelTime) { // 创建内容
        self.labelTime = [[UILabel alloc] init];
        self.labelTime.textAlignment = NSTextAlignmentCenter;
        self.labelTime.textColor = [UIColor grayColor];
        self.labelTime.font = ChatTimeFont;
    }
    [self.contentView addSubview:self.labelTime];
    
    //重新计算frame
    CGFloat timeY = ChatMargin;
    CGRect timeRect = [self.messageFrame.strTime boundingRectWithSize:CGSizeMake(300, 100) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : ChatTimeFont} context:nil];
    
    CGFloat timeX = (Main_Screen_Width - timeRect.size.width) / 2;
    self.messageFrame.timeF = CGRectMake(timeX,
                                         timeY,
                                         timeRect.size.width + ChatTimeMarginW,
                                         timeRect.size.height + ChatTimeMarginH);
    
    self.labelTime.text = self.messageFrame.strTime;
    self.labelTime.frame = self.messageFrame.timeF;
}

- (void)loadAvatarImage {
    if (!self.messageFrame.showAvatar) {
        return;
    }
    
    if (!self.avatarImage) { // 创建内容
        self.avatarImage = [[UIImageView alloc] init];
        self.avatarImage.layer.cornerRadius = self.messageFrame.avatarRadius;
        self.avatarImage.layer.masksToBounds = YES;
    }
    UIImage *placeholder = nil;
    NSString *avatarURL = nil;
    switch (self.messageFrame.message.direction) {
        case MessageDir_ToWorker:
            placeholder = [UIImage imageNamed:IMGFILE(@"v5_avatar_customer")];
            avatarURL = [V5ClientAgent shareClient].config.avatar;
            break;
        case MessageDir_Comment: // 文本类型评价消息
        case MessageDir_FromRobot:
            placeholder = [UIImage imageNamed:IMGFILE(@"v5_avatar_robot")];
            break;
        case MessageDir_ToCustomer: {
            placeholder = [UIImage imageNamed:IMGFILE(@"v5_avatar_worker")];
            // 读取本地photo
            NSString *key = [NSString stringWithFormat:@"v5photo_%lld", self.messageFrame.message.wId];
            avatarURL = [V5Util readPreferencesValueWithKey:key];
        }
            break;
            
        default:
            placeholder = [UIImage imageNamed:IMGFILE(@"v5_avatar_robot")];
            break;
    }
    [V5ImageLoader setImageView:self.avatarImage
                        withURL:avatarURL
               placeholderImage:placeholder
                   failureImage:nil];
    
    self.avatarImage.frame = self.messageFrame.avatarF;
    [self.contentView addSubview:self.avatarImage];
}

/**
 *  加载聊天气泡(文本、图片、位置)
 */
- (void)loadBubbleContent {
    // 加载头像
    [self loadAvatarImage];
    
    V5Message *message = self.messageFrame.message;
    
    if (!self.btnContent) { // 创建内容
        self.btnContent = [CRMessageContentButton buttonWithType:UIButtonTypeCustom];
        [self.btnContent setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.btnContent.titleLabel.font = ChatContentFont;
        self.btnContent.titleLabel.numberOfLines = 0;
        [self.btnContent addTarget:self action:@selector(btnContentClick) forControlEvents:UIControlEventTouchUpInside];
        __block CRMessageCell *cellSelf = self;
        self.btnContent.richLabel.linkTapHandler = ^(V5KZLinkType linkType, NSString *string) {
            if (linkType == V5KZLinkTypeNone) {
                // btnContent单击事件
                [cellSelf btnContentClick];
            } else if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidClick:cellSelf linkType:linkType link:string];
            }
        };
        self.btnContent.richLabel.linkLongPressHandler = ^(V5KZLinkType linkType, NSString *string) {
            if (linkType == V5KZLinkTypeNone) {
                // btnContent长按事件
                [cellSelf btnContentLongClick:nil];
            } else if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidLongClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidLongClick:cellSelf linkType:linkType link:string];
            }
        };
        [self.btnContent addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(btnContentLongClick:)]];
        
        // 创建消息状态指示器(发送状态)
        self.statusView = [[CRStatusView alloc] init];
        self.statusView.resendClick = ^(void) {
            if ([cellSelf.delegate respondsToSelector:@selector(resendDidClick:)]) {
                [cellSelf.delegate resendDidClick:cellSelf];
            }
        };
    }
    [self.contentView addSubview:self.btnContent];
    [self.contentView addSubview:self.statusView];
    
    // 重置内容
    [self.btnContent setTitle:@"" forState:UIControlStateNormal];
    self.btnContent.richLabel.hidden = YES;
    self.btnContent.voiceBackView.hidden = YES;
    self.btnContent.backImageView.hidden = YES;
    if (message.direction == MessageDir_ToWorker) {
        self.statusView.hidden = NO;
    } else {
        self.statusView.hidden = YES;
    }
    //    V5Log(@"%@ status:%ld", [messageFrame.v5message getDefaultContent], (long)messageFrame.v5message.state);
    //    self.btnContent.frame = messageFrame.contentF;
    
    // 设置内容
    CGFloat leftPadding = 0;
    // 背景气泡图
    UIImage *normal;
    UIImage *highlight;
    
    if (message.direction == MessageDir_ToWorker) {
        self.btnContent.isMyMessage = YES;
        self.btnContent.richLabel.textColor = ChatToTextColor;
        [self.btnContent setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.btnContent.contentEdgeInsets = UIEdgeInsetsMake(ChatContentTop, ChatContentRight, ChatContentBottom, ChatContentLeft);
        leftPadding = ChatContentRight;
        
        normal = [UIImage imageNamed:IMGFILE(@"v5_chatto_nbg")];
        normal = [normal resizableImageWithCapInsets:UIEdgeInsetsMake(30, 15, 15, 22)]; // 35,10,10,22
        highlight = [UIImage imageNamed:IMGFILE(@"v5_chatto_pbg")];
        highlight = [highlight resizableImageWithCapInsets:UIEdgeInsetsMake(30, 15, 15, 22)]; //35,10,10,22
    } else {
        self.btnContent.isMyMessage = NO;
        [self.btnContent setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.btnContent.contentEdgeInsets = UIEdgeInsetsMake(ChatContentTop, ChatContentLeft, ChatContentBottom, ChatContentRight);
        leftPadding = ChatContentLeft;
        if (message.direction == MessageDir_ToCustomer) {
            self.btnContent.richLabel.textColor = ChatFromWorkerTextColor;
            normal = [UIImage imageNamed:IMGFILE(@"v5_chatfrom_worker_nbg")];
            highlight = [UIImage imageNamed:IMGFILE(@"v5_chatfrom_worker_pbg")];
        } else {
            self.btnContent.richLabel.textColor = ChatFromRobotTextColor;
            normal = [UIImage imageNamed:IMGFILE(@"v5_chatfrom_robot_nbg")];
            highlight = [UIImage imageNamed:IMGFILE(@"v5_chatfrom_robot_pbg")];
        }
        normal = [normal resizableImageWithCapInsets:UIEdgeInsetsMake(30, 22, 15, 15)]; // 35,22,10,10
        highlight = [highlight resizableImageWithCapInsets:UIEdgeInsetsMake(30, 22, 15, 15)]; //35.22.10.10
    }
    
    [self.btnContent setBackgroundImage:normal forState:UIControlStateNormal];
    [self.btnContent setBackgroundImage:highlight forState:UIControlStateHighlighted];
    
    switch (message.messageType) {
        case MessageType_Image: {
            self.btnContent.frame = self.messageFrame.contentF;
            self.statusView.frame = self.messageFrame.statusF;
            self.statusView.status = self.messageFrame.message.state;
            
            self.btnContent.backImageView.hidden = NO;
            if ([(V5ImageMessage *)message image]) {
                self.btnContent.backImageView.image = [(V5ImageMessage *)message image];
            } else {
                NSString *picUrl = [V5Util getThumbnailURLOfImage:(V5ImageMessage *)message];
                [V5ImageLoader setImageView:self.btnContent.backImageView
                                    withURL:picUrl
                           placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
                               failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]];
            }
            
            self.btnContent.backImageView.frame = CGRectMake(0, 0, self.btnContent.frame.size.width, self.btnContent.frame.size.height);
            
            [self makeMaskView:self.btnContent.backImageView withImage:normal];
        }
            break;
            
        case MessageType_Location: {
            self.btnContent.frame = self.messageFrame.contentF;
            self.statusView.frame = self.messageFrame.statusF;
            self.statusView.status = self.messageFrame.message.state;
            
            self.btnContent.backImageView.hidden = NO;
            V5LocationMessage *locationMessage = (V5LocationMessage *)message;
            NSString *mapUrl = [NSString stringWithFormat:MAP_PIC_URL_FORMAT, locationMessage.x, locationMessage.y, locationMessage.x, locationMessage.y];
//            V5Log(@"位置：%@", [mapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
            [V5ImageLoader setImageView:self.btnContent.backImageView
                                withURL:[mapUrl URLEncodedString]
                       placeholderImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_loading")]
                           failureImage:[UIImage imageNamed:IMGFILE(@"v5_chat_image_failure")]];
            
            self.btnContent.backImageView.frame = CGRectMake(0, 0, self.btnContent.frame.size.width, self.btnContent.frame.size.height);
            [self makeMaskView:self.btnContent.backImageView withImage:normal];
        }
            break;
            
        case MessageType_Voice: {
            self.btnContent.frame = self.messageFrame.contentF;
            self.statusView.frame = self.messageFrame.statusF;
            self.statusView.status = MessageSendStatus_Unknown;//self.messageFrame.message.state; //[修改]发送语音中不显示status
            
            V5VoiceMessage *voiceMessage = (V5VoiceMessage *)self.messageFrame.message;
            self.btnContent.voiceBackView.hidden = NO;
            self.btnContent.second.text = [NSString stringWithFormat:@"%.0f″", voiceMessage.voiceLength];
            if (voiceMessage.voiceLength < 1.0 && voiceMessage.voiceLength > 0.1) {
                self.btnContent.second.text = @"1″";
            }
            if (voiceMessage.url && ![V5Util isVoiceMessageExists:voiceMessage] && !self.messageFrame.isDownloadingMessage) {
                self.messageFrame.isDownloadingMessage = YES;
                [self.btnContent benginLoadVoice];
                [V5Util downloadVoiceWithOption:nil
                                        withURL:voiceMessage.url
                                   voiceMessage:voiceMessage
                                downloadSuccess:^(id responseObject)
                 {
//                     V5Log(@"download voice success!!! nsdata:%@", [responseObject description]);
                     // 下载成功
                     voiceMessage.state = MessageSendStatus_Arrived;
                     self.statusView.status = MessageSendStatus_Arrived;
                     voiceMessage.local_url = [V5Util getWAVVoicePath:voiceMessage];
                     // 转换语音格式
                     BOOL convertRst = [V5VoiceConverter ConvertAmrToWav:[V5Util getAMRVoicePath:voiceMessage]
                                                           wavSavePath:voiceMessage.local_url];
                     if (!convertRst) {
//                         V5Log(@"VoiceConverter -> failed %@ to %@", [V5Util getAMRVoicePath:voiceMessage], voiceMessage.local_url);
                     } else {
                         [V5Util deleteFileWithPath:[V5Util getAMRVoicePath:voiceMessage]];
                     }
                     // 获得语音播放时间
                     voiceMessage.voiceLength = [V5Util getVoiceDurationOnPath:voiceMessage.local_url];
                     self.btnContent.second.text = [NSString stringWithFormat:@"%.0f″", voiceMessage.voiceLength];
                     if (voiceMessage.voiceLength < 1.0 && voiceMessage.voiceLength > 0.1) {
                         self.btnContent.second.text = @"1″";
                     }
                     [self.btnContent didLoadVoice];
                     self.messageFrame.isDownloadingMessage = NO;
                 } downloadFailure:^(NSError *error) {
                     // 下载失败
                     if (self.messageFrame.imageRetryCounter < 5) { // 重试5次以内
                         self.messageFrame.imageRetryCounter++;
                         double delayInSeconds = 1.0;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                             V5Log(@"download voice retry:%lu 需要重试Url:%@", (unsigned long)self.messageFrame.imageRetryCounter, voiceMessage.url);
                             if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidMediaLoadFailed:willRetry:)]) {
                                 [self.delegate cellDidMediaLoadFailed:self willRetry:YES];
                             }
                         });
                     } else { // 加载失败
//                         V5Log(@"download voice failure!!!");
                         voiceMessage.state = MessageSendStatus_Failure;
                         self.statusView.status = MessageSendStatus_Failure;
                         [self.btnContent didLoadVoiceFailed];
                         self.messageFrame.isDownloadingMessage = NO;
                         if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidMediaLoadFailed:willRetry:)]) {
                             [self.delegate cellDidMediaLoadFailed:self willRetry:NO];
                         }
                     }
                 } progress:nil];
            }
        }
            break;
            
        case MessageType_Text:
        default: {
            self.btnContent.richLabel.hidden = NO;
            // 内容字符串特殊格式处理
            NSString *emojiString = [message getDefaultContent];
            // [message.strContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
            UIFont *font = ChatContentFont; //[UIFont systemFontOfSize:16];
            NSDictionary *attributes = @{NSFontAttributeName: font};
            
            NSAttributedString *attributedString = [NSAttributedString emotionAttributedStringFrom:emojiString attributes:attributes];
            self.btnContent.richLabel.attributedText = attributedString;
            CGRect attributeRect = [self.btnContent.richLabel.V5KZAttributedString boundsWithSize:CGSizeMake(ChatContentW - (self.messageFrame.showAvatar ? ChatIconWH : 0), CGFLOAT_MAX)];
//            V5Log(@"宽度：%f 高度：%f %@", attributeRect.size.width, attributeRect.size.height, attributedString.string);
            self.btnContent.richLabel.frame = CGRectMake(leftPadding,
                                                         ChatContentTop,
                                                         attributeRect.size.width,
                                                         attributeRect.size.height);
            [self.btnContent.richLabel sizeToFit];
            CGFloat contentW = self.btnContent.richLabel.frame.size.width + ChatContentLeft + ChatContentRight;
            CGFloat contentH = self.btnContent.richLabel.frame.size.height + ChatContentTop + ChatContentBottom;
            CGFloat contentX = 0; // self.messageFrame.contentF
            
            if (message.direction == MessageDir_ToWorker) {
                contentX = Main_Screen_Width - ChatMargin - contentW - (self.messageFrame.showAvatar ? ChatIconWH + AvatarMargin : 0);
            } else {
                contentX = ChatMargin + (self.messageFrame.showAvatar ? ChatIconWH + AvatarMargin : 0);
            }
            CGFloat contentY = CGRectGetMaxY(self.messageFrame.timeF) + ChatMargin;
            self.btnContent.frame = CGRectMake(contentX,
                                               contentY,
                                               contentW,
                                               contentH);
            self.statusView.frame = CGRectMake(contentX - ChatStatusWH - 5,
                                               contentY + (self.btnContent.frame.size.height - ChatStatusWH)/ 2,
                                               ChatStatusWH,
                                               ChatStatusWH);
            self.messageFrame.cellHeight = CGRectGetMaxY(self.btnContent.frame) + ChatMargin;
            self.statusView.status = self.messageFrame.message.state;
        };
            break;
    }
}

/**
 *  加载单图文View
 */
- (void)loadSingleArticle {
    V5Article *article = [[(V5ArticlesMessage *)self.messageFrame.message articles] objectAtIndex:0];
    if (!self.singleArticle) { // 创建单图文view
        CGRect contentFrame = CGRectMake((Main_Screen_Width - ArticleContentW)/2,
                                         self.messageFrame.showTime ? self.messageFrame.contentF.origin.y : ChatMargin,
                                         ArticleContentW,
                                         ArticleContentH);
        self.singleArticle = [[CRSingleArticleView alloc] initWithFrame:contentFrame];
        __block CRMessageCell *cellSelf = self;
        self.singleArticle.articleClickHandler = ^(NSString *url) {
            if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidClick:cellSelf linkType:V5KZLinkTypeArticleURL link:url];
            }
        };
        self.singleArticle.articleLongClickHandler = ^(NSString *url) {
            if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidLongClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidLongClick:cellSelf linkType:V5KZLinkTypeArticleURL link:url];
            }
        };
    } else {
        CGRect contentFrame = CGRectMake((Main_Screen_Width - ArticleContentW)/2,
                                         self.messageFrame.showTime ? self.messageFrame.contentF.origin.y : ChatMargin,
                                         ArticleContentW,
                                         ArticleContentH);
        self.singleArticle.frame = contentFrame;
    }
    [self.contentView addSubview:self.singleArticle];
    
    [self.singleArticle contentWithArticle:article];
    self.messageFrame.cellHeight = CGRectGetMaxY(self.singleArticle.frame) + ChatMargin;
}

/**
 *  加载多图文View
 */
- (void)loadMultiArticles {
    NSArray<V5Article *> *articles = [(V5ArticlesMessage *)self.messageFrame.message articles];
    if (!self.multiArticles) { // 创建多图文view
        CGRect contentFrame = CGRectMake((Main_Screen_Width - ArticleContentW)/2,
                                         self.messageFrame.showTime ? self.messageFrame.contentF.origin.y : ChatMargin,
                                         ArticleContentW,
                                         ArticleContentH);
        self.multiArticles = [[CRMultiArticleView alloc] initWithFrame:contentFrame];
        __block CRMessageCell *cellSelf = self;
        self.multiArticles.articleClickHandler = ^(NSString *url) {
            if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidClick:cellSelf linkType:V5KZLinkTypeArticleURL link:url];
            }
        };
        self.multiArticles.articleLongClickHandler = ^(NSString *url) {
            if ([cellSelf.delegate respondsToSelector:@selector(cellLinkDidLongClick:linkType:link:)]) {
                [cellSelf.delegate cellLinkDidLongClick:cellSelf linkType:V5KZLinkTypeArticleURL link:url];
            }
        };
    } else {
        CGRect contentFrame = CGRectMake((Main_Screen_Width - ArticleContentW)/2,
                                         self.messageFrame.showTime ? self.messageFrame.contentF.origin.y : ChatMargin,
                                         ArticleContentW,
                                         ArticleContentH);
        self.multiArticles.frame = contentFrame;
    }
    [self.contentView addSubview:self.multiArticles];
    
    [self.multiArticles contentWithArticles:articles];
    self.messageFrame.cellHeight = CGRectGetMaxY(self.multiArticles.frame) + ChatMargin;
}

/**
 *  清空MessageCell
 */
- (void)resetMessageCell {
    if (self.labelTime) {
        [self.labelTime removeFromSuperview];
    }
    if (self.avatarImage) {
        [self.avatarImage removeFromSuperview];
    }
    if (self.btnContent) {
        [self.btnContent removeFromSuperview];
    }
    if (self.statusView) {
        [self.statusView removeFromSuperview];
    }
    if (self.singleArticle) {
        [self.singleArticle removeFromSuperview];
    }
    if (self.multiArticles) {
        [self.multiArticles removeFromSuperview];
    }
}

//内容及Frame设置
- (void)setMessageFrame:(CRMessageFrame *)messageFrame {

    _messageFrame = messageFrame;
    V5Message *message = messageFrame.message;
    
    [self resetMessageCell];
    
    // 1、设置时间
    if (messageFrame.showTime) {
        [self loadLabelTime];
    }

    // 2、设置内容
    switch (message.messageType) {
        case MessageType_Articles:
            // 单、多图文显示
            if ([[(V5ArticlesMessage *)message articles] count] == 1) {
                [self loadSingleArticle];
            } else if ([[(V5ArticlesMessage *)message articles] count] > 1) {
                [self loadMultiArticles];
            }
            break;
            
        case MessageType_Text:
        case MessageType_Location:
        case MessageType_Image:
        case MessageType_Voice:
        default:
            // 文本气泡，以及图片位置显示
            [self loadBubbleContent];
            break;
    }
    
    
}

- (void)makeMaskView:(UIView *)view withImage:(UIImage *)image {
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(view.frame, 0.0f, 0.0f);
    view.layer.mask = imageViewMask.layer;
}

// 处理监听触发事件
-(void)sensorStateChange:(NSNotificationCenter *)notification {
    if ([[UIDevice currentDevice] proximityState] == YES){
//        V5Log(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    else{
//        V5Log(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

@end



