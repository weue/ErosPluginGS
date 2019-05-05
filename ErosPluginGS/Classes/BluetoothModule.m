//
//  GSEventModule.m
//  WeexEros
//
//  Created by caas on 2019/3/30.
//  Copyright © 2019 benmu. All rights reserved.
//

#import "BluetoothModule.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "EscCommand.h"
#import "TscCommand.h"
#import "NSData+Base64.h"

#import <WeexPluginLoader/WeexPluginLoader.h>
// 第一个参数为暴露给 js 端 Module 的名字，
// 第二个参数为你 Module 的类名
WX_PlUGIN_EXPORT_MODULE(BluetoothModule, BluetoothModule)

@interface BluetoothModule ()

@property(nonatomic,strong)NSMutableDictionary *dicts;
@property(nonatomic,strong)NSMutableArray *blueDevices;

@property(nonatomic,strong)CBCentralManager *bluetoothManager;

@property(nonatomic, strong) NSString *support;
@property(nonatomic, strong) NSString *enable;

@property(nonatomic, assign) BOOL isReceive;

@end

@implementation BluetoothModule

// 将方法暴露出去
WX_EXPORT_METHOD_SYNC(@selector(isSupport))
WX_EXPORT_METHOD_SYNC(@selector(isEnabled))
WX_EXPORT_METHOD(@selector(searchDevices:endCallBack:))
WX_EXPORT_METHOD(@selector(queryTsc:))
WX_EXPORT_METHOD(@selector(disconnectPrinter))
WX_EXPORT_METHOD(@selector(stopSearchDevices))
WX_EXPORT_METHOD(@selector(bondDevice:callback:))
WX_EXPORT_METHOD(@selector(printLabel:callback:))

// @synthesize weexInstance;

-(NSMutableDictionary *)dicts {
    if (!_dicts) {
        _dicts = [[NSMutableDictionary alloc]init];
    }
    return _dicts;
}
-(NSMutableArray *)blueDevices {
    if (!_blueDevices) {
        _blueDevices = [[NSMutableArray alloc]init];
    }
    return _blueDevices;
}

-(CBCentralManager *)bluetoothManager {
    if (_bluetoothManager == nil) {
        _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _bluetoothManager;
}

/**
 * 是否支持蓝牙设备
 */
- (BOOL)isSupport {
    [self.bluetoothManager.delegate centralManagerDidUpdateState:self.bluetoothManager];
    return _support;
}

/**
 * 蓝牙是否启用
 */
- (BOOL)isEnabled {
    [self.bluetoothManager.delegate centralManagerDidUpdateState:self.bluetoothManager];
    return _enable;
}

/**
 * 查询设备是否支持TSC以及当前状态
 */
-(void)queryTsc:(WXModuleCallback)callback{
    //发送标签模式查询
    unsigned char tscCommand[] = {0x1B, 0x21, 0x3F};
    NSData *data = [NSData dataWithBytes:tscCommand length:sizeof(tscCommand)];
    self.isReceive = NO;
    __block NSString *dataStr = @"99";
    Manager.connecter.readData = ^(NSData * _Nullable data) {
        self.isReceive = YES;
        if (data.length > 0) {
            dataStr  = [self convertDataToHexStr:data];
            NSLog(@"dataStr -> %@",dataStr);
            /**
             返回值(16 进制) 打印机状态
             00 正常
             01 开盖
             02 卡纸
             03 卡纸、开盖
             04 缺纸
             05 缺纸、开盖
             08 无碳带
             09 无碳带、开盖
             0A 无碳带、卡纸
             0B 无碳带、卡纸、开盖
             0C 无碳带、缺纸
             0D 无碳带、缺纸、开盖
             10 暂停打印 20 正在打印 80 其他错误
             */

            callback(dataStr);
        }
        
        NSLog(@"data -> %@",data);
    };
    [Manager write:data];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if([@"99" isEqualToString:dataStr]) {
            callback(dataStr);
        }
    });

}

- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

/**
 *  搜索蓝牙打印机
 *
 * @param callback 回调
 */
- (void)searchDevices:(WXModuleKeepAliveCallback)callback endCallBack:(WXModuleKeepAliveCallback)endCallBack {
    [Manager stopScan];
    if (Manager.bleConnecter == nil) {
        [Manager didUpdateState:^(NSInteger state) {
            switch (state) {
                    case CBCentralManagerStateUnsupported:
                    NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
                    break;
                    case CBCentralManagerStateUnauthorized:
                    NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
                    break;
                    case CBCentralManagerStatePoweredOff:
                    NSLog(@"Bluetooth is currently powered off.");
                    break;
                    case CBCentralManagerStatePoweredOn:
                    [self startScane:callback];
                    NSLog(@"Bluetooth power on");
                    break;
                    case CBCentralManagerStateUnknown:
                default:
                    break;
            }
        }];
    } else {
        [self startScane:callback];
    }
    
    //10秒之后结束搜索
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [Manager stopScan];
        endCallBack(@"1", true);
    });
    
}

/**
 * 停止扫描
 */
- (void)stopSearchDevices {
    [Manager stopScan];
}

/**
 * 断开连接
 */
- (void)disconnectPrinter {
    [Manager close];
}

/**
 *  连接蓝牙打印机
 *
 * @param deviceAddress 设备标识
 * @param successCallback 回到
 */
- (void)bondDevice:(NSString *)deviceAddress callback:(WXModuleCallback)callback {
    CBPeripheral *peripheral ;//= //[[self.dicts objectForKey:uuid] objectForKey:@"obj"];
    for (int i = 0; i < [self.blueDevices count] ; i ++) {
        NSMutableDictionary *info = [self.blueDevices objectAtIndex:i];
        if ([deviceAddress isEqualToString:[info objectForKey:@"deviceAddress"]]) {
            peripheral = [info objectForKey:@"obj"];
            break;
        }
    }
    if (peripheral) {
        [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack:^(ConnectState state) {
            /**
             NOT_FOUND_DEVICE,//未找到设备
             CONNECT_STATE_DISCONNECT,//断开连接
             CONNECT_STATE_CONNECTING,//连接中
             CONNECT_STATE_CONNECTED,//连接上
             CONNECT_STATE_TIMEOUT,//连接超时
             CONNECT_STATE_FAILT//连接失败
             */
            if (state == CONNECT_STATE_CONNECTED) {
                if (callback) {
                    callback(@"true");
                }
            }else if(state == CONNECT_STATE_TIMEOUT || state == CONNECT_STATE_FAILT){
                if (callback) {
                    callback(@"false");
                }
            }
        }];
    }
    
}

/**
 *  打印标签 json
 */
- (void)printLabel:(NSString *)jsonData callback:(WXModuleCallback)callback {
    
    NSDictionary *dic =  [BluetoothModule dictionaryWithJsonString:jsonData];
    
//    dic = [BluetoothModule readLocalFileWithName:@"data"];
    
    [Manager write:[self tscCommand:dic]];
//    callback(@"true");
}

-(float)findSpeedValue:(NSInteger) sp{
    // SPEED1DIV5(1.5F), SPEED2(2.0F), SPEED3(3.0F), SPEED4(4.0F);
    switch (sp) {
            case 2:
            return 2.0f;
            break;
            case 3:
            return 3.0f;
            break;
            case 4:
            return 4.0f;
            break;
            case 1:
        default:
            return 1.5f;
            break;
    }
}

-(NSData *)tscCommand:(NSDictionary *)options{
    NSInteger width = [[options valueForKey:@"width"] integerValue];
    NSInteger height = [[options valueForKey:@"height"] integerValue];
    NSInteger gap = [[options valueForKey:@"gap"] integerValue];
    NSInteger home = [[options valueForKey:@"home"] integerValue];
    NSString *tear = [options valueForKey:@"tear"];
    if(!tear || ![@"ON" isEqualToString:tear]) tear = @"OFF";
    NSArray *texts = [options objectForKey:@"text"];
    NSArray *qrCodes = [options objectForKey:@"qrcode"];
    NSArray *barCodes = [options objectForKey:@"barcode"];
    NSArray *images = [options objectForKey:@"image"];
    NSArray *reverses = [options objectForKey:@"revers"];
    NSInteger direction = [[options valueForKey:@"direction"] integerValue];
    NSInteger density = [[options valueForKey:@"density"] integerValue];
    NSArray* reference = [options objectForKey:@"reference"];
    NSInteger sound = [[options valueForKey:@"sound"] integerValue];
    NSInteger speed = [[options valueForKey:@"speed"] integerValue];

    TscCommand *tsc = [[TscCommand alloc] init];
    if(speed){
        [tsc addSpeed:[self findSpeedValue:speed]];
    }
    if(density){
        [tsc addDensity:density];
    }
    [tsc addSize:width :height];
    [tsc addGapWithM:gap withN:0];
    [tsc addDirection:direction];
    if(reference && [reference count] ==2){
        NSInteger x = [[reference objectAtIndex:0] integerValue];
        NSInteger y = [[reference objectAtIndex:1] integerValue];
        NSLog(@"refernce  %ld y:%ld ",x,y);
        [tsc addReference:x :y];
    }else{
        [tsc addReference:0 :0];
    }
 
    [tsc addTear:tear];
//    if(home && home == 1){
//        [tsc addBackFeed:16];
//        [tsc addHome];
//    }
    [tsc addCls];
    
    //Add Texts
    for(int i=0; texts && i<[texts count];i++){
        NSDictionary * text = [texts objectAtIndex:i];
        NSString *t = [text valueForKey:@"text"];
        NSInteger x = [[text valueForKey:@"x"] integerValue];
        NSInteger y = [[text valueForKey:@"y"] integerValue];
        NSString *fontType = [text valueForKey:@"fonttype"];
        NSInteger rotation = [[text valueForKey:@"rotation"] integerValue];
        NSInteger xscal = [[text valueForKey:@"xscal"] integerValue];
        NSInteger yscal = [[text valueForKey:@"yscal"] integerValue];
        Boolean bold = [[text valueForKey:@"bold"] boolValue];
        
        [tsc addTextwithX:x withY:y withFont:fontType withRotation:rotation withXscal:xscal withYscal:yscal withText:t];
        if(bold){
            [tsc addTextwithX:x+1 withY:y withFont:fontType withRotation:rotation withXscal:xscal withYscal:yscal withText:t];
            [tsc addTextwithX:x withY:y+1 withFont:fontType withRotation:rotation withXscal:xscal withYscal:yscal withText:t];
        }
    }
    
    //images
    for (int i = 0; images && i < [images count]; i++) {
        NSDictionary *img = [images objectAtIndex:i];
        NSInteger x = [[img valueForKey:@"x"] integerValue];
        NSInteger y = [[img valueForKey:@"y"] integerValue];
        NSInteger imgWidth = [[img valueForKey:@"width"] integerValue];
        NSInteger mode = [[img valueForKey:@"mode"] integerValue];
        NSString *image  = [img valueForKey:@"image"];
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:image options:0];
        UIImage *uiImage = [[UIImage alloc] initWithData:imageData];
        
        [tsc addBitmapwithX:x withY:y withMode:mode withWidth:imgWidth withImage:uiImage];
    }
    
    //QRCode
    for (int i = 0; qrCodes && i < [qrCodes count]; i++) {
        NSDictionary *qr = [qrCodes objectAtIndex:i];
        NSInteger x = [[qr valueForKey:@"x"] integerValue];
        NSInteger y = [[qr valueForKey:@"y"] integerValue];
        NSInteger qrWidth = [[qr valueForKey:@"width"] integerValue];
        NSString *level = [qr valueForKey:@"level"];
        if(!level)level = @"M";
        NSInteger rotation = [[qr valueForKey:@"rotation"] integerValue];
        NSString *code = [qr valueForKey:@"code"];

        [tsc addQRCode:x :y :level :qrWidth :@"A" :rotation :code];
    }
    
    //BarCode
    for (int i = 0; barCodes && i < [barCodes count]; i++) {
        NSDictionary *bar = [barCodes objectAtIndex:i];
        NSInteger x = [[bar valueForKey:@"x"] integerValue];
        NSInteger y = [[bar valueForKey:@"y"] integerValue];
        NSInteger barWide =[[bar valueForKey:@"wide"] integerValue];
        if(!barWide) barWide = 2;
        NSInteger barHeight = [[bar valueForKey:@"height"] integerValue];
        NSInteger narrow = [[bar valueForKey:@"narrow"] integerValue];
        if(!narrow) narrow = 2;
        NSInteger rotation = [[bar valueForKey:@"rotation"] integerValue];
        NSString *code = [bar valueForKey:@"code"];
        NSString *type = [bar valueForKey:@"type"];
        NSInteger readable = [[bar valueForKey:@"readable"] integerValue];
        
        [tsc add1DBarcode:x :y :type :barHeight :readable :rotation :narrow :barWide :code];
    }
    for(int i=0; reverses&& i < [reverses count]; i++){
        NSDictionary *area = [reverses objectAtIndex:i];
        NSInteger ax = [[area valueForKey:@"x"] integerValue];
        NSInteger ay = [[area valueForKey:@"y"] integerValue];
        NSInteger aWidth = [[area valueForKey:@"width"] integerValue];
        NSInteger aHeight = [[area valueForKey:@"height"] integerValue];

        [tsc addReverse:ax :ay :aWidth :aHeight];
    }
    
    if ([options objectForKey:@"count"]) {
        [tsc addPrint:[[options objectForKey:@"count"] intValue] :1];
    }else {
        [tsc addPrint:1 :1];
    }
    if (sound) {
        [tsc addSound:2 :100];
    }
    return [tsc getCommand];
}


/**
 * 搜索蓝牙打印机
 */
- (void) startScane:(WXModuleKeepAliveCallback)successCallback {
    [self.blueDevices removeAllObjects];
    [self.dicts removeAllObjects];
    [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
        if (peripheral.name != nil) {
            NSLog(@"name -> %@",peripheral.name);
//            NSUInteger oldCounts = [self.dicts count];
//            NSMutableDictionary *info = [[NSMutableDictionary alloc]init];
//            [info setObject:peripheral forKey:@"obj"];
//            [info setObject:peripheral.name forKey:@"name"];
//            [self.dicts setObject:info forKey:peripheral.identifier.UUIDString];
            
//            NSUInteger oldCounts = [self.blueDevices count];
            NSMutableDictionary *info = [[NSMutableDictionary alloc]init];
            [info setObject:peripheral.identifier.UUIDString forKey:@"deviceAddress"];
            [info setObject:peripheral forKey:@"obj"];
            [info setObject:peripheral.name forKey:@"deviceName"];
            
            if (![self.dicts objectForKey:peripheral.identifier.UUIDString]) {
                [self.blueDevices addObject:info];
                [self.dicts setObject:info forKey:peripheral.identifier.UUIDString];
                if (successCallback) {
                    successCallback(info,true);
                }
            }
            
        }
    }];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    self.enable = @"true";
    self.support  = @"true";
    switch (central.state) {
            case CBCentralManagerStatePoweredOff:{
                self.enable = @"false";
            }
            break;
            case CBCentralManagerStatePoweredOn:{
                self.enable = @"true";
            }
            break;
            case CBCentralManagerStateResetting:
            break;
            case CBCentralManagerStateUnauthorized:
            break;
            case CBCentralManagerStateUnknown:{
                self.enable = @"false";
            }
            break;
            case CBCentralManagerStateUnsupported:{
                self.support  = @"false";
            }
            break;
        default:
            break;
    }
    
}
                              
- (UIImage*)decodeBase64ToImage:(NSString*)strEncodeData {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}
                              
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

// 读取本地JSON文件
+ (NSDictionary *)readLocalFileWithName:(NSString *)name {
    // 获取文件路径
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    // 将文件数据化
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    // 对数据进行JSON格式化并返回字典形式
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

@end
