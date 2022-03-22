//
//  RNCPagerViewComponentView.h
//  PagerView
//
//  Created by ptrocki on 22/12/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <React/RCTViewComponentView.h>
#import "UIViewController+CreateExtension.h"

NS_ASSUME_NONNULL_BEGIN

@interface RNCPagerViewComponentView : RCTViewComponentView <UIPageViewControllerDataSource, UIPageViewControllerDelegate,UIScrollViewDelegate>

@property(strong, nonatomic, readonly) UIPageViewController *nativePageViewController;
@property(nonatomic, strong) NSMutableArray<UIViewController *> *nativeChildrenViewControllers;
@property(nonatomic) NSInteger initialPage;
@property(nonatomic) NSInteger currentIndex;

- (void)setPage:(NSInteger)number;
- (void)setPageWithoutAnimation:(NSInteger)number;

@end

NS_ASSUME_NONNULL_END

