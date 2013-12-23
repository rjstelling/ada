//
//  ADATypes.h
//  ada
//
//  Created by Richard Stelling on 23/12/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

typedef int ADAInt32;
typedef short ADAInt16;

#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long ADAInt64;
#else
# warning Building as 32-bit.
typedef long long ADAInt64;
#endif