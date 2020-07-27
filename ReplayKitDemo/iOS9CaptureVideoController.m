//
//  iOS9CaptureVideoController.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/21.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "iOS9CaptureVideoController.h"
#import "SampleHandler.h"

@interface iOS9CaptureVideoController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    dispatch_queue_t videoProcessingQueue;
    dispatch_queue_t audioProcessingQueue;
}
@property (weak, nonatomic) IBOutlet UIView *liveView;
@property (nonatomic, strong) AVCaptureSession *session;    // 音视频录制期间管理者
@property (nonatomic, strong) AVCaptureDevice *videoDevice; // 视频管理者, (用来操作所闪光灯, 聚焦, 摄像头切换)
@property (nonatomic, strong) AVCaptureDevice *audioDevice; // 音频管理者
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;   // 视频输入数据的管理对象
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;   // 音频输入数据的管理对象
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput; // 视频输出数据的管理者
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput; // 音频输出数据的管理者

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer; // 用来展示视频的图像
@property (nonatomic, strong) SampleHandler *sampleHandler;

@end

@implementation iOS9CaptureVideoController

- (void)dealloc
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    [self.videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
    [self.audioOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
    [_sampleHandler broadcastFinished];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _sampleHandler = [[SampleHandler alloc] init];
    videoProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    audioProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    [self checkDeviceAuth];
}
// 检查是否授权摄像头的使用权限
- (void)checkDeviceAuth {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:   // 已授权
            NSLog(@"已授权");
            [self initAVCaptureSession];
            break;
        case AVAuthorizationStatusNotDetermined:    // 用户尚未进行允许或者拒绝,
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    NSLog(@"已授权");
                    [self initAVCaptureSession];
                } else {
                    NSLog(@"用户拒绝授权摄像头的使用, 返回上一页, 请打开--> 设置 -- > 隐私 --> 通用等权限设置");
                }
            }];
        }
            break;
        default:
        {
            NSLog(@"用户尚未授权摄像头的使用权");
        }
            break;
    }
}

// 初始化 管理者
- (void)initAVCaptureSession {
    self.session = [[AVCaptureSession alloc] init];
    // 设置录像的分辨率
    // 先判断是被是否支持要设置的分辨率
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        // 如果支持则设置
        [self.session canSetSessionPreset:AVCaptureSessionPreset1280x720];
    } else if ([self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
        [self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540];
    } else if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.session canSetSessionPreset:AVCaptureSessionPreset640x480];
    }
    // 开始配置
    [self.session beginConfiguration];
    // 初始化视频管理
    self.videoDevice = nil;
    // 创建摄像头类型数组
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    // 便利管理抓捕道德所有支持制定类型的 设备集合
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront) {
            self.videoDevice = device;
        }
    }
    // 视频
    [self videoInputAndOutput];
    
    // 音频
    [self audioInputAndOutput];
    
    // 录制的同时播放
    [self initPreviewLayer];
    
    // 提交配置
    [self.session commitConfiguration];
}

// 视频输入输出
- (void)videoInputAndOutput {
    NSError *error;
    // 视频输入
    // 初始化 根据输入设备来初始化输出对象
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
    if (error) {
        NSLog(@"-- 摄像头出错 -- %@", error);
        return;
    }
    // 将输入对象添加到管理者 -- AVCaptureSession 中
    // 先判断是否能搞添加输入对象
    if ([self.session canAddInput:self.videoInput]) {
        // 管理者能够添加 才可以添加
        [self.session addInput:self.videoInput];
    }
    
    // 视频输出
    // 初始化 输出对象
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    // 是否允许卡顿时丢帧
    self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
    if ([self supportsFastTextureUpload])
    {
        // 是否支持全频色彩编码 YUV 一种色彩编码方式, 即YCbCr, 现在视频一般采用该颜色空间, 可以分离亮度跟色彩, 在不影响清晰度的情况下来压缩视频
        BOOL supportsFullYUVRange = NO;
        
        // 获取输出对象 支持的像素格式
        NSArray *supportedPixelFormats = self.videoOutput.availableVideoCVPixelFormatTypes;
        
        for (NSNumber *currentPixelFormat in supportedPixelFormats)
        {
            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            {
                supportsFullYUVRange = YES;
            }
        }
        
        // 根据是否支持 来设置输出对象的视频像素压缩格式,
        if (supportsFullYUVRange)
        {
            [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
        else
        {
            [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
    }
    else
    {
        [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    
    // 设置代理
    [self.videoOutput setSampleBufferDelegate:self queue:videoProcessingQueue];
    // 判断管理是否可以添加 输出对象
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
        AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        // 设置视频的方向
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        // 视频稳定设置
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        connection.videoScaleAndCropFactor = connection.videoMaxScaleAndCropFactor;
    }
}


// 音频输入输出
- (void)audioInputAndOutput {
    NSError *jfError;
    // 音频输入设备
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    // 音频输入对象
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioDevice error:&jfError];
    if (jfError) {
        NSLog(@"-- 录音设备出错 -- %@", jfError);
    }
    
    // 将输入对象添加到 管理者中
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    // 音频输出对象
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    // 将输出对象添加到管理者中
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
    // 设置代理
    [self.audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
}

// 播放同时进行播放
- (void)initPreviewLayer {
    [self.view layoutIfNeeded];
    // 初始化对象
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = self.view.layer.bounds;
    self.previewLayer.connection.videoOrientation = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
    
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.position = CGPointMake(self.liveView.frame.size.width*0.5,self.liveView.frame.size.height*0.5);
    
    CALayer *layer = self.liveView.layer;
    layer.masksToBounds = true;
    [layer addSublayer:self.previewLayer];
}

#pragma mark 返回上一级
- (IBAction)backAction:(id)sender
{
    [self.session stopRunning];
    [_sampleHandler broadcastFinished];
}

#pragma mark 切换摄像头
- (IBAction)change:(id)sender
{
    //获取摄像头列表
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //获取当前摄像头方向
    AVCaptureDevicePosition currentPosition = self.videoDevice.position;
    //转换摄像头
    if (currentPosition == AVCaptureDevicePositionBack){
        currentPosition = AVCaptureDevicePositionFront;
    }else{
        currentPosition = AVCaptureDevicePositionBack;
    }
    //获取到新的AVCaptureDevice
    NSArray *captureDeviceArray = [devices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", currentPosition]];
    AVCaptureDevice *device = captureDeviceArray.firstObject;
    self.videoDevice = device;
    //开始配置
    [self.session beginConfiguration];
    //构造一个新的AVCaptureDeviceInput的输入端
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //移除掉就的AVCaptureDeviceInput
    [self.session removeInput:self.videoInput];
    //将新的AVCaptureDeviceInput添加到AVCaptureSession中
    if ([self.session canAddInput:newInput]){
        [self.session addInput:newInput];
        self.videoInput = newInput;
    }
    //提交配置
    [self.session commitConfiguration];
    //重新获取连接并设置视频的方向、是否镜像
    AVCaptureConnection *conn = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (device.position == AVCaptureDevicePositionFront && conn.supportsVideoMirroring){
        conn.videoMirrored = YES;
    }
    
}

//修改fps
-(void)updateFps:(NSInteger)fps
{
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

#pragma mark 开始直播
- (IBAction)begin:(id)sender
{
    [_sampleHandler broadcastStartedWithSetupInfo:nil];
    [self.session startRunning];
}


#pragma mark --  AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (captureOutput == self.audioOutput) {
        [_sampleHandler processSampleBuffer:sampleBuffer withType:RPSampleBufferTypeAudioMic];
    } else {
        [_sampleHandler processSampleBuffer:sampleBuffer withType:RPSampleBufferTypeVideo];
    }
}


#pragma mark - Methods
// 是否支持快速纹理更新
- (BOOL)supportsFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
#endif
}

@end
