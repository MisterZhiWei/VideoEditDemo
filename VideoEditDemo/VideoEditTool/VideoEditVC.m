//
//  VideoEditVC.m
//  VideoEditDemo
//
//  Created by 刘志伟 on 2017/8/17.
//  Copyright © 2017年 刘志伟. All rights reserved.
//
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define EDGE_EXTENSION_FOR_THUMB 20

#import "VideoEditVC.h"
#import "DragEditView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VideoEditVC ()<UIScrollViewDelegate>{
    UIScrollView    *editScrollView;
    UIView          *bottomView;
    DragEditView    *leftDragView;
    DragEditView    *rightDragView;
    UIView          *line;
    UIView          *topBorder;
    UIView          *bottomBorder;
}

@property (nonatomic, strong) AVPlayerItem      *playItem;
@property (nonatomic, strong) AVPlayerLayer     *playerLayer;
@property (nonatomic, strong) AVPlayer          *player;
@property (nonatomic, strong) NSTimer           *repeatTimer;   // 循环播放计时器
@property (nonatomic, strong) NSTimer           *lineMoveTimer; // 播放条移动计时器
@property (nonatomic, strong) NSMutableArray    *framesArray;   // 视频帧数组

@property (nonatomic, strong) NSString *tempVideoPath;
@property (nonatomic, assign) CGPoint   leftStartPoint;
@property (nonatomic, assign) CGPoint   rightStartPoint;
@property (nonatomic, assign) BOOL      isDraggingRightOverlayView;
@property (nonatomic, assign) BOOL      isDraggingLeftOverlayView;
@property (nonatomic, assign) CGFloat   startTime;      // 编辑框内视频开始时间秒
@property (nonatomic, assign) CGFloat   endTime;        // 编辑框内视频结束时间秒
@property (nonatomic, assign) CGFloat   startPointX;    // 编辑框起始点
@property (nonatomic, assign) CGFloat   endPointX;      // 编辑框结束点
@property (nonatomic, assign) CGFloat   IMG_Width;      // 视频帧宽度
@property (nonatomic, assign) CGFloat   linePositionX;  // 播放条的位置
@property (nonatomic, assign) CGFloat   boderX;         // 编辑框边线X
@property (nonatomic, assign) CGFloat   boderWidth;     // 编辑框边线长度
@property (nonatomic, assign) CGFloat   touchPointX;     // 编辑视图区域外触点
@property (nonatomic, assign) BOOL      isEdited;       // YES：编辑完成

@end

@implementation VideoEditVC

#pragma mark lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self initFunctions];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (self.player) {
        [self invalidatePlayer];
    }
}

#pragma mark 释放引用
- (void)invalidatePlayer{
    [self stopTimer];
    [self.player removeObserver:self forKeyPath:@"timeControlStatus"];
    [self.player pause];
    [self.playItem removeObserver:self forKeyPath:@"status"];
}

#pragma mark 自定义方法
- (void)initFunctions{
    // 手机静音时可播放声音
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-80, SCREEN_WIDTH, 80)];
    bottomView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bottomView];
    editScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50)];
    editScrollView.showsHorizontalScrollIndicator = NO;
    editScrollView.bounces = NO;
    [bottomView addSubview:editScrollView];
    editScrollView.delegate = self;
    
    // 添加编辑框上下边线
    self.boderX = 45;
    self.boderWidth = SCREEN_WIDTH-90;
    topBorder = [[UIView alloc] initWithFrame:CGRectMake(self.boderX, 0, self.boderWidth, 2)];
    topBorder.backgroundColor = [UIColor whiteColor];
    [bottomView addSubview:topBorder];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(self.boderX, 50-2, self.boderWidth, 2)];
    bottomBorder.backgroundColor = [UIColor whiteColor];
    [bottomView addSubview:bottomBorder];
    
    // 添加左右编辑框拖动条
    leftDragView = [[DragEditView alloc] initWithFrame:CGRectMake(-(SCREEN_WIDTH-50), 0, SCREEN_WIDTH, 50) Left:YES];
    leftDragView.hitTestEdgeInsets = UIEdgeInsetsMake(0, -(EDGE_EXTENSION_FOR_THUMB), 0, -(EDGE_EXTENSION_FOR_THUMB));
    [bottomView addSubview:leftDragView];
    
    rightDragView = [[DragEditView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-50), 0, SCREEN_WIDTH, 50) Left:NO];
    rightDragView.hitTestEdgeInsets = UIEdgeInsetsMake(0, -(EDGE_EXTENSION_FOR_THUMB), 0, -(EDGE_EXTENSION_FOR_THUMB));
    [bottomView addSubview:rightDragView];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveOverlayView:)];
    [bottomView addGestureRecognizer:panGestureRecognizer];
    
    // 播放条
    line = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 3, 50)];
    line.backgroundColor = [UIColor colorWithRed:214/255.0 green:230/255.0 blue:247/255.0 alpha:1.0];
    [bottomView addSubview:line];
    line.hidden = YES;
    
    UIButton *doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-60, 50, 60, 30)];
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [doneBtn setTitleColor:[UIColor colorWithRed:14/255.0 green:178/255.0 blue:10/255.0 alpha:1.0] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(notifyDelegateOfDidChange) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:doneBtn];
    
    // 默认startTime 0秒 endTime 10秒
    self.startTime = 0;
    self.endTime = 10;
    self.startPointX = 50;
    self.endPointX = SCREEN_WIDTH-50;
    self.IMG_Width = (SCREEN_WIDTH-100)/10;
}

#pragma mark 编辑区域手势拖动
- (void)moveOverlayView:(UIPanGestureRecognizer *)gesture{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self stopTimer];
            BOOL isRight =  [rightDragView pointInsideImgView:[gesture locationInView:rightDragView]];
            BOOL isLeft  =  [leftDragView pointInsideImgView:[gesture locationInView:leftDragView]];
            _isDraggingRightOverlayView = NO;
            _isDraggingLeftOverlayView = NO;
            
            self.touchPointX = [gesture locationInView:bottomView].x;
            if (isRight){
                self.rightStartPoint = [gesture locationInView:bottomView];
                _isDraggingRightOverlayView = YES;
                _isDraggingLeftOverlayView = NO;
            }
            else if (isLeft){
                self.leftStartPoint = [gesture locationInView:bottomView];
                _isDraggingRightOverlayView = NO;
                _isDraggingLeftOverlayView = YES;
                
            }
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:bottomView];
           
            // Left
            if (_isDraggingLeftOverlayView){
                CGFloat deltaX = point.x - self.leftStartPoint.x;
                CGPoint center = leftDragView.center;
                center.x += deltaX;
                CGFloat durationTime = (SCREEN_WIDTH-100)*2/10; // 最小范围2秒
                BOOL flag = (self.endPointX-point.x)>durationTime;
                
                if (center.x >= (50-SCREEN_WIDTH/2) && flag) {
                     leftDragView.center = center;
                    self.leftStartPoint = point;
                    self.startTime = (point.x+editScrollView.contentOffset.x)/self.IMG_Width;
                    topBorder.frame = CGRectMake(self.boderX+=deltaX/2, 0, self.boderWidth-=deltaX/2, 2);
                    bottomBorder.frame = CGRectMake(self.boderX+=deltaX/2, 50-2, self.boderWidth-=deltaX/2, 2);
                    self.startPointX = point.x;
                }
                CMTime startTime = CMTimeMakeWithSeconds((point.x+editScrollView.contentOffset.x)/self.IMG_Width, self.player.currentTime.timescale);
                
                // 只有视频播放的时候才能够快进和快退1秒以内
                [self.player seekToTime:startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            }
            else if (_isDraggingRightOverlayView){ // Right
                CGFloat deltaX = point.x - self.rightStartPoint.x;
                CGPoint center = rightDragView.center;
                center.x += deltaX;
                CGFloat durationTime = (SCREEN_WIDTH-100)*2/10; // 最小范围2秒
                BOOL flag = (point.x-self.startPointX)>durationTime;
                if (center.x <= (SCREEN_WIDTH-50+SCREEN_WIDTH/2) && flag) {
                    rightDragView.center = center;
                    self.rightStartPoint = point;
                    self.endTime = (point.x+editScrollView.contentOffset.x)/self.IMG_Width;
                    topBorder.frame = CGRectMake(self.boderX, 0, self.boderWidth+=deltaX/2, 2);
                    bottomBorder.frame = CGRectMake(self.boderX, 50-2, self.boderWidth+=deltaX/2, 2);
                    self.endPointX = point.x;
                }
                CMTime startTime = CMTimeMakeWithSeconds((point.x+editScrollView.contentOffset.x)/self.IMG_Width, self.player.currentTime.timescale);
                
                // 只有视频播放的时候才能够快进和快退1秒以内
                [self.player seekToTime:startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            }
            else { // 移动scrollView
                CGFloat deltaX = point.x - self.touchPointX;
                CGFloat newOffset = editScrollView.contentOffset.x-deltaX;
                CGPoint currentOffSet = CGPointMake(newOffset, 0);
                
                if (currentOffSet.x >= 0 && currentOffSet.x <= (editScrollView.contentSize.width-SCREEN_WIDTH)) {
                    editScrollView.contentOffset = CGPointMake(newOffset, 0);
                    self.touchPointX = point.x;
                }
            }
            
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            [self startTimer];
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark 视频裁剪
- (void)notifyDelegateOfDidChange{
    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    
    [self deleteTempFile];
    
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                          initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    
    NSURL *furl = [NSURL fileURLWithPath:self.tempVideoPath];
    exportSession.outputURL = furl;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, self.player.currentTime.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.endTime - self.startTime, self.player.currentTime.timescale);;
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                break;
                
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
                
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Export completed");
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    UISaveVideoAtPathToSavedPhotosAlbum([furl relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
                    NSLog(@"编辑后的视频路径： %@",weakSelf.tempVideoPath);
                    
                    weakSelf.isEdited = YES;
                    [weakSelf invalidatePlayer];
                    [weakSelf initPlayerWithVideoUrl:furl];
                    bottomView.hidden = YES;
                });
            }
                break;
                
            default:
                NSLog(@"Export other");

                break;
        }
    }];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        NSLog(@"保存到相册失败");
    }
    else {
        NSLog(@"保存到相册成功");
    }
}

- (void)deleteTempFile{
    NSURL *url = [NSURL fileURLWithPath:self.tempVideoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    }
    else {
        NSLog(@"no file by that name");
    }
}

#pragma mark - 初始化player
- (void)initPlayerWithVideoUrl:(NSURL *)videlUrl{
    self.playItem = [[AVPlayerItem alloc] initWithURL:videlUrl];
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playItem];
    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.contentsScale = [UIScreen mainScreen].scale;
    self.playerLayer.frame = CGRectMake(0, 80, self.view.bounds.size.width, SCREEN_HEIGHT-160);
    [self.view.layer addSublayer:self.playerLayer];
}

#pragma mark - KVO属性播放属性监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.playItem.status) {
            case AVPlayerStatusUnknown:
                NSLog(@"KVO：未知状态，此时不能播放");
                break;
            case AVPlayerStatusReadyToPlay:
                if (!_player.timeControlStatus || _player.timeControlStatus != AVPlayerTimeControlStatusPaused) {
                    [_player play];
                    if (!self.isEdited) {
                        line.hidden = NO;
                        [self startTimer];
                    }
                }
                NSLog(@"KVO：准备完毕，可以播放");
                break;
            case AVPlayerStatusFailed:
                NSLog(@"KVO：加载失败，网络或者服务器出现问题");
                break;
            default:
                break;
        }
    }
    
    if ([keyPath isEqualToString:@"timeControlStatus"]) {
        // 剪切完视频后自动循环播放
        if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
            [self.player seekToTime:CMTimeMake(0, 1)];
            [self.player play];
        }
    }
}

#pragma mark  - 开启计时器
- (void)startTimer{
    double duarationTime = (self.endPointX-self.startPointX-20)/SCREEN_WIDTH*10;
    line.hidden = NO;
    self.linePositionX = self.startPointX+10;
    self.lineMoveTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(lineMove) userInfo:nil repeats:YES];
    
     // 开启循环播放
    self.repeatTimer = [NSTimer scheduledTimerWithTimeInterval:duarationTime target:self selector:@selector(repeatPlay) userInfo:nil repeats:YES];
    [self.repeatTimer fire];
}

#pragma mark  - 编辑区域循环播放
- (void)repeatPlay{
    [self.player play];
    CMTime start = CMTimeMakeWithSeconds(self.startTime, self.player.currentTime.timescale);
    [self.player seekToTime:start toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark  - 播放条移动
- (void)lineMove{
    double duarationTime = (self.endPointX-self.startPointX-20)/SCREEN_WIDTH*10;
    self.linePositionX += 0.01*(self.endPointX - self.startPointX-20)/duarationTime;
    
    if (self.linePositionX >= CGRectGetMinX(rightDragView.frame)-3) {
        self.linePositionX = CGRectGetMaxX(leftDragView.frame)+3;
    }
    
    line.frame = CGRectMake(self.linePositionX, 0, 3, 50);
}

#pragma mark  - 关闭计时器
- (void)stopTimer{
    [self.repeatTimer invalidate];
    [self.lineMoveTimer invalidate];
    line.hidden = YES;
}

#pragma mark  - 读取解析视频帧
- (void)analysisVideoFrames{
    // 初始化asset对象
    AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:self.videoUrl options:nil];
    // 获取总视频的长度 = 总帧数 / 每秒的帧数
    long videoSumTime = videoAsset.duration.value / videoAsset.duration.timescale;
    
    // 创建AVAssetImageGenerator对象
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc]initWithAsset:videoAsset];
    generator.maximumSize = bottomView.frame.size;
    generator.appliesPreferredTrackTransform = YES;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    // 添加需要帧数的时间集合
    self.framesArray = [NSMutableArray array];
    for (int i = 0; i < videoSumTime; i++) {
        CMTime time = CMTimeMake(i *videoAsset.duration.timescale , videoAsset.duration.timescale);
        NSValue *value = [NSValue valueWithCMTime:time];
        [self.framesArray addObject:value];
    }
    
    __block long count = 0;
    __weak typeof(self) weakSelf = self;
    [generator generateCGImagesAsynchronouslyForTimes:self.framesArray completionHandler:^(CMTime requestedTime, CGImageRef img, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        if (result == AVAssetImageGeneratorSucceeded) {
            NSLog(@"%ld",count);
            UIImageView *thumImgView = [[UIImageView alloc] initWithFrame:CGRectMake(50+count*weakSelf.IMG_Width, 0, weakSelf.IMG_Width, 70)];
            thumImgView.image = [UIImage imageWithCGImage:img];
            dispatch_async(dispatch_get_main_queue(), ^{
                [editScrollView addSubview:thumImgView];
                editScrollView.contentSize = CGSizeMake(100+count*weakSelf.IMG_Width, 0);
            });
            count++;
        }
        
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"AVAssetImageGeneratorCancelled");
        }
    }];
}

#pragma mark  - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self startTimer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self letScrollViewScrollAndResetPlayerStartTime];
    // 视频暂停时可通过  AVPlayerItem 的API - (void)stepByCount:(NSInteger)stepCount; 滑动，目前未找到step的具体大小 官方文档说的不清楚
//    NSInteger step = offsetX/(50.0*self.framesArray.count)*72;
//    NSLog(@"移动步数:%ld",step);
    //    if ([self.playItem canStepForward] && step > 0) {
    //        [self.playItem stepByCount:step];
    //    }
    //
    //    if ([self.playItem canStepBackward] && step < 0) {
    //         [self.playItem stepByCount:step];
    //    }
}

#pragma mark  - scrollView滑动时设置
-(void)letScrollViewScrollAndResetPlayerStartTime{
    CGFloat offsetX = editScrollView.contentOffset.x;
    CMTime startTime;
    
    if (offsetX>=0) {
        startTime = CMTimeMakeWithSeconds((offsetX+self.startPointX)/self.IMG_Width, self.player.currentTime.timescale);
        CGFloat duration = self.endTime-self.startTime;
        self.startTime = (offsetX+self.startPointX)/self.IMG_Width;
        self.endTime = self.startTime+duration;
    }
    else {
        startTime = CMTimeMakeWithSeconds(self.startPointX, self.player.currentTime.timescale);
    }
    
    // 只有视频播放的时候才能够快进和快退1秒以内
    [self.player seekToTime:startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark - setMethod
- (void)setVideoUrl:(NSURL *)videoUrl{
    _videoUrl = videoUrl;
    if (!self.isEdit) {
        [self analysisVideoFrames];
    }
    else {
        leftDragView.hidden = YES;
        rightDragView.hidden = YES;
    }
    
    [self initPlayerWithVideoUrl:videoUrl];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 50)];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(dismissSelfVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
}

- (void)dismissSelfVC{
    [self dismissViewControllerAnimated:YES completion:^{  }];
}

#pragma mark -  getMethod
- (NSMutableArray *)framesArray{
    if (!_framesArray) {
        _framesArray = [NSMutableArray array];
    }
    return _framesArray;
}

@end
