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

const NSInteger ADADataFieldByteLength = 2;
const NSInteger ADADataFieldDataLengthByteLength = 1;
const NSInteger ADAInitialCapacity = (1024 * 2); //2k

@implementation ADAPayload
{
    NSMutableData *_payloadData;
}

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
    [self appendData:[self dataField:ADAMajorVersionID data:&ADAMajorVersion length:sizeof(ADAMajorVersion)]];
    [self appendData:[self dataField:ADAMinorVersionID data:&ADAMinorVersion length:sizeof(ADAMinorVersion)]];
}

- (void)addCreationData
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|
                                                                             NSCalendarUnitDay|NSCalendarUnitHour|
                                                                             NSCalendarUnitMinute|NSCalendarUnitSecond|
                                                                             NSCalendarUnitTimeZone)
                                                                   fromDate:[NSDate date]];
    
    ADAInt32 year = (ADAInt32)[components year];
    NSData *yearData = [self dataField:ADAPayloadCreationDateYearID data:&year length:sizeof(year)];
    [self appendData:yearData];
    
    ADAInt16 month = (ADAInt16)[components month];
    NSData *monthData = [self dataField:ADAPayloadCreationDateMonthID data:&month length:sizeof(month)];
    [self appendData:monthData];
    
    ADAInt16 day = (ADAInt16)[components day];
    NSData *dayData = [self dataField:ADAPayloadCreationDateDayID data:&day length:sizeof(day)];
    [self appendData:dayData];
    
    ADAInt16 hour = (ADAInt16)[components hour];
    NSData *hourData = [self dataField:ADAPayloadCreationDateHouID data:&hour length:sizeof(hour)];
    [self appendData:hourData];
    
    ADAInt16 minute = (ADAInt16)[components minute];
    NSData *minuteData = [self dataField:ADAPayloadCreationDateMinuteID data:&minute length:sizeof(minute)];
    [self appendData:minuteData];
    
    ADAInt16 second = (ADAInt16)[components second];
    NSData *secondData = [self dataField:ADAPayloadCreationDateSecondID data:&second length:sizeof(second)];
    [self appendData:secondData];
   
    NSTimeZone *timeZone = [components timeZone];
    NSData *timeZoneData = [self dataField:ADAPayloadCreationDateTimeZoneID data:[[timeZone name] UTF8String] length:[timeZone name].length];
    [self appendData:timeZoneData];
}

- (NSData *)dataField:(ADADataFieldID)fieldID data:(const void *)data length:(NSInteger)length
{
    NSAssert(length <= 0xFF, @"Data length is too long");
    
    NSMutableData *fieldData = [[NSMutableData alloc] initWithBytes:&fieldID length:ADADataFieldByteLength];
    [fieldData appendBytes:&length length:ADADataFieldDataLengthByteLength]; //write size into 1 byte
    [fieldData appendBytes:data length:length]; //write data
    
    return [fieldData copy];
}

#pragma mark - Public API

- (NSData *)payloadData
{
    ADAInt64 crcCheck = [_payloadData crc32Value];
    
    NSMutableData *payload = [NSMutableData dataWithBytes:&crcCheck length:sizeof(ADAInt64)];
    [payload appendData:_payloadData];
    
    return [payload copy];
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
    NSData *fieldData = [self dataField:fieldID data:data length:length];
    
    return [self appendData:fieldData];
}

@end
