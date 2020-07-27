/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWSystemAVCapture.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AWSystemAVCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

//音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;

//输出数据接收
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

//会话
@property (nonatomic, strong) AVCaptureSession *captureSession;

@end

@implementation AWSystemAVCapture


-(void)onInit{
    [self createCaptureDevice];
    [self createOutput];
    [self createCaptureSession];
}

//初始化视频设备
-(void) createCaptureDevice{
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
}

//创建会话
-(void) createCaptureSession{
    AVCaptureSession *captureSession = [AVCaptureSession new];
    
    [captureSession beginConfiguration];
    
    if ([captureSession canAddInput:_audioInputDevice]) {
        [captureSession addInput:_audioInputDevice];
    }
    
    if([captureSession canAddOutput:_audioDataOutput]){
        [captureSession addOutput:_audioDataOutput];
    }
    
    [captureSession commitConfiguration];
    self.captureSession = captureSession;
}

//销毁会话
-(void) destroyCaptureSession{
    if (_captureSession) {
        [_captureSession removeInput:_audioInputDevice];
        [_captureSession removeOutput:_audioDataOutput];
    }
    _captureSession = nil;
}

- (void)onStartCapture {
    [_captureSession startRunning];
}

- (void)onStopCapture {
    [_captureSession stopRunning];
}

-(void) createOutput{
    
    dispatch_queue_t captureQueue = dispatch_queue_create("aw.capture.queue", DISPATCH_QUEUE_SERIAL);
    
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.isCapturing) {
        if ([_audioDataOutput isEqual:captureOutput]){
            [_delegate systemAVCapture:self didReciveSampleBuffer:sampleBuffer];
        }
    }
}

@end
