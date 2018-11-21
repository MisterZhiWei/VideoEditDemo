//
//  VideoEditVC.h
//  VideoEditDemo
//
//  Created by 刘志伟 on 2017/8/17.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

/*
 *根据实际需求，可以判断如果总时长小于10秒或其他时长可以不用编辑

 */

#import <UIKit/UIKit.h>

@interface VideoEditVC : UIViewController

/*
 待编辑视频的URL
 */
@property (nonatomic, strong) NSURL *videoUrl;

/**
 * 默认为YES NO：不显示视频帧并不可编辑剪切视频
 */
@property (nonatomic, assign) BOOL isEdit;

@end
