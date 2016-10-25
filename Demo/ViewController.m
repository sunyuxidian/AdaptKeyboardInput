//
//  ViewController.m
//  Demo
//
//  Created by SunYu on 16/10/13.
//  Copyright © 2016年 SunYu. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+AdaptKeyboardInput.h"
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height+20);
    [self installAdaptKeyboardInput];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
