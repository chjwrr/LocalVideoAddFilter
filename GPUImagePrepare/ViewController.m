

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
@interface ViewController ()<GPUImageMovieDelegate>

@property (nonatomic,strong)GPUImageMovie *movie;//播放
@property (nonatomic,strong)GPUImageFilter *filter;//滤镜
@property (nonatomic,strong)GPUImageView *filterView;//播放视图
@property (nonatomic,strong)GPUImageMovieWriter *writer;//保存
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self saveVideo];
    
    
    UIButton *button=[[UIButton alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-44, 44, 44)];
    [self.view addSubview:button];
    [button setBackgroundColor:[UIColor redColor]];
    [button addTarget:self action:@selector(changeFilter) forControlEvents:UIControlEventTouchUpInside];

}


/**
 播放视频，实时添加滤镜
 */
- (void)playVideo{
    /**
     *
     *  http://tx2.a.yximgs.com/upic/2016/07/01/21/BMjAxNjA3MDEyMTM4MjhfNzIwMjExNF84NTc1MTQ1NjJfMl8z.mp4?tag=1-1467534669-w-0-25bdx25jov-5a63ad5ba6299f84
     */
    NSURL *sampleURL = [[NSBundle mainBundle]URLForResource:@"demo" withExtension:@"mp4" subdirectory:nil];
    
    /**
     *  初始化 movie
     */
    _movie = [[GPUImageMovie alloc] initWithURL:sampleURL];
    
    /**
     *  是否重复播放
     */
    _movie.shouldRepeat = NO;
    
    /**
     *  控制GPUImageView预览视频时的速度是否要保持真实的速度。
     *  如果设为NO，则会将视频的所有帧无间隔渲染，导致速度非常快。
     *  设为YES，则会根据视频本身时长计算出每帧的时间间隔，然后每渲染一帧，就sleep一个时间间隔，从而达到正常的播放速度。
     */
    _movie.playAtActualSpeed = YES;
    
    /**
     *  设置代理 GPUImageMovieDelegate，只有一个方法 didCompletePlayingMovie
     */
    _movie.delegate = self;
    
    /**
     *  This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
     *
     *  这使当前视频处于基准测试的模式，记录并输出瞬时和平均帧时间到控制台
     *
     *  每隔一段时间打印： Current frame time : 51.256001 ms，直到播放或加滤镜等操作完毕
     */
    _movie.runBenchmark = YES;
    
    /**
     *  添加卡通滤镜
     */
    _filter = [[GPUImageToonFilter alloc] init];
    [_movie addTarget:_filter];
    
    /**
     *  添加显示视图
     */
    
    [_filter addTarget:self.filterView];
    
    [self.view addSubview:_filterView];
    
    /**
     *  视频处理后输出到 GPUImageView 预览时不支持播放声音，需要自行添加声音播放功能
     *
     *  开始处理并播放...
     */
    [_movie startProcessing];
    
    
}

- (void)didCompletePlayingMovie {
    NSLog(@"播放完成");
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    NSLog(@"pathToMovie:  %@",pathToMovie);
    
    _writer =[[GPUImageMovieWriter alloc]initWithMovieURL:movieURL size:CGSizeMake(320,480)];
    
    _writer.encodingLiveVideo = NO;
    _writer.shouldPassthroughAudio = NO;
    [_filter addTarget:_writer];
    
    
    
    [_movie enableSynchronizedEncodingUsingMovieWriter:_writer];
    _movie.audioEncodingTarget = _writer;
    
    
    
    
    [_writer startRecording];
    [_writer setCompletionBlock:^{
        NSLog(@"完成！！！");
    }];
    [_writer setFailureBlock:^(NSError *error){
        NSLog(@"失败！！！ %@",error);
    }];
}


- (GPUImageView *)filterView {
    if (!_filterView) {
        _filterView = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-44)];
    }
    return _filterView;
}

- (void)changeFilter {
    
    int index=arc4random()%8;
    
    [self switchCameraFilter:index];
}

- (void)switchCameraFilter:(NSInteger)index {
    [_movie removeAllTargets];
    switch (index) {
        case 0:
            _filter = [[GPUImageBilateralFilter alloc] init];
            break;
        case 1:
            _filter = [[GPUImageHueFilter alloc] init];
            break;
        case 2:
            _filter = [[GPUImageColorInvertFilter alloc] init];
            break;
        case 3:
            _filter = [[GPUImageSepiaFilter alloc] init];
            break;
        case 4: {
            _filter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [(GPUImageGaussianBlurPositionFilter*)_filter setBlurRadius:40.0/320.0];
        }
            break;
        case 5:
            _filter = [[GPUImageMedianFilter alloc] init];
            break;
        case 6:
            _filter = [[GPUImageVignetteFilter alloc] init];
            break;
        case 7:
            _filter = [[GPUImageKuwaharaRadius3Filter alloc] init];
            break;
        default:
            _filter = [[GPUImageBilateralFilter alloc] init];
            break;
    }
    [_movie addTarget:_filter];
    if (self.filterView != nil) {
        [self.filterView removeFromSuperview];
    }
    [_filter addTarget:self.filterView];
    [self.view addSubview:self.filterView];
}



/**
 不播放视频，视频添加滤镜直接保存本地
 */
- (void)saveVideo {
    NSURL *sampleURL = [[NSBundle mainBundle]URLForResource:@"demo" withExtension:@"mp4" subdirectory:nil];
    
    // 初始化 movie
    _movie = [[GPUImageMovie alloc] initWithURL:sampleURL];
    _movie.shouldRepeat = NO;
    _movie.playAtActualSpeed = YES;
    
    // 设置加滤镜视频保存路径
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL       = [NSURL fileURLWithPath:pathToMovie];
    
    // 初始化
    _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480, 640)];
    _writer.encodingLiveVideo = NO;
    _writer.shouldPassthroughAudio = NO;
    
    /**
     如果你设置了 _movie.audioEncodingTarget = _writer;
     会报如下错误：
     *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVAssetWriterInput appendSampleBuffer:] Cannot append sample buffer: Input buffer must be in an uncompressed format when outputSettings is not nil'
     暂时没去深究，以后再解决！
     */
    
    // 添加滤镜
    GPUImageToonFilter *filter = [[GPUImageToonFilter alloc] init];
    [_movie addTarget:filter];
    [filter addTarget:_writer];
    
    [_movie enableSynchronizedEncodingUsingMovieWriter:_writer];
    [_writer startRecording];
    [_movie startProcessing];
    
    __weak typeof(self) weakSelf = self;
    
    [_writer setCompletionBlock:^{
        NSLog(@"OK");
        
        [filter removeTarget:weakSelf.writer];
        [weakSelf.writer finishRecording];
    }];

    
    
}


@end
