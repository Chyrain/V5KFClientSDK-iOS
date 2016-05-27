//
//  UUInputFunctionView.h
//  UUChatDemoForTextVoicePicture
//
//  Created by shake on 14-8-27.
//  Copyright (c) 2014年 uyiuyao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CRInputFunctionView;
@class CRInputMoreView;
@class V5VoiceMessage;

// 底部显示类型
typedef NS_ENUM(NSInteger, CRBottomViewType) {
    BottomTypeNone = 0,         //不显示
    BottomTypeMore,             //显示更多功能
    BottomTypeHotQuestion,      //显示常见问题
    BottomTypeRelativeQuestion, //显示相关问题
    BottomTypeFace              //显示表情
};

/**
 *  底部栏显示状态
 */
typedef NS_ENUM(NSInteger, CRInputBarState) {
    CRInputBarState_TextInput = 0,      // 文本输入
    CRInputBarState_VoiceRecord = 1,    // 语音输入
    CRInputBarState_MoreFunc = 2        // 更多功能输入栏
};

@protocol CRInputFunctionViewDelegate <NSObject>
@required
// text
- (BOOL)CRInputFunctionView:(CRInputFunctionView *)funcView sendMessage:(NSString *)message;

// audio
- (BOOL)CRInputFunctionView:(CRInputFunctionView *)funcView sendVoiceMessage:(V5VoiceMessage *)voiceMessage;

/**
 *  回调返回InputFunctionView的高度变化和起始位置
 *
 *  @param height 高度差
 *  @param y      y轴起始位置
 */
- (void)CRInputFunctionView:(CRInputFunctionView *)funcView willChangeOriginY:(CGFloat)y;

/**
 *  选择指定序号的功能
 *
 *  @param index 选中的序号
 */
- (void)CRInputFunctionView:(CRInputFunctionView *)funcView selectMoreFunctionOfIndex:(NSInteger)index;

/**
 *  是否支持语音输入
 *
 *  @param funcView CRInputFunctionView
 *
 *  @return BOOL
 */
- (BOOL)isCRInputFunctionViewEnableVoiceRecord:(CRInputFunctionView *)funcView;


@end

@interface CRInputFunctionView : UIView <UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, retain) UIButton *btnSendMessage;
@property (nonatomic, retain) UITextView *TextViewInput;
@property (nonatomic, retain) UIButton *btnChangeVoiceState; // 语音｜文字切换
@property (nonatomic, retain) UIButton *btnVoiceRecord; // 长按录音

// 输入框下方的扩展输入View:统称bottomView
@property (nonatomic, retain) UIView *moreView;     //底部更多输入扩展View(CRInputMoreView)
@property (nonatomic, retain) UIView *questionView; //底部自定义扩展View(常见问答、相关问题)(CRInputQuestionView)
@property (nonatomic, retain) UIView *faceView;     //底部表情(CRInputFaceView)
@property (nonatomic, retain) UIView *activeView;   //当前显示的View

@property (nonatomic,strong) NSArray *imageArray;   //点击加号弹出的View中的图片数组
@property (nonatomic,strong) NSArray *nameArray;    //点击加号弹出的View中的图片名称数组
@property (nonatomic, assign) CRBottomViewType bottomShowType;
@property (nonatomic, assign) BOOL isAbleToSendTextMessage;

@property (nonatomic, retain) UIViewController *superVC;

@property (nonatomic, assign) id<CRInputFunctionViewDelegate> delegate;


- (id)initWithSuperVC:(UIViewController *)superVC
             delegate:(id<CRInputFunctionViewDelegate>)delegate
                frame:(CGRect)frame;

/**
 *  显示bottomView
 *
 *  @param viewType bottomView类型
 *  @param params   携带参数,imageArray\questionArray等参数
 *  @param animated 是否显示动画
 */
- (void)showBottomViewType:(CRBottomViewType)viewType withParams:(id)params animated:(BOOL)animated;
- (void)showBottomViewType:(CRBottomViewType)viewType withParams:(id)params; //默认显示动画

/**
 *  隐藏bottomView
 */
- (void)hideBottomView;

//- (void)changeSendBtnWithShow:(BOOL)isMore;
//- (void)textViewDidChange:(UITextView *)textView;

/**
 *  不同显示状态
 *
 *  @param state CRInputBarState
 */
- (void)updateFrameOnState:(CRInputBarState)state;

@end
