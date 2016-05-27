//
//  VoiceRecorder.h
//  mcss
//
//  Created by chyrain on 16/4/13.
//  Copyright © 2016年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *   录音失败原因
 */
typedef NS_ENUM(NSInteger, KV5VoiceRecordFailedReason) {
    // 录音太短
    VoiceRecordFailedReason_TooShort = 0,
    // 格式转换失败
    VoiceRecordFailedReason_ConvertFailed = 1
};

@protocol V5VoiceRecorderDelegate <NSObject>
- (void)failRecordWithReason:(KV5VoiceRecordFailedReason)reason;
- (void)beginConvert;
- (void)endConvertWithPath:(NSString *)voicePath;
@end

@interface V5VoiceRecorder : NSObject

@property (nonatomic, weak) id<V5VoiceRecorderDelegate> delegate;

- (id)initWithDelegate:(id<V5VoiceRecorderDelegate>)delegate;
- (void)startRecordWithFile:(NSString *)filename;
- (void)stopRecord;
- (void)cancelRecord;

@end

