//
//  TXCGroupObject.h
//  Toxicity
//
//  Created by James Linnell on 9/14/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TXCGroupObject : NSObject

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSString *groupPublicKey; //string for the public key, needed mainly for accepting invite etc
@property (nonatomic, strong) NSMutableArray *groupMembers; //so far this will be comprised of strings for the names
@property (nonatomic, strong) NSMutableArray *messages;

- (id)initWithPublicKey:(NSString *)key name:(NSString *)name;

@end
