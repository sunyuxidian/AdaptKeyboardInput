//  Created by SunYu on 16/10/11.
//  Copyright © 2016年 SunYu. All rights reserved.

#import "UIViewController+AdaptKeyboardInput.h"
#import <objc/runtime.h>

static void * keyboardHideTapGestureKey = (void *)@"keyboardHideTapGesture";
static void * observerContext = (void *)@"observerContext";
static void * observerObjectKey = (void *)@"observerObjectKey";
static void * observerObjectLockKey = (void *)@"observerObjectLockKey";
static void * scrollViewKey = (void *)@"scrollViewKey";
static void * inputBottomPaddingKey = (void *)@"inputBottomPaddingKey";


#pragma mark -
@interface SYScrollViewObserverObject : NSObject
@property (nonatomic,weak)id<SYUIViewControllerAdaptKeyboardInputDelegate>controllerAdaptiveKeyboardInputDelegate;
@end

@implementation SYScrollViewObserverObject

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(context == observerContext && [object isKindOfClass:UIScrollView.class])
    {
        UIScrollView *scrollView = (UIScrollView *)object;
        if(scrollView.isDragging && [self.controllerAdaptiveKeyboardInputDelegate respondsToSelector:@selector(SY_CloseKeyboard)])
        {
            [self.controllerAdaptiveKeyboardInputDelegate SY_CloseKeyboard];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end


#pragma mark -
@implementation UIViewController(KeyboardAdapt)

#pragma mark - public method
- (void)installAdaptKeyboardInput
{
    [self SY_AddNotification];
}

- (void)uninstallAdaptKeyboardInput
{
    [self SY_ClearNotification];
}

- (void)setInputBottomPadding:(CGFloat)distance
{
    objc_setAssociatedObject(self, inputBottomPaddingKey, @(distance), OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - add/remove notification
- (void)SY_AddNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SY_UIViewControllerKeyboardShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SY_UIViewControllerKeyboardHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)SY_ClearNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - associate objects
- (void)SY_SetKeyboardHideTapGesture:(UITapGestureRecognizer *)keyboardHideTapGesture
{
    objc_setAssociatedObject(self, keyboardHideTapGestureKey, keyboardHideTapGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)SY_KeyboardHideTapGesture
{
    return objc_getAssociatedObject(self, keyboardHideTapGestureKey);
}


- (void)SY_SetScrollView:(UIScrollView *)view
{
    objc_setAssociatedObject(self, scrollViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIScrollView *)SY_ScrollView
{
    return objc_getAssociatedObject(self, scrollViewKey);
}

#pragma mark - add/remove gesture
- (void)SY_addHideTapGesture
{
    [self SY_SetKeyboardHideTapGesture:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(SY_TapGestureAction)]];
    [self.view addGestureRecognizer:self.SY_KeyboardHideTapGesture];
    
}
- (void)SY_RemoveHideTapGesture
{
    UIGestureRecognizer *ges = self.SY_KeyboardHideTapGesture;
    if([self.view.gestureRecognizers containsObject:ges])
    {
        [self.view removeGestureRecognizer:ges];
    }
}

- (void)SY_TapGestureAction
{
    [self SY_CloseKeyboard];
}

#pragma mark - close keyboard protocol
- (void)SY_CloseKeyboard
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

#pragma mark -  observer
- (SYScrollViewObserverObject *)SY_GetSYScrollViewObserverObject
{
    SYScrollViewObserverObject* object = objc_getAssociatedObject(self, observerObjectKey);
    if(object == nil || ![object isKindOfClass:SYScrollViewObserverObject.class])
    {
        object =  [SYScrollViewObserverObject new];
        object.controllerAdaptiveKeyboardInputDelegate = self;
        objc_setAssociatedObject(self, observerObjectKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return object;
}

#pragma mark - observer lock
- (BOOL)SY_ObserverLocked
{
    return [objc_getAssociatedObject(self, observerObjectLockKey) boolValue];
}

- (void)SY_LockObserver
{
    objc_setAssociatedObject(self, observerObjectLockKey, @YES, OBJC_ASSOCIATION_ASSIGN);
}

- (void)SY_UnlockObserver
{
    objc_setAssociatedObject(self, observerObjectLockKey, @NO, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - add/remove observer for scrollView
- (void)SY_AddObserverForScrollView:(UIScrollView *)scrollView
{
    if(scrollView == nil) return;
    if([self SY_ObserverLocked]) return;
    [self SY_LockObserver];
    
    [scrollView addObserver:[self SY_GetSYScrollViewObserverObject]
                 forKeyPath:@"contentOffset"
                    options:NSKeyValueObservingOptionNew
                    context:observerContext];
}

- (void)SY_RemoveObserverForScrollView:(UIScrollView *)scrollView
{
    if(scrollView == nil) return;
    if([self SY_ObserverLocked]) [self SY_UnlockObserver];
    
    [scrollView removeObserver:[self SY_GetSYScrollViewObserverObject]
                    forKeyPath:@"contentOffset"
                       context:observerContext];
}

#pragma mark - input bottom
- (CGFloat)SY_getInputBottom:(UIView *)inputView
{
    CGFloat dist = 10;
    id distObj = objc_getAssociatedObject(self, inputBottomPaddingKey);
    if(distObj)
    {
        return [distObj floatValue];
    }
    else
    {
        UIView *superView = inputView.superview;
        if(![superView isKindOfClass:UIScrollView.class])
        {
            CGFloat viewHeight = inputView.bounds.size.height;
            CGFloat superViewHeight = superView.bounds.size.height;
            dist = superViewHeight - viewHeight - inputView.frame.origin.y;
        }

    }
    return dist;
}

#pragma mark - keyboard notifications
- (void)SY_UIViewControllerKeyboardShowNotification:(NSNotification *)notification
{
    NSValue * keyboardFrame = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = keyboardFrame.CGRectValue;
    CGFloat duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [self SY_addHideTapGesture];
    
    UIView *view = [self SY_GetFirstRespondView];
    UIScrollView *sView = [self SY_GetSuperScrollViewFromView:view];
    [self SY_AddObserverForScrollView:sView];
    
    CGRect viewToWindowRect = [self.view.window convertRect:view.frame fromView:view.superview];
    CGFloat viewTop = viewToWindowRect.origin.y;
    CGFloat keyboardTop = keyboardRect.origin.y;
    
    CGFloat viewHeight = view.bounds.size.height;
    CGFloat padding = [self SY_getInputBottom:view];
 
    CGFloat delta = keyboardTop - (viewTop + viewHeight + padding);
    if(delta < 0)
    {
        [UIView beginAnimations:@"keyboardShow" context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        self.view.transform = CGAffineTransformMakeTranslation(0, delta);
        [UIView commitAnimations];
    }
}

- (void)SY_UIViewControllerKeyboardHideNotification:(NSNotification *)notification
{
    CGFloat duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [self SY_RemoveHideTapGesture];
    [self SY_RemoveObserverForScrollView:[self SY_ScrollView]];
    
    if(!CGAffineTransformEqualToTransform(self.view.transform,CGAffineTransformIdentity))
    {
        [UIView beginAnimations:@"keyboardHide" context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        self.view.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    }

}

#pragma mark - find firstResponder view
/**
 BFS find firstResponder View

 @return view
 */
- (UIView *)SY_GetFirstRespondView
{
    if(self.view.subviews.count == 0)
    {
        return nil;
    }
    
    NSMutableArray *queue = @[].mutableCopy;
    [queue addObject:self.view];
    while (queue.count > 0)
    {
        UIView *first = queue[0];
        [queue removeObjectAtIndex:0];
        for (NSInteger i = 0; i < first.subviews.count; i++) {
            UIView *node = first.subviews[i];
            if(([node isKindOfClass:[UITextView class]] || [node isKindOfClass:[UITextField class]]) &&
               [node isFirstResponder])
            {
                return node;
            }
            [queue addObject:node];
        }
    }
    return nil;
}

#pragma mark - find a scrollview
/**
 @param view self.view's subview

 @return superview which is a scrollview
 */
- (UIScrollView *)SY_GetSuperScrollViewFromView:(UIView *)view
{
    UIView *superView = view.superview;
    if(!superView)
    {
        return nil;
    }
    
    while(![superView isMemberOfClass:UIWindow.class] &&
          ![superView isEqual:self.view] &&
          ![superView isKindOfClass:UIScrollView.class])
    {
        superView = superView.superview;
    }
    
    if([superView isKindOfClass:UIScrollView.class])
    {
        [self SY_SetScrollView:(UIScrollView*)superView];
        return (UIScrollView *)superView;
    }
    
    return nil;
}


@end
