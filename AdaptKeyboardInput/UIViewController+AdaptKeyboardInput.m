//  Created by SunYu on 16/10/11.
//  Copyright © 2016年 SunYu. All rights reserved.

#import "UIViewController+AdaptKeyboardInput.h"
#import <objc/runtime.h>

static void * keyboardHideTapGestureKey = (void *)@"keyboardHideTapGesture";
static void * keyboardHidePanGestureKey = (void *)@"keyboardHidePanGestureKey";
static void * observerContext = (void *)@"observerContext";
static void * observerObjectKey = (void *)@"observerObjectKey";
static void * observerObjectLockKey = (void *)@"observerObjectLockKey";
static void * scrollViewKey = (void *)@"scrollViewKey";
static void * inputBottomPaddingKey = (void *)@"inputBottomPaddingKey";

static void * keyboardIsShowingKey = (void *)@"keyboardIsShowingKey";

static void * keyboardDeltaKey = (void *)@"keyboardDeltaKey";


#pragma mark -
@interface SYScrollViewObserverObject : NSObject
@property (nonatomic,weak)id<SYUIViewControllerAdaptKeyboardInputDelegate>controllerAdaptiveKeyboardInputDelegate;
@end

@implementation SYScrollViewObserverObject

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
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

- (void)SY_viewDidAppear:(BOOL)animated
{
    [self SY_viewDidAppear:animated];
    [self implementInViewDidAppear];
}

#pragma mark - public method
- (void)installAdaptKeyboardInput
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method didAppear = class_getInstanceMethod([UIViewController class], @selector(viewDidAppear:)) ;
        Method newDidAppear = class_getInstanceMethod([UIViewController class], @selector(SY_viewDidAppear:));
        method_exchangeImplementations(didAppear,newDidAppear);
    });
    [self SY_AddNotification];
    [self SY_AddGestureAndObserver];
}

- (void)uninstallAdaptKeyboardInput
{
    [self SY_ClearNotification];
    [self SY_RemoveGestureAndObserver];
}

- (void)setInputBottomPadding:(CGFloat)distance
{
    objc_setAssociatedObject(self, inputBottomPaddingKey, @(distance), OBJC_ASSOCIATION_ASSIGN);
}

- (void)implementInViewDidAppear
{
    CGFloat delta = [self SY_KeyboardDelta];
    UIView *view = [self SY_GetFirstRespondView];
    
    if([self keyboardIsShowing] && view)
    {
        CGRect fr = self.view.frame;
        fr.origin.y = [self SY_SelfViewTop] + delta;
        self.view.frame = fr;
    }
}

#pragma mark - self.view Top
- (CGFloat)SY_SelfViewTop
{
    CGFloat threshold = 0;
    if(self.edgesForExtendedLayout == UIRectEdgeTop || self.edgesForExtendedLayout == UIRectEdgeAll)
    {
        threshold = 0;
    }
    else
    {
        threshold = 64;
    }
    return threshold;
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


- (void)SY_SetKeyboardHidePanGesture:(UIPanGestureRecognizer *)keyboardHidePanGesture
{
    objc_setAssociatedObject(self, keyboardHidePanGestureKey, keyboardHidePanGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)SY_KeyboardHidePanGesture
{
    return objc_getAssociatedObject(self, keyboardHidePanGestureKey);
}


- (void)SY_SetScrollView:(UIScrollView *)view
{
    objc_setAssociatedObject(self, scrollViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIScrollView *)SY_ScrollView
{
    return objc_getAssociatedObject(self, scrollViewKey);
}

- (void)setKeyboardIsShowing:(BOOL)keyboardIsShowing
{
    objc_setAssociatedObject(self,keyboardIsShowingKey,@(keyboardIsShowing),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)keyboardIsShowing
{
    return [objc_getAssociatedObject(self,keyboardIsShowingKey) boolValue];
}

- (void)SY_SetKeyboardDelta:(CGFloat)delta
{
    objc_setAssociatedObject(self,keyboardDeltaKey,@(delta),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)SY_KeyboardDelta
{
    return [objc_getAssociatedObject(self, keyboardDeltaKey) floatValue];
}


#pragma mark - add/remove gesture
- (void)SY_addHideGesture
{
    UITapGestureRecognizer *tap = [self SY_KeyboardHideTapGesture];
    if(!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(SY_TapGestureAction:)];
        [self SY_SetKeyboardHideTapGesture:tap];
    }
    
    if(![self.view.gestureRecognizers containsObject:tap])
    {
        [self.view addGestureRecognizer:tap];
    }
    
    UIPanGestureRecognizer *pan = [self SY_KeyboardHidePanGesture];
    if(!pan)
    {
        pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(SY_TapGestureAction:)];
    }
    
    if(![self.view.gestureRecognizers containsObject:pan])
    {
        [self.view addGestureRecognizer:pan];
    }
    
    
}
- (void)SY_RemoveHideGesture
{
    UIGestureRecognizer *ges = self.SY_KeyboardHideTapGesture;
    if([self.view.gestureRecognizers containsObject:ges])
    {
        [self.view removeGestureRecognizer:ges];
    }
    
    UIGestureRecognizer *pan = self.SY_KeyboardHidePanGesture;
    if([self.view.gestureRecognizers containsObject:pan])
    {
        [self.view removeGestureRecognizer:pan];
    }
}

- (void)SY_TapGestureAction:(UIGestureRecognizer *)gesture
{
    BOOL condition = YES;
    if([gesture isKindOfClass:[UIPanGestureRecognizer class]])
    {
        condition = gesture.state == UIGestureRecognizerStateBegan;
    }
    else
    {
        condition = gesture.state == UIGestureRecognizerStateEnded;
    }
    
    if(condition)
    {
        [self SY_CloseKeyboard];
    }
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
    if(![self SY_ObserverLocked]) return;
    [self SY_UnlockObserver];
    
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
    [self SY_AddGestureAndObserver];
    
    NSValue * keyboardFrame = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = keyboardFrame.CGRectValue;
    CGFloat duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    UIView *view = [self SY_GetFirstRespondView];

    CGRect viewToWindowRect = [self.view.window convertRect:view.frame fromView:view.superview];
    CGFloat viewTop = viewToWindowRect.origin.y;
    CGFloat keyboardTop = keyboardRect.origin.y;
    
    CGFloat viewHeight = view.bounds.size.height;
    CGFloat padding = [self SY_getInputBottom:view];
 
    CGFloat delta = keyboardTop - (viewTop + viewHeight + padding);
    
//    CGFloat threshold = [self SY_SelfViewTop];
    
    if(view && (delta < 0 || (delta > 0 && self.keyboardIsShowing)))//cover || update when showing
    {
        [self SY_SetKeyboardDelta:delta];
        [UIView beginAnimations:@"keyboardShow" context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        CGRect frame = self.view.frame;
        frame.origin.y += delta;
        self.view.frame = frame;
        [UIView commitAnimations];
    }
    
    self.keyboardIsShowing = YES;
}

- (void)SY_UIViewControllerKeyboardHideNotification:(NSNotification *)notification
{
    CGFloat duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGFloat threshold = [self SY_SelfViewTop];
    [self SY_RemoveGestureAndObserver];
    
    BOOL animated = self.view.frame.origin.y != threshold;
    
    if(animated)
    {
        [UIView beginAnimations:@"keyboardHide" context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
    }
    CGRect frame = self.view.frame;
    frame.origin.y = threshold;
    self.view.frame = frame;
    
    if(animated)
    {
        [UIView commitAnimations];
    }
    
    self.keyboardIsShowing = NO;
}

- (void)SY_AddGestureAndObserver
{
    [self SY_addHideGesture];
    
    UIView *view = [self SY_GetFirstRespondView];
    UIScrollView *sView = [self SY_GetSuperScrollViewFromView:view];
    [self SY_AddObserverForScrollView:sView];
}

- (void)SY_RemoveGestureAndObserver
{
    [self SY_RemoveHideGesture];
    [self SY_RemoveObserverForScrollView:[self SY_ScrollView]];
}
#pragma mark - find firstResponder view
/**
 BFS find firstResponder View

 @return view
 */
- (UIView *)SY_GetFirstRespondView
{
    if([self respondsToSelector:@selector(returnFirstResponderView)])
    {
        if([[self returnFirstResponderView] isKindOfClass:[UIView class]])
        {
            return [self returnFirstResponderView];
        }
    }
    
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
