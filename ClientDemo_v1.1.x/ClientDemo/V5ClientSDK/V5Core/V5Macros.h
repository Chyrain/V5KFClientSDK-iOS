//
//  V5Macros.h
//


#ifndef V5Macros_h
#define V5Macros_h

#import "V5Defination.h"

// [修改]最大开场消息ID(10位)
#define OPEN_QUES_MAX_ID 9999999999L

// debug连接模式
//#define V5_DEBUG

#define V5_VERSION @"1.1.3" // v1.1.3_r0525

// 启用log打印，默认1-启用/0-禁用
#ifdef DEBUG
#define V5EnabledLog 1
#else
#define V5EnabledLog 0
#endif

#define USE_THUMBNAIL YES // 是否使用缩略图
#define ENABLE_VOICE_SEND YES // 是否支持语音发送

#define MAX_UPLOADIMG_WIDTH 2000.0f

// 语音文件缓存路径
#define VOICE_CACHE_PATH [NSString stringWithFormat:@"%@/v5voicecache", PATH_OF_DOCUMENT]


// 网络连接类型监测。将此字符串添加到NSNotificationCenter的观察者，可监测网络变化。
#define kV5NetworkStatusChange @"V5NetworkStatusChange"


//** 自定义信息 **************************************************************
#define V5BundleName @"V5Client.bundle"
#define V5BUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:V5BundleName]
#define V5BUNDLE [NSBundle bundleWithPath:V5BUNDLE_PATH]

//#define BUNDLE_DEBUG
// 获取本地化strings文件的字符串,key, val:默认值
#ifdef BUNDLE_DEBUG
#define V5LocalStr(key, val) \
    NSLocalizedStringWithDefaultValue(key, @"V5Localizable", [NSBundle mainBundle], val, nil)
#define IMGFILE(file) file
#define FILEPATH(name, type) [[NSBundle mainBundle] pathForResource:name ofType:type]
#define MB_IMGFILE(file) [@"MJRefresh.bundle" stringByAppendingPathComponent:file]
#else
#define V5LocalStr(key, val) \
    NSLocalizedStringWithDefaultValue(key, @"V5Localizable", V5BUNDLE, val, nil)
#define IMGFILE(file) [V5BundleName stringByAppendingPathComponent:file]
#define FILEPATH(name, type) [V5BUNDLE pathForResource:name ofType:type]
#define MB_IMGFILE(file) [V5BundleName stringByAppendingPathComponent:file]
#endif

//数据库
#define V5_DB_NAME      @"v5_client.db"
#define V5_TABLE_NAME   @"v5_message"
#define V5_TABLE_NAME_FMT   @"v5_message_%@"

// 本地化存储键值字符串宏
#define CFG_UID             @"v5_sdk_uid"
#define CFG_APP_KEY         @"v5_sdk_app_key"
#define CFG_SITE_ID         @"v5_sdk_site_id"
#define CFG_SITE_NAME       @"v5_sdk_site_name"
#define CFG_ACCOUNT         @"v5_sdk_account"
#define CFG_DEVICE_TOKEN    @"v5_sdk_deviceToken"
#define CFG_VISITOR         @"v5_sdk_visitor"
#define CFG_AUTH            @"v5_sdk_authorization"
#define CFG_TIMESTAMP       @"v5_sdk_timestamp"
#define CFG_EXPIRES         @"v5_sdk_expires"
#define CFG_CUSTOM_CONTENT  @"v5_sdk_custom_content" // 自定义用户信息
#define CFG_PUSH_ENABLE     @"v5_sdk_push_enable"  // 是否开启推送
#define CFG_PIC_AUTH        @"v5_sdk_wxyt_auth"    // 万象优图Authorization
#define CFG_PIC_URL         @"v5_sdk_wxyt_url"     // 万象优图URL
#define CFG_INITIALIZED     @"v5_sdk_initialized"

// 连接地址、认证地址等URL格式字符串
#define V5_INIT_URL         (@"http://www.v5kf.com/public/appsdk/init")

#ifdef V5_DEBUG
#define WS_URL_FMT          (@"wss://chat.v5kf.com/debug/appws/v2?auth=%@")
#define ACCOUNT_AUTH_URL    (@"https://chat.v5kf.com/debug/appauth/v2")
#define PIC_AUTH_URL        (@"https://chat.v5kf.com/debug/wxyt/app?auth=%@")
#define MEDIA_AUTH_URL      (@"https://chat.v5kf.com/debug/wxyt/app?auth=%@&type=%@&suffix=%@")
#else
#define WS_URL_FMT          (@"wss://chat.v5kf.com/public/appws/v2?auth=%@")
#define ACCOUNT_AUTH_URL    (@"https://chat.v5kf.com/public/appauth/v2")
#define PIC_AUTH_URL        (@"https://chat.v5kf.com/public/wxyt/app?auth=%@")
#define MEDIA_AUTH_URL      (@"https://chat.v5kf.com/public/wxyt/app?auth=%@&type=%@&suffix=%@")
#endif

#define HOTQUES_URL_FMT @"https://chat.v5kf.com/public/api_dkf/get_hot_ques?sid=%@"

#define MAP_PIC_URL_FORMAT \
@"https://apis.map.qq.com/ws/staticmap/v2/?center=%f,%f&zoom=15&size=300*200&maptype=roadmap&markers=size:small|color:0x207CC4|label:V|%f,%f&key=WWBBZ-5FQR4-QBWUP-DFRYQ-5Y4HH-2OBV6"

// 保存的配置文件名
#define V5_CONFIG_FILE @"V5Config.plist"

// debug时用于输出日志
#if V5EnabledLog
#define V5Log(s, ...) NSLog(@"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] \
lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define V5Log(s, ...)
#endif


//** 沙盒路径 ***********************************************************************************
#define PATH_OF_APP_HOME    NSHomeDirectory()
#define PATH_OF_TEMP        NSTemporaryDirectory()
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]


/* ****************************************************************************************************************** */
/** DEBUG LOG **/
#ifdef DEBUG

#define DLog( s, ... ) NSLog( @"< %@:(%d) > %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

#define DLog( s, ... )

#endif


/** DEBUG RELEASE **/
#if DEBUG

#define MCRelease(x)            [x release]

#else

#define MCRelease(x)            [x release], x = nil

#endif


/** NIL RELEASE **/
#define NILRelease(x)           [x release], x = nil


/* ****************************************************************************************************************** */
#pragma mark - Frame (宏 x, y, width, height)

// App Frame
#define Application_Frame       [[UIScreen mainScreen] applicationFrame]

// App Frame Height&Width
#define App_Frame_Height        [[UIScreen mainScreen] applicationFrame].size.height
#define App_Frame_Width         [[UIScreen mainScreen] applicationFrame].size.width

// MainScreen Height&Width
#define Main_Screen_Height      [[UIScreen mainScreen] bounds].size.height
#define Main_Screen_Width       [[UIScreen mainScreen] bounds].size.width

// View 坐标(x,y)和宽高(width,height)
#define X(v)                    (v).frame.origin.x
#define Y(v)                    (v).frame.origin.y
#define WIDTH(v)                (v).frame.size.width
#define HEIGHT(v)               (v).frame.size.height

#define MinX(v)                 CGRectGetMinX((v).frame)
#define MinY(v)                 CGRectGetMinY((v).frame)

#define MidX(v)                 CGRectGetMidX((v).frame)
#define MidY(v)                 CGRectGetMidY((v).frame)

#define MaxX(v)                 CGRectGetMaxX((v).frame)
#define MaxY(v)                 CGRectGetMaxY((v).frame)


#define RECT_CHANGE_x(v,x)          CGRectMake(x, Y(v), WIDTH(v), HEIGHT(v))
#define RECT_CHANGE_y(v,y)          CGRectMake(X(v), y, WIDTH(v), HEIGHT(v))
#define RECT_CHANGE_point(v,x,y)    CGRectMake(x, y, WIDTH(v), HEIGHT(v))
#define RECT_CHANGE_width(v,w)      CGRectMake(X(v), Y(v), w, HEIGHT(v))
#define RECT_CHANGE_height(v,h)     CGRectMake(X(v), Y(v), WIDTH(v), h)
#define RECT_CHANGE_size(v,w,h)     CGRectMake(X(v), Y(v), w, h)

// 系统控件默认高度
#define kStatusBarHeight        (20.f)

#define kTopBarHeight           (44.f)
#define kBottomBarHeight        (49.f)

#define kCellDefaultHeight      (44.f)

#define kEnglishKeyboardHeight  (216.f)
#define kChineseKeyboardHeight  (252.f)


/* ****************************************************************************************************************** */
#pragma mark - Funtion Method (宏 方法)

// PNG JPG 图片路径
#define PNGPATH(NAME)           [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:NAME] ofType:@"png"]
#define JPGPATH(NAME)           [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:NAME] ofType:@"jpg"]
#define PATH(NAME, EXT)         [[NSBundle mainBundle] pathForResource:(NAME) ofType:(EXT)]

// 加载图片
#define PNGIMAGE(NAME)          [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(NAME) ofType:@"png"]]
#define JPGIMAGE(NAME)          [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(NAME) ofType:@"jpg"]]
#define IMAGE(NAME, EXT)        [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(NAME) ofType:(EXT)]]

// 字体大小(常规/粗体)
#define BOLDSYSTEMFONT(FONTSIZE)[UIFont boldSystemFontOfSize:FONTSIZE]
#define SYSTEMFONT(FONTSIZE)    [UIFont systemFontOfSize:FONTSIZE]
#define FONT(NAME, FONTSIZE)    [UIFont fontWithName:(NAME) size:(FONTSIZE)]

// 颜色(RGB)
#define RGBCOLOR(r, g, b)       [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r, g, b, a)   [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

//number转String
#define IntTranslateStr(int_str) [NSString stringWithFormat:@"%d",int_str];
#define FloatTranslateStr(float_str) [NSString stringWithFormat:@"%.2d",float_str];

// View 圆角和加边框
#define ViewBorderRadius(View, Radius, Width, Color)\
                                \
                                [View.layer setCornerRadius:(Radius)];\
                                [View.layer setMasksToBounds:YES];\
                                [View.layer setBorderWidth:(Width)];\
                                [View.layer setBorderColor:[Color CGColor]]

// View 圆角
#define ViewRadius(View, Radius)\
                                \
                                [View.layer setCornerRadius:(Radius)];\
                                [View.layer setMasksToBounds:YES]

// 当前版本
#define FSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define DSystemVersion          ([[[UIDevice currentDevice] systemVersion] doubleValue])
#define SSystemVersion          ([[UIDevice currentDevice] systemVersion])

// 当前语言
#define CURRENTLANGUAGE         ([[NSLocale preferredLanguages] objectAtIndex:0])

// 是否Retina屏
#define isRetina                ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? \
                                CGSizeEqualToSize(CGSizeMake(640, 960), \
                                                  [[UIScreen mainScreen] currentMode].size) : \
                                NO)

// 是否iPhone5
#define isiPhone5               ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? \
                                CGSizeEqualToSize(CGSizeMake(640, 1136), \
                                                  [[UIScreen mainScreen] currentMode].size) : \
                                NO)
// 是否iPhone5
#define isiPhone4               ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? \
                                CGSizeEqualToSize(CGSizeMake(640, 960), \
                                [[UIScreen mainScreen] currentMode].size) : \
                                NO)

// 是否IOS7
#define isIOS7                  ([[[UIDevice currentDevice]systemVersion]floatValue] >= 7.0)
// 是否IOS6
#define isIOS6                  ([[[UIDevice currentDevice]systemVersion]floatValue] < 7.0)

// 是否iPad
#define isPad                   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

// UIView - viewWithTag
#define VIEWWITHTAG(_OBJECT, _TAG)\
                                \
                                [_OBJECT viewWithTag : _TAG]

// 本地化字符串
/** NSLocalizedString宏做的其实就是在当前bundle中查找资源文件名“Localizable.strings”(参数:键＋注释) */
#define LocalString(x, ...)     NSLocalizedString(x, nil)
/** NSLocalizedStringFromTable宏做的其实就是在当前bundle中查找资源文件名“xxx.strings”(参数:键＋文件名＋注释) */
#define AppLocalString(x, ...)  NSLocalizedStringFromTable(x, @"someName", nil)

// RGB颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue)\
                                \
                                [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                                 blue:((float)(rgbValue & 0xFF))/255.0 \
                                                alpha:1.0]

#if TARGET_OS_IPHONE
/** iPhone Device */
#endif

#if TARGET_IPHONE_SIMULATOR
/** iPhone Simulator */
#endif

// ARC
#if __has_feature(objc_arc)
/** Compiling with ARC */
#else
/** Compiling without ARC */
#endif


/* ****************************************************************************************************************** */
#pragma mark - Log Method (宏 LOG)

// 日志 / 断点
// =============================================================================================================================
// DEBUG模式
#define ITTDEBUG

// LOG等级
#define ITTLOGLEVEL_INFO        10
#define ITTLOGLEVEL_WARNING     3
#define ITTLOGLEVEL_ERROR       1

// =============================================================================================================================
// LOG最高等级
#ifndef ITTMAXLOGLEVEL

#ifdef DEBUG
#define ITTMAXLOGLEVEL ITTLOGLEVEL_INFO
#else
#define ITTMAXLOGLEVEL ITTLOGLEVEL_ERROR
#endif

#endif

// =============================================================================================================================
// LOG PRINT
// The general purpose logger. This ignores logging levels.
#ifdef ITTDEBUG
#define ITTDPRINT(xx, ...)      NSLog(@"< %s:(%d) > : " xx , __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define ITTDPRINT(xx, ...)      ((void)0)
#endif

// Prints the current method's name.
#define ITTDPRINTMETHODNAME()   ITTDPRINT(@"%s", __PRETTY_FUNCTION__)

// Log-level based logging macros.
#if ITTLOGLEVEL_ERROR <= ITTMAXLOGLEVEL
#define ITTDERROR(xx, ...)      ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDERROR(xx, ...)      ((void)0)
#endif

#if ITTLOGLEVEL_WARNING <= ITTMAXLOGLEVEL
#define ITTDWARNING(xx, ...)    ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDWARNING(xx, ...)    ((void)0)
#endif

#if ITTLOGLEVEL_INFO <= ITTMAXLOGLEVEL
#define ITTDINFO(xx, ...)       ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDINFO(xx, ...)       ((void)0)
#endif

// 条件LOG
#ifdef ITTDEBUG
#define ITTDCONDITIONLOG(condition, xx, ...)\
                                \
                                {\
                                    if ((condition))\
                                    {\
                                        ITTDPRINT(xx, ##__VA_ARGS__);\
                                    }\
                                }
#else
#define ITTDCONDITIONLOG(condition, xx, ...)\
                                \
                                ((void)0)
#endif

// 断点Assert
#define ITTAssert(condition, ...)\
                                \
                                do {\
                                    if (!(condition))\
                                    {\
                                        [[NSAssertionHandler currentHandler]\
                                        handleFailureInFunction:[NSString stringWithFormat:@"< %s >", __PRETTY_FUNCTION__]\
                                                           file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent]\
                                                     lineNumber:__LINE__\
                                                    description:__VA_ARGS__];\
                                    }\
                                } while(0)


/* ****************************************************************************************************************** */
#pragma mark - Constants (宏 常量)


/** 时间间隔 */
#define kHUDDuration            (1.f)

/** 一天的秒数 */
#define SecondsOfDay            (24.f * 60.f * 60.f)
/** 秒数 */
#define Seconds(Days)           (24.f * 60.f * 60.f * (Days))

/** 一天的毫秒数 */
#define MillisecondsOfDay       (24.f * 60.f * 60.f * 1000.f)
/** 毫秒数 */
#define Milliseconds(Days)      (24.f * 60.f * 60.f * 1000.f * (Days))


//** textAlignment ***********************************************************************************

#if !defined __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
# define LINE_BREAK_WORD_WRAP UILineBreakModeWordWrap
# define TextAlignmentLeft UITextAlignmentLeft
# define TextAlignmentCenter UITextAlignmentCenter
# define TextAlignmentRight UITextAlignmentRight

#else
# define LINE_BREAK_WORD_WRAP NSLineBreakByWordWrapping
# define TextAlignmentLeft NSTextAlignmentLeft
# define TextAlignmentCenter NSTextAlignmentCenter
# define TextAlignmentRight NSTextAlignmentRight

#endif



#endif
