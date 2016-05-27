//
//  V5Util.h
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/11.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "V5Macros.h"

@class V5VoiceMessage;
@class V5ImageMessage;
@interface V5Util : NSObject

// 读取保存自己定义的plist文件
+ (void)saveConfigWithValue:(NSString *)value forKey:(NSString *)key;
+ (id)readConfigValueWithKey:(NSString *)key;

// 读取保存系统默认偏好plist文件
+ (void)savePreferencesWithValue:(NSString *)value forKey:(NSString *)key;
+ (id)readPreferencesValueWithKey:(NSString *)key;

// 读取保存临时保存信息plist文件
+ (void)saveTempWithValue:(NSString *)value forKey:(NSString *)key;
+ (id)readTempValueWithKey:(NSString *)key;

// MD5
+ (NSString *)md5:(NSString *)input;
+ (NSString *)md5OfData:(NSData *)data;

+ (BOOL)isEmptyString:(NSString *)str;

+ (BOOL)isBlankString:(NSString *)string;

// 等比例压缩图片到最大宽度
+ (UIImage *)imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth;

// 获取／转换图片缩略图URL
+ (NSString *)getThumbnailURLOfImage:(V5ImageMessage *)imageMessage;

// 下载语音
+ (void)downloadVoiceWithOption:(NSDictionary *)paramDic
                        withURL:(NSString*)requestURL
                   voiceMessage:(V5VoiceMessage*)voiceMessage
                downloadSuccess:(void (^)(id responseObject))success
                downloadFailure:(void (^)(NSError *error))failure
                       progress:(void (^)(float progress))progress;

/**
 *  获得wav音频文件时长
 *
 *  @param data wav音频数据
 *
 *  @return 时长
 */
+ (NSTimeInterval)getVoiceDuration:(NSData *)data;
+ (NSTimeInterval)getVoiceDurationOnPath:(NSString *)filePath;

/* 获得语音文件路径 */
+ (NSString*)getVoicePathByFileName:(NSString *)_fileName ofType:(NSString *)_type;
+ (NSString *)getAMRVoicePath:(V5VoiceMessage *)voiceMessage;
+ (NSString *)getWAVVoicePath:(V5VoiceMessage *)voiceMessage;

/**
 *  获得指定路径的音频文件NSData
 *
 *  @param filePath 本地路径
 *
 *  @return NSData
 */
+ (NSData *)getSongDataWithPath:(NSString *)filePath;

+ (BOOL)isFileExists:(NSString *)path;

// 语音是否存在
+ (BOOL)isVoiceMessageExists:(V5VoiceMessage *)voiceMessage;

/**
 *  清理语音缓存
 *
 *  @return BOOL
 */
+ (BOOL)clearVoiceCache;
// 语音缓存大小
+ (CGFloat)getVoiceCacheSize;

// 文件夹大小
+ (CGFloat)folderSizeAtPath:(NSString*) folderPath;
// 文件大小
+ (long long)fileSizeAtPath:(NSString *)filePath;
// 删除文件
+ (void)deleteFileWithPath:(NSString *)path;
@end
