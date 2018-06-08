//
//  PlayerLogger.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#ifndef PlayerLogger_h
#define PlayerLogger_h

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#define NSLogMethod() NSLog(@"%s", __func__)
#else
#define NSLog(...)
#define NSLogMethod()
#endif

#endif /* PlayerLogger_h */
