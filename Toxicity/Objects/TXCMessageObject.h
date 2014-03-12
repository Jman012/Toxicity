//
//  TXCMessageObject.h
//  Toxicity
//
//  Created by James Linnell on 8/15/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MessageOrigin) {
    MessageLocation_Me,
    MessageLocation_Them
} ;

@interface TXCMessageObject : NSObject

@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) MessageOrigin  origin;
@property (nonatomic, assign, getter = isDidFailToSend, setter = setDidFailToSend:) BOOL didFailToSend;
@property (nonatomic, assign, getter = isGroupMessage, setter = setIsGroupMessage:) BOOL groupMessage;
@property (nonatomic, assign, getter = isActionMessage, setter = setIsActionMessage:) BOOL actionMessage;
@property (nonatomic, copy) NSString *recipientKey;
@property (nonatomic, copy) NSString *senderKey;
@property (nonatomic, copy) NSString *senderName;

@end
