//
//  RNCardStreamController.m
//  RNCardStreamDemo
//
//  Created by Ryan Nystrom on 7/21/14.
//  Copyright (c) 2014 Ryan Nystrom. All rights reserved.
//

#import "RNCardStreamController.h"
#import <objc/runtime.h>
#import <POP.h>

// Private class to help RNCardStreamController pull out the contentView on reuse
@interface RNCardStreamReusableCell : UICollectionViewCell
@property (nonatomic, copy) void (^reuseBlock) ();
@end

@implementation RNCardStreamReusableCell

- (void)prepareForReuse {
    [super prepareForReuse];
    if (self.reuseBlock) {
        self.reuseBlock();
    }
}

@end

// Private class that handles basic to/from animations
// http://www.objc.io/issue-5/view-controller-transitions.html
// Implementation is at the end of this file
@interface RNCardStreamAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end

// Delegates transition animations
@interface RNCardStreamTransitionDelegate : NSObject <UINavigationControllerDelegate>

@property (nonatomic, strong) RNCardStreamAnimator *animator;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition* interactionController;

@end

@implementation RNCardStreamTransitionDelegate

- (instancetype)init {
    if (self = [super init]) {
        _animator = [[RNCardStreamAnimator alloc] init];
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    return self;
}

- (void)setNavigationController:(UINavigationController *)navigationController {
    if (_navigationController != navigationController) {
        if (self.panGesture.view) {
            [self.panGesture.view removeGestureRecognizer:self.panGesture];
        }
        
//        _navigationController = navigationController;
//        [_navigationController.view addGestureRecognizer:self.panGesture];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return self.animator;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return self.interactionController;
//    return nil;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    UIView* view = self.navigationController.view;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:view];
        if (location.x < CGRectGetMidX(view.bounds) && self.navigationController.viewControllers.count > 1) { // left half
            self.interactionController = [UIPercentDrivenInteractiveTransition new];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:view];
        CGFloat d = fabs(translation.x / CGRectGetWidth(view.bounds));
        [self.interactionController updateInteractiveTransition:d];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([recognizer velocityInView:view].x > 0) {
            [self.interactionController finishInteractiveTransition];
        } else {
            [self.interactionController cancelInteractiveTransition];
        }
        self.interactionController = nil;
    }
}

@end

@interface RNCardStreamController ()
<UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

// UIView reuse, I wouldn't mess with these
@property (nonatomic, strong) NSMutableArray *reusePool;
@property (nonatomic, strong) NSMutableDictionary *registeredReuseIdentifiers;

// Stores all non-reused views
@property (nonatomic, strong) NSMutableDictionary *sectionViews;
@property (nonatomic, strong) NSMutableDictionary *sectionCollectionViews;

@property (nonatomic, assign) NSInteger visibleSectionIndex;

@property (nonatomic, strong) RNCardStreamTransitionDelegate *cardTransitionDelegate;

@property (nonatomic, strong) UIView *selectedView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

// Private category to attach rn_reuseIdentifier strings to UIViews
@interface UIView (RNCardStreamController)
@property (nonatomic, strong) NSString *rn_reuseIdentifier;
@end

@implementation UIView (RNCardStreamController)

static const void *kRNCardStreamControllerReuseIdentifier = &kRNCardStreamControllerReuseIdentifier;

- (NSString *)rn_reuseIdentifier {
    return objc_getAssociatedObject(self, kRNCardStreamControllerReuseIdentifier);
}

- (void)setRn_reuseIdentifier:(NSString *)rn_reuseIdentifier {
    objc_setAssociatedObject(self, kRNCardStreamControllerReuseIdentifier, rn_reuseIdentifier, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation RNCardStreamController

NSString * const kRNCardStreamControllerCollectionCellIdentifier = @"kRNCardStreamControllerCollectionCellIdentifier";

#pragma mark - Init

- (id)init {
    if (self = [super init]) {
        [self rn_init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self rn_init];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self rn_init];
    }
    return self;
}

- (void)rn_init {
    _reusePool = [NSMutableArray new];
    _registeredReuseIdentifiers = [NSMutableDictionary new];
    _sectionViews = [NSMutableDictionary new];
    _sectionCollectionViews = [NSMutableDictionary new];
    _cardVerticalSpacing = 3.f;
    _statusBarHidden = YES;
    _cardTransitionDelegate = [[RNCardStreamTransitionDelegate alloc] init];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGesture.delegate = self;
}

- (void)loadView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    self.scrollView.bounces = NO;
    
    [self.scrollView addGestureRecognizer:self.panGesture];
    
    [self.panGesture requireGestureRecognizerToFail:self.scrollView.panGestureRecognizer];
    
    self.view = self.scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSAssert(self.navigationController, @"RNCardStreamController uses UINavigationController with a transition controller. UINavigationController is required.");
    
    self.cardTransitionDelegate.navigationController = self.navigationController;
    self.navigationController.delegate = self.cardTransitionDelegate;
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // controller relies on the nav bar being hidden
    // if you really want it you can subclass RNCardStreamController, but it's never been tested
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - View Reuse

- (void)registerClass:(Class)aClass forReuseIdentifier:(NSString *)identifier {
    NSAssert(self.registeredReuseIdentifiers[identifier] == nil, @"Cannot re-register the reuse identifier %@.",identifier);
    NSAssert([aClass isSubclassOfClass:UIView.class], @"Cannot register a class that isn't a subclass of UIView.");
    
    [self registerType:aClass forReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forReuseIdentifier:(NSString *)identifier {
    NSAssert(self.registeredReuseIdentifiers[identifier] == nil, @"Cannot re-register the reuse identifier %@.",identifier);
    
    [self registerType:nib forReuseIdentifier:identifier];
}

// Private method to be DRY
- (void)registerType:(id)type forReuseIdentifier:(NSString *)identifier {
    self.registeredReuseIdentifiers[identifier] = type;
}

- (void)returnViewToThePool:(UIView *)view {
    [view removeFromSuperview];
    [self.reusePool addObject:view];
}

#pragma mark - Setters

- (void)setDataSource:(id<RNCardStreamControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    if (statusBarHidden != _statusBarHidden) {
        _statusBarHidden = statusBarHidden;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - Getters

// create a section view if it doesn't exist yet, otherwise get it from the table
- (UIView *)sectionViewForIndex:(NSInteger)index {
    id idx = @(index);
    
    if (! self.sectionViews[idx]) {
        id view = [self.dataSource cardStreamController:self viewForSection:index];
        
        [view setClipsToBounds:YES];
        
        self.sectionViews[idx] = view;
    }
    
    return self.sectionViews[idx];
}

// create a collection view if it doesn't exist yet, otherwise get it from the table
- (UICollectionView *)collectionViewForSection:(NSInteger)section {
    id idx = @(section);
    
    if (! self.sectionCollectionViews[idx]) {
        id view = [self createRowCollectionView];
        self.sectionCollectionViews[idx] = view;
    }
    
    return self.sectionCollectionViews[idx];
}

// Should be used in dataSource method -cardStreamController:viewForRowAtIndexPath:
- (id)dequeReusableViewWithIdentifier:(NSString *)identifier {
    NSAssert(identifier, @"Cannot dequeue a view without an identifier.");
    
    UIView *view;
    
    // find a reuseable view. can be nil
    for (UIView *poolView in self.reusePool) {
        if ([poolView.rn_reuseIdentifier isEqualToString:identifier]) {
            view = poolView;
            break;
        }
    }
    
    // no view to reuse, instantiate it
    if (! view) {
        id reuseKey = self.registeredReuseIdentifiers[identifier];
        
        NSAssert(reuseKey, @"Must have registered identifier %@ with a Class or UINib.",identifier);
        
        // instantiate view from UINib
        if ([reuseKey isKindOfClass:UINib.class]) {
            UINib *nib = reuseKey;
            NSArray *objs = [nib instantiateWithOwner:nil options:nil];
            
            NSAssert(objs.count > 0, @"Nib %@ could not be instantiated. Have you added it to your bundle?",nib);
            
            view = [objs firstObject];
        // instantiate view from Class
        } else {
            Class aClass = reuseKey;
            view = [[aClass alloc] init];
        }
    // remove view so it isn't reused twice
    } else {
        [self.reusePool removeObject:view];
    }
    
    view.rn_reuseIdentifier = identifier;
    
    return view;
}

// helper method to create and configure a new UICollectionView for a section
- (UICollectionView *)createRowCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    view.showsHorizontalScrollIndicator = NO;
    view.showsVerticalScrollIndicator = NO;
    view.backgroundColor = [UIColor clearColor];
    view.dataSource = self;
    view.delegate = self;
    view.clipsToBounds = NO;
    
    view.bounces = YES;
    view.alwaysBounceHorizontal = NO;
    view.alwaysBounceVertical = YES;
    
//    [view addGestureRecognizer:self.panGesture];
    [self.panGesture requireGestureRecognizerToFail:view.panGestureRecognizer];
    
    // private class used to help w/ view reuse. overrides -prepareForReuse and calls a block
    [view registerClass:RNCardStreamReusableCell.class forCellWithReuseIdentifier:kRNCardStreamControllerCollectionCellIdentifier];
    
    return view;
}

- (NSInteger)indexOfSectionView:(UIView *)sectionView {
    // assumes collection views have a parent scroll view and then a section view
    NSNumber *idx = [[self.sectionViews allKeysForObject:sectionView.superview.superview] firstObject];
    if (idx) {
        return idx.integerValue;
    }
    return NSNotFound;
}

- (UICollectionView *)visibleCollectionView {
    return self.sectionCollectionViews[@(self.visibleSectionIndex)];
}

- (NSArray *)visibleRowViews {
    return [[self visibleCollectionView] valueForKeyPath:@"contentView"];
}

- (CGFloat)widthForRowInSection:(NSInteger)section {
    return [self.delegate respondsToSelector:@selector(widthForRowInCardStreamController:forSection:)] ?
        [self.delegate widthForRowInCardStreamController:self forSection:section] :
        self.scrollView.frame.size.width / 2 - 5.f;
}

#pragma mark - Layout

- (void)reloadData {
    // don't reload if the view hasn't been init'd
    if (self.scrollView && self.dataSource) {
        [self layoutSectionViews];
        
        [self updateFocusedCollectionView];
    }
}

- (void)updateFocusedCollectionView {
    UICollectionView *visible = [self visibleCollectionView];
    
    for (UICollectionView *view in [self.sectionCollectionViews allValues]) {
        if (view == visible) {
            view.scrollsToTop = YES;
        } else {
            view.scrollsToTop = NO;
        }
    }
}

#pragma mark - Section Layout

- (void)layoutSectionViews {
    NSInteger sections = [self.dataSource numberOfSectionsInCardStreamController:self];
    CGRect frame = self.scrollView.frame;
    frame.origin.y = 0;
    
    for (NSInteger section = 0; section < sections; section++) {
        UIView *sectionView = [self sectionViewForIndex:section];
        sectionView.frame = frame;
        
        // only addSubView if the sectionView is not in the master view
        if (sectionView.superview != self.scrollView) {
            NSAssert(!sectionView.superview, @"View for section %li already has a superview. Code smell.",(long)section);
            
            [self.scrollView addSubview:sectionView];
        }
        
        // layout the collection view for each section
        [self layoutRowViewForSection:section];
        
        // increment the height to bump each section down
        frame.origin.y += frame.size.height;
    }
    
    self.scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height * sections);
    
    // move the y position in case it was changed
    [self.scrollView setContentOffset:CGPointMake(0, self.visibleSectionIndex * frame.size.height) animated:NO];
}

// should be called AFTER -sectionViewForIndex: in -layoutSectionViews
- (void)layoutRowViewForSection:(NSInteger)section {
    UIView *sectionView = [self sectionViewForIndex:section];
    CGRect frame = sectionView.frame;
    
    // 0 since the collectionView is stored in a section view
    frame.origin.y = 0;
    
    // rows should maintain the aspect ratio of their container
    CGFloat rowWidth = [self widthForRowInSection:section];
    
    // collectionView should huge the right edge and be as wide as rows
    frame.origin.x = frame.size.width - rowWidth;
    frame.size.width = rowWidth;
    
    // pinch the views in just a little
    frame = CGRectInset(frame, self.cardVerticalSpacing, self.cardVerticalSpacing);
    
    UICollectionView *collectionView = [self collectionViewForSection:section];

    // parent UIScrollView absorbs pan gestures so that the main scrollview does not bounce or scroll
    if (! collectionView.superview) {
        UIScrollView *parent = [[UIScrollView alloc] initWithFrame:frame];
        parent.bounces = NO;
        parent.scrollsToTop = NO;
        parent.backgroundColor = [UIColor clearColor];
        parent.clipsToBounds = NO;
        
        [self.panGesture requireGestureRecognizerToFail:parent.panGestureRecognizer];
        
        frame.origin = CGPointZero;
        collectionView.frame = frame;
        
        [parent addSubview:collectionView];
        
        [sectionView addSubview:parent];
    }
}

#pragma mark - Interactions

- (void)pushViewControllerAtSection:(NSInteger)section row:(NSInteger)row {
    UIViewController *controller = [self.dataSource cardStreamController:self controllerForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
    
    NSAssert(controller, @"Cannot push a nil controller.");
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger cardSection = [self indexOfSectionView:collectionView];
    
    NSAssert(cardSection != NSNotFound, @"Could not find section for collection view.");
    
    return [self.dataSource cardStreamController:self numberOfRowsInSection:cardSection];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RNCardStreamReusableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRNCardStreamControllerCollectionCellIdentifier forIndexPath:indexPath];
    
    NSInteger cardSection = [self indexOfSectionView:collectionView];
    NSIndexPath *cardIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:cardSection];
    
    UIView *view = [self.dataSource cardStreamController:self viewForRowAtIndexPath:cardIndexPath];
    
    // view should take up the entire collection view cell and resize with it
    view.frame = cell.contentView.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    NSAssert(view.superview == nil, @"Reuseable view already has a superview. Code smell.");
    
    [cell.contentView addSubview:view];
    
    // when cell is going to be reused, remove the content view and put it back in the pool
    __weak typeof(self) weakSelf = self;
    cell.reuseBlock = ^{
        [weakSelf returnViewToThePool:view];
    };
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = [self indexOfSectionView:collectionView];
    
    self.selectedView = [collectionView cellForItemAtIndexPath:indexPath];
    
    // remember that indexPath.section is the section of the *collectionView* which is always 0
    [self pushViewControllerAtSection:section row:indexPath.row];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger cardSection = [self indexOfSectionView:collectionView];
    CGFloat rowWidth = [self widthForRowInSection:cardSection];
    
    CGRect frame = self.scrollView.frame;
    CGFloat aspectRatio = rowWidth / frame.size.width;
    
    CGFloat spacing = self.cardVerticalSpacing;
    
    return CGSizeMake(rowWidth - 2 * spacing, aspectRatio * frame.size.height - 2 * spacing);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.cardVerticalSpacing;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        // update the index after every scroll, use the ivar in case we override the setter
        CGRect frame = self.scrollView.frame;
        NSInteger offset = scrollView.contentOffset.y;
        NSInteger height = frame.size.height;
        _visibleSectionIndex = offset / height;
        
        [self updateFocusedCollectionView];
    }
}

#pragma mark - UIGestureRecognizerDelegate

#pragma mark - UIGestureRecognizer

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.scrollView.scrollEnabled = NO;
        [self visibleCollectionView].scrollEnabled = NO;
        [(UIScrollView *)[[self visibleCollectionView] superview] setScrollEnabled:NO];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [recognizer locationInView:self.scrollView];
        NSLog(@"%@",NSStringFromCGPoint(point));
    } else {
        self.scrollView.scrollEnabled = YES;
        [self visibleCollectionView].scrollEnabled = YES;
        [(UIScrollView *)[[self visibleCollectionView] superview] setScrollEnabled:YES];
    }
}

@end

@implementation RNCardStreamAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    id to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    id from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // going to a detail view
    if ([from isKindOfClass:RNCardStreamController.class]) {
        [self animateToDetailView:to fromCard:from withContext:transitionContext];
    } else {
        // going back
        [self animateBackFromDetail:from toCard:to withContext:transitionContext];
    }
}

- (void)animateToDetailView:(UIViewController *)detail fromCard:(RNCardStreamController *)card withContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *container = [transitionContext containerView];
    
    UIView *fromView = card.selectedView;
    
    UIView *fromSnap = [fromView snapshotViewAfterScreenUpdates:NO];
    fromSnap.frame = [fromView.superview convertRect:fromView.frame toView:container];
    [container addSubview:fromSnap];
    
    UIView *toSnap = [detail.view snapshotViewAfterScreenUpdates:YES];
    toSnap.alpha = 0;
    [container addSubview:toSnap];
    
    fromView.hidden = YES;
    
    POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    spring.fromValue = [NSValue valueWithCGRect:fromSnap.frame];
    spring.toValue = [NSValue valueWithCGRect:container.bounds];
    [fromSnap pop_addAnimation:spring forKey:nil];
    
    [toSnap pop_addAnimation:spring forKey:nil];
    
    spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
    spring.toValue = @(1);
    [toSnap pop_addAnimation:spring forKey:nil];
    
    [spring setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        fromView.hidden = NO;
        
        [toSnap removeFromSuperview];
        [fromSnap removeFromSuperview];
        [card.view removeFromSuperview];
        
        [container addSubview:detail.view];
        
        [transitionContext completeTransition:finished];
    }];
}

- (void)animateBackFromDetail:(UIViewController *)detail toCard:(RNCardStreamController *)card withContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *container = [transitionContext containerView];
    
    [container addSubview:card.view];
    
    UIView *fromView = detail.view;
    
    UIView *toView = card.selectedView;
    
    UIView *toParent = toView.superview;
    [toView removeFromSuperview];
    
    UIView *fromSnap = [fromView snapshotViewAfterScreenUpdates:NO];
    fromSnap.layer.cornerRadius = 4;
    fromSnap.clipsToBounds = YES;
    [container addSubview:fromSnap];
    
    UIView *toSnap = [toView snapshotViewAfterScreenUpdates:YES];
    toSnap.alpha = 0;
    [container addSubview:toSnap];
    
    fromView.hidden = YES;
    
    CGRect toFrame = [toParent convertRect:toView.frame toView:container];
    
    POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    spring.fromValue = [NSValue valueWithCGRect:fromView.frame];
    spring.toValue = [NSValue valueWithCGRect:toFrame];
    [fromSnap pop_addAnimation:spring forKey:nil];
    
    [toSnap pop_addAnimation:spring forKey:nil];
    
    spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
    spring.fromValue = @(0);
    spring.toValue = @(1);

    [spring setCompletionBlock:^(POPAnimation * animation, BOOL finished) {
        [toParent addSubview:toView];
        
        toView.hidden = NO;
        
        [toSnap removeFromSuperview];
        [fromSnap removeFromSuperview];
        [detail.view removeFromSuperview];
        
        [transitionContext completeTransition:finished];
    }];
    
    [toSnap pop_addAnimation:spring forKey:nil];
}

@end