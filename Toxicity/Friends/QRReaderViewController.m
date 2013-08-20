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
        NSLog(@"Symbol: %@", symbol);
        NSLog(@"Symbol Data: %@", symbol.data);
    }
}

@end
