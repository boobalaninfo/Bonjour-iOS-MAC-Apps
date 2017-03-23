//
//  CHomeViewController.m
//  BonjourMac
//
//  Created by Boobalan Munusamy on 5/2/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import "CHomeViewController.h"



#define SERVICE_NAME @"_probonjore._tcp."
#define ACK_SERVICE_NAME @"_ack._tcp."

@interface CHomeViewController(){
}
@property (weak) IBOutlet NSTextFieldCell *txtLogs;

@property(nonatomic,strong) NSNetServiceBrowser* coServiceBrowser;
@property (weak) IBOutlet NSTableView *tblView;

@property(nonatomic, strong) NSMutableData* mutableData;
@property (weak) IBOutlet NSTextField *lblConnected;

@property (weak) IBOutlet NSTextField *txtInfo;
@property (weak) IBOutlet NSButton *btnSendInfo;

@property(nonatomic,strong) NSMutableDictionary* dictSockets;

@property(nonatomic,strong) NSNetService * service;
@property(nonatomic,strong) GCDAsyncSocket* socket;

@property(nonatomic, strong) NSMutableData* dataBuffer;
@end

@implementation CHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
 
        [self startService];
       // [self publishService];
        _dictSockets=[NSMutableDictionary dictionary];
        _dataBuffer = [NSMutableData data];
    }
    return self;
}



-(void)startService{
    if (self.arrDevices) {
        [self.arrDevices removeAllObjects];
        
    }else{
        _arrDevices=[NSMutableArray array];
    }
    
    _coServiceBrowser=[[NSNetServiceBrowser alloc]init];
    self.coServiceBrowser.delegate=self;
    [self.coServiceBrowser searchForServicesOfType:SERVICE_NAME inDomain:@"local."];
    
}

#pragma mark- Delegates

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    // Retrieve to get the @"MyView" from the pool or,
    // if no version is available in the pool, load the Interface Builder version
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"DeviceName" owner:self];
    
    
    if (self.arrDevices.count==0) {
        result.textField.stringValue=@"Search Bonjour Devices....";
    }else{
        // Set the stringValue of the cell's text field to the nameArray value at row
        NSNetService* coService=[self.arrDevices objectAtIndex:row];
        result.textField.stringValue = coService.name;
    }
  
    
    // Return the result
    return result;
}



-(NSInteger) numberOfRowsInTableView:(NSTableView *)tableView{
    if (self.arrDevices.count==0) {
        return 1;
    }else{
         return self.arrDevices.count;
    }
   
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    NSLog(@"%@", aNotification.userInfo);


    NSNetService* coService =[self.arrDevices objectAtIndex:self.tblView.selectedRow];
 
    NSLog(@"Selected Device %@", coService.name);
    coService.delegate=self;
    [coService resolveWithTimeout:30.0f];
   
    
    
    
}


#pragma mark - Service Delegate

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{

    DLog(@"Didnot resolved: %@", errorDict);
    [sender setDelegate:self
     ];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender{
    DLog(@"netServiceDidResolveAddress %@", sender.name);
    if ([self connectWithServer:sender]) {
        DLog("Connected with server");
        NSString* str=[NSString stringWithFormat:@"Connected with %@", sender.name];
        DLog(@"Device ")
        self.lblConnected.stringValue=str ;
        self.lblConnected.textColor=[NSColor greenColor];
    }
}




-(BOOL)connectWithServer:(NSNetService*)service{
    BOOL isConnected=NO;
    
    NSArray* arrAddress =[[service addresses] mutableCopy];
    GCDAsyncSocket * coSocket= [self.dictSockets objectForKey:service.name];
    
    
   if (!coSocket  || ![coSocket isConnected]) {
        GCDAsyncSocket * coSocket=[[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        //Connect
        while (!isConnected && [arrAddress count]) {
            NSData* address= [arrAddress objectAtIndex:0];
            NSError* error;
            if ([coSocket connectToAddress:address error:&error]) {
                [self.dictSockets setObject:coSocket forKey:service.name];
                isConnected=YES;
            }else if(error){
                DLog(@"Unable to connect with Device %@ userinfo %@", error,error.userInfo);
            }
        }
   }else{
         isConnected = [coSocket isConnected];
   }
    
   
    return isConnected;
}


#pragma mark GCDAsyncSocket delegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    DLog(@"Connected to host: %@ port: %hu", host, port);
   [sock readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
  
    
    self.txtLogs.stringValue=@"";
    self.lblConnected.stringValue=@"Connected with ";

}


-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    DLog(@"Disconnected to host: %@", err.userInfo);
   
    self.lblConnected.stringValue= [NSString stringWithFormat:@"No device is connected"];
    self.lblConnected.textColor=[NSColor redColor];
    
}


-(GCDAsyncSocket*)getSelectedSocket{
    NSNetService* coService =[self.arrDevices objectAtIndex:self.tblView.selectedRow];
    return  [self.dictSockets objectForKey:coService.name];
    
}


-(void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    DLog(@"Read data");
   
    if ([self getSelectedSocket]== sock) {
        [_dataBuffer appendData:data];
        if ([sock socketAvailableBytes] == 0) {
            //[sock socketFDBytesAvailable];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:_dataBuffer options:NSJSONReadingMutableLeaves error:nil];
            DLog("Dictionary Info: %@", dict);
            NSString* strInfo =  (NSString*)[dict objectForKey:@"data"];
            [_dataBuffer setLength:0];
            self.txtLogs.stringValue= strInfo;
        }
   
    }
    
    
    
    [sock readDataWithTimeout:-1.0f tag:0];

 
}


-(void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    DLog(@"Read stream is closed");
    
    
}
#pragma mark- Service browser delegate;

-(void)stopBrowsing{
    if (self.coServiceBrowser) {
        [self.coServiceBrowser stop];
        self.coServiceBrowser.delegate=nil;
        [self setCoServiceBrowser:nil];
    }
}

-(void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
    [self stopBrowsing];
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict{
    [self stopBrowsing];
}


-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (aNetService) {
    
        [self.arrDevices removeObject:aNetService];
    }
    
    if (!moreComing) {
        [self.tblView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (aNetService) {
        [self.arrDevices addObject:aNetService];
    }
    
    if (!moreComing) {
        [self.arrDevices sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        [self.tblView reloadData];
    }
}


#pragma mark - Send info
- (IBAction)btnSendInfo:(id)sender {
    
    NSData* data=[self.txtInfo.stringValue dataUsingEncoding:NSUTF8StringEncoding];
    
    
    [[self getSelectedSocket] writeData:data withTimeout:-1.0f tag:0];
 
    DLog(@"Write Data");
    
    
}


@end
