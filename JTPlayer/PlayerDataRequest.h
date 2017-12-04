//
//  PlayerDataRequest.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerData.h"

@class PlayerDataRequest;

@protocol PlayerDataRequestDelegate <NSObject>

- (void)playerDataRequest:(PlayerDataRequest *_Nonnull)dataRequest didReceiveData:(NSData *_Nullable)data receiveDataToURL:(NSURL *_Nullable)location;
- (void)playerDataRequest:(PlayerDataRequest *_Nonnull)dataRequest didFinishDownloadingToURL:(NSURL *_Nullable)location;
- (void)playerDataRequest:(PlayerDataRequest *_Nonnull)dataRequest didCompleteWithError:(NSError *_Nullable)error;

@end

@interface PlayerDataRequest : NSObject

@property (nonatomic, readonly) NSInteger requestOffset;
@property (nonatomic, readonly) NSInteger downloadedLength;
@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) NSString * _Nullable contentType;

@property (nonatomic, readonly) NSString * _Nullable cacheDirectory;

@property (nonatomic, weak) id<PlayerDataRequestDelegate> _Nullable delegate;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull )initWithCacheDirectory:(NSString *_Nonnull)cacheDirectory;

- (void)resume:(NSString *_Nullable)urlString requestOffset:(NSInteger)offset;
- (void)cancel:(NSString *_Nonnull)urlString;
- (void)invalidate;

@end
