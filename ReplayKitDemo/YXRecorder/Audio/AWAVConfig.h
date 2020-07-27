/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

/*
 音视频配置文件，其中有些值有固定范围，不能随意填写。
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureDevice.h>

@interface AWAudioConfig : NSObject<NSCopying>
@property (nonatomic, assign) NSInteger bitRate;//可自由设置
@property (nonatomic, assign) NSInteger channelCount;//可选 1 2
@property (nonatomic, assign) NSInteger sampleRate;//可选 44100 22050 11025 5500
@property (nonatomic, assign) NSInteger sampleSize;//可选 16 8

@end
