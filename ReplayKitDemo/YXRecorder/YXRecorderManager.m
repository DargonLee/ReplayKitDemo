//
//  YXRecorderManager.m
//  ObjectiveCTools
//
//  Created by HPCL20190110 on 2019/3/22.
//  Copyright © 2019 HPCL20190110. All rights reserved.
//

#import "YXRecorderManager.h"
#import <UIKit/UIKit.h>
#import "YXFrameRecorder.h"
#import "AWSystemAVCapture.h"

@interface YXRecorderManager() <YXFrameRecorderDelegate, AWSystemAVCaptureDelegate>

/// 音频录制工具
@property (nonatomic, strong) AWSystemAVCapture *awAudioRecorder;

/// 视频录制工具
@property (nonatomic, strong) YXFrameRecorder *yxFrameRecorder;

@end


@implementation YXRecorderManager

- (instancetype)init {
    if (self = [super init]) {
        
        [self demandForRight];
        
        AWSystemAVCapture * sysAVCapture = [[AWSystemAVCapture alloc] initWithAudioConfig:[[AWAudioConfig alloc] init]];
        sysAVCapture.delegate = self;
        _awAudioRecorder = sysAVCapture;
        
        YXFrameRecorder *yxFrameRecorder = [[YXFrameRecorder alloc] init];
        yxFrameRecorder.delegate = self;
        _yxFrameRecorder = yxFrameRecorder;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionEnterBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}


///进入后台的时候停止录制,防止崩溃  真机: 只能保存到沙盒,无法接连保存到相册  模拟器: 可以接连保存到相册
- (void)actionEnterBackGround {
    
    [self.yxFrameRecorder stopRecord];
    [self.awAudioRecorder stopCapture];
}


/// 设置帧率
- (void)setFrameRate:(YXFrameRate)rate {
    
    if (rate == YXFrameRate10 || rate == YXFrameRate15 || rate == YXFrameRate20 || rate == YXFrameRate25 || rate == YXFrameRate30) {
        self.yxFrameRecorder.frameRate = rate;
    } else {
        self.yxFrameRecorder.frameRate = YXFrameRate10;
    }
}


- (void)demandForRight {
    // 麦克风权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        AVAuthorizationStatus avAuth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (avAuth == AVAuthorizationStatusAuthorized) {
            NSLog(@"✅ 麦克风已授权!");
        } else {
            NSLog(@"❌ 没有麦克风权限");
        }
    }];
}


/// 开始录制
- (void)startRecord {
    [self.yxFrameRecorder startRecord];
    [self.awAudioRecorder startCapture];
}

/// 暂停录制
- (void)pauseRecord {
    [self.yxFrameRecorder pauseRecord];
}

/// 继续录制
- (void)resumeRecord {
    [self.yxFrameRecorder resumeRecord];
}

/// 结束录制
- (void)stopRecord {
    [self.yxFrameRecorder stopRecord];
    [self.awAudioRecorder stopCapture];
}


#pragma mark - 视频代理 YXFrameRecorderDelegate
- (void)frameRecorder:(YXFrameRecorder *)manager didReciveImageBuffer:(CVPixelBufferRef)buffer {
    [_delegate recorderManager:self didReciveSampleBuffer:nil orImageBuffer:buffer type:UUSampleBufferTypeVideo];
}

#pragma mark
- (void)systemAVCapture:(AWSystemAVCapture *)audioCapture didReciveSampleBuffer:(CMSampleBufferRef)buffer {
    [_delegate recorderManager:self didReciveSampleBuffer:buffer orImageBuffer:nil type:UUSampleBufferTypeAudioMic];
}


#pragma mark - 销毁对象
- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"⭕️ 成功释放 %s", __func__);
}

@end
