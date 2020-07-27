//
//  ProxyTimer.m
//  ReplayKitDemo
//
//  Created by Harlans on 2020/7/16.
//  Copyright © 2020 Harlans. All rights reserved.
//

#import "ProxyTimer.h"

@implementation ProxyObject

+ (instancetype)proxyWithTarget:(id)target
{
    ProxyObject *proxy = [[self class] alloc];
    proxy.target = target;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL sel = [invocation selector];
    if ([self.target respondsToSelector:sel]) {
        [invocation invokeWithTarget:self.target];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.target respondsToSelector:aSelector];
}

@end

@implementation ProxyTimer

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo
{
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:ti target:[ProxyObject proxyWithTarget: aTarget] selector:aSelector userInfo:userInfo repeats:yesOrNo];
    return timer;
}

@end
