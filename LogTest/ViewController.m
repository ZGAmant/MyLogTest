//
//  ViewController.m
//  LogTest
//
//  Created by ZG on 2024/4/24.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *serverIP;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

@property (nonatomic, strong) GCDAsyncSocket *clienSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)sendMessage:(id)sender {
    NSData *messageData = [self.messageTextField.text dataUsingEncoding:NSUTF8StringEncoding];
//    NSMutableData *data = [[NSMutableData alloc]init];
//    [data appendData:[@"LOG" dataUsingEncoding:NSUTF8StringEncoding]];
//    NSLog(@"%ld",messageData.length);
//    Byte result[4];
//    result[0] = (Byte) ((messageData.length >> 24) & 0xff);
//    result[1] = (Byte) ((messageData.length >> 16) & 0xff);
//    result[2] = (Byte) ((messageData.length >> 8) & 0xff);
//    result[3] = (Byte) (messageData.length & 0xff);
//    [data appendData:[NSMutableData dataWithBytes:result length:4]];
//    Byte type[2] = {0x01,0x02};
//    [data appendData:[NSMutableData dataWithBytes:type length:2]];
//
//    [data appendData:messageData];
    
    
    [self.clienSocket writeData:[self encryptedData:messageData dataType:1] withTimeout:-1 tag:0];
    
}

-(NSData *)encryptedData:(NSData *)data dataType:(UInt8)dataType{
    NSMutableData *retData = [[NSMutableData alloc]init];
    [retData appendData:[@"LOG" dataUsingEncoding:NSUTF8StringEncoding]];
    Byte result[4];
    result[0] = (Byte) ((data.length >> 24) & 0xff);
    result[1] = (Byte) ((data.length >> 16) & 0xff);
    result[2] = (Byte) ((data.length >> 8) & 0xff);
    result[3] = (Byte) (data.length & 0xff);
    [retData appendData:[NSMutableData dataWithBytes:result length:4]];
    [retData appendData:[NSData dataWithBytes:&dataType length:sizeof(dataType)]];
    Byte type[1] = {0x02};
    [retData appendData:[NSMutableData dataWithBytes:type length:1]];
    NSLog(@"%@",retData);
    [retData appendData:data];
    return retData;
}

- (NSMutableData *)byteOrderWithData:(NSData *)data{
    NSUInteger length = [data length];
    NSLog(@"%ld",length);
    Byte result[4];
    result[0] = (Byte) ((length >> 24)&0xff);
    result[1] = (Byte) ((length >> 16)&0xff);
    result[2] = (Byte) ((length >> 8)&0xff);
    result[3] = (Byte) (length&0xff);
    NSLog(@"%2s", result);
    NSMutableData * orderData = [NSMutableData dataWithBytes:result length:4];
    [orderData appendData:data];
    return orderData;
}

- (IBAction)connectServer:(id)sender {
    NSError *error = nil;
    /*LQ~ 连接服务器 */
   //CONNECT_TIMEOUT是一个宏定义,定义超时的时间,我用的是30秒
    if (![self.clienSocket connectToHost:self.serverIP.text onPort:12345 withTimeout:-1 error:&error])
    {
        NSLog(@"TCP连接失败");
    }
    if (error != nil)
    {
        //当有错误的时候抛出异常错误信息
        @throw [NSException exceptionWithName:@"GCDAsyncSocket" reason:[error localizedDescription] userInfo:nil];
    }
}
- (IBAction)closeConnect:(id)sender {
    [self.clienSocket disconnect];
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"连接成功:%@",host);
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSLog(@"设备名:%@",deviceName);
    [self.clienSocket readDataWithTimeout:-1 tag:0];
    [self.clienSocket writeData:[self encryptedData:[deviceName dataUsingEncoding:NSUTF8StringEncoding] dataType:0] withTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"收到消息:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"消息已发送，tag: %ld", tag);
}
 
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)length tag:(long)tag {
    NSLog(@"部分消息已发送，length: %lu, tag: %ld", (unsigned long)length, tag);
}
 
- (void)socket:(GCDAsyncSocket *)sock didCloseWithError:(NSError *)error {
    // 处理关闭连接或发生错误的情况
    if (error) {
        NSLog(@"连接关闭，发生错误: %@", error);
    } else {
        NSLog(@"连接正常关闭");
    }
}


-(GCDAsyncSocket *)clienSocket{
    if (!_clienSocket) {
        _clienSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clienSocket;
}


@end
