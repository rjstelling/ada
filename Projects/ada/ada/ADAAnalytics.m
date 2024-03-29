//
//  ADAAnalytics.m
//  ADA Analytics
//
//  Created by Richard Stelling on 11/11/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "ADAAnalytics.h"
#import "ADAPayload.h"
#import "ADAPayloadOperation.h"

//Required for feature querying

@import CoreTelephony;
@import CoreLocation;
@import AVFoundation;

#pragma mark - Versioning

ADAInt16 ADAMajorVersion = 1;
ADAInt16 ADAMinorVersion = 0;

@implementation ADAAnalytics
{
    BOOL _isDebuggerAttached;
    NSOperationQueue *_queue;
}

#pragma mark - Life Cycle

// This is called when the library is loaded into th eObjective-C runtime.
// We use this to create a singleton of the ADAAnalytics object.
+ (void)load
{
#ifdef ADA_LOGGING
    NSLog(@"[ADA ANALYTICS] Loading ADA into Objective-C runtime");
#endif
    
    [ADAAnalytics sharedAnalyticsManager];
        
#ifdef ADA_LOGGING
    NSLog(@"[ADA ANALYTICS] Singleton created on main thread");
#endif
}

+ (ADAAnalytics *)sharedAnalyticsManager
{
    static dispatch_once_t onceToken;
    static ADAAnalytics *manager_ = nil;
    
    dispatch_once(&onceToken, ^{
        manager_ = [[ADAAnalytics alloc] init];
    });
    
    return manager_;
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
#ifdef DEBUG
        if(AmIBeingDebugged())
        {
            NSLog(@"[ADA ANALYTICS] Running with a debugger attached, no data will be sent to the servers.");
            _isDebuggerAttached = YES;
        }
#endif
        
#ifdef ADA_LOGGING
        NSLog(@"[ADA ANALYTICS] -init called while creating ADAAnalytics object");
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onApplicationDidBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    
    return self;
}

#pragma mark - Notifications

- (void)onApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    const u_int32_t upperBounds = 5; //a higher number will result in less frequent sampling
    u_int32_t random = arc4random_uniform(upperBounds);
    
    if((random == (upperBounds - 1) || _isDebuggerAttached) /* && !([[UIDevice currentDevice].model isEqualToString:@"iPhone Simulator"]) */ )
    {
        //Only collect data here, this has a 1/upperBounds
        //chnace of being triggered.
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self collectDeviceInfo];
        });
    }
}

- (void)collectDeviceInfo
{
    ADAPayload *payload = [ADAPayload new];
    
    /* Device Info */
    [self addString:[UIDevice currentDevice].model withFieldID:ADADeviceModelID toPayload:payload];
    [self addString:[UIDevice currentDevice].localizedModel withFieldID:ADADeviceLocalizedModelID toPayload:payload];
    [self addString:[UIDevice currentDevice].systemName withFieldID:ADADeviceSystemNameID toPayload:payload];
    [self addString:[UIDevice currentDevice].systemVersion withFieldID:ADADeviceSystemVersionID toPayload:payload];
    [self addString:[[UIDevice currentDevice].identifierForVendor UUIDString] withFieldID:ADADeviceIdentifierForVendorID toPayload:payload];
    [self addBool:[UIDevice currentDevice].multitaskingSupported withFieldID:ADADeviceMultitaskingSupportID toPayload:payload];
    
    [self addString:[[NSLocale currentLocale] localeIdentifier] withFieldID:ADADeviceCurrentLocaleID toPayload:payload];
    
    /* Screen */
    [self addInteger:CGRectGetHeight([UIScreen mainScreen].bounds) withFieldID:ADADeviceScreenHeight toPayload:payload];
    [self addInteger:CGRectGetWidth([UIScreen mainScreen].bounds) withFieldID:ADADeviceScreenWidth toPayload:payload];
    [self addInteger:[UIScreen mainScreen].scale withFieldID:ADADeviceScreenScale toPayload:payload];
    
    /* OpenGLES */
    unsigned int oglesMajor = 0, oglesMinor = 0;
    EAGLGetVersion(&oglesMajor, &oglesMinor);

    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if(!context)
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if(!context)
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    [self addOpenGLInfo:context toPayload:payload];
    
    //[self addInteger:oglesMajor withFieldID:ADAOpenGLESMajorID toPayload:payload];
    //[self addInteger:oglesMinor withFieldID:ADAOpenGLESMinorID toPayload:payload];
    
    /* CoreTelephony */
    CTTelephonyNetworkInfo *ctTelephonyNetworkInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *ctCarrier = [ctTelephonyNetworkInfo subscriberCellularProvider];

    [self addString:ctTelephonyNetworkInfo.currentRadioAccessTechnology withFieldID:ADATelephonyRadioAccessTechnologyID toPayload:payload];
    [self addString:ctCarrier.carrierName withFieldID:ADATelephonyCarrierNameID toPayload:payload];
    [self addString:ctCarrier.mobileCountryCode withFieldID:ADATelephonyMobileCountryCodeID toPayload:payload];
    [self addString:ctCarrier.mobileNetworkCode withFieldID:ADATelephonyMobileNetworkCodeID toPayload:payload];
    [self addString:ctCarrier.isoCountryCode withFieldID:ADATelephonyISOCountryCodeID toPayload:payload];
    [self addBool:ctCarrier.allowsVOIP withFieldID:ADATelephonyAllowsVOIPID toPayload:payload];
    
    /* CoreMotion */
    CMMotionManager *motionManager = [CMMotionManager new];
    [self addInteger:[CMMotionManager availableAttitudeReferenceFrames] withFieldID:ADAMotionAttitudeReferenceFramesID toPayload:payload];
    [self addBool:motionManager.isAccelerometerAvailable withFieldID:ADAMotionHasAccelerometerID toPayload:payload];
    [self addBool:motionManager.isGyroAvailable withFieldID:ADAMotionHasGyroID toPayload:payload];
    [self addBool:motionManager.isMagnetometerAvailable withFieldID:ADAMotionHasMagnetometerID toPayload:payload];
    [self addBool:motionManager.isDeviceMotionAvailable withFieldID:ADAMotionHasDeviceMotionID toPayload:payload];
    [self addBool:[CMStepCounter isStepCountingAvailable] withFieldID:ADAMotionHasStepCountingID toPayload:payload];
    
    /* CoreLocation */
    [self addBool:[CLLocationManager locationServicesEnabled] withFieldID:ADALocationServicesEnabledID toPayload:payload];
    [self addBool:[CLLocationManager headingAvailable] withFieldID:ADALocationHeadingAvailableID toPayload:payload];
    [self addBool:[CLLocationManager significantLocationChangeMonitoringAvailable] withFieldID:ADALocationSignificantLocationChangeMonitoringAvailableID toPayload:payload];
//    if([CLLocationManager resolveClassMethod:@selector(regionMonitoringEnabled)])
//        [self addBool:[CLLocationManager regionMonitoringEnabled] withFieldID:ADALocationRegionMonitoringEnabledID toPayload:payload];
    [self addBool:[CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] withFieldID:ADALocationRegionMonitoringAvailableForCircularRegion toPayload:payload];
    [self addBool:[CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] withFieldID:ADALocationRegionMonitoringAvailableForBeaconRegion toPayload:payload];
    [self addBool:[CLLocationManager isRangingAvailable] withFieldID:ADALocationRangingAvailableID toPayload:payload];
    [self addBool:[CLLocationManager deferredLocationUpdatesAvailable] withFieldID:ADALocationDeferredUpdatesAvailable toPayload:payload];
    
    /* AVFoundation & AVCaptureDevice
     - (BOOL)isFlashModeSupported:(AVCaptureFlashMode)flashMode;
     - (BOOL)isFocusModeSupported:(AVCaptureFocusMode)focusMode;
     - (BOOL)isExposureModeSupported:(AVCaptureExposureMode)exposureMode;
     - (BOOL)isWhiteBalanceModeSupported:(AVCaptureWhiteBalanceMode)whiteBalanceMode
     - formats
     */
    
    //There are multiple capture devices
    
    for(AVCaptureDevice *device in [AVCaptureDevice devices])
    {
        NSMutableData *deviceData = [NSMutableData dataWithCapacity:0xFF];
        
        //Position
        AVCaptureDevicePosition position = device.position;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDevicePositionID data:&position length:sizeof(device.position)]];
        
        //modelID
        NSLog(@"\t[ADA ANALYTICS] %03X -> %@", ADACaptureDeviceModelID, device.modelID);
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceModelID data:[device.modelID UTF8String] length:device.modelID.length]];
        
        //localizedName
        NSLog(@"\t[ADA ANALYTICS] %03X -> %@", ADACaptureDeviceLocalizedNameID, device.localizedName);
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceLocalizedNameID data:[device.localizedName UTF8String] length:device.localizedName.length]];
        
        //Flash
        BOOL hasFlash = device.hasFlash;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceHasFlashID data:&hasFlash length:1]];
        
        //Tourch
        BOOL hasTourch = device.hasTorch;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceHasTourchID data:&hasTourch length:1]];
        
        //Point Of Interest Supported
        BOOL focusPointOfInterestSupported = device.focusPointOfInterestSupported;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceFocusPOISupportedID data:&focusPointOfInterestSupported length:1]];

        //autoFocusRangeRestrictionSupported
        BOOL autoFocusRangeRestrictionSupported = device.autoFocusRangeRestrictionSupported;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceAutoFocusRangeRestrictionSupportedID data:&autoFocusRangeRestrictionSupported length:1]];
        
        //smoothAutoFocusSupported
        BOOL smoothAutoFocusSupported = device.smoothAutoFocusSupported;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceSmoothAutoFocusSupportedID data:&smoothAutoFocusSupported length:1]];
        
        //exposurePointOfInterestSupported
        BOOL exposurePointOfInterestSupported = device.exposurePointOfInterestSupported;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceExposurePointOfInterestSupportedID data:&exposurePointOfInterestSupported length:1]];
        
        //lowLightBoostSupported
        BOOL lowLightBoostSupported = device.lowLightBoostSupported;
        [deviceData appendData:[ADAPayload dataField:ADACaptureDeviceLowLightBoostSupportedID data:&lowLightBoostSupported length:1]];
        
        [self addData:[deviceData bytes] length:deviceData.length withFieldID:ADACaptureDeviceID toPayload:payload];
    }
   
    //Add to queue for processing, this will either save to disk or set over the wire depending
    //on network conditions
    [_queue addOperation:[ADAPayloadOperation payloadOperation:payload]];
}

- (void)addOpenGLInfo:(EAGLContext *)oglesContext toPayload:(ADAPayload *)payload
{
    [EAGLContext setCurrentContext:oglesContext];

    const GLubyte *oglesVendor = glGetString(GL_VENDOR);
    [self addString:[NSString stringWithUTF8String:(const char *)oglesVendor] withFieldID:ADAOpenGLESVendorID toPayload:payload];
    
    const GLubyte *oglesVersion = glGetString(GL_VERSION);
    [self addString:[NSString stringWithUTF8String:(const char *)oglesVersion] withFieldID:ADAOpenGLESVersionID toPayload:payload];
    
    const GLubyte *oglesRenderer = glGetString(GL_RENDERER);
    [self addString:[NSString stringWithUTF8String:(const char *)oglesRenderer] withFieldID:ADAOpenGLESRendererID toPayload:payload];

    //This is too long > 255 bytes
//    const GLubyte *oglesExtentions = glGetString(GL_EXTENSIONS);
//    [self addString:[NSString stringWithUTF8String:(const char *)oglesExtentions] withFieldID:ADAOpenGLESExtentionsID toPayload:payload];
}

- (void)addString:(NSString *)dataString withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    NSParameterAssert(payload);
    
    if(!dataString || dataString.length == 0)
        return;
    
    NSLog(@"[ADA ANALYTICS] %03X -> %@", field, dataString);
    
    const char *stringData = [dataString UTF8String];
    BOOL success = [payload appendData:stringData length:dataString.length field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

- (void)addBool:(BOOL)yesNo withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    NSLog(@"[ADA ANALYTICS] %03X -> %d", field, yesNo);
    
    BOOL success = [payload appendData:&yesNo length:1 field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

- (void)addInteger:(NSInteger)value withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    NSLog(@"[ADA ANALYTICS] %03X -> %ld", field, (long)value);
    
    BOOL success = [payload appendData:&value length:sizeof(value) field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

- (void)addData:(const void *)data length:(NSInteger)dataLength withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    NSLog(@"[ADA ANALYTICS] %03X -> {DATA} (length: %ld)", field, (long)dataLength);
    
    BOOL success = [payload appendData:data length:dataLength field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

@end

#ifdef DEBUG

@implementation ADAAnalytics (Debugging)

+ (void)resendPayload
{
    NSLog(@"[ADA ANALYTICS] %s", __PRETTY_FUNCTION__);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[ADAAnalytics sharedAnalyticsManager] collectDeviceInfo];
    });
}

@end

#endif //DEBUG