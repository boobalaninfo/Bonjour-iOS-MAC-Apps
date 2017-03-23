//
//  CAppDelegate.m
//  BonjourMac
//
//  Created by Boobalan Munusamy on 5/2/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import "CAppDelegate.h"
#import "CHomeViewController.h"

@implementation CAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.homeController = [[CHomeViewController alloc]initWithNibName:@"CHomeViewController" bundle:nil];
   
    NSMutableArray* arrDevice=[[NSMutableArray alloc]init];
     //[arrDevice addObject:coDevice];
    
    
    self.homeController.arrDevices=arrDevice;
    [self.window.contentView addSubview:self.homeController.view];
    self.homeController.view.frame = ((NSView*)self.window.contentView).bounds;
}

@end
