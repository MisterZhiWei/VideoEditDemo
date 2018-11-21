//
//  DragEditView.h
//  VideoEditDemo
//
//  Created by 刘志伟 on 2017/8/17.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DragEditView : UIView

- (instancetype)initWithFrame:(CGRect)frame Left:(BOOL)left;

@property (assign, nonatomic) UIEdgeInsets hitTestEdgeInsets;

- (BOOL)pointInsideSelf:(CGPoint)point;

- (BOOL)pointInsideImgView:(CGPoint)point;

@end
