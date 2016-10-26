//
//  ViewController.m
//  Demo
//
//  Created by SunYu on 16/10/13.
//  Copyright © 2016年 SunYu. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+AdaptKeyboardInput.h"
#import "NextViewController.h"
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.scrollView.alwaysBounceVertical = YES;
    
    UIButton *nextButton = [UIButton buttonWithType:0];
    [nextButton addTarget:self action:@selector(nextAction) forControlEvents:UIControlEventTouchUpInside];
    nextButton.backgroundColor = [UIColor redColor];
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [nextButton setTitleColor:UIColor.whiteColor  forState:UIControlStateNormal];
    nextButton.frame = CGRectMake(0, 300, 200, 24);
    [self.view addSubview:nextButton];
}

- (void)nextAction
{
    UIViewController *vc = [NextViewController new];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self installAdaptKeyboardInput];
    [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self uninstallAdaptKeyboardInput];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (UIView *)returnFirstResponderView
{
    return self.textField;
}
@end
