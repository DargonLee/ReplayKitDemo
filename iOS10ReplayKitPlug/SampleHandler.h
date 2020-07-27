//
//  SampleHandler.h
//  iOS10ReplayKitPlug
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>

typedef NS_ENUM(NSInteger, UUSampleBufferType) {
    UUSampleBufferTypeVideo = 1,
    UUSampleBufferTypeAudioApp,
    UUSampleBufferTypeAudioMic,
};

@interface SampleHandler : RPBroadcastSampleHandler

@property (nonatomic, copy) NSString *speed;

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo;

- (void)broadcastPaused;

- (void)broadcastResumed;

- (void)broadcastFinished;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

- (void)requireNetwork;

@end
