//
//  ADAPayload.h
//  ada
//
//  Created by Richard Stelling on 23/12/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADATypes.h"

extern const NSInteger ADADataFieldByteLength;

typedef NS_ENUM(ADAInt32, ADADataFieldID)
{
    //0x000 -> 0xFFF
    
    //0x001 -> 0x0FF are reserved for device idetification
    ADADeviceModelID = 0x0001,
    ADADeviceLocalizedModelID = 0x0002,
    ADADeviceSystemNameID = 0x0003,
    ADADeviceSystemVersionID = 0x0004,
    ADADeviceIdentifierForVendorID = 0x0005,
    
    //0x100 -> 0x1FF are reserved fopr meta data
    ADAPayloadCreationDateYearID = 0x0100,
    ADAPayloadCreationDateMonthID = 0x0100,
    ADAPayloadCreationDateDayID = 0x0101,
    ADAPayloadCreationDateHouID = 0x0102,
    ADAPayloadCreationDateMinuteID = 0x0103,
    ADAPayloadCreationDateSecondID = 0x0104,
    ADAPayloadCreationDateTimeZoneID = 0x0105,
    
    //0x200 -> 0xC00 are reserved
    
    //> 0xC00 are available features
    
    //OpenGL
    ADAOpenGLESMajorID = 0x0C01,
    ADAOpenGLESMinorID = 0x0C02,
    
    //CoreTelephony
    ADATelephonyRadioAccessTechnologyID = 0x0C11,
    ADATelephonyCarrierNameID = 0x0C12,
    ADATelephonyMobileCountryCodeID = 0x0C13,
    ADATelephonyMobileNetworkCodeID = 0x0C14,
    ADATelephonyISOCountryCodeID = 0x0C15,
    ADATelephonyAllowsVOIPID = 0x0C16,
    
    //CoreMotion
    ADAMotionHasAccelerometerID = 0xC21,
    ADAMotionHasGyroID = 0xC22,
    ADAMotionHasMagnetometerID = 0xC23,
    ADAMotionHasDeviceMotionID = 0xC24,
    ADAMotionHasStepCountingID = 0xC25,
    ADAMotionAttitudeReferenceFramesID = 0xC26,
    
    //CoreLocation
    ADALocationServicesEnabledID = 0xC31,
    ADALocationHeadingAvailableID = 0xC32,
    ADALocationSignificantLocationChangeMonitoringAvailableID = 0xC33,
    //isMonitoringAvailableForClass:(Class)regionClass
    ADALocationRegionMonitoringEnabledID = 0xC34,
    ADALocationRangingAvailableID = 0xC35,
    
    //Version
    ADAMajorVersionID = 0xFFFF,
    ADAMinorVersionID = 0xEEEE
};

@interface ADAPayload : NSObject

// Add data to the payload.
- (BOOL)appendData:(const void *)data length:(NSInteger)length field:(ADADataFieldID)fieldID;

//CRC32 checksummed payload data.
- (NSData *)payloadData;

@end
