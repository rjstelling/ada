//
//  ADAPayloadOperation.m
//  ada
//
//  Created by Richard Stelling on 03/01/2014.
//  Copyright (c) 2014 The Ada Analytics Cooperative. All rights reserved.
//

#import "ADAPayloadOperation.h"
#import "ADAPayload.h"
#import "ADAAnalytics.h"

// Files
NSString *const ADACacheFileExtention = @"ada";

inline static NSURL* cacheURLForFilename(NSString *filename)
{
    NSString *adaFilename = [filename stringByAppendingPathExtension:ADACacheFileExtention];
    NSURL *cacheDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSLog(@"[ADA ANALYTICS] Cached  object %@ saved in %@", adaFilename, cacheDir.path);
    
    return [cacheDir URLByAppendingPathComponent:adaFilename];
}

@interface ADAPayloadOperation ()

@property (strong, nonatomic) ADAPayload *payload;

@end

@implementation ADAPayloadOperation

+ (ADAPayloadOperation *)payloadOperation:(ADAPayload *)aPayload
{
#ifdef DEBUG
    if(AmIBeingDebugged())
    {
        return [self blockOperationWithBlock:^{
            NSLog(@"[ADA ANALYTICS] Debugger attached, this is the data we would send to the server:\n%@", [aPayload payloadData]);
        }];
    }
#endif //DEBUG
    
    ADAPayloadOperation *me = [self blockOperationWithBlock:^{
        //Check network
        NSError *error = nil;
        
        //This caches result
        NSString *success = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://adalytics.io/status.htm"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
        
        if([success isEqualToString:@"SUCCESS"])
        {
            NSLog(@"[ADA ANALYTICS] Sending blob to server.");
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://adalytics.io/add.php"]];
            request.HTTPMethod = @"POST";
            [request setValue:@"application/x-adalytics" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"adalytics/%d.%d", ADAMajorVersion, ADAMinorVersion] forHTTPHeaderField:@"User-Agent"];
            request.HTTPBody = [aPayload payloadData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Create url connection and fire request
                NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                [conn start];
            });
        }
        else
        {
            NSLog(@"[ADA ANALYTICS] Saving blob to disk.");
            
            NSUUID *payloadUDID = [NSUUID UUID];
            [NSKeyedArchiver archiveRootObject:aPayload toFile:cacheURLForFilename(payloadUDID.UUIDString).path];
        }
        //Send data or save to disk
    }];
    
    [me setQueuePriority:NSOperationQueuePriorityVeryLow];
    me.payload = aPayload;
    
    [me setCompletionBlock:^{
        //check cache folder for more blobs
    }];
    
    return me;
}

@end

/*

*/

/*
 ///POST
 //http://adalytics.io/service.cfc?method=test
 // Create the request.
 //    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://adalytics.io/service.cfc?method=test"]];
 //    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://164.177.156.26/ada/adalytics.php"]];
 
 //    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://164.177.156.26/ada/adalytics.php"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1];
 //
 //    // Specify that it will be a POST request
 //    request.HTTPMethod = @"POST";
 //    [request setValue:@"application/x-adalytics" forHTTPHeaderField:@"Content-Type"];
 //    [request setValue:[NSString stringWithFormat:@"adalytics/%d.%d", ADAMajorVersion, ADAMinorVersion] forHTTPHeaderField:@"User-Agent"];
 //
 //    // This is how we set header fields
 //    //[request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
 //    //[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
 //
 //    request.HTTPBody = payloadData;
 //
 //    dispatch_async(dispatch_get_main_queue(), ^{
 //        // Create url connection and fire request
 //        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
 //        [conn start];
 //    });
 
 - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
 {
 NSLog(@"%@", error);
 }
 
 - (void)connectionDidFinishLoading:(NSURLConnection *)connection
 {
 NSURLRequest *req = [connection currentRequest];
 
 NSLog(@"%@", req);
 }
 
 - (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
 {
 NSLog(@"%@", response);
 }
 
 - (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
 {
 NSLog(@"%@", [[NSString alloc] initWithBytes:[data bytes] length:data.length encoding:NSUTF8StringEncoding]);
 }
*/