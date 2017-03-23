//
//  CHomeViewController.h
//  BonjourMac
//
//  Created by Boobalan Munusamy on 5/2/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@interface CHomeViewController : NSViewController<NSNetServiceBrowserDelegate,NSNetServiceDelegate,GCDAsyncSocketDelegate>
@property(strong) NSMutableArray* arrDevices;
@end
