//
//  iOS10ViewController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS10ViewController.h"
#import "ProxyTimer.h"

#import <ReplayKit/ReplayKit.h>
API_AVAILABLE(ios(10.0))
@interface iOS10ViewController ()<RPBroadcastActivityViewControllerDelegate,RPBroadcastControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) RPBroadcastActivityViewController *broadcastAVC;
@property (nonatomic, strong) RPBroadcastController *broadcastController;

@end

@implementation iOS10ViewController


- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"iOS10ViewController - dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.timer = [ProxyTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeCount) userInfo:nil repeats:YES];
}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}

- (IBAction)begin:(id)sender
{
    if (@available(iOS 10.0, *)) {
        [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
        
        if (![RPScreenRecorder sharedRecorder].isRecording) {
            [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"RPBroadcast err %@", [error localizedDescription]);
                }
                broadcastActivityViewController.delegate = self;
                [self presentViewController:broadcastActivityViewController animated:YES completion:nil];
            }];
        } else {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop Live?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self stop:nil];
            }];
            UIAlertAction *cancle = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alert addAction:ok];
            [alert addAction:cancle];
            [self presentViewController:alert animated:YES completion:nil];
            
        }
    }
    
}

- (IBAction)stop:(id)sender
{
    [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"finishBroadcastWithHandler:%@", error.localizedDescription);
        }
    }];
}

#pragma mark - RPBroadcastActivityViewControllerDelegate
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(RPBroadcastController *)broadcastController error:(NSError *)error
API_AVAILABLE(ios(10.0))
{
    [broadcastActivityViewController dismissViewControllerAnimated:YES
                                                        completion:nil];
    NSLog(@"BundleID %@", broadcastController.broadcastExtensionBundleID);
    self.broadcastController = broadcastController;
    self.broadcastController.delegate = self;
    if (error) {
        NSLog(@"BAC: %@ didFinishWBC: %@, err: %@",
              broadcastActivityViewController,
              broadcastController,
              error);
        return;
    }

    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"-----start success----");
            // 这里可以添加camerPreview
        } else {
            NSLog(@"startBroadcast:%@",error.localizedDescription);
        }
    }];
}

// Watch for service info from broadcast service
- (void)broadcastController:(RPBroadcastController *)broadcastController
       didUpdateServiceInfo:(NSDictionary <NSString *, NSObject <NSCoding> *> *)serviceInfo
API_AVAILABLE(ios(10.0))
{
    NSLog(@"didUpdateServiceInfo: %@", serviceInfo);
}

// Broadcast service encountered an error
- (void)broadcastController:(RPBroadcastController *)broadcastController
         didFinishWithError:(NSError *)error API_AVAILABLE(ios(10.0))
{
    NSLog(@"didFinishWithError: %@", error);
}

- (void)broadcastController:(RPBroadcastController *)broadcastController didUpdateBroadcastURL:(NSURL *)broadcastURL API_AVAILABLE(ios(10.0))
{
    NSLog(@"---didUpdateBroadcastURL: %@",broadcastURL);
}
     
@end
