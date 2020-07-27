/*
 copyright 2016 wanghongyu.
 The project page：https://github.com/hardman/AWLive
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

/*
 视频捕获基类。将捕获的音/视频数据送入 encodeSampleQueue串行队列进行编码，然后送入sendSampleQueue队列发送至rtmp接口。
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AWAVConfig.h"


@interface AWAVCapture : NSObject
//配置
@property (nonatomic, strong) AWAudioConfig *audioConfig;

//是否正在录制
@property (nonatomic, assign, getter=isCapturing) BOOL capturing;;

//初始化
-(instancetype) initWithAudioConfig:(AWAudioConfig *)audioConfig;

//初始化
-(void) onInit;

//停止capture
-(void) stopCapture;

//停止
-(void) onStopCapture;

//用户开始
-(void) onStartCapture;

//开始capture
-(BOOL) startCapture;

@end
