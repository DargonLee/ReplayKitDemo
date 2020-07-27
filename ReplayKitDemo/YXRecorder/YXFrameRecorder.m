//
//  YXFrameRecorder.m
//  ObjectiveCTools
//
//  Created by HPCL20190110 on 2019/3/26.
//  Copyright © 2019 HPCL20190110. All rights reserved.
//

#import "YXFrameRecorder.h"
#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>
#include "libyuv.h"
#import <objc/runtime.h>

#define aw_stride(wid) ((wid % 16 != 0) ? ((wid) + 16 - (wid) % 16): (wid))

@interface YXFrameRecorder() {
    unsigned char *y_buffer;
    unsigned char *uv_buffer;
}

/// 每一帧间隔的时间
@property (nonatomic, assign) NSInteger frameSpace;

/// 视频帧间隔时间累加
@property (nonatomic, assign) NSInteger indexOfFrameTimePoint;

/// 定时器,截屏
@property (nonatomic, strong) dispatch_source_t timer;

/// 是否正在录制
@property (nonatomic, assign) BOOL isRecording;

/// 标记是否重复点击开始
@property (nonatomic, assign) BOOL isRestart;

/// 当前屏幕
@property (nonatomic, strong) UIWindow *window;
/// 屏幕尺寸
@property (nonatomic, assign) CGSize screenSize;

/// 屏幕缩放比例
@property (nonatomic, assign) CGFloat screenScale;

@end


@implementation YXFrameRecorder

- (instancetype)init {
    
    if (self = [super init]) {
        
        _isRecording = NO;
        
        _isRestart = NO;
        
        _frameRate = 20;
        
        //100毫秒执行一次, 1 秒 定时器执行 10次
        _frameSpace = 1000 / _frameRate;
        
        _window = [UIApplication sharedApplication].keyWindow;
        
        _screenSize = _window.bounds.size;
        
        _screenScale = [UIScreen mainScreen].scale;
    }
    
    return self;
}

/// 重写set方法, 设置帧率 和 间隔
- (void)setFrameRate:(NSInteger)frameRate {
    _frameRate = frameRate;
    _frameSpace = 1000 / _frameRate;
}


- (void)dealloc {
    
    if (_timer) {
        dispatch_source_cancel(_timer);
    }
    
    if (!y_buffer) {
        free(y_buffer);
    }
    if (!uv_buffer) {
        free(uv_buffer);
    }
    
    NSLog(@"⭕️ 成功释放 %s", __func__);
}

#pragma mark - 开始录制
/// 开始录制
- (BOOL)startRecord {
    
    if (_isRestart) { //不允许重复点击开始
        NSLog(@"正在录制中!");
        return NO;
    }
    
    if (_isRecording) {
        
        NSLog(@"⭕️ 视频 正在录制中");
        return NO;
        
    } else {
        _isRecording = YES;
        
        _isRestart = YES;
        
        _indexOfFrameTimePoint = 0;
        
        NSLog(@"✅ 视频 已开始录制");
        
        __weak typeof(self) weakself = self;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        NSTimeInterval interval = NSEC_PER_MSEC * _frameSpace;
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, interval, 0);
        dispatch_source_set_event_handler(_timer, ^{
            [weakself drawFrame];
        });
        dispatch_resume(_timer);
        
        return YES;
    }
}


#pragma mark - 暂停录制
/// 暂停录制
- (void)pauseRecord {
    
    if (_isRecording) { //处于正在录制
        
        _isRecording = NO;
        NSLog(@"⭕️ 视频 录制暂停");
        
    } else {  //处于暂停
        NSLog(@"⭕️ 视频录制 已经 处于暂停");
    }
}


#pragma mark - 继续录制
/// 继续录制
- (void)resumeRecord {
    if (_isRecording) { //处于正在录制
        NSLog(@"⭕️ 视频 正在录制中");
    } else {
        _isRecording = YES;
        NSLog(@"♓️ 视频 录制继续");
    }
}


#pragma mark - 结束录制
/// 结束录制
- (void)stopRecord {
    
    if (_isRestart == NO) {  //表示还没有开始录制, 点击结束不做操作
        NSLog(@"⭕️ 录屏 已经 处于结束");
        return;
    }
    
    NSLog(@"✅ 视频录制结束");
    _isRecording = NO;
    _isRestart = NO;
    
    dispatch_source_cancel(_timer);
}

#pragma mark - 写入视频帧
///写入视频帧
- (void)writeVideoFrameAtTime:(CMTime)time addImage:(CGImageRef)newImage {
    //生成YUV格式视频
    [self writeYUVVideoFrameAtTime:time addImage:newImage];
}
 
- (void)writeYUVVideoFrameAtTime:(CMTime)time addImage:(CGImageRef)newImage {
    // yuv 格式的数据背景没花纹
    CVPixelBufferRef pixelBuffer = [self yuvBufferFromCGImage:newImage];
    
    // rgb格式的数据背景有花纹
    //CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:newImage];
    [_delegate frameRecorder:self didReciveImageBuffer:pixelBuffer];
    
#ifdef DEBUG
//    UIImage *image = [self imageFromYuvBuffer:pixelBuffer];
#endif
    
    // 清理掉数据,内存暴涨
    CVPixelBufferRelease(pixelBuffer);
    CGImageRelease(newImage);
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];

    CVPixelBufferRef pxbuffer = NULL;

    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);

    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,frameWidth,frameHeight,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options, &pxbuffer);

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8,CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);

    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0,frameWidth,frameHeight),  image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}

- (UIImage *)imageFromYuvBuffer:(CVPixelBufferRef)pixelBuffer {
    CGImageRef image = NULL;
    OSStatus status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &image);
    
    UIImage * res = nil;
    if (status == noErr) {
        res = [UIImage imageWithCGImage:image];
    }
    CGImageRelease(image);

    return res;
}

- (CVPixelBufferRef)yuvBufferFromCGImage:(CGImageRef)newImage {
    CGDataProviderRef provider = CGImageGetDataProvider(newImage);
    CFDataRef pixelData = CGDataProviderCopyData(provider);
    const unsigned char *data = CFDataGetBytePtr(pixelData);
    
    size_t frameWidth = CGImageGetWidth(newImage);
    size_t frameHeight = CGImageGetHeight(newImage);
    CFRelease(pixelData);
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
    size_t width = aw_stride(CVPixelBufferGetWidth(pixelBuffer));
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    size_t wh = width * height;
    
    if (!y_buffer) {
        y_buffer = calloc(wh, 1);
    }
    if (!uv_buffer) {
        uv_buffer = calloc(wh / 2, 1);
    }
    
    int ret = ARGBToNV12(data, width * 4, y_buffer, width, uv_buffer, (width + 1) / 2 * 2, width, height);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yPlane, y_buffer, wh);
    
    uint8_t *uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uvPlane, uv_buffer, wh / 2);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (void)drawFrame {
    
    if (!_isRecording) {  //已处于暂停的时候就停止视频的写入
        return;
    }
    
    UIGraphicsBeginImageContextWithOptions(_screenSize, NO, _screenScale);
    
    // YES CPU会递增 NO不会 动画都能捕捉到
    [_window drawViewHierarchyInRect:_window.bounds afterScreenUpdates:NO];
    
    //动画捕捉不到 CPU不会递增
    //[_window.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGImageRef cgImage = CGImageCreateCopy(image.CGImage);
    
    image = nil;
    
    [self writeVideoFrameAtTime:CMTimeMake(_indexOfFrameTimePoint, 1000) addImage:cgImage];
    
    _indexOfFrameTimePoint += _frameSpace;
}

@end

