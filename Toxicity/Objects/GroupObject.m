//
//  GroupObject.m
//  Toxicity
//
//  Created by James Linnell on 9/14/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "GroupObject.h"

@implementation GroupObject

@synthesize groupPulicKey, groupMembers;

- (id)init {
    self = [super init];
    if (self) {
        
        groupPulicKey = @"";
        
        groupMembers = [[NSMutableArray alloc] init];
        
    }
    return self;
}

@end
