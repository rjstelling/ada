//
//  ADAAnalytics.h
//  ADA Analytics
//
//  Created by Richard Stelling on 11/11/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef RELEASE
# undef ADA_LOGGING
#else
# define ADA_LOGGING 1
#endif

@interface ADAAnalytics : NSObject

@end
