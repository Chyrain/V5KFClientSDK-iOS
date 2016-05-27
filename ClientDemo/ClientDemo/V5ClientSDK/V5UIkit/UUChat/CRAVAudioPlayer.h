//
//  CRAVAudioPlayer.h
//  BloodSugarForDoc
//
//  Created by shake on 14-9-1.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@protocol CRAVAudioPlayerDelegate <NSObject>

- (void)CRAVAudioPlayerBeiginLoadVoice;
- (void)CRAVAudioPlayerBeiginPlay;
- (void)CRAVAudioPlayerDidFinishPlay;

@end

@interface CRAVAudioPlayer : NSObject
@property (nonatomic ,strong)  AVAudioPlayer *player;
@property (nonatomic, assign)id <CRAVAudioPlayerDelegate>delegate;
+ (CRAVAudioPlayer *)sharedInstance;

-(BOOL)playSongWithFilePath:(NSString *)path;
-(void)playSongWithUrl:(NSString *)songUrl;
-(BOOL)playSongWithData:(NSData *)songData;

- (void)stopSound;
@end
