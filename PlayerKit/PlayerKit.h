//
//  PlayerKit.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Player.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlayerKit : NSObject

/*!
 The version of PlayerKit framework.
 */
@property (class, nonatomic, readonly) NSString *version;

/*!
 The directory's path for saving the cache file is being downloaded.
 */
@property (class, nonatomic) NSString *cacheDirectory;

/*!
 The directory's path for saving the file has been completely downloaded.
 */
@property (class, nonatomic) NSString *destDirectory;

/*!
 @method        previewFromVideoURL:atTime:completion:
 @param         url the video address url that you want to get a frame.
 @param         seconds get a preview at the sepecified time.
 @param         completion A block object to be executed when the frame is got. This block has no return value and takes a single UIImage argument that indicates the image from a video at the specified time. The method is asynchronous and the complete block return in a main thread.
 @abstract      get the frame at the sepecified time from the video address url.
 */
+ (void)previewFromVideoURL:(NSURL *)url
                     atTime:(NSTimeInterval)seconds
                 completion:(void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
