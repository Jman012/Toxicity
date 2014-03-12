//
//  TXCGroupObject.m
//  Toxicity
//
//  Created by James Linnell on 9/14/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCGroupObject.h"

@implementation TXCGroupObject

@synthesize groupPulicKey, groupMembers, groupName;

- (id)init {
    self = [super init];
    if (self) {
        
        groupPulicKey = @"";
        
        groupMembers = [[NSMutableArray alloc] init];
        
        groupName = @"";
        
    }
    return self;
}

@end
