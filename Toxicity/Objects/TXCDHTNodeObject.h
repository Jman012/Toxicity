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

@property (nonatomic, copy) NSString *dhtName;
@property (nonatomic, copy) NSString *dhtIP;
@property (nonatomic, copy) NSString *dhtPort;
@property (nonatomic, copy) NSString *dhtKey;
@property (nonatomic, assign) ToxDHTNodeConnectionStatus connectionStatus;


@end
