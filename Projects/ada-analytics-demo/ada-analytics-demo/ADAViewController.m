//
//  ADAViewController.m
//  ada-analytics-demo
//
//  Created by Richard Stelling on 11/11/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import "ADAViewController.h"
#import "ADAAnalytics.h"

@interface ADAViewController ()

@end

@implementation ADAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    ADAAnalytics *manager = [ADAAnalytics sharedAnalyticsManager];
//    NSLog(@"%@", manager);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)send:(id)sender
{
    [ADAAnalytics resendPayload];
}

@end
