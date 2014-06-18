//
//  TXCGroupObject.m
//  Toxicity
//
//  Created by James Linnell on 9/14/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCGroupObject.h"

@implementation TXCGroupObject

- (id)initWithPublicKey:(NSString *)key name:(NSString *)name {
    self = [super init];
    if (self) {
        
        self.groupPublicKey = key;
        self.groupName = name;
        self.groupMembers = [[NSMutableArray alloc] init];
        self.messages = [[NSMutableArray alloc] init];
        
    }
    return self;
}

@end
