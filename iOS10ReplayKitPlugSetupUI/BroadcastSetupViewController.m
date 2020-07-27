//
//  BroadcastSetupViewController.m
//  iOS10ReplayKitPlugSetupUI
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "BroadcastSetupViewController.h"

@implementation BroadcastSetupViewController

// Call this method when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup {
    NSLog(@"userDidFinishSetup");
   NSURL *broadcastURL = [NSURL URLWithString:@"rtmp://192.168.3.69/live/stream"];
    
    // 所有需要的信息都可以通过setupInfo传递到Extension 的 SampleHandler里
    NSDictionary *setupInfo = @{ @"broadcastName" : @"example" };
    
    // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    [self.extensionContext completeRequestWithBroadcastURL:broadcastURL setupInfo:setupInfo];
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1 userInfo:nil]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *startBtn = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(100, 100, 100, 100)];
        [button setBackgroundColor:[UIColor greenColor]];
        [button setTitle:@"开始直播" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(userDidFinishSetup) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    UIButton *closeBtn = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(230, 100, 100, 100)];
        [button setBackgroundColor:[UIColor redColor]];
        [button setTitle:@"取消" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(userDidCancelSetup) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    [self.view addSubview:startBtn];
    [self.view addSubview:closeBtn];
}

- (void)viewWillAppear:(BOOL)animated {
     [super viewDidAppear:animated];
    NSLog(@"viewWillAppear");
}

@end
