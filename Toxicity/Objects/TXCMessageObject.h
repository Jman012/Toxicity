//
//  TXCMessageObject.h
//  Toxicity
//
//  Created by James Linnell on 8/15/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MessageOrigin) {
    MessageLocation_Me,
    MessageLocation_Them
} ;

@interface TXCMessageObject : NSObject

@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) MessageOrigin  origin;
@property (nonatomic, assign, getter = isDidFailToSend) BOOL didFailToSend;
@property (nonatomic, assign, getter = isGroupMessage) BOOL groupMessage;
@property (nonatomic, assign, getter = isActionMessage) BOOL actionMessage;
@property (nonatomic, copy) NSString *recipientKey;
@property (nonatomic, copy) NSString *senderKey;
@property (nonatomic, copy) NSString *senderName;

@end
