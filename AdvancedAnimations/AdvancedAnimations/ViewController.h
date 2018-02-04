//
//  ViewController.h
//  AdvancedAnimations
//
//  Created by Daniel Gastón on 04/02/2018.
//  Copyright © 2018 Daniel Gastón. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *safeView;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurEffectView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *commentHeaderView;

- (IBAction)didTapCloseButton:(id)sender;

@end

