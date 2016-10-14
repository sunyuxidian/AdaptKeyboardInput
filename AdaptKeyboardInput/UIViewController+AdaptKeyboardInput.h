//  Created by SunYu on 16/10/11.
//  Copyright © 2016年 SunYu. All rights reserved.

#import <UIKit/UIKit.h>

@protocol SYUIViewControllerAdaptKeyboardInputDelegate <NSObject>

@optional
- (void)SY_CloseKeyboard;
- (void)setInputBottomPadding:(CGFloat)distance;

@end

@interface UIViewController(AdaptKeyboardInput)<SYUIViewControllerAdaptKeyboardInputDelegate>

- (void)installAdaptKeyboardInput;
- (void)uninstallAdaptKeyboardInput;

@end
