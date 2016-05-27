//
//  CRConfigMcros.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/28.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#ifndef CRConfigMacros_h
#define CRConfigMacros_h

#import "V5Macros.h"

#define KEYBAR_ANIM_DURATION 0.25f //界面动画时间

#define ChatTableViewBG RGBCOLOR(198, 218, 218)
#define ChatMargin 6                               //气泡间隔
#define AvatarMargin 4                             //气泡与头像间隔
#define ChatIconWH 40                               //头像宽高height、width
#define ChatPicWH (((Main_Screen_Width > 500 ? 500 : Main_Screen_Width) - 110.0)/2)   //气泡图片宽高
#define ChatContentW ((Main_Screen_Width > 500 ? 500 : Main_Screen_Width) - 90.0)    //气泡内容宽度，图文宽度(居中)
#define ChatStatusWH 35                             //气泡状态宽高

#define ArticleContentW ((Main_Screen_Width > 500 ? 500 : Main_Screen_Width) - 40.0)      //图文宽度
#define ArticleContentH ((Main_Screen_Width > 500 ? 500 : Main_Screen_Width) - 60.0)      //图文高度
#define ArticleFrameMargin 10                           //图文边框间隔
#define ArticleInnerMargin 10                           //图文内容标签间隔
#define ArticleImageHeight (ArticleContentW/2)          //单图文大图高度(宽度:ArticleContentW - 2*ArticleFrameMargin)
#define ArticlesImageHeight ((ArticleContentW)*2/5)     //多图文大图高度(宽度:ArticleContentW - 2*ArticleInnerMargin)
#define ArticlesPicWH 50                                //多图文小图标宽高
#define ArticlesInnerMargin 6                           //多图文边框内边距
#define ArticleBGRadius 5.0                             //图文背景圆角
#define ArticleBGNormalColor [UIColor whiteColor]       //图文背景色
#define ArticleBGHighlightColor RGBCOLOR(234, 234, 234) //图文高亮背景色
#define ArticleTitleColor [UIColor blackColor]          //单图文标题颜色
#define ArticleDescColor [UIColor grayColor]            //单图文简介颜色
#define ArticleDescFont SYSTEMFONT(14.0)                //单图文简介字体
#define ArticleTitleFont SYSTEMFONT(18.0)               //单图文标题字体
#define ArticleMoreColor RGBCOLOR(66, 66, 66)           //单图文查看全文颜色
#define ArticleMoreFont SYSTEMFONT(16.0)                //单图文查看全文字体
#define ArticlesTitleColor RGBCOLOR(99, 99, 99)         //多图文标题颜色
#define ArticlesTitleFont SYSTEMFONT(16.0)              //多图文标题字体
#define ArticlesLineHeight 1                            //多图文分割线高度(像素)
#define ArticlesLineColor [UIColor lightGrayColor]      //多图文分割线颜色
#define ArticlesHeaderTextColor [UIColor whiteColor]    //多图文头部图文标题颜色
#define ArticlesHeaderTextFont SYSTEMFONT(16.0)         //多图文头部图文标题字体
#define ArticlesHeaderBGColor RGBACOLOR(33, 33, 33, 0.8)//多图文头部图文标题背景色
#define ArticlesHeaderLabelInsets UIEdgeInsetsMake(0, 4, 0, 4) //多图文头部图文标题内边距

#define ChatTimeMarginW 9  //时间文本与边框间隔宽度方向
#define ChatTimeMarginH 6  //时间文本与边框间隔高度方向

#define ChatContentMargin 11 //相关问题左边距
#define ChatContentTop 10   //文本内容与按钮上边缘间隔
#define ChatContentLeft 18  //文本内容与按钮左边缘间隔
#define ChatContentBottom 10 //文本内容与按钮下边缘间隔
#define ChatContentRight 11 //文本内容与按钮右边缘间隔

#define ChatTimeFont [UIFont systemFontOfSize:11]   //时间字体
#define ChatContentFont [UIFont systemFontOfSize:16]//内容字体

#define ChatFromRobotTextColor      RGBCOLOR(255,255,255)
#define ChatFromWorkerTextColor     RGBCOLOR(255,255,255)
#define ChatToTextColor             RGBCOLOR(88,88,88)

// 底部输入功能键盘相关
#define INPUT_BAR_H 46
#define INPUT_BTN_H 36
#define InputHorizontalPadding 5
#define InputVerticalPadding 5
#define InputTextViewInnerPadding 3

#define InputBGColor RGBCOLOR(235, 236, 238)
#define InputMoreHPadding 25.0
#define InputMoreVPadding 30.0
#define InputMoreLabelColor [UIColor darkGrayColor]
#define InputMoreLabelFont [UIFont systemFontOfSize:12.0]
#define InputSupportLabelColor [UIColor lightGrayColor]
#define InputSupportLabelFont [UIFont systemFontOfSize:12.0]

#define InputQuesTextColor RGBCOLOR(66, 66, 66)
#define InputQuesTextFont SYSTEMFONT(14.0)

#endif