//
//  SampleUploadHandler.h
//  iOS10ReplayKitPlug
//
//  Created by Harlans on 2020/7/21.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleUploadHandler : NSObject

@property (nonatomic, copy) NSString *speed;

+ (instancetype)shareTool;
- (void)prepareToStart:(NSDictionary *)dict;

- (void)stop;
- (void)sendAudioBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)sendVideoBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
