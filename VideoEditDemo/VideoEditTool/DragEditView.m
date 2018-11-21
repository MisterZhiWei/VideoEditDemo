//
//  DragEditView.m
//  VideoEditDemo
//
//  Created by 刘志伟 on 2017/8/17.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

#import "DragEditView.h"

@interface DragEditView(){
    UIImageView *imgView;
}

@property (nonatomic ,assign) BOOL isLeft;

@end

@implementation DragEditView

- (instancetype)initWithFrame:(CGRect)frame Left:(BOOL)left{
    self = [[DragEditView alloc] initWithFrame:frame];
    self.backgroundColor = [UIColor clearColor];
    UIView *backView = [[UIView alloc] initWithFrame:self.bounds];
    backView.backgroundColor = [UIColor blackColor];
    backView.alpha = 0.6;
    [self addSubview:backView];
    self.isLeft = left;
    [self initSubViews];
    
    return self;
}

- (void)initSubViews{
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    CGRect imgFrame;
    if (self.isLeft) {
        imgFrame = CGRectMake(width-10, 0, 10, height);
    }
    else {
        imgFrame = CGRectMake(0, 0, 10, height);
    }
    
    imgView = [[UIImageView alloc] initWithFrame:imgFrame];
    imgView.image = [UIImage imageNamed:@"drag.jpg"];
    [self addSubview:imgView];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    return [self pointInsideSelf:point];
}

- (BOOL)pointInsideSelf:(CGPoint)point{
    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, _hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

- (BOOL)pointInsideImgView:(CGPoint)point{
    CGRect relativeFrame = imgView.frame;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, _hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

@end
