//
// Created by Виктор Шаманов on 3/12/14.
// Copyright (c) 2014 JamesTech. All rights reserved.
//

#import "TXCStatusLabel.h"

@interface TXCStatusLabel ()

@property (strong, nonatomic) NSString *textValue;
@property (strong, nonatomic) UIFont *fontValue;
@property (strong, nonatomic) UIColor *colorValue;


@end

@implementation TXCStatusLabel

#pragma mark - Public methods

- (void)setStatusColor:(UIColor *)statusColor {
    if (_statusColor != statusColor) {
        _statusColor = statusColor;
        [self updateTextAndStatus];
    }
}

#pragma mark - Private methods

- (void)updateTextAndStatus {

    NSMutableDictionary *statusStringAttributes = [NSMutableDictionary dictionary];

    if (self.statusColor) {
        statusStringAttributes[NSForegroundColorAttributeName] = self.statusColor;
    }

    if (!self.statusFont) {
        self.statusFont = self.font;
    }

    if (self.statusFont) {
        statusStringAttributes[NSFontAttributeName] = self.statusFont;
    }

    NSAttributedString *statusAttributedString = [[NSAttributedString alloc] initWithString:self.statusString
                                                                                 attributes:statusStringAttributes];




    NSMutableDictionary *valueStringAttributes = [NSMutableDictionary dictionary];

    if (self.fontValue) {
        valueStringAttributes[NSFontAttributeName] = self.fontValue;
    }

    if (self.colorValue) {
        valueStringAttributes[NSForegroundColorAttributeName] = self.colorValue;
    }

    if (!valueStringAttributes.count) {
        valueStringAttributes = nil;
    }

    if (!self.textValue) {
        self.textValue = @"";
    }

    NSAttributedString *valueAttributedString = [[NSAttributedString alloc] initWithString:self.textValue
                                                                                attributes:valueStringAttributes];




    self.attributedText = ({
        NSMutableAttributedString *mutableAttributedText = [[NSMutableAttributedString alloc] init];

        [mutableAttributedText appendAttributedString:statusAttributedString];

        [mutableAttributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

        [mutableAttributedText appendAttributedString:valueAttributedString];

        mutableAttributedText.copy;
    });

}

- (NSString *)statusString {
    if (!_statusString) {
        _statusString = @"●";
    }
    return _statusString;
}

- (void)setTextValue:(NSString *)textValue {
    if (_textValue != textValue) {
        _textValue = textValue;
        [self updateTextAndStatus];
    }
}

- (void)setFontValue:(UIFont *)fontValue {
    if (_fontValue != fontValue) {
        _fontValue = fontValue;
        [self updateTextAndStatus];
    }
}

- (void)setColorValue:(UIColor *)colorValue {
    if (_colorValue != colorValue) {
        _colorValue = colorValue;
        [self updateTextAndStatus];
    }
}

#pragma mark - UILabel methods

#pragma mark - Setters

- (void)setText:(NSString *)text {
    self.textValue = text;
}

- (void)setFont:(UIFont *)font {
    self.fontValue = font;
}

- (void)setTextColor:(UIColor *)textColor {
    self.colorValue = textColor;
}

#pragma mark - Getters

- (NSString *)text {
    return _textValue;
}

- (UIFont *)font {
    return _fontValue;
}

- (UIColor *)textColor {
    return _colorValue;
}




@end