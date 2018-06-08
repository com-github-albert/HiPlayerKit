//
//  PlayerAssetLoaderDelegate.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface PlayerAssetLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOriginScheme:(NSString *)scheme
                      cacheDirectory:(NSString *)cacheDirectory
                       destDirectory:(NSString *)destDirectory;

- (void)invalidate;

@end
