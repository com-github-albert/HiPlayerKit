//
//  PlayerKit.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Player.h"
#import "PlayerDelegate.h"

@interface PlayerKit : NSObject

@property (class, nonatomic, readonly) NSString *version;

@property (class, nonatomic) NSString *destDirectory;
@property (class, nonatomic) NSString *cacheDirectory;

@end
