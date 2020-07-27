//
//  iOS11ViewController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/17.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS11ViewController.h"
#import "ProxyTimer.h"
#import "SampleHandler.h"

#import <VideoToolbox/VideoToolbox.h>
#import <ReplayKit/ReplayKit.h>


@interface iOS11ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) SampleHandler *sampleHandler;

@end

@implementation iOS11ViewController

- (void)dealloc
{
    NSLog(@"iOS9CaptureViewController - dealloc");
    [self.timer invalidate];
    self.timer = nil;
    [self stop:nil];
    [_sampleHandler broadcastFinished];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.timer = [ProxyTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeCount) userInfo:nil repeats:YES];
    _sampleHandler = [[SampleHandler alloc] init];
    self.speedLabel.text = _sampleHandler.speed;
    
}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}

- (IBAction)begin:(id)sender
{
    [self beginRPScreenRecorderAndRTMP];
}

- (void)beginRPScreenRecorderAndRTMP
{
    if (@available(iOS 10.0, *)) {
        UIView *view = [RPScreenRecorder sharedRecorder].cameraPreviewView;
        view.frame = CGRectMake(0, 0, 300, 300);
        [self.view addSubview:view];
        [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
    }
    
    [_sampleHandler broadcastStartedWithSetupInfo:nil];
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder] setCameraEnabled:YES];
        [[RPScreenRecorder sharedRecorder] setCameraPosition:RPCameraPositionFront];
        if ([[RPScreenRecorder sharedRecorder] isAvailable]) {
            [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                NSLog(@"%@", sampleBuffer);
                [self.sampleHandler processSampleBuffer:sampleBuffer withType:bufferType];
            } completionHandler:^(NSError * _Nullable error) {
                NSLog(@"%@", error);
            }];
        }
    }
    
}

- (IBAction)stop:(id)sender
{
    [self.sampleHandler broadcastFinished];
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
           
        }];
    }
}

- (NSString *)documentDictionary
{
    return [(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)) objectAtIndex:0];
}

@end
