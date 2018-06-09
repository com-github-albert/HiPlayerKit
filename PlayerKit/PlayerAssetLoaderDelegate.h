//
//  PlayerAssetLoaderDelegate.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class    PlayerAssetLoaderDelegate
 @abstract handle resource loading requests
 */
@interface PlayerAssetLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

/*!
 Unavailable initialize method.
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 Create a PlayerAssetLoaderDelegate that handles resource loading requests

 @param scheme the origin scheme for resource loading requests
 @param cacheDirectory the directory's path for saving cache file
 @param destDirectory the directory's path for saving the downloaded video file
 @return a instance of PlayerAssetLoaderDelegate
 */
- (instancetype)initWithOriginScheme:(NSString *)scheme
                      cacheDirectory:(NSString *)cacheDirectory
                       destDirectory:(NSString *)destDirectory;

/*!
 Cacneling the download task.
 invalidate() is thread safe meaning that it can be called from a tread separate to the one in which the delegate is creating.
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
