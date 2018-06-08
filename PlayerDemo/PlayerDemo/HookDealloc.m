//
//  HookDealloc.m
//  PlayerDemo
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "HookDealloc.h"
#import <objc/runtime.h>

typedef id(*_IMP)(id, SEL, ...);
typedef void(*_VIMP)(id, SEL, ...);

@implementation HookDealloc

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Method method = class_getInstanceMethod(self, @selector(init));
//        _VIMP originIMP = (_VIMP)method_getImplementation(method);
//        
//        id impBlock = ^(id target, SEL action) {
//            originIMP(target, action);
//            NSLog(@"%@ is dealloc", [target class]);
//        };
//        
//        [self changeMethod:method impBlock:impBlock];
//    });
//}
//
//+ (void)changeMethod:(Method _Nullable)method
//            impBlock:(void (^ __nullable)(void))block {
//    IMP orientationIMP = imp_implementationWithBlock(block);
//    method_setImplementation(method, orientationIMP);
//}

@end
