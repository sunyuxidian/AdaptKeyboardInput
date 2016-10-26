//
//  NextViewController.m
//  Demo
//
//  Created by SunYu on 16/10/26.
//  Copyright © 2016年 SunYu. All rights reserved.
//

#import "NextViewController.h"
#import "UIViewController+AdaptKeyboardInput.h"

@interface NextViewController ()
@property (nonatomic,strong)UIScrollView *scrollView;
@property (nonatomic,strong)UITextView *textView;
@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.scrollView];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 300, 200, 40)];
    self.textView.backgroundColor = [UIColor blueColor];
    [self.scrollView addSubview:self.textView];
    
    
    UIView *vv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    vv.backgroundColor = [UIColor greenColor];
    [self.scrollView addSubview:vv];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self installAdaptKeyboardInput];
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self uninstallAdaptKeyboardInput];
}
@end
