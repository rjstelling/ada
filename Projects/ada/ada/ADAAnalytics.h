//
//  ADAAnalytics.h
//  ADA Analytics
//
//  Created by Richard Stelling on 11/11/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADATypes.h"

#ifdef RELEASE
# undef ADA_LOGGING
#else
# define ADA_LOGGING 1
#endif

extern ADAInt16 ADAMajorVersion;
extern ADAInt16 ADAMinorVersion;

@interface ADAAnalytics : NSObject

@end
