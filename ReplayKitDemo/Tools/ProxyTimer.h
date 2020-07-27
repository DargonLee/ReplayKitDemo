//
//  ProxyTimer.h
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProxyObject : NSProxy

@property (weak, nonatomic) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end


@interface ProxyTimer : NSObject

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;

@end

NS_ASSUME_NONNULL_END
