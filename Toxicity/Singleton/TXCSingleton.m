//
//  TXCSingleton.m
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCSingleton.h"

extern NSString *const TXCToxAppDelegateUserDefaultsToxData;

@implementation TXCSingleton

@synthesize dhtNodeList, currentConnectDHT;
@synthesize userNick, userStatusMessage, userStatusType;
@synthesize pendingFriendRequests, mainFriendList, mainFriendMessages;
@synthesize currentlyOpenedFriendNumber, toxCoreInstance;
@synthesize defaultAvatarImage, avatarImageCache;
@synthesize groupList, pendingGroupInvites, pendingGroupInviteFriendNumbers, groupMessages;

- (id)init
{
    if ( self = [super init] )
    {
        self.dhtNodeList = [[NSMutableArray alloc] init];
        self.currentConnectDHT = [[TXCDHTNodeObject alloc] init];
        
        self.userNick = @"";
        self.userStatusMessage = @"";
        self.userStatusType = TXCToxFriendUserStatus_None;
        
        self.pendingFriendRequests = [[NSMutableDictionary alloc] init];
        
        self.mainFriendList = [[NSMutableArray alloc] init];
        self.mainFriendMessages = [[NSMutableArray alloc] init];
        
        self.defaultAvatarImage = [UIImage imageNamed:@"default-avatar"];
        self.avatarImageCache = [[NSCache alloc] init];
        
        self.groupList = [[NSMutableArray alloc] init];
        self.pendingGroupInvites = [[NSMutableDictionary alloc] init];
        self.pendingGroupInviteFriendNumbers = [[NSMutableDictionary alloc] init];
        self.groupMessages = [[NSMutableArray alloc] init];
        
        //if -1, no chat windows open
        currentlyOpenedFriendNumber = [NSIndexPath indexPathForItem:-1 inSection:-1];
    }
    return self;
    
}

+ (TXCSingleton *)sharedSingleton
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Generic class methods

+ (BOOL)friendNumber:(int)theNumber matchesKey:(NSString *)theKey {
    
    if (!(theNumber < [[[TXCSingleton sharedSingleton] mainFriendList] count])) {
        return NO;
    }
    
    TXCFriendObject *tempFriend = [[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:theNumber];
    if ([theKey isEqualToString:tempFriend.publicKey]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)friendPublicKeyIsValid:(NSString *)theKey {
    //validate
    if (!theKey) {
        return NO;
    }
    
    if ([theKey isEqualToString:@""]) {
        return NO;
    }
    
    @try {
        if ([[theKey substringToIndex:6] isEqualToString:@"tox://"]) {
            theKey = [theKey substringFromIndex:6];
        }
    }
    @catch (NSException *e) {
        return NO;
    }
    
    @try {
        NSError *error = NULL;
        NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
        NSUInteger matchKey = [regexKey numberOfMatchesInString:theKey options:0 range:NSMakeRange(0, [theKey length])];
        if ([theKey length] != (TOX_FRIEND_ADDRESS_SIZE * 2) || matchKey == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
    @catch (NSException *e) {
        return NO;
    }
    
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[TXCSingleton sharedSingleton] toxCoreInstance], ourAddress);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
    }
    if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theKey]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can't add your own key, silly!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
    //todo: check to make sure it's not that of a friend already added
    for (TXCFriendObject *tempFriend in [[TXCSingleton sharedSingleton] mainFriendList]) {
        if ([[tempFriend.publicKeyWithNoSpam uppercaseString] isEqualToString:[theKey uppercaseString]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You've already added that friend!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
    
    return YES;
}

+ (void)saveFriendListInUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (TXCFriendObject *arrayFriend in [[TXCSingleton sharedSingleton] mainFriendList]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[arrayFriend copy]];
        [array addObject:data];
    }
    [prefs setObject:array forKey:@"friend_list"];
    [prefs synchronize];
}

+ (void)saveToxDataInUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    uint32_t toxLength = tox_size([[TXCSingleton sharedSingleton] toxCoreInstance]);
    uint8_t *toxBuffer = malloc(toxLength);
    tox_save([[TXCSingleton sharedSingleton] toxCoreInstance], toxBuffer);
    NSData *toxData = [[NSData alloc] initWithBytes:toxBuffer length:toxLength];
    [prefs setObject:toxData forKey:TXCToxAppDelegateUserDefaultsToxData];
    [prefs synchronize];
}

+ (void)saveGroupListInUserDefaults {
    
}

#pragma mark - Avatar Cache methods

- (void)avatarImageForKey:(NSString *)key type:(AvatarType)type finishBlock:(void (^)(UIImage *))finishBlock {
    UIImage *tempImage = [self.avatarImageCache objectForKey:key];
    
    if (tempImage) {
        if (finishBlock)
            finishBlock(tempImage);
        
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadAvatarForKey:key type:type finishBlock:finishBlock];
        });
    }
    
}

- (void)loadAvatarForKey:(NSString *)theKey type:(AvatarType)type finishBlock:(void (^)(UIImage *))finishBlock {
    //todo: check our filesystem or w/e to see if we already have an avatar saved, if not, fetch a new one
        
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *ourDocumentLocation = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSArray *documentContents = [fileManager contentsOfDirectoryAtPath:ourDocumentLocation error:&error];
    
    __block BOOL imageFoundInFilesystem = NO;
    if (!error) {
        [documentContents enumerateObjectsUsingBlock:^(NSString *tempFilename, NSUInteger idx, BOOL *stop) {
            if ([tempFilename isEqualToString:[theKey stringByAppendingString:@".png"]]) {
                //we already have a .png for this firned's public key
                //load the image from this file
                UIImage *loadedAvatarImage = [UIImage imageWithContentsOfFile:[ourDocumentLocation stringByAppendingPathComponent:tempFilename]];
                
                //put image into cache
                if (loadedAvatarImage) {
                    [self.avatarImageCache setObject:loadedAvatarImage forKey:theKey];
                    if (finishBlock) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            finishBlock(loadedAvatarImage);
                        });
                    }
                    
                } else {
                    //image did not load correctly, lets download it and rewrite it
                    [self fetchRobohashAvatarForKey:theKey type:type finishBlock:finishBlock];
                    
                }
                
                //nothing else to do, break out of the for loop
                imageFoundInFilesystem = YES;
                *stop = YES;            }
        }];
    }
    
    if (imageFoundInFilesystem == NO) {
        //if we've made it this far into the method, that means no .png was found or loading it failed.
        //therefore we must download one:
        [self fetchRobohashAvatarForKey:theKey type:type finishBlock:finishBlock];
    }
}

- (void)fetchRobohashAvatarForKey:(NSString *)theKey type:(AvatarType)type finishBlock:(void (^)(UIImage *))finishBlock {
    //todo: changed the size based on display?
    NSURL *roboHashURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://robohash.org/%@.png?size=96x96%@", theKey, (type == AvatarType_Group ? @"&set=set3" : @"")]];
    NSURLRequest *request = [NSURLRequest requestWithURL:roboHashURL];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               UIImage *downloadedImage = nil;
                               if (!error && data) {
                                   sleep(1); //ensure that the table view is all done loading, so cellForRow works
                                   downloadedImage = [[UIImage alloc] initWithData:data];
                               }
                               
                               if (downloadedImage) {
                                   [self.avatarImageCache setObject:downloadedImage forKey:theKey];
                                   
                                   NSString *ourDocumentLocation = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
                                   NSString *theFilename = [[ourDocumentLocation stringByAppendingPathComponent:theKey] stringByAppendingPathExtension:@"png"];
                                   [UIImagePNGRepresentation(downloadedImage) writeToFile:theFilename atomically:YES];
                                   
                                   if (finishBlock) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           finishBlock(downloadedImage);
                                       });
                                   }
                                   
                                   
                               } else {
                                   //downlaod didn't work, use the default
                                   [self.avatarImageCache setObject:self.defaultAvatarImage forKey:theKey];
                                   if (finishBlock)
                                       finishBlock(self.defaultAvatarImage);
                                   
                                   
                               }
                               
                           }];
    
}

@end
