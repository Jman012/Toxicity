//
//  QRReaderViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/20/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Singleton.h"
#import "ZBarSDK.h"
#import "Messenger.h"

@interface QRReaderViewController : UIViewController <ZBarReaderViewDelegate>
{
    IBOutlet ZBarReaderView     *readerView;
}

@property (nonatomic) IBOutlet ZBarReaderView *readerView;

- (IBAction)cancelButtonPushed:(id)sender;

@end
