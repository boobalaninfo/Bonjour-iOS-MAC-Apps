//
//  CHostControllerViewController.h
//  ProBonjour
//
//  Created by Boobalan Munusamy on 4/30/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHostControllerViewController : UIViewController<NSNetServiceDelegate, GCDAsyncSocketDelegate,UITextViewDelegate, NSNetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSNetService *service;
@property (strong, nonatomic) GCDAsyncSocket *socket;

@end
