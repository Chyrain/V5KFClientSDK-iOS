//
//  CRAVAudioPlayer.m
//  BloodSugarForDoc
//
//  Created by shake on 14-9-1.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import "CRAVAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "V5Util.h"

@interface CRAVAudioPlayer ()<AVAudioPlayerDelegate>

@end

@implementation CRAVAudioPlayer

+ (CRAVAudioPlayer *)sharedInstance
{
    static CRAVAudioPlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });    
    return sharedInstance;
}

-(void)playSongWithUrl:(NSString *)songUrl
{
    
    dispatch_async(dispatch_queue_create("playSoundFromUrl", NULL), ^{
        [self.delegate CRAVAudioPlayerBeiginLoadVoice];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:songUrl]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playSoundWithData:data];
        });
    });
}

-(BOOL)playSongWithFilePath:(NSString *)path
{
    [self setupPlaySound];
    return [self playSoundWithPath:path];
}

-(BOOL)playSongWithData:(NSData *)songData
{
    [self setupPlaySound];
    return [self playSoundWithData:songData];
}

-(BOOL)playSoundWithPath:(NSString *)filePath{
    if (_player) {
        [_player stop];
        _player.delegate = nil;
        _player = nil;
    }
    NSError *playerError;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:&playerError];
    _player.volume = 1.0f;
    if (_player == nil){
        NSLog(@"ERror creating player: %@ forFile:%@", [playerError description], filePath);
    }
    _player.delegate = self;
    BOOL played = [_player play];
    NSLog(@"playSoundWithData result:%d", played);
    if (played) {
        [self.delegate CRAVAudioPlayerBeiginPlay];
    }
    return played;
}

-(BOOL)playSoundWithData:(NSData *)soundData{
    if (_player) {
        [_player stop];
        _player.delegate = nil;
        _player = nil;
    }
    NSError *playerError;
    _player = [[AVAudioPlayer alloc] initWithData:soundData error:&playerError];
    _player.volume = 1.0f;
    if (_player == nil){
        NSLog(@"ERror creating player: %@", [playerError description]);
    }
    _player.delegate = self;
    BOOL played = [_player play];
    NSLog(@"playSoundWithData result:%d", played);
    if (played) {
        [self.delegate CRAVAudioPlayerBeiginPlay];
    }
    return played;
}

-(void)setupPlaySound{
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:app];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.delegate CRAVAudioPlayerDidFinishPlay];
}

- (void)stopSound
{
    if (_player && _player.isPlaying) {
        [_player stop];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application{
    [self.delegate CRAVAudioPlayerDidFinishPlay];
}

@end