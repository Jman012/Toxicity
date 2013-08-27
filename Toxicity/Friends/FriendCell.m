//
//  FriendCell.m
//  Toxicity
//
//  Created by James Linnell on 8/25/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "FriendCell.h"

@implementation FriendCell

@synthesize nickLabel = _nickLabel, messageLabelText = _messageLabelText, statusColor = _statusColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        cellBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        
        /*****Background Grey Color*****/
        mainLayerBG = [CALayer layer];
        mainLayerBG.frame = self.bounds;
        mainLayerBG.backgroundColor = [[UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.0f] CGColor];
        mainLayerBG.name = @"Background";
        [cellBackgroundView.layer insertSublayer:mainLayerBG atIndex:0];
        
        /*****Background Gradient*****/
        mainLayerGradient = [CAGradientLayer layer];
        mainLayerGradient.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 1, self.bounds.size.width, self.bounds.size.height - 1);
        UIColor *top = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.4f alpha:1.0f];
        UIColor *bottom = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.3f alpha:1.0f];
        mainLayerGradient.colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
        mainLayerGradient.name = @"Gradient";
        
        [cellBackgroundView.layer insertSublayer:mainLayerGradient atIndex:1];
        
        [self setBackgroundView:cellBackgroundView];
        
        /*****Friend Status Image*****/
        //default is gray
        statusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 16, 0, 16, 64)];
        [statusImageView setImage:[UIImage imageNamed:@"status-gray"]];
        [self addSubview:statusImageView];
        
        /*****Nick Label*****/
        self.nickLabel = [[UILabel alloc] init];
        [self.nickLabel setTextColor:[UIColor whiteColor]];
        [self.nickLabel setBackgroundColor:[UIColor clearColor]];
        [self.nickLabel setShadowColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f]];
        [self.nickLabel setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        [self.nickLabel setFont:[UIFont systemFontOfSize:18.0f]];
        
        [self.contentView addSubview:self.nickLabel];
        
        /*****Message Label*****/
        messageLabel = [[UILabel alloc] init];
        [messageLabel setTextAlignment:NSTextAlignmentLeft];
        [messageLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [messageLabel setNumberOfLines:2];
        
        [messageLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setFont:[UIFont systemFontOfSize:12.0f]];

        [messageLabel setShadowColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f]];
        [messageLabel setShadowOffset:CGSizeMake(0.5f, 0.5f)];
        
        [self.contentView addSubview:messageLabel];
        
        /*****Selected Background View*****/
        UIView *selected = [[UIView alloc] initWithFrame:self.bounds];
        CALayer *selectedBGLayer = [CALayer layer];
        selectedBGLayer.frame = self.bounds;
        selectedBGLayer.backgroundColor = [[UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.0f] CGColor];
        selectedBGLayer.name = @"SelectedBackground";
        [selected.layer insertSublayer:selectedBGLayer atIndex:0];
        
        CAGradientLayer *selectedGrad = [CAGradientLayer layer];
        selectedGrad.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 1, self.bounds.size.width, self.bounds.size.height - 1);
        UIColor *selectedTop = [UIColor colorWithHue:0.5f saturation:0.0f brightness:0.2f alpha:1.0f];
        UIColor *selectedBottom = [UIColor colorWithHue:0.5f saturation:0.0f brightness:0.3f alpha:1.0f];
        selectedGrad.colors = [NSArray arrayWithObjects:(id)[selectedTop CGColor], (id)[selectedBottom CGColor], nil];
        selectedGrad.name = @"SelectedGradient";
        [selected.layer insertSublayer:selectedGrad atIndex:1];
        
//        selected.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
        
        self.selectedBackgroundView = selected;
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    
//    NSLog(@"setSelected: %d", (int)selected);
//    mainLayerGradient.hidden = selected;
//    mainLayerBG.hidden = selected;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //calculates the desired width. if it's in editing mde (with the red delete button) use the contentView width and 20px padding (10px on each side)
    //and if not editing use entire width minus 20px padding (10px each side) and the width of the status view
    CGFloat labelWidth;
    if (self.editing) {
        labelWidth = self.contentView.bounds.size.width - 20;
    } else {
        labelWidth = self.bounds.size.width - 20 - statusImageView.frame.size.width;
    }
    
    /*****Nick Label*****/
    [self.nickLabel setFrame:CGRectMake(10, 8, labelWidth, 22)];
    
    /*****Message Label*****/
    [messageLabel setFrame:CGRectMake(10, 30, labelWidth, messageLabel.frame.size.height)];
    
    /*****Gradient*****/
    cellBackgroundView.frame = self.bounds;
    //have to redo gradient on height change
    mainLayerGradient.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 1, self.bounds.size.width, self.bounds.size.height - 1);
    mainLayerBG.frame = self.bounds;
    
    /*****Selected View*****/
    for (CAGradientLayer *grad in self.selectedBackgroundView.layer.sublayers) {
        if ([grad.name isEqualToString:@"SelectedGradient"]) {
            grad.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 1, self.bounds.size.width, self.bounds.size.height - 1);
        }
    }
}

- (void)setStatusColor:(FriendCellStatusColor)statusColor {
    switch (statusColor) {
        case FriendCellStatusColor_Gray:
            [statusImageView setImage:[UIImage imageNamed:@"status-gray"]];
            break;
            
        case FriendCellStatusColor_Green:
            [statusImageView setImage:[UIImage imageNamed:@"status-green"]];
            break;
            
        case FriendCellStatusColor_Yellow:
            [statusImageView setImage:[UIImage imageNamed:@"status-yellow"]];
            break;
            
        case FriendCellStatusColor_Red:
            [statusImageView setImage:[UIImage imageNamed:@"status-red"]];
            break;
            
        default:
            break;
    }
}

- (void)setMessageLabelText:(NSString *)messageLabelText {
    [messageLabel setText:messageLabelText];
    [messageLabel sizeToFit];
    CGRect newFrame = messageLabel.frame;
    
    CGFloat labelWidth;
    if (self.editing) {
        labelWidth = self.contentView.bounds.size.width - 20;
    } else {
        labelWidth = self.bounds.size.width - 20 - statusImageView.frame.size.width;
    }
    
    newFrame.size.width = labelWidth;
}

@end
