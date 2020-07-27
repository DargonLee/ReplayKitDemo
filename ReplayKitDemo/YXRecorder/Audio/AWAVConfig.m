/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWAVConfig.h"

@implementation AWAudioConfig
- (instancetype)init
{
    self = [super init];
    if (self) {
        _bitRate = 100000;
        _channelCount = 1;
        _sampleSize = 16;
        _sampleRate = 44100;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    AWAudioConfig *audioConfig = [[AWAudioConfig alloc] init];
    audioConfig.bitRate = _bitRate;
    audioConfig.channelCount = _channelCount;
    audioConfig.sampleRate = _sampleRate;
    audioConfig.sampleSize = _sampleSize;
    return audioConfig;
}

@end

