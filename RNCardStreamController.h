//
//  RNCardStreamController.h
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/21/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

@import UIKit;

@protocol RNCardStreamRow <NSObject>

@required
- (UIView *)cardView;

@end

@class RNCardStreamController;

@protocol RNCardStreamControllerDataSource <NSObject>

@required

// Return the number of horizontal sections in the controller
- (NSInteger)numberOfSectionsInCardStreamController:(RNCardStreamController *)cardStreamController;

// Return the number of vertical rows in the section
- (NSInteger)cardStreamController:(RNCardStreamController *)cardStreamController numberOfRowsInSection:(NSInteger)section;

// Return the view for the section. This is the view that takes up most of the screen behind the "cards".
// Keep these views light, they are not reused or cached.
- (UIView *)cardStreamController:(RNCardStreamController *)cardStreamController viewForSection:(NSInteger)section;

// Return the view for a particular row. Classes should be registered prior to use.
- (UIView *)cardStreamController:(RNCardStreamController *)cardStreamController viewForRowAtIndexPath:(NSIndexPath *)indexPath;

// Return the controller for a particular row. This is used at transition time so it should be kept lightweight.
// Controllers are not reused. Avoid heavy lifting in -viewDidLoad
- (UIViewController *)cardStreamController:(RNCardStreamController *)cardStreamController controllerForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol RNCardStreamControllerDelegate <NSObject>

@optional

// Return the height of the row at a certain section. All cards must be the same height. Width is determined by the aspect ratio of the container.
// Default is 100 points
- (CGFloat)widthForRowInCardStreamController:(RNCardStreamController *)cardStreamController forSection:(NSInteger)section;

@end

@interface RNCardStreamController : UIViewController

// The dataSource for the controller. Cannot use this controller with a dataSource
@property (nonatomic, weak) id <RNCardStreamControllerDataSource> dataSource;

// The delegate that handles touches and interactions
@property (nonatomic, weak) id <RNCardStreamControllerDelegate> delegate;

// Reload data from the dataSource and force layout
- (void)reloadData;

// Register a UIViewController subclass to be reused
- (void)registerClass:(Class)aClass forReuseIdentifier:(NSString *)identifier;

// Register a Nib to be reused
- (void)registerNib:(UINib *)nib forReuseIdentifier:(NSString *)identifier;

// Deque a view. If a dequeable view does not exist, one will be created for you
- (id)dequeReusableViewWithIdentifier:(NSString *)identifier;

// Get all visible row views for the visible section
- (NSArray *)visibleRowViews;

// Hide the status bar just like Paper
// Default YES
@property (nonatomic) BOOL statusBarHidden;

// The vertical spacing between each card.
// Default 3
@property (nonatomic) CGFloat cardVerticalSpacing;

@end
