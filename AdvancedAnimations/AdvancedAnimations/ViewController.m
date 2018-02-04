//
//  ViewController.m
//  AdvancedAnimations
//
//  Created by Daniel Gastón on 04/02/2018.
//  Copyright © 2018 Daniel Gastón. All rights reserved.
//

#import "ViewController.h"

#define animatorDuration 1
#define commentViewHeight 64

typedef NS_ENUM(NSInteger, State) {
    kStateCollapsed,
    kStateExpanded
};

@interface ViewController ()

@property (nonatomic, strong) UIView *commentView;
@property (nonatomic, strong) UILabel *commentTitleLabel;
@property (nonatomic, strong) UIImageView *commentDummyView;

@property (nonatomic, assign) CGFloat progressWhenInterrupted;
@property (nonatomic, strong) NSMutableArray<UIViewPropertyAnimator*> *runningAnimators;
@property (nonatomic, assign) State state;

@end

@implementation ViewController

#pragma mark - View LyfeCycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializePreProcessing];
    [self initializeSubViews];
    [self initializeGestures];
}

- (BOOL)prefersStatusBarHidden
{
    return true;
}


#pragma mark - Initialization Methods

- (void)initializePreProcessing
{
    // Tracks all running animators
    self.progressWhenInterrupted = 0;
    self.runningAnimators = @[].mutableCopy;
    self.state = kStateCollapsed;
}

- (void)initializeSubViews
{
    [self.blurEffectView setEffect:nil];

    self.commentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.commentTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.commentDummyView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    // Collapsed comment view
    self.commentView.frame = [self collapsedFrame];
    self.commentView.backgroundColor = UIColor.whiteColor;
    [self.safeView addSubview:self.commentView];
    
    // Title label
    [self.commentTitleLabel setText:@"Comments"];
    [self.commentTitleLabel sizeToFit];
    [self.commentTitleLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
    [self.commentTitleLabel setCenter:CGPointMake(self.view.frame.size.width / 2, commentViewHeight / 2)];
    [self.commentView addSubview:self.commentTitleLabel];
    
    // Dummy view
    [self.commentDummyView setFrame:CGRectMake(0.0,
                                    commentViewHeight,
                                    self.view.frame.size.width,
                                    self.view.frame.size.height - commentViewHeight - self.headerView.frame.size.height
                                           )];
    [self.commentDummyView setImage:[UIImage imageNamed:@"comments"]];
    [self.commentDummyView setContentMode:UIViewContentModeScaleAspectFit];
    [self.commentView addSubview:self.commentDummyView];
}

- (void)initializeGestures
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    
    [self.commentView addGestureRecognizer:tapGestureRecognizer];
    [self.commentView addGestureRecognizer:panGestureRecognizer];
}

#pragma mark - Helper Methods

- (State)nextState
{
    switch (self.state) {
        case kStateCollapsed:
            return kStateExpanded;
        case kStateExpanded:
            return kStateCollapsed;
    }
}

- (CGRect)expandedFrame
{
    return CGRectMake(0,
                      self.headerView.frame.size.height,
                      self.view.frame.size.width,
                      self.view.frame.size.height - self.headerView.frame.size.height);
}

- (CGRect)collapsedFrame
{
    return CGRectMake(0,
                      self.view.frame.size.height - commentViewHeight,
                      self.view.frame.size.width,
                      commentViewHeight);
}

- (CGFloat)fractionComplete:(State)state translation:(CGPoint)translation
{
    CGFloat translationY = (state == kStateExpanded) ? -translation.y : translation.y;
    return translationY / (self.view.frame.size.height - commentViewHeight - self.headerView.frame.size.height) + self.progressWhenInterrupted;
}

#pragma mark - Helper Methods (Gestures)

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    [self animateOrReverseRunningTransition:[self nextState] duration:animatorDuration];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.commentView];
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self startInteractiveTransition:[self nextState] duration:animatorDuration];
            break;
        case UIGestureRecognizerStateChanged:
            [self updateInteractiveTransition:[self fractionComplete:[self nextState] translation:translation]];
            break;
        case UIGestureRecognizerStateEnded:
            
            [self continueInteractiveTransition:[self fractionComplete:[self nextState] translation:translation]];
            break;
        default:
            break;
    }
}

- (IBAction)didTapCloseButton:(id)sender
{
    if (self.state == kStateExpanded) {
        [self animateOrReverseRunningTransition:[self nextState] duration: animatorDuration];
    }
}

#pragma mark - Helper Methods (Animator transition)

// Frame Animation
- (void)addFrameAnimator:(State)state duration:(NSTimeInterval)duration
{
    // Frame Animation
    UIViewPropertyAnimator *frameAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:duration dampingRatio:1 animations:^{
        switch (state) {
            case kStateExpanded:
                [self.commentView setFrame:[self expandedFrame]];
                break;
            case kStateCollapsed:
                [self.commentView setFrame:[self collapsedFrame]];
                break;
        }
    }];
    
    [frameAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
        switch (finalPosition) {
            case UIViewAnimatingPositionStart:
            {
                // Fix blur animator bug don't know why
                switch (state) {
                    case kStateExpanded:
                        [self.blurEffectView setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
                        break;
                    case kStateCollapsed:
                        [self.blurEffectView setEffect:nil];
                        break;
                }
            }
                break;
            case UIViewAnimatingPositionEnd:
                self.state = [self nextState];
                break;
            default:
                break;
        }
        
        [self.runningAnimators removeAllObjects];
    }];
    
    [self.runningAnimators addObject:frameAnimator];
}

// Blur Animation
- (void)addBlurAnimator:(State)state duration:(NSTimeInterval)duration
{
    id <UITimingCurveProvider> timing = nil;
    switch (state) {
        case kStateExpanded:
            timing = [[UICubicTimingParameters alloc] initWithControlPoint1:CGPointMake(0.75, 0.1) controlPoint2:CGPointMake(0.9, 0.25)];
            break;
        case kStateCollapsed:
            timing = [[UICubicTimingParameters alloc] initWithControlPoint1:CGPointMake(0.1, 0.75) controlPoint2:CGPointMake(0.25, 0.9)];
            break;
    }
    
    UIViewPropertyAnimator *blurAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:duration timingParameters:timing];
    
    if (@available(iOS 11.0, *)) {
        blurAnimator.scrubsLinearly = false;
    }
    [blurAnimator addAnimations:^{
        switch (state) {
            case kStateExpanded:
                [self.blurEffectView setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
                break;
            case kStateCollapsed:
                [self.blurEffectView setEffect:nil];
                break;
        }
    }];
     
    [self.runningAnimators addObject:blurAnimator];
}

// Label Scale Animation
- (void)addLabelScaleAnimator:(State)state duration:(NSTimeInterval)duration
{
    UIViewPropertyAnimator *scaleAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:duration dampingRatio:1 animations:^{

        switch (state) {
            case kStateExpanded:
            {
                CGAffineTransform transform = self.commentTitleLabel.transform;
                [self.commentTitleLabel setTransform:CGAffineTransformScale(transform, 1.8, 1.8)];
            }
                break;
            case kStateCollapsed:
                {
                    [self.commentTitleLabel setTransform:CGAffineTransformIdentity];
                }
                break;
        }
    }];
    
    [self.runningAnimators addObject:scaleAnimator];
}

// CornerRadius Animation
- (void)addCornerRadiusAnimator:(State)state duration:(NSTimeInterval)duration
{
    [self.commentView setClipsToBounds:YES];
    
    // Corner mask
    if (@available(iOS 11.0, *)) {
        [self.commentView.layer setMaskedCorners:kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner];
    }
    
    UIViewPropertyAnimator *cornerRadiusAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:duration dampingRatio:1 animations:^{
        switch (state) {
            case kStateExpanded:
                self.commentView.layer.cornerRadius = 20;
                break;
            case kStateCollapsed:
                self.commentView.layer.cornerRadius = 0;
                break;
        }
    }];
    
    [self.runningAnimators addObject:cornerRadiusAnimator];
}

// KeyFrame Animation
- (void)addKeyFrameAnimator:(State)state duration:(NSTimeInterval)duration
{
    UIViewPropertyAnimator *keyFrameAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:duration curve:UIViewAnimationCurveLinear animations:^{
        
        [UIView animateKeyframesWithDuration:0 delay:0 options:0 animations:^{
            
            switch (state) {
                case kStateExpanded:{
                    
                    [UIView addKeyframeWithRelativeStartTime:duration/2 relativeDuration:duration/2 animations:^{
                        self.commentHeaderView.alpha = 1;
                        CGAffineTransform bTransform = self.backButton.transform;
                        [self.backButton setTransform:CGAffineTransformRotate(bTransform, - M_PI/2)];
                        CGAffineTransform cTransform = self.closeButton.transform;
                        [self.closeButton setTransform:CGAffineTransformRotate(cTransform, - M_PI/2)];
                    }];
                }
                    break;
                case kStateCollapsed: {
                    
                    [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:duration/2 animations:^{
                        self.commentHeaderView.alpha = 0;
                        [self.backButton setTransform:CGAffineTransformIdentity];
                        [self.closeButton setTransform:CGAffineTransformIdentity];
                    }];
                    
                    
                    [UIView addKeyframeWithRelativeStartTime:0 relativeDuration: duration/2  animations:^{
                        self.commentHeaderView.alpha = 0;
                        [self.backButton setTransform:CGAffineTransformIdentity];
                        [self.closeButton setTransform:CGAffineTransformIdentity];
                    }];
                }
                    break;
            }
        } completion:nil];
    }];
    
    [self.runningAnimators addObject:keyFrameAnimator];
}

// Perform all animations with animators if not already running
- (void)animateTransitionIfNeeded:(State)state duration:(NSTimeInterval)duration
{
    if (!self.runningAnimators.count) {
        [self addFrameAnimator:state duration:duration];
        [self addBlurAnimator:state duration:duration];
        [self addLabelScaleAnimator:state duration:duration];
        [self addCornerRadiusAnimator:state duration:duration];
        [self addKeyFrameAnimator:state duration:duration];
    }
}

// Starts transition if necessary or reverse it on tap
- (void)animateOrReverseRunningTransition:(State)state duration:(NSTimeInterval)duration
{
    if (!self.runningAnimators.count) {
        [self animateTransitionIfNeeded:state duration:duration];
        
        for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
            [propAnimator startAnimation];
        }
    } else {
        for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
            [propAnimator setReversed:!propAnimator.reversed];
        }
    }
}

// Starts transition if necessary and pauses on pan .began
- (void)startInteractiveTransition:(State)state duration:(NSTimeInterval)duration
{
    [self animateTransitionIfNeeded:state duration:duration];
    
    for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
        [propAnimator pauseAnimation];
    }
    
    // TODO: CHECK THIS COMPLEX IF
    //original:     progressWhenInterrupted = runningAnimators.first?.fractionComplete ?? 0
    // ours
    self.progressWhenInterrupted = self.runningAnimators.firstObject ?
    self.runningAnimators.firstObject.fractionComplete ?: 0 : 0;
    

}

// Scrubs transition on pan .changed
- (void)updateInteractiveTransition:(CGFloat)fractionComplete
{
    for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
        [propAnimator setFractionComplete:fractionComplete];
    }
}

// Continues or reverse transition on pan .ended
- (void)continueInteractiveTransition:(CGFloat)fractionComplete
{
    BOOL cancel = fractionComplete < 0.2;
    
    if (cancel) {
        
        for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
            [propAnimator setReversed:!propAnimator.reversed];
            [propAnimator continueAnimationWithTimingParameters:nil durationFactor:0];
        }
        return;
    }

    id <UITimingCurveProvider> timing = [[UICubicTimingParameters alloc] initWithAnimationCurve:UIViewAnimationCurveEaseOut];
    
    for (UIViewPropertyAnimator *propAnimator in self.runningAnimators) {
        [propAnimator continueAnimationWithTimingParameters:timing durationFactor:0];
    }
}

@end
