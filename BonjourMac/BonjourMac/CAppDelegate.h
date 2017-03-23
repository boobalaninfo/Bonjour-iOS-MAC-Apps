//
//  CAppDelegate.h
//  BonjourMac
//
//  Created by Boobalan Munusamy on 5/2/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHomeViewController.h"
@interface CAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,strong) IBOutlet CHomeViewController *homeController;
@end
