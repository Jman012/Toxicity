//
//  TXCSingleton.m
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCSingleton.h"
#import <dns_sd.h>

extern NSString *const TXCToxAppDelegateUserDefaultsToxData;

@implementation TXCSingleton

- (id)init
{
    if ( self = [super init] )
    {
        self.dhtNodeList = [[NSMutableArray alloc] init];
        [self loadNodesFromFile];
        self.lastAttemptedConnect = time(0);
        srand(self.lastAttemptedConnect);
        
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
        self.currentlyOpenedFriendNumber = [NSIndexPath indexPathForItem:-1 inSection:-1];
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

#pragma mark - Node list methods

- (void)loadNodesFromFile
{
    NSString *nodesFileLocation = [[NSBundle mainBundle] pathForResource:@"ToxDHTNodes" ofType:@"plist"];
    NSMutableDictionary *nodesPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:nodesFileLocation];
    self.dhtNodeList = (NSMutableArray *)nodesPlist[@"Nodes"];
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
                                   if (finishBlock) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           finishBlock(self.defaultAvatarImage);
                                       });
                                   }
                                   
                                   
                               }
                               
                           }];
    
}

@end
