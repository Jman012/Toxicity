//
//  TXCDHTNodeObject.m
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCDHTNodeObject.h"

@implementation TXCDHTNodeObject

- (id)init {
    self = [super init];
    if (self) {
        self.dhtName = [[NSString alloc] init];
        self.dhtIP = [[NSString alloc] init];
        self.dhtPort = [[NSString alloc] init];
        self.dhtKey = [[NSString alloc] init];
        self.connectionStatus = ToxDHTNodeConnectionStatus_NotConnected;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.dhtName = [decoder decodeObjectForKey:@"dht_name"];
        self.dhtIP = [decoder decodeObjectForKey:@"dht_ip"];
        self.dhtPort = [decoder decodeObjectForKey:@"dht_port"];
        self.dhtKey = [decoder decodeObjectForKey:@"dht_key"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.dhtName forKey:@"dht_name"];
    [encoder encodeObject:self.dhtIP forKey:@"dht_ip"];
    [encoder encodeObject:self.dhtPort forKey:@"dht_port"];
    [encoder encodeObject:self.dhtKey forKey:@"dht_key"];
}

- (id)copy {
    TXCDHTNodeObject *temp = [[TXCDHTNodeObject alloc] init];
    temp.dhtName = [self.dhtName copy];
    temp.dhtIP = [self.dhtIP copy];
    temp.dhtPort = [self.dhtPort copy];
    temp.dhtKey = [self.dhtKey copy];
    temp.connectionStatus = self.connectionStatus;
    
    return temp;
}

@end
