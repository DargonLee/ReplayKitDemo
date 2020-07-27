//
//  iOS12ViewController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/22.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS12ViewController.h"
#import "ProxyTimer.h"
#import "SampleHandler.h"

#import <ReplayKit/ReplayKit.h>

API_AVAILABLE(ios(12.0))
@interface iOS12ViewController ()
@property (nonatomic, strong) RPSystemBroadcastPickerView *broadPickerView;
@property (nonatomic, assign) NSUInteger count;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation iOS12ViewController

- (void)dealloc
{
    NSLog(@"iOS9CaptureViewController - dealloc");
    [self.timer invalidate];
    self.timer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.timer = [ProxyTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeCount) userInfo:nil repeats:YES];  
    
    if (@available(iOS 12.0, *)) {
        _broadPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(40, 60, 100, 100)];
        _broadPickerView.preferredExtension = @"com.uusafe.sdk.iOS10ReplayKitPlug";
        [self.view addSubview:_broadPickerView];
    }

}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}


@end
