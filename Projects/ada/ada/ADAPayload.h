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
    ADADeviceMultitaskingSupportID = 0x0006,
    
    ADADeviceCurrentLocaleID = 0x0007,
    
    //Screen
    ADADeviceScreenHeight = 0x0011,
    ADADeviceScreenWidth = 0x0012,
    ADADeviceScreenScale = 0x0013,
    
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
    ADAOpenGLESVersionID = 0x0C03,
    ADAOpenGLESRendererID = 0x0C04,
    ADAOpenGLESExtentionsID = 0x0C05,
    ADAOpenGLESVendorID = 0x0C06,
    
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
    ADALocationRegionMonitoringEnabledID = 0xC34,
    ADALocationRangingAvailableID = 0xC35,
    ADALocationRegionMonitoringAvailableForCircularRegion = 0xC36,
    ADALocationRegionMonitoringAvailableForBeaconRegion = 0xC37,
    ADALocationDeferredUpdatesAvailable = 0xC38,
    
    //AVCaptureDevice
    ADACaptureDeviceID /* Dictionary */ = 0xC41, //there will be multiple entries. The length refers to the end of the nested field-lenght-value items
    ADACaptureDevicePositionID = 0xC42,
    ADACaptureDeviceHasFlashID = 0xC43,
    ADACaptureDeviceHasTourchID = 0xC44,
    ADACaptureDeviceFocusPOISupportedID = 0xC45,
    ADACaptureDeviceAutoFocusRangeRestrictionSupportedID = 0xC46,
    ADACaptureDeviceSmoothAutoFocusSupportedID = 0xC47,
    ADACaptureDeviceExposurePointOfInterestSupportedID = 0xC48,
    ADACaptureDeviceLowLightBoostSupportedID = 0xC49,
    ADACaptureDeviceModelID = 0xC4A,
    ADACaptureDeviceLocalizedNameID = 0xC4B,
    
    //Version
    ADAMajorVersionID = 0xFFFF,
    ADAMinorVersionID = 0xEEEE
};

@interface ADAPayload : NSObject

// Add data to the payload.
- (BOOL)appendData:(const void *)data length:(NSInteger)length field:(ADADataFieldID)fieldID;

//Serilized data, not added to the payload
+ (NSData *)dataField:(ADADataFieldID)fieldID data:(const void *)data length:(NSInteger)length;

//CRC32 checksummed payload data.
- (NSData *)payloadData;

@end
