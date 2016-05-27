//
//  VoiceRecorder.m
//  mcss
//
//  Created by chyrain on 16/4/13.
//  Copyright © 2016年 V5KF. All rights reserved.
//

#import "V5VoiceRecorder.h"
#import "V5Util.h"
#import <AVFoundation/AVFoundation.h>
#import "V5VoiceConverter.h"

@interface V5VoiceRecorder()<AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSString *filename;
@end

@implementation V5VoiceRecorder

#pragma mark - Init Methods

- (id)initWithDelegate:(id<V5VoiceRecorderDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
        if (![[NSFileManager defaultManager] fileExistsAtPath:VOICE_CACHE_PATH]) {
            // 创建文件夹路径
            [[NSFileManager defaultManager] createDirectoryAtPath:VOICE_CACHE_PATH
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }
    }
    return self;
}

- (void)setRecorder
{
    _recorder = nil;
    NSError *recorderSetupError = nil;
    NSURL *url = [NSURL fileURLWithPath:[self wavPath]]; // 录音时保存为wav
    _recorder = [[AVAudioRecorder alloc] initWithURL:url
                                            settings:[V5VoiceConverter GetAudioRecorderSettingDict]
                                               error:&recorderSetupError];
    if (recorderSetupError) {
        V5Log(@"%@",recorderSetupError);
    }
    _recorder.meteringEnabled = YES;
    _recorder.delegate = self;
    [_recorder prepareToRecord];
}

- (void)setSesstion
{
    _session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(_session == nil)
        V5Log(@"Error creating session: %@", [sessionError description]);
    else
        [_session setActive:YES error:nil];
}

#pragma mark - Public Methods

- (void)startRecordWithFile:(NSString *)filename
{
    self.filename = filename;
    [self setSesstion];
    [self setRecorder];
    [_recorder record];
}


- (void)stopRecord
{
    double cTime = _recorder.currentTime;
    [_recorder stop];
    
    if (cTime > 1) {
        [self audio_WAVtoAMR];
    }else {
        
        [_recorder deleteRecording];
        
        if ([_delegate respondsToSelector:@selector(failRecordWithReason:)]) {
            [_delegate failRecordWithReason:VoiceRecordFailedReason_TooShort];
        }
    }
}

- (void)cancelRecord
{
    [_recorder stop];
    [_recorder deleteRecording];
}

- (void)deleteWAVCache
{
    [self deleteFileWithPath:[self wavPath]];
}

- (void)deleteAMRCache
{
    [self deleteFileWithPath:[self amrPath]];
}

- (void)deleteFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:path error:nil])
    {
        V5Log(@"删除以前的音频文件:%@", path);
    }
}

#pragma mark - Convert Utils
- (void)audio_WAVtoAMR
{
    // remove the old amr file
    [self deleteAMRCache];
    
    V5Log(@"AMR转换开始");
    if (_delegate && [_delegate respondsToSelector:@selector(beginConvert)]) {
        [_delegate beginConvert];
    }

    if ([V5VoiceConverter ConvertWavToAmr:[self wavPath] amrSavePath:[self amrPath]]) {
        V5Log(@"AMR转换结束");
        if (_delegate && [_delegate respondsToSelector:@selector(endConvertWithPath:)]) {
            [_delegate endConvertWithPath:[self wavPath]];
        }
    } else {
        V5Log(@"wav转amr失败");
        if ([_delegate respondsToSelector:@selector(failRecordWithReason:)]) {
            [_delegate failRecordWithReason:VoiceRecordFailedReason_ConvertFailed];
        }
    }
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
}

#pragma mark - Path Utils
- (NSString *)wavPath
{
    NSString *cafPath = [V5Util getVoicePathByFileName:self.filename ofType:@"wav"];
    return cafPath;
}

- (NSString *)amrPath
{
    NSString *mp3Path = [V5Util getVoicePathByFileName:self.filename ofType:@"amr"];

    return mp3Path;
}

@end
