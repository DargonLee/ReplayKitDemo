//
//  SampleHandler.m
//  iOS10ReplayKitPlug
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//


#import "SampleHandler.h"
#import "SampleUploadHandler.h"

#define NOW (CACurrentMediaTime()*1000)

@interface SampleHandler()

@property (nonatomic, strong) SampleUploadHandler *tool;

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    NSLog(@"broadcastStartedWithSetupInfo");
    [self requireNetwork];
    self.tool = [SampleUploadHandler shareTool];
    self.speed = self.tool.speed;
    [self.tool prepareToStart:setupInfo];
    NSLog(@"------prepareToStart-------");
    
}

- (void)broadcastAnnotatedWithApplicationInfo:(NSDictionary *)applicationInfo
{
    NSLog(@"broadcastAnnotatedWithApplicationInfo");
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"broadcastPaused");
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"broadcastResumed");
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"broadcastFinished");
    [self.tool stop];

}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    NSLog(@"%@", sampleBuffer);
    switch (sampleBufferType) {
        case 4:
            // Handle video pixel buffe，截图直接生成PixelBuffer，而不是CMSampleBufferRef
      {
        [self.tool sendPixelBuffer:sampleBuffer];
      }
            break;
            
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
      {
        [self.tool sendVideoBuffer:sampleBuffer];
      }
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
      {
        [self.tool sendAudioBuffer:sampleBuffer];
      }
            break;
            
        default:
            break;
    }
    [self updateServiceInfo:@{}];
    
}

- (void)requireNetwork
{
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.baidu.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }] resume];
}

@end
