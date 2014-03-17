//
//  TXCQRReaderViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/20/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCQRReaderViewController.h"
#import "TXCSingleton.h"
#import "TXCAppDelegate.h"
#import <ZBarSDK.h>

NSString *const QRReaderViewControllerNotificationQRReaderDidAddFriend = @"QRReaderDidAddFriend";

@interface TXCQRReaderViewController ()  <ZBarReaderViewDelegate>

@property (nonatomic, weak) IBOutlet ZBarReaderView *readerView;

- (IBAction)cancelButtonPushed:(id)sender;

@end


@implementation TXCQRReaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.readerView.readerDelegate = self;
    self.readerView.allowsPinchZoom = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.readerView start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.readerView stop];
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
