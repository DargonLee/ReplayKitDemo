/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

/*
 使用系统接口捕获视频，没有进行美颜。
 系统捕获音视频的详细过程。
 */

#import <Foundation/Foundation.h>
#import "AWAVCapture.h"
#import <CoreMedia/CMSampleBuffer.h>

@class AWSystemAVCapture;
@protocol AWSystemAVCaptureDelegate <NSObject>

- (void)systemAVCapture:(AWSystemAVCapture *)audioCapture didReciveSampleBuffer:(CMSampleBufferRef)buffer;

@end

@interface AWSystemAVCapture : AWAVCapture
@property (nonatomic, weak) id<AWSystemAVCaptureDelegate> delegate;
@end
