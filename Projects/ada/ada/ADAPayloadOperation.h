//
//  ADAPayloadOperation.h
//  ada
//
//  Created by Richard Stelling on 03/01/2014.
//  Copyright (c) 2014 The Ada Analytics Cooperative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADATypes.h"

@class ADAPayload;

@interface ADAPayloadOperation : NSBlockOperation

+ (ADAPayloadOperation *)payloadOperation:(ADAPayload *)aPayload;

@end
