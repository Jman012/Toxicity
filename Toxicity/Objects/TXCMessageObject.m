//
//  TXCMessageObject.m
//  Toxicity
//
//  Created by James Linnell on 8/15/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCMessageObject.h"

@implementation TXCMessageObject

- (id)initWithMessage:(NSString *)message origin:(MessageOrigin)origin family:(MessageFamily)family type:(MessageType)type senderName:(NSString *)senderName senderKey:(NSString *)senderKey recipientKey:(NSString *)recipientKey
{
    self = [super init];
    if (self) {
        self.message = message;
        self.origin = origin;
        self.family = family;
        self.type = type;
        self.senderName = senderName;
        self.senderKey = senderKey;
        self.recipientKey = recipientKey;
        
        self.didFailToSend = FALSE;
    }
    return self;
}

@end
