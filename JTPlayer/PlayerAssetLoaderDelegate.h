//
//  PlayerAssetLoaderDelegate.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface PlayerAssetLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOriginScheme:(NSString *)scheme cacheDirectory:(NSString *)cacheDirectory destDirectory:(NSString *)destDirectory;

@end
