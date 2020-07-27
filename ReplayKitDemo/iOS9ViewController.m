//
//  iOS9ViewController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS9ViewController.h"
#import "ProxyTimer.h"

#import <ReplayKit/ReplayKit.h>

@interface iOS9ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation iOS9ViewController

- (void)dealloc
{
    [self.timer invalidate];
    NSLog(@"iOS9ViewController - dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.timer = [ProxyTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeCount) userInfo:nil repeats:YES];
    if (![[RPScreenRecorder sharedRecorder] isCameraEnabled]) {
        [[RPScreenRecorder sharedRecorder] setCameraEnabled:YES];
    }
    [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
    
    UIView *view = [RPScreenRecorder sharedRecorder].cameraPreviewView;
    view.frame = CGRectMake(10, 10, 300, 300);
    [self.view addSubview:view];
}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}

- (IBAction)begin:(id)sender
{
    if ([[RPScreenRecorder sharedRecorder] isAvailable]) {
        [[RPScreenRecorder sharedRecorder] startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
            
        }];
    }
}

- (IBAction)stop:(id)sender
{
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController *previewViewController, NSError *  error){
        
        [self presentViewController:previewViewController animated:YES completion:^{
            NSLog(@"presentViewController");
        }];
    }];
}


@end
