//
//  iOS9CaptureViewController.m
//  ObjectiveCTools
//
//  Created by HPCL20190110 on 2019/3/27.
//  Copyright © 2019 ChinaRapidFinance. All rights reserved.
//

#import "iOS9CaptureViewController.h"
#import "YXRecorderManager.h"
#import "SampleHandler.h"
#import "ProxyTimer.h"

@interface iOS9CaptureViewController () <YXRecorderManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, strong) YXRecorderManager *recorderManager;
@property (nonatomic, strong) SampleHandler *sampleHandler;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation iOS9CaptureViewController


- (void)dealloc
{
    NSLog(@"iOS9CaptureViewController - dealloc");
    [self.timer invalidate];
    self.timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stop:nil];
    [_sampleHandler broadcastFinished];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.timer = [ProxyTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeCount) userInfo:nil repeats:YES];
    //预先初始化,防止卡顿
    _recorderManager = [[YXRecorderManager alloc] init];
    _recorderManager.delegate = self;
    
    _sampleHandler = [[SampleHandler alloc] init];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [_sampleHandler broadcastStartedWithSetupInfo:nil];
}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}

- (IBAction)start:(id)sender{
    [_recorderManager startRecord];
}

- (IBAction)pause:(id)sender {
    [_recorderManager pauseRecord];
    [_sampleHandler broadcastPaused];
}

- (IBAction)resume:(id)sender {
    [_recorderManager resumeRecord];
    [_sampleHandler broadcastResumed];
}

- (IBAction)stop:(id)sender {
    [_recorderManager stopRecord];
    [_sampleHandler broadcastFinished];
}

- (void)recorderManager:(YXRecorderManager *)manager didReciveSampleBuffer:(CMSampleBufferRef)buffer orImageBuffer:(CVPixelBufferRef)imageBuffer type:(UUSampleBufferType)type
{
    if (imageBuffer) {
        [_sampleHandler processSampleBuffer:imageBuffer withType:4];
    } else {
        [_sampleHandler processSampleBuffer:buffer withType:RPSampleBufferTypeAudioMic];
    }
}

- (void)didEnterBackground
{
    
}

@end

