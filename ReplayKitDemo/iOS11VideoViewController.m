//
//  iOS11VideoViewController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/27.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS11VideoViewController.h"
#import "ProxyTimer.h"

#import <VideoToolbox/VideoToolbox.h>
#import <ReplayKit/ReplayKit.h>

@interface iOS11VideoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriterInput *micInput;

@property (nonatomic, assign) BOOL startedSession;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation iOS11VideoViewController

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
    [self initAssetWriter2];
}

- (void)timeCount
{
    self.timerLabel.text = [NSString stringWithFormat:@"%zd", self.count++];
}

- (void)initAssetWriter2
{
    int x = arc4random() % 100;
    NSString *fileName = [NSString stringWithFormat:@"%d",x];
    
    [self createReplaysFolder];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/Recoders/video%@.mov", [self documentDictionary], fileName];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];

    
    NSError *error = nil;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:fileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    self.assetWriter = assetWriter;
    
    
    NSLog(@"%@", error);
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecTypeH264,AVVideoCodecKey,
                                   @(size.width),AVVideoWidthKey,
                                   @(size.height),AVVideoHeightKey,
                                   nil];
    
    //初始化视频写入类
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoInput.expectsMediaDataInRealTime = YES;
    //将视频输入源加入
    if ([self.assetWriter canAddInput:_videoInput]) {
        [self.assetWriter addInput:_videoInput];
    }

    
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *audioSettings = @{
        AVEncoderBitRateKey : @(96000),
        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey : @(1),
        AVSampleRateKey : @(44100.0)
    };
    //初始化音频写入类
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _audioInput.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    if ([self.assetWriter canAddInput:_audioInput]) {
        [self.assetWriter addInput:_audioInput];
    }
}

- (IBAction)begin:(id)sender
{
    [self beginJustScreenRecorder];
}

- (IBAction)stop:(id)sender
{
    [self.videoInput markAsFinished];
    [self.audioInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        
    }];
    
    [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)beginJustScreenRecorder
{
    [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
    [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        //NSLog(@"%@",sampleBuffer);
        if (error) {
            NSLog(@"error:%@",error);
            return;
        }
        
        if (CMSampleBufferDataIsReady(sampleBuffer)) {
            if (self.assetWriter.status == AVAssetWriterStatusUnknown && bufferType == RPSampleBufferTypeVideo) {
                CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                //开始写入
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:startTime];
                self.startedSession = YES;
            }
            
            if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                NSLog(@"writer error %@", self.assetWriter.error.localizedDescription);
                return;
            }
            
            if (bufferType == RPSampleBufferTypeVideo) {
                if (self.videoInput.readyForMoreMediaData == YES && self.startedSession == YES) {
                    NSLog(@"写入[视频]数据");
                    [self.videoInput appendSampleBuffer:sampleBuffer];
                }
            }
            if (bufferType == RPSampleBufferTypeAudioMic) {
                if (self.audioInput.readyForMoreMediaData == YES) {
                    NSLog(@"写入=音频=数据");
                    [self.audioInput appendSampleBuffer:sampleBuffer];
                    
                }
            }
        }
        
    } completionHandler:^(NSError * _Nullable error) {
        NSLog(@"error:%@",error);
    }];
}

- (void)createReplaysFolder
{
    NSString *documentDirectoryPath = [self documentDictionary];
    
    NSString *replayDirectoryPath = [documentDirectoryPath stringByAppendingString:@"/Recoders"];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:replayDirectoryPath]) {
        [fileMgr createDirectoryAtPath:replayDirectoryPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
}

- (NSString *)documentDictionary
{
    return [(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)) objectAtIndex:0];
}

@end
