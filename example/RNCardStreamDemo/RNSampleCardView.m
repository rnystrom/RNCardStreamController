//
//  RNSampleCardView.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/23/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNSampleCardView.h"

@implementation RNSampleCardView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 4;
    self.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1].CGColor;
    self.layer.borderWidth = 0.5;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.4;
    self.clipsToBounds = NO;
}

@end
