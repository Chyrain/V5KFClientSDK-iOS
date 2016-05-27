//
//  V5MessageManager.m
//  V5KFClientTest
//
//  Created by V5KF_MBP on 15/12/2.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5MessageManager.h"

@implementation V5MessageManager

+ (V5Message *)receiveMessageFromJSON:(NSDictionary *)jsonData {
    NSInteger type = [[jsonData objectForKey:@"message_type"] intValue];
    V5Message *message = nil;
    switch (type) {
        case MessageType_Text:
            message = [[V5TextMessage alloc] initWithJSON:jsonData];
            break;
            
        case MessageType_Image:
            message = [[V5ImageMessage alloc] initWithJSON:jsonData];
            break;
            
        case MessageType_Location:
            message = [[V5LocationMessage alloc] initWithJSON:jsonData];
            break;
            
        case MessageType_Articles:
            message = [[V5ArticlesMessage alloc] initWithJSON:jsonData];
            break;
            
        case MessageType_Control:
            message = [[V5ControlMessage alloc] initWithJSON:jsonData];
            break;
            
        case MessageType_Voice:
            message = [[V5VoiceMessage alloc] initWithJSON:jsonData];
            break;
            
        default:
            message = [[V5UndefinedMessage alloc] initWithJSON:jsonData];
            break;
    }
    return message;
}

+ (V5TextMessage *)obtainTextMessageWithContent:(NSString *)content {
    V5TextMessage *textMessage = [[V5TextMessage alloc] initWithContent:content];
    return textMessage;
}

+ (V5LocationMessage *)obtainLocationMessageWithX:(double)x
                                                y:(double)y
                                            scale:(double)scale
                                            label:(NSString *)label {
    V5LocationMessage *locationMessage = [[V5LocationMessage alloc] initWithLatitude:x
                                                                           longitude:y
                                                                               scale:scale
                                                                               label:label];
    return locationMessage;
}

+ (V5ImageMessage *)obtainImageMessageWithPicUrl:(NSString *)picUrl mediaId:(NSString *)mediaId {
    V5ImageMessage *imageMessage = [[V5ImageMessage alloc] initWithPicUrl:picUrl mediaId:mediaId];
    return imageMessage;
}

+ (V5ImageMessage *)obtainImageMessageWithImage:(UIImage *)image {
    V5ImageMessage *imageMessage = [[V5ImageMessage alloc] initWithImage:image];
    return imageMessage;
}

+ (V5ControlMessage *)obtainControlMessageWithCode:(NSInteger)code
                                              argc:(NSInteger)argc
                                              argv:(NSString *)argv {
    V5ControlMessage *controlMessage = [[V5ControlMessage alloc] initWithCode:code
                                                                         argc:argc
                                                                         argv:argv];
    return controlMessage;
}

@end
