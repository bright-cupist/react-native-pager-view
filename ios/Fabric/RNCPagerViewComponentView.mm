//
//  RNCPagerViewComponentView.m
//  PagerView
//
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNCPagerViewComponentView.h"
#import <react/renderer/components/PagerView/ComponentDescriptors.h>
#import <react/renderer/components/PagerView/EventEmitters.h>
#import <react/renderer/components/PagerView/Props.h>
#import <react/renderer/components/PagerView/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"


using namespace facebook::react;

@interface RNCPagerViewComponentView () <RCTRNCViewPagerViewProtocol, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate>
@end

@implementation RNCPagerViewComponentView {
    UIScrollView *scrollView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNCViewPagerProps>();
    _props = defaultProps;
    _nativeChildrenViewControllers = [[NSMutableArray alloc] init];
    _currentIndex = -1;
  }
  return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //Workaround to fix incorrect frame issue
    UIViewController *controller = [_nativeChildrenViewControllers objectAtIndex:_currentIndex];
    [_nativePageViewController
        setViewControllers:@[controller]
        direction:UIPageViewControllerNavigationDirectionForward
        animated:NO
        completion:^(BOOL finished) { }];

}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
    if (!_nativePageViewController) {
        const auto &viewProps = *std::static_pointer_cast<const RNCViewPagerProps>(_props);
        NSDictionary *options = @{ UIPageViewControllerOptionInterPageSpacingKey: @(viewProps.pageMargin) };
        UIPageViewControllerNavigationOrientation orientation = UIPageViewControllerNavigationOrientationHorizontal;
        switch (viewProps.orientation) {
            case RNCViewPagerOrientation::Horizontal:
                orientation = UIPageViewControllerNavigationOrientationHorizontal;
                break;
            case RNCViewPagerOrientation::Vertical:
                orientation = UIPageViewControllerNavigationOrientationVertical;
                break;
        }
        _nativePageViewController = [[UIPageViewController alloc]
                                       initWithTransitionStyle: UIPageViewControllerTransitionStyleScroll
                                       navigationOrientation:orientation
                                       options:options];
        _nativePageViewController.dataSource = self;
        _nativePageViewController.delegate = self;
        [self addSubview:_nativePageViewController.view];
    }
    UIViewController *wrapper = [[UIViewController alloc] initWithView:childComponentView];
    [_nativeChildrenViewControllers insertObject:wrapper atIndex:index];
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
    [[_nativeChildrenViewControllers objectAtIndex:index].view removeFromSuperview];
    [_nativeChildrenViewControllers objectAtIndex:index].view = nil;
    [_nativeChildrenViewControllers removeObjectAtIndex:index];
    [_nativePageViewController.view removeFromSuperview];
    _nativePageViewController = nil;
}

- (void)shouldDismissKeyboard:(RNCViewPagerKeyboardDismissMode)dismissKeyboard {
    UIScrollViewKeyboardDismissMode dismissKeyboardMode = UIScrollViewKeyboardDismissModeNone;
    switch (dismissKeyboard) {
      case RNCViewPagerKeyboardDismissMode::None:
            dismissKeyboardMode = UIScrollViewKeyboardDismissModeNone;
            break;
      case RNCViewPagerKeyboardDismissMode::OnDrag:
            dismissKeyboardMode = UIScrollViewKeyboardDismissModeOnDrag;
            break;
    }
    scrollView.keyboardDismissMode = dismissKeyboardMode;
}

- (void)updateProps:(const facebook::react::Props::Shared &)props oldProps:(const facebook::react::Props::Shared &)oldProps{
    const auto &oldScreenProps = *std::static_pointer_cast<const RNCViewPagerProps>(_props);
    const auto &newScreenProps = *std::static_pointer_cast<const RNCViewPagerProps>(props);
    if (_currentIndex == -1) {
        _currentIndex = newScreenProps.initialPage;
        [_nativePageViewController
            setViewControllers: @[[_nativeChildrenViewControllers objectAtIndex:_currentIndex]]
            direction:UIPageViewControllerNavigationDirectionForward
            animated:YES
            completion:^(BOOL finished) { }];
        for (UIView *subview in _nativePageViewController.view.subviews) {
             if([subview isKindOfClass:UIScrollView.class]){
                 ((UIScrollView *)subview).delegate = self;
                 ((UIScrollView *)subview).delaysContentTouches = NO;
                 scrollView = (UIScrollView *)subview;
                 [self shouldDismissKeyboard: newScreenProps.keyboardDismissMode];
             }
         }
    }
    
    if (oldScreenProps.keyboardDismissMode != newScreenProps.keyboardDismissMode) {
        [self shouldDismissKeyboard: newScreenProps.keyboardDismissMode];
    }
    
    if (newScreenProps.scrollEnabled != scrollView.scrollEnabled) {
        scrollView.scrollEnabled = newScreenProps.scrollEnabled;
    }
    
    [super updateProps:props oldProps:oldProps];
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
    NSLog(@"");
}
- (UIViewController *)nextControllerForController:(UIViewController *)controller
                                      inDirection:(UIPageViewControllerNavigationDirection)direction {
    NSUInteger numberOfPages = _nativeChildrenViewControllers.count;
    NSInteger index = [_nativeChildrenViewControllers indexOfObject:controller];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    direction == UIPageViewControllerNavigationDirectionForward ? index++ : index--;
    
    if (index < 0 || (index > (numberOfPages - 1))) {
        return nil;
    }
    
    return [_nativeChildrenViewControllers objectAtIndex:index];
}

- (UIViewController *)currentlyDisplayed {
    return _nativePageViewController.viewControllers.firstObject;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(nonnull NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    if(finished){
        NSLog(@"_currentIndex %ld",(long)_currentIndex);
    }
    if (completed) {
        UIViewController* currentVC = [self currentlyDisplayed];
        NSUInteger currentIndex = [_nativeChildrenViewControllers indexOfObject:currentVC];
        _currentIndex = currentIndex;
        NSLog(@"_currentIndex %ld",(long)_currentIndex);
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
//    UIPageViewControllerNavigationDirection direction = [self isLtrLayout] ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    return [self nextControllerForController:viewController inDirection:UIPageViewControllerNavigationDirectionForward];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
//    UIPageViewControllerNavigationDirection direction = [self isLtrLayout] ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
    return [self nextControllerForController:viewController inDirection:UIPageViewControllerNavigationDirectionReverse];
}

#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNCViewPagerComponentDescriptor>();
}


@end

Class<RCTComponentViewProtocol> RNCViewPagerCls(void)
{
  return RNCPagerViewComponentView.class;
}
