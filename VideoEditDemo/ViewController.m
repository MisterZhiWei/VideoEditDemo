//
//  ViewController.m
//  VideoEditDemo
//
//  Created by 刘志伟 on 2017/8/17.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "VideoEditVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadLaunchImageView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 120, 50)];
    [button setTitle:@"选取编辑视频" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.view addSubview:button];
    self.view.backgroundColor = [UIColor whiteColor];
    [button addTarget:self action:@selector(selectVideoAsset) forControlEvents:UIControlEventTouchUpInside];
}

- (void)loadLaunchImageView{
    CGSize viewSize = self.view.bounds.size;
    NSString *viewOrientation = @"Portrait";    //横屏请设置成 @"Landscape"
    NSString *launchImage = nil;
    
    NSArray* imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    for (NSDictionary* dict in imagesDict)
    {
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]])
        {
            launchImage = dict[@"UILaunchImageName"];
        }
    }
    
    UIImageView *launchView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:launchImage]];
    launchView.frame = self.view.bounds;
    launchView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:launchView];
    
    [UIView animateWithDuration:2.0f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         launchView.alpha = 0.0f;
                         launchView.layer.transform = CATransform3DScale(CATransform3DIdentity, 1.2, 1.2, 1);
                         
                     }
                     completion:^(BOOL finished) {
                         
                         [launchView removeFromSuperview];
                         
                     }];
}

- (void)selectVideoAsset{
    UIImagePickerController *myImagePickerController = [[UIImagePickerController alloc] init];
    myImagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    myImagePickerController.mediaTypes =
    [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    myImagePickerController.delegate = self;
    myImagePickerController.editing = NO;
    [self presentViewController:myImagePickerController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    VideoEditVC *videoEditVC = [[VideoEditVC alloc] init];
    videoEditVC.videoUrl = url;
    
    [self presentViewController:videoEditVC animated:YES completion:^{   }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
