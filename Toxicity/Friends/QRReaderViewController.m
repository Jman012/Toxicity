//
//  QRReaderViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/20/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "QRReaderViewController.h"

@interface QRReaderViewController ()

@end

@implementation QRReaderViewController

@synthesize readerView;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    readerView.readerDelegate = self;
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];

}

- (void)viewDidAppear:(BOOL)animated {
    [readerView start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [readerView stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ZBar Delegate

- (void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
    for (ZBarSymbol *symbol in symbols) {
        NSLog(@"Symbol Data: %@", symbol.data);
        
        //make sure it's an actualvalid key
        
        //validate
        NSError *error = NULL;
        NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
        NSUInteger matchKey = [regexKey numberOfMatchesInString:symbol.data options:0 range:NSMakeRange(0, [symbol.data length])];
        if ([symbol.data length] != (FRIEND_ADDRESS_SIZE * 2) || matchKey == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        char convertedKey[(FRIEND_ADDRESS_SIZE * 2) + 1];
        int pos = 0;
        uint8_t ourAddress[FRIEND_ADDRESS_SIZE];
        getaddress([[Singleton sharedSingleton] toxCoreMessenger], ourAddress);
        for (int i = 0; i < FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
        }
        if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:symbol.data]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can't add your own key, silly!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        //todo: check to make sure it's not that of a friend already added
        for (FriendObject *tempFriend in [[Singleton sharedSingleton] mainFriendList]) {
            if ([[tempFriend.publicKey lowercaseString] isEqualToString:[symbol.data lowercaseString]]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You've already added that friend!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [alert show];
                return;
            }
        }
        
        //actually add friend
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFriend" object:nil userInfo:@{@"new_friend_key": symbol.data}];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"QRReaderDidAddFriend" object:nil];
        }];
    }
}

@end
