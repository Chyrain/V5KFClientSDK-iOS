//
//  V5Util.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/11.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "V5Config.h"
#import "V5Util.h"
#import "V5ImageMessage.h"
#import "V5VoiceMessage.h"
#import "V5AFNetworking.h"
@import AVFoundation;

@implementation V5Util

+ (void)saveConfigWithValue:(NSString *)value forKey:(NSString *)key {
    // 获取应用沙盒的Douch
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *plist = [paths objectAtIndex:0];
    // 获取一个plist文件
    NSString *path = [plist stringByAppendingPathComponent:V5_CONFIG_FILE];
    
    // 读取数据
    NSMutableArray* data = [NSMutableArray arrayWithContentsOfFile:path];
    NSMutableDictionary *dic = [data objectAtIndex:0];
    if (!data) {
        data = [[NSMutableArray alloc] initWithCapacity:1];
    }
    if (!dic) {
        dic = [[NSMutableDictionary alloc] initWithCapacity:1];
        [data addObject:dic];
    }
    
    // 设置值
    [dic setObject:value forKey:key];
    [data writeToFile:path atomically:YES];
}

+ (id)readConfigValueWithKey:(NSString *)key {
    // 获取应用沙盒的Douch
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *plist1 = [paths objectAtIndex:0];
    
    // 获取一个plist文件
    NSString *path = [plist1 stringByAppendingPathComponent:V5_CONFIG_FILE];
//    NSDictionary* data = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSMutableArray* data = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    return [[data objectAtIndex:0] objectForKey:key];
}

+ (void)savePreferencesWithValue:(NSString *)value forKey:(NSString *)key {
    // 获取标准函数对象
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
}

+ (id)readPreferencesValueWithKey:(NSString *)key {
    // 获取标准函数对象
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

+ (void)saveTempWithValue:(NSString *)value forKey:(NSString *)key {
    // 获取tmp路径
    NSString *path = NSTemporaryDirectory();
    V5Log(@"--- tmp path --- :%@", path);
    
    // 读取数据
    NSMutableArray* data = [NSMutableArray arrayWithContentsOfFile:path];
    NSMutableDictionary *dic = [data objectAtIndex:0];
    if (!data) {
        data = [[NSMutableArray alloc] initWithCapacity:1];
    }
    if (!dic) {
        dic = [[NSMutableDictionary alloc] initWithCapacity:1];
        [data addObject:dic];
    }
    
    // 设置值
    [dic setObject:value forKey:key];
    [data writeToFile:path atomically:YES];}

+ (id)readTempValueWithKey:(NSString *)key {
    // 获取tmp路径
    NSString *path = NSTemporaryDirectory();
    NSMutableArray* data = [[NSMutableArray alloc] initWithContentsOfFile:path];
    return [[data objectAtIndex:0] objectForKey:key];
}

+ (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

+ (NSString *)md5OfData:(NSData *)data {
    const char* original_str = (const char *)[data bytes];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (CC_LONG)strlen(original_str), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x",digist[i]]; //小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
}

+ (BOOL)isEmptyString:(NSString *)str {
    if (str == nil || [str isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

#pragma mark - 图片压缩

+ (UIImage *)imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    if (targetWidth > width) {
        return sourceImage;
    }
    
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

/**
 *  获取／转换图片缩略图URL
 *
 *  @param imageMessage 图片消息对象
 *  @param siteId       站点ID
 *
 *  @return 缩略图URL
 */
+ (NSString *)getThumbnailURLOfImage:(V5ImageMessage *)imageMessage {
    NSString *picUrl = [imageMessage picUrl];
    V5Log(@"Image message url>>>:%@", picUrl);
    if (picUrl) {
        if (USE_THUMBNAIL && [picUrl containsString:@"image.myqcloud.com/"]) { // 来自万象优图的缩略图
            picUrl = [NSString stringWithFormat:@"%@/thumbnail", [imageMessage picUrl]];
        }
    }
    V5Log(@"<<<Image message thumbnail url>>>:%@", picUrl);
    return picUrl;
}

/**
 *  @author Jakey
 *
 *  @brief  下载文件
 *
 *  @param paramDic   附加post参数
 *  @param requestURL 请求地址
 *  @param savedPath  保存 在磁盘的位置
 *  @param success    下载成功回调
 *  @param failure    下载失败回调
 *  @param progress   实时下载进度回调
 */
+ (void)downloadVoiceWithOption:(NSDictionary *)paramDic
                        withURL:(NSString*)requestURL
                   voiceMessage:(V5VoiceMessage*)voiceMessage
                downloadSuccess:(void (^)(id responseObject))success
                downloadFailure:(void (^)(NSError *error))failure
                       progress:(void (^)(float progress))progress {
    NSString *savedPath = [self getAMRVoicePath:voiceMessage];
    V5Log(@"savePath:%@", savedPath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:VOICE_CACHE_PATH]) {
        V5Log(@"Path not exit -> create");
        // 创建文件夹路径
        [[NSFileManager defaultManager] createDirectoryAtPath:VOICE_CACHE_PATH
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:savedPath]) {
        NSData *mediaData = [self getMediaFileWithPath:savedPath];
        success(mediaData);
        V5Log(@"读取缓存成功:%@", savedPath);
        return;
    }
    
    V5AFHTTPRequestSerializer *serializer = [V5AFHTTPRequestSerializer serializer];
    [serializer setValue:@"http://chat.v5kf.com" forHTTPHeaderField:@"Origin"];
    NSMutableURLRequest *request =[serializer requestWithMethod:@"GET" URLString:requestURL parameters:paramDic error:nil];
    V5AFHTTPRequestOperation *operation = [[V5AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:savedPath append:NO]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progress) {
            float p = (float)totalBytesRead / totalBytesExpectedToRead;
            progress(p);
        }
        //V5Log(@"voice download progress：%f", (float)totalBytesRead / totalBytesExpectedToRead);
    }];
    
    [operation setCompletionBlockWithSuccess:^(V5AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        //V5Log(@"voice下载成功");
    } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:savedPath]) {
            // 清除失败文件
            [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:savedPath] error:nil];
        }
        failure(error);
        //V5Log(@"voice下载失败:%@ response:%@", [error description], [operation.responseObject description]);
    }];
    
    [operation start];
}

+ (NSData *)getMediaFileWithPath:(NSString *)filaPath {
    NSData *fileData = [NSData dataWithContentsOfFile:filaPath];
    return fileData;
}

#pragma mark - 生成文件路径
+ (NSString*)getVoicePathByFileName:(NSString *)_fileName ofType:(NSString *)_type { // Documents/v5voicecache/xxxxx
    NSString* fileDirectory = [[[VOICE_CACHE_PATH
                                 stringByAppendingPathComponent:_fileName]
                                stringByAppendingPathExtension:_type]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return fileDirectory;
}

+ (NSString *)getAMRVoicePath:(V5VoiceMessage *)voiceMessage {
    if (!voiceMessage.url) {
        return nil;
    }
    NSString *voiceId = [self md5:voiceMessage.url];
    return [self getVoicePathByFileName:[NSString stringWithFormat:@"%@", voiceId]
                                 ofType:@"amr"];
}

+ (NSString *)getWAVVoicePath:(V5VoiceMessage *)voiceMessage {
    if (!voiceMessage.url) {
        return nil;
    }
    NSString *voiceId = [self md5:voiceMessage.url];
    return [self getVoicePathByFileName:[NSString stringWithFormat:@"%@", voiceId]
                                 ofType:@"wav"];
}

#pragma mark - 获取音频文件信息

/**
 *  获得wav音频文件时长
 *
 *  @param data wav音频数据
 *
 *  @return 时长
 */
+ (NSTimeInterval)getVoiceDuration:(NSData *)data {
    if (data == nil) {
        return 0;
    }
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:nil];
    return player.duration;
}

/**
 *  获得wav音频文件时长
 *
 *  @param filePath wav音频数据路径
 *
 *  @return 时长
 */
+ (NSTimeInterval)getVoiceDurationOnPath:(NSString *)filePath {
    if (filePath == nil) {
        return 0;
    }
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath]
                                                                   error:nil];
    return player.duration;
}

#pragma mark - 获取文件大小
+ (NSInteger) getFileSize:(NSString*)path {
    NSFileManager * filemanager = [[NSFileManager alloc] init];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ((theFileSize = [attributes objectForKey:NSFileSize]) )
            return [theFileSize intValue];
        else
            return -1;
    } else{
        return -1;
    }
}

/**
 *  获得指定路径的音频文件NSData
 *
 *  @param filePath 本地路径
 *
 *  @return NSData
 */
+ (NSData *)getSongDataWithPath:(NSString *)filePath {
    return [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
}

+ (BOOL)isFileExists:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)isVoiceMessageExists:(V5VoiceMessage *)voiceMessage {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getWAVVoicePath:voiceMessage]];
}

+ (BOOL)clearVoiceCache {
    return [[NSFileManager defaultManager] removeItemAtPath:VOICE_CACHE_PATH error:nil];
}

+ (CGFloat)getVoiceCacheSize {
    return [self folderSizeAtPath:VOICE_CACHE_PATH];
}

/**
 *  文件夹大小
 *
 *  @param folderPath 文件夹路径
 *
 *  @return 大小
 */
+ (CGFloat)folderSizeAtPath:(NSString *)folderPath {
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath])
        return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize / (1024.0f * 1024.0f);
}

/**
 *  文件大小
 *
 *  @param folderPath 文件路径
 *
 *  @return 大小
 */
+ (long long)fileSizeAtPath:(NSString *)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

+ (void)deleteFileWithPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:path error:nil])
    {
        V5Log(@"delete file success:%@", path);
    }
}

@end
