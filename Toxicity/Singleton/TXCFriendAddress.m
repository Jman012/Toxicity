//
//  TXCFriendAddress.m
//  Toxicity
//
//  Created by James Linnell on 3/31/14.
//  Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "TXCFriendAddress.h"
#import <tox.h>
#import <dns_sd.h>
#import "RegexKitLite.h"
#import "TXCSingleton.h"

@implementation TXCFriendAddress

- (id)init
{
    self = [super init];
    if (self) {
        self.originalInput = nil;
        self.resolvedAddress = nil;
    }
    return self;
}

- (id)initWithToxAddress:(NSString *)ambiguousAddress
{
    self = [super init];
    if (self) {
        self.originalInput = ambiguousAddress;
    }
    return self;
}

- (void)resolveAddressWithCompletionBlock:(void (^)(NSString *resolvedAddress, TXCFriendAddressError error))completion
{
    self.completionBlock = completion;
    BOOL refrainFromErroring = NO;
    
    if (!self.originalInput) {
        self.completionBlock(nil, TXCFriendAddressError_Nil);
        return;
    }
    
    // Plain Tox address
    if ([self.originalInput isMatchedByRegex:@"^[0-9A-Fa-f]+$"] && [self.originalInput length] == TOX_FRIEND_ADDRESS_SIZE) {
        TXCFriendAddressError error = [TXCFriendAddress friendAddressIsValid:self.originalInput];
        if (error == TXCFriendAddressError_None){
            self.resolvedAddress = [self.originalInput copy];
            self.completionBlock(self.resolvedAddress, TXCFriendAddressError_None);
            return;
        } else {
            self.completionBlock(nil, error);
            return;
        }
    }
    
    // tox:// address (for plain address)
    if ([self.originalInput isMatchedByRegex:@"tox:\\/\\/[0-9A-Fa-f]+$"]) {
        NSString *addressToCheck = [self.originalInput substringFromIndex:6];
        TXCFriendAddressError error = [TXCFriendAddress friendAddressIsValid:addressToCheck];
        if (error == TXCFriendAddressError_None) {
            self.resolvedAddress = addressToCheck;
            self.completionBlock(self.resolvedAddress, TXCFriendAddressError_None);
            return;
        } else {
            self.completionBlock(nil, error);
            return;
        }
    }
    
    // tox:// address (for DNS lookup)
    if ([self.originalInput isMatchedByRegex:@"tox:\\/\\/.+\\@.+\\..+$"]) {
        NSString *dnsFull = [self.originalInput substringFromIndex:6];
        NSString *dnsUser = [dnsFull componentsSeparatedByString:@"@"][0];
        NSString *dnsServer = [dnsFull componentsSeparatedByString:@"@"][1];
        
        refrainFromErroring = YES; // Because we're using a callback somewhere else, don't let this method call the block
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CFTypeRef retainedContext = CFBridgingRetain(self);
            DNSServiceRef serviceRef;
            DNSServiceQueryRecord(&serviceRef, 0, 0, [[NSString stringWithFormat:@"%@._tox.%@", dnsUser, dnsServer] UTF8String],
                                  kDNSServiceType_TXT, kDNSServiceClass_IN, queryCallback, (void *)retainedContext);
            DNSServiceProcessResult(serviceRef);
            DNSServiceRefDeallocate(serviceRef);
        });
    }
    
    // No other implementations yet
    
    if (!refrainFromErroring) {
        self.completionBlock(nil, TXCFriendAddressError_UnknownFormat);
        return;
    }
}

+ (TXCFriendAddressError)friendAddressIsValid:(NSString *)theKey
{
    if (!theKey) {
        return TXCFriendAddressError_Nil;
    }
    
    if (![theKey isMatchedByRegex:@"^[0-9A-Fa-f]+$"]) {
        return TXCFriendAddressError_Invalid;
    }
    
    if ([theKey length] != TOX_FRIEND_ADDRESS_SIZE*2) {
        return  TXCFriendAddressError_Invalid;
    }
    
    // Our key
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[TXCSingleton sharedSingleton] toxCoreInstance], ourAddress);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
    }
    if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theKey]) {
        return TXCFriendAddressError_OwnKey;
    }
    
    // Friend's key
    for (TXCFriendObject *tempFriend in [[TXCSingleton sharedSingleton] mainFriendList]) {
        if ([[tempFriend.publicKey uppercaseString] isEqualToString:[[theKey substringToIndex:TOX_CLIENT_ID_SIZE*2] uppercaseString]]) {
            return TXCFriendAddressError_AlreadyAdded;
        }
    }
    
    return TXCFriendAddressError_None;
}

#pragma mark - DNS methods

+ (NSString *)addressFromTXTRecord:(NSString *)recordTXT
{
    if (![recordTXT isMatchedByRegex:@"v=tox[0-9]+;id=[0-9A-Fa-f]+$"]) {
        return nil;
    }
    
    NSString *versionString = [recordTXT componentsSeparatedByString:@";"][0];
    NSUInteger version = [[versionString substringFromIndex:5] integerValue];
    
    switch (version) {
        case 1: {
            NSString *idString = [[recordTXT componentsSeparatedByString:@";"][1] substringFromIndex:3];
            NSLog(@"TXT Record: %@\nVersion: %lu, Address: %@", recordTXT, (unsigned long)version, idString);
            return idString;
            break;
        }
            
        default:
            break;
    }
    
    return nil;
}

static void queryCallback(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
                          DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype,
                          uint16_t rrclass, uint16_t rdlen, const void *rdata, uint32_t ttl, void *context)
{
    TXCFriendAddress *bridgedSelf = (__bridge TXCFriendAddress *)(context);

    if (errorCode == kDNSServiceErr_NoError && rdlen > 1) {
        NSMutableData *txtData = [NSMutableData dataWithCapacity:rdlen];
        
        for (uint16_t i = 1; i < rdlen; i += 256) {
            [txtData appendBytes:rdata + i length:MIN(rdlen - i, 255)];
        }
        
        NSString *theTXT = [[NSString alloc] initWithBytes:txtData.bytes length:txtData.length encoding:NSASCIIStringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            TXCFriendAddressError error = [TXCFriendAddress friendAddressIsValid:[TXCFriendAddress addressFromTXTRecord:theTXT]];
            if (error == TXCFriendAddressError_None) {
                bridgedSelf.completionBlock([TXCFriendAddress addressFromTXTRecord:theTXT], TXCFriendAddressError_None);
            } else {
                bridgedSelf.completionBlock(nil, error);
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            bridgedSelf.completionBlock(nil, TXCFriendAddressError_NoData);
        });
    }
}

#pragma mark - Error alert view

- (void)showError:(TXCFriendAddressError)error
{
    NSString *description = @"";
    switch (error) {
        case TXCFriendAddressError_OwnKey:
            description = @"You can't add your own key.";
            break;
            
        case TXCFriendAddressError_AlreadyAdded:
            description = @"You can't add someone already on your friendslist.";
            break;
            
        case TXCFriendAddressError_BadNoSpam:
            description = @"That address is old, the nospam was bad.";
            break;
            
        case TXCFriendAddressError_NoData:
            description = @"Unable to resolve DNS TXT data.";
            break;
            
        case TXCFriendAddressError_Nil:
            description = @"There's no key!";
            break;
            
        case TXCFriendAddressError_Invalid:
            description = @"Unable to add that key, it doesn't follow certain requirements. Is it old?";
            break;
            
        case TXCFriendAddressError_UnknownFormat:
            description = @"Unknown format.";
            break;
            
        default:
            description = @"Unkown Error";
            break;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:description
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
