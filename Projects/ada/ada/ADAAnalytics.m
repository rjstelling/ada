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

//Required for feature querying

@import CoreTelephony;
@import CoreLocation;

#ifdef DEBUG
# include <assert.h>
# include <stdbool.h>
# include <sys/types.h>
# include <unistd.h>
# include <sys/sysctl.h>

#pragma mark - Versioning

ADAInt16 ADAMajorVersion = 1;
ADAInt16 ADAMinorVersion = 0;

#pragma mark - Debug Info

static bool AmIBeingDebugged(void)
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}
#endif //DEBUG

@implementation ADAAnalytics
{
    BOOL _isDebuggerAttached;
}

#pragma mark - Life Cycle

// This is called when the library is loaded into th eObjective-C runtime.
// We use this to create a singleton of the ADAAnalytics object.
+ (void)load
{
#ifdef ADA_LOGGING
    NSLog(@"[ADA ANALYTICS] Loading ADA into Objective-C runtime");
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [ADAAnalytics sharedAnalyticsManager];
        
#ifdef ADA_LOGGING
        NSLog(@"[ADA ANALYTICS] Singleton created on background thread");
#endif
    });
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
    }
    
    return self;
}

#pragma mark - Notifications

- (void)onApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    const u_int32_t upperBounds = 5; //a higher number will result in less frequent sampling
    u_int32_t random = arc4random_uniform(upperBounds);
    
    if(random == (upperBounds - 1) || _isDebuggerAttached)
    {
        //Only collect data here, this has a 1/upperBounds
        //chnace of being triggered.
        
        [self collectDeviceInfo];
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
    
    /* OpenGLES */
    unsigned int oglesMajor = 0, oglesMinor = 0;
    EAGLGetVersion(&oglesMajor, &oglesMinor);
    [self addData:&oglesMajor length:sizeof(oglesMajor) withFieldID:ADAOpenGLESMajorID toPayload:payload];
    [self addData:&oglesMinor length:sizeof(oglesMinor) withFieldID:ADAOpenGLESMinorID toPayload:payload];
    
    /* CoreTelephony */
    CTTelephonyNetworkInfo *ctTelephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
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
    
    /* CoreLocation
     + (BOOL)isMonitoringAvailableForClass:(Class)regionClass
     + (CLAuthorizationStatus)authorizationStatus
     + (BOOL)deferredLocationUpdatesAvailable
     */
    [self addBool:[CLLocationManager locationServicesEnabled] withFieldID:ADALocationServicesEnabledID toPayload:payload];
    [self addBool:[CLLocationManager headingAvailable] withFieldID:ADALocationHeadingAvailableID toPayload:payload];
    [self addBool:[CLLocationManager significantLocationChangeMonitoringAvailable] withFieldID:ADALocationSignificantLocationChangeMonitoringAvailableID toPayload:payload];
    [self addBool:[CLLocationManager regionMonitoringEnabled] withFieldID:ADALocationRegionMonitoringEnabledID toPayload:payload];
    [self addBool:[CLLocationManager isRangingAvailable] withFieldID:ADALocationRangingAvailableID toPayload:payload];
    
    /* AVFoundation
     + (NSArray *)devices;
     + (NSArray *)devicesWithMediaType:(NSString *)mediaType;
     
     AVCaptureDevice
     AVCaptureDevicePosition position;
     BOOL hasFlash;
     - (BOOL)isFlashModeSupported:(AVCaptureFlashMode)flashMode;
     BOOL hasTorch;
     - (BOOL)isFocusModeSupported:(AVCaptureFocusMode)focusMode;
     BOOL focusPointOfInterestSupported;
     BOOL autoFocusRangeRestrictionSupported
     BOOL smoothAutoFocusSupported
     - (BOOL)isExposureModeSupported:(AVCaptureExposureMode)exposureMode;
     BOOL exposurePointOfInterestSupported
     - (BOOL)isWhiteBalanceModeSupported:(AVCaptureWhiteBalanceMode)whiteBalanceMode
     BOOL lowLightBoostSupported
     CGFloat videoZoomFactor
     */
    
    NSData *payloadData = [payload payloadData];
    
    NSLog(@"%@", payloadData);
    NSLog(@"Data Length: %lu", (unsigned long)payloadData.length);
}

- (void)addString:(NSString *)dataString withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    NSParameterAssert(payload);
    
    if(!dataString)
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
    NSLog(@"[ADA ANALYTICS] %03X -> %d", field, value);
    
    BOOL success = [payload appendData:&value length:sizeof(value) field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

- (void)addData:(void *)data length:(NSInteger)dataLength withFieldID:(ADADataFieldID)field toPayload:(ADAPayload *)payload
{
    BOOL success = [payload appendData:data length:dataLength field:field];
    
    NSAssert(success, @"Failed to add data.");
    
    if(!success)
        NSLog(@"Failed");
}

@end
