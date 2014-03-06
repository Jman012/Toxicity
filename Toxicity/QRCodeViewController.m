//
//  QRCodeViewController.m
//  Toxicity
//
//  Created by Виктор Шаманов on 3/6/14.
//  Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "QRCodeViewController.h"
#import "QREncoder/QREncoder.h"

@interface QRCodeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;

@end

@implementation QRCodeViewController

#pragma mark - View controller lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIImage *qrCode = [QREncoder encode:self.code size:4 correctionLevel:QRCorrectionLevelLow scaleFactor:10];
    self.qrImageView.image = qrCode;
}

@end
