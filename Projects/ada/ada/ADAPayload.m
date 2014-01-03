//
//  ADAPayload.m
//  ada
//
//  Created by Richard Stelling on 23/12/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import "ADAPayload.h"
#import "ADAAnalytics.h"
#import "NSData+Hashing.h"
#import <zlib.h>

const NSInteger ADADataFieldByteLength = 2;
const NSInteger ADADataFieldDataLengthByteLength = 1;
const NSInteger ADAInitialCapacity = (1024 * 2); //2k

@implementation ADAPayload
{
    NSMutableData *_payloadData;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_payloadData forKey:@"_payloadData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if(self)
    {
        _payloadData = [aDecoder decodeObjectForKey:@"_payloadData"];
    }
    
    return self;
}

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _payloadData = [NSMutableData dataWithCapacity:ADAInitialCapacity];
        
        [self addVersion];
        [self addCreationData];
    }
    
    return self;
}

#pragma mark - Private API

- (void)addVersion
{
    [self appendData:[ADAPayload dataField:ADAMajorVersionID data:&ADAMajorVersion length:sizeof(ADAMajorVersion)]];
    [self appendData:[ADAPayload dataField:ADAMinorVersionID data:&ADAMinorVersion length:sizeof(ADAMinorVersion)]];
}

- (void)addCreationData
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|
                                                                             NSCalendarUnitDay|NSCalendarUnitHour|
                                                                             NSCalendarUnitMinute|NSCalendarUnitSecond|
                                                                             NSCalendarUnitTimeZone)
                                                                   fromDate:[NSDate date]];
    
    ADAInt32 year = (ADAInt32)[components year];
    NSData *yearData = [ADAPayload dataField:ADAPayloadCreationDateYearID data:&year length:sizeof(year)];
    [self appendData:yearData];
    
    ADAInt16 month = (ADAInt16)[components month];
    NSData *monthData = [ADAPayload dataField:ADAPayloadCreationDateMonthID data:&month length:sizeof(month)];
    [self appendData:monthData];
    
    ADAInt16 day = (ADAInt16)[components day];
    NSData *dayData = [ADAPayload dataField:ADAPayloadCreationDateDayID data:&day length:sizeof(day)];
    [self appendData:dayData];
    
    ADAInt16 hour = (ADAInt16)[components hour];
    NSData *hourData = [ADAPayload dataField:ADAPayloadCreationDateHouID data:&hour length:sizeof(hour)];
    [self appendData:hourData];
    
    ADAInt16 minute = (ADAInt16)[components minute];
    NSData *minuteData = [ADAPayload dataField:ADAPayloadCreationDateMinuteID data:&minute length:sizeof(minute)];
    [self appendData:minuteData];
    
    ADAInt16 second = (ADAInt16)[components second];
    NSData *secondData = [ADAPayload dataField:ADAPayloadCreationDateSecondID data:&second length:sizeof(second)];
    [self appendData:secondData];
   
    NSTimeZone *timeZone = [components timeZone];
    NSData *timeZoneData = [ADAPayload dataField:ADAPayloadCreationDateTimeZoneID data:[[timeZone name] UTF8String] length:[timeZone name].length];
    [self appendData:timeZoneData];
}

#pragma mark - Public API

+ (NSData *)dataField:(ADADataFieldID)fieldID data:(const void *)data length:(NSInteger)length
{
    NSAssert(length <= 0xFF, @"Data length is too long");
    
    NSMutableData *fieldData = [[NSMutableData alloc] initWithBytes:&fieldID length:ADADataFieldByteLength];
    [fieldData appendBytes:&length length:ADADataFieldDataLengthByteLength]; //write size into 1 byte
    [fieldData appendBytes:data length:length]; //write data
    
    return [fieldData copy];
}

- (NSData *)payloadData
{
    NSData *compressedData = [self deflate:_payloadData];
    ADAInt64 crcCheck = [compressedData crc32Value];
    
    NSMutableData *payload = [NSMutableData dataWithBytes:&crcCheck length:sizeof(ADAInt64)];
    [payload appendData:compressedData];
    
    return [payload copy];
}

- (NSData *)deflate:(NSData *)inData
{
    //Compression is turned up to 11.
    
    z_stream zlibStreamStruct;
    zlibStreamStruct.zalloc    = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so
    zlibStreamStruct.zfree     = Z_NULL; // that when we call deflateInit2 they will be
    zlibStreamStruct.opaque    = Z_NULL; // updated to use default allocation functions.
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far
    zlibStreamStruct.next_in   = (Bytef*)[inData bytes]; // Pointer to input bytes
    zlibStreamStruct.avail_in  = (uInt)inData.length; // Number of input bytes left to process
    
    int initError = deflateInit2(&zlibStreamStruct, Z_BEST_COMPRESSION, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);

    NSAssert(initError == Z_OK, @"Error defating data");
    
    //The zlib documentation states that destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.
    NSMutableData *compressedData = [NSMutableData dataWithLength:inData.length * 1.01 + 12];
    
    int deflateStatus = Z_ERRNO;
    
    do
    {
        // Store location where next byte should be put in next_out
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
        
        // Calculate the amount of remaining free space in the output buffer
        // by subtracting the number of bytes that have been written so far
        // from the buffer's total capacity
        zlibStreamStruct.avail_out = (uInt)(compressedData.length - zlibStreamStruct.total_out);
        
        /* deflate() compresses as much data as possible, and stops/returns when
         the input buffer becomes empty or the output buffer becomes full. If
         deflate() returns Z_OK, it means that there are more bytes left to
         compress in the input buffer but the output buffer is full; the output
         buffer should be expanded and deflate should be called again (i.e., the
         loop should continue to rune). If deflate() returns Z_STREAM_END, the
         end of the input stream was reached (i.e.g, all of the data has been
         compressed) and the loop should stop. */
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
        
    } while ( deflateStatus == Z_OK );
    
    NSAssert(deflateStatus == Z_STREAM_END, @"Error defating data");
    
    // Free data structures that were dynamically created for the stream.
    deflateEnd(&zlibStreamStruct);
    
    [compressedData setLength:zlibStreamStruct.total_out];
    
    NSLog(@"Compressed data from %lu bytes to %lu bytes (%f%%)", inData.length, compressedData.length, 100-((float)compressedData.length/(float)inData.length)*100.0);
    
    return [compressedData copy];
}

- (BOOL)appendData:(NSData *)data
{
    return [self appendData:[data bytes] length:data.length];
}

- (BOOL)appendData:(const void *)data length:(NSInteger)length
{
    NSAssert(_payloadData, @"Payload data object is missing.");
    
    BOOL success = NO;
    NSInteger startLength = _payloadData.length;
    
    [_payloadData appendBytes:data length:length];
    
    success = ((startLength + length) == _payloadData.length);
    
    return success;
}

- (BOOL)appendData:(const void *)data length:(NSInteger)length field:(ADADataFieldID)fieldID
{
    NSData *fieldData = [ADAPayload dataField:fieldID data:data length:length];
    
    return [self appendData:fieldData];
}

@end
