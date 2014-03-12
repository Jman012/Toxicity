//
//  TXCDHTNodeObject.h
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ToxDHTNodeConnectionStatus) {
    ToxDHTNodeConnectionStatus_NotConnected,
    ToxDHTNodeConnectionStatus_Connecting,
    ToxDHTNodeConnectionStatus_Connected
} ;

@interface TXCDHTNodeObject : NSObject
{
    
}

@property (nonatomic, strong) NSString *dhtName;
@property (nonatomic, strong) NSString *dhtIP;
@property (nonatomic, strong) NSString *dhtPort;
@property (nonatomic, strong) NSString *dhtKey;
@property (nonatomic, assign) ToxDHTNodeConnectionStatus connectionStatus;


@end
