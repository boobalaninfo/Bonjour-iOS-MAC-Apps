//
//  CHostControllerViewController.m
//  ProBonjour
//
//  Created by Boobalan Munusamy on 4/30/14.
//  Copyright (c) 2014 greateindiaclub. All rights reserved.
//

#import "CHostControllerViewController.h"

#define SERVICE_NAME @"_probonjore._tcp."

#define ACK_SERVICE_NAME @"_ack._tcp."

@interface CHostControllerViewController (){
    NSMutableData* dataBuffer;
}
@property (weak, nonatomic) IBOutlet UILabel *lblReceivedInfo;

@property (weak, nonatomic) IBOutlet UITextField *txtInfo;
@property (weak, nonatomic) IBOutlet UILabel *lblConnect;

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UILabel *lblNotSubscribe;

@property(nonatomic, strong) NSMutableArray* arrServices;
@property (weak, nonatomic) IBOutlet UITableView *tblview;


@property(nonatomic,strong)    NSNetServiceBrowser* coServiceBrowser;
@property(nonatomic,strong) NSMutableDictionary* dictSockets;

@property(nonatomic,assign) int selectedIndex;
@end

@implementation CHostControllerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)btnBackButton:(id)sender {
 [self.service stop];
    self.socket=nil;
    self.service=nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    dataBuffer = [NSMutableData data];
    // Do any additional setup after loading the view.
   [self startBroadCasting];
   // [self startBrowsingServices];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)connectedWithDevice{
    self.lblConnect.text=@"Connected with Device";
    self.lblConnect.textColor=[UIColor greenColor];
    self.txtInfo.hidden=NO;
    self.btnSend.hidden=NO;
}

-(void)disconnectedWithDevice{
    self.lblConnect.text=@"No device is connected";
    self.lblConnect.textColor=[UIColor redColor];
    self.txtInfo.hidden=YES;
    self.btnSend.hidden=YES;
}


-(void)startBroadCasting{
    self.socket=[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError* error = nil;
    if ([self.socket acceptOnPort:0 error:&error]) {
        self.service =[[NSNetService alloc]initWithDomain:@"local." type:SERVICE_NAME name:@"" port:[self.socket localPort]];
        self.service.delegate=self;
        [self.service publish];
    }else {
        NSLog(@"Unable to create socket. Error %@ with user info %@.", error, [error userInfo]);
    }
}

- (void)netServiceDidPublish:(NSNetService *)service {
    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}
- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}


-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    self.socket= newSocket;

    [self.socket readDataToLength:sizeof(uint64_t) withTimeout:-1.0f tag:0];
    [self connectedWithDevice];
    NSLog(@"Accepted the new socked");
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    
    NSLog(@"%@", error.userInfo);
    
    if (self.socket == socket) {
    
         [self disconnectedWithDevice];
    }
    
   
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"Write data is done");
}


-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    NSLog(@"Trying to read the data");

    [dataBuffer appendData:data];
    if ([sock socketAvailableBytes]==0) {
        NSString* strInfo =[[NSString alloc]initWithData:dataBuffer encoding:NSUTF8StringEncoding];
        self.lblReceivedInfo.text= strInfo;
        [dataBuffer setLength:0];
    }
 
    
    [sock readDataWithTimeout:-1.0f tag:0];
    
}

-(GCDAsyncSocket*)getSelectedSocket{
    NSNetService* coService =[self.arrServices objectAtIndex:self.selectedIndex];
    return  [self.dictSockets objectForKey:coService.name];
    
}

- (IBAction)btnSendInfo:(id)sender {
    NSDictionary* dictInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.txtInfo.text,@"data", nil];
    NSData* dataDict = [NSJSONSerialization dataWithJSONObject:dictInfo options:NSJSONWritingPrettyPrinted error:nil];
 
    [self.socket writeData:dataDict withTimeout:-1.0f tag:0];
   
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - tableview delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.arrServices count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* coTableViewCell =[tableView dequeueReusableCellWithIdentifier:@"deviceName"];
    NSNetService* coBrowser = [self.arrServices objectAtIndex:indexPath.row];
    coTableViewCell.textLabel.text= coBrowser.name;
    
    return coTableViewCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    
    self.selectedIndex= indexPath.row;
    NSNetService* coService =[self.arrServices objectAtIndex:indexPath.row];
    
    NSLog(@"Start connect with device %@", coService.name);
    coService.delegate=self;
    [coService resolveWithTimeout:30.0f];
}
@end
