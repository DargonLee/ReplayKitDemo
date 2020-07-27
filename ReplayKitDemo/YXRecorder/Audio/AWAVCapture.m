/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWAVCapture.h"

__weak static AWAVCapture *sAWAVCapture = nil;

@interface AWAVCapture()

//进入后台后，不推视频流
@property (nonatomic, assign) BOOL inBackground;
@end

@implementation AWAVCapture

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:audioConfig to init" reason:nil userInfo:nil];
}

-(instancetype) initWithAudioConfig:(AWAudioConfig *)audioConfig{
    self = [super init];
    if (self) {
        self.audioConfig = audioConfig;
        sAWAVCapture = self;
        [self onInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

-(void) onInit{}

-(void) willEnterForeground{
    self.inBackground = NO;
}

-(void) didEnterBackground{
    self.inBackground = YES;
}

//修改fps
-(void) updateFps:(NSInteger) fps{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *vDevice in videoDevices) {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps) {
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}

-(BOOL) startCapture {
    
    if (!self.audioConfig) {
        NSLog(@"one of videoConfig and audioConfig must be NON-NULL");
        return NO;
    }
    
    self.capturing = YES;
    [self onStartCapture];
    
    return YES;
}

-(void) stopCapture{
    self.capturing = NO;
    [self onStopCapture];
}

-(void) onStopCapture{}

-(void) onStartCapture{}

@end
