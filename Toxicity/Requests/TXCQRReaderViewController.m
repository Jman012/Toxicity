//
//  TXCQRReaderViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/20/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCQRReaderViewController.h"
#import "TXCSingleton.h"
#import "ZBarSDK.h"
#import "TXCAppDelegate.h"

NSString *const QRReaderViewControllerNotificationQRReaderDidAddFriend = @"QRReaderDidAddFriend";

@interface TXCQRReaderViewController ()  <ZBarReaderViewDelegate>

@property (nonatomic, weak) IBOutlet ZBarReaderView *readerView;

- (IBAction)cancelButtonPushed:(id)sender;

@end


@implementation TXCQRReaderViewController



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
    
    self.readerView.readerDelegate = self;
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];

}

- (void)viewDidAppear:(BOOL)animated {
    [self.readerView start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.readerView stop];
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
        
        if ([TXCSingleton friendPublicKeyIsValid:symbol.data]) {
            //actually add friend
            TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
            [ourDelegate addFriend:symbol.data];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:QRReaderViewControllerNotificationQRReaderDidAddFriend object:nil];
            }];
        }
    }
}

@end
