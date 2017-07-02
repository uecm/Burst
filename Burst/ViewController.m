//
//  ViewController.m
//  Burst
//
//  Created by Egor on 6/28/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "ViewController.h"
#import "ImageManager.h"
#import <YYAnimatedImageView.h>
#import <YYImage.h>

#import <HTPressableButton.h>
#import <UIColor+HTColor.h>
#import <MRProgress.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *imageView;

@property (weak, nonatomic) IBOutlet HTPressableButton *openGalleryButton;
@property (weak, nonatomic) IBOutlet HTPressableButton *makeGifButton;
@property (weak, nonatomic) IBOutlet HTPressableButton *playGifButton;
@property (weak, nonatomic) IBOutlet HTPressableButton *editButton;

@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondsLabel;

@property (strong, nonatomic) NSArray<UIImage *> *images;
@property (strong, nonatomic) YYImage *animationImage;

@property (strong, nonatomic) MRProgressOverlayView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
        }];
    }
    
    self.makeGifButton.alpha = 0;
    self.playGifButton.alpha = 0;
    self.slider.alpha = 0;
    self.fpsLabel.alpha = 0;
    self.secondsLabel.alpha = 0;
    
    self.imageView.autoPlayAnimatedImage = false;
    
    // Setup buttons
    [self setupButton:self.openGalleryButton withColor:[UIColor ht_aquaColor] shadowColor:[UIColor ht_aquaDarkColor]];
    [self setupButton:self.makeGifButton withColor:[UIColor ht_aquaColor] shadowColor:[UIColor ht_aquaDarkColor]];
    [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}






-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:true completion:nil];
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSURL *imageURL = info[UIImagePickerControllerReferenceURL];

    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeHiddenAssets = true;
    options.includeAllBurstAssets = true;
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[imageURL] options:options];
    PHAsset *asset = [fetchResult firstObject];
    
    if (!asset.representsBurst) {
        NSLog(@"Selected photo is not a burst.");
        return;
    }

    [picker dismissViewControllerAnimated:true completion:^{
        self.progressView.progress = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleImageMediaWithAsset:asset options:options];
        });
    }];
}



-(void) handleImageMediaWithAsset:(PHAsset*)asset options:(PHFetchOptions*)options{
    
    PHFetchResult *burstPhotos = [PHAsset fetchAssetsWithBurstIdentifier:asset.burstIdentifier options:options];
    NSLog(@"Burst has %d photos in it.", (int)burstPhotos.count);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [ImageManager imagesFromFetchResult:burstPhotos completion:^(BOOL success, NSArray *imgs) {
            if (success) {
                self.images = imgs;
                NSLog(@"Fetched photos array has %d photos in it.",(int)imgs.count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateImageView];
                    [self.progressView dismiss:true completion:^{
                        self.progressView = nil;
                    }];
                    [self updateFpsLabel];
                });
            }
        } progress:^(float progress, int counter) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressView) {
                    self.progressView.progress = progress;
                }
            });
        }];
    });
}



#pragma mark - Buttons

- (IBAction)openGalleryPressed:(id)sender {
    
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:true completion:nil];
}


- (IBAction)playGifPressed:(id)sender {
    
    BOOL currentlyPlaying = self.imageView.currentIsPlayingAnimation;
    BOOL ended = self.imageView.currentAnimatedImageIndex == self.images.count-1;
    
    [self.imageView addObserver:self forKeyPath:@"currentAnimatedImageIndex" options:NSKeyValueObservingOptionNew context:nil];
    
    if (ended) {
        self.imageView.currentAnimatedImageIndex = 0;
        currentlyPlaying = false;
    }
    if (currentlyPlaying){
        [self.imageView stopAnimating];
        [self.playGifButton setTitle:@"Play a gif" forState:UIControlStateNormal];
        [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
    }
    else {
        
        [self.imageView startAnimating];
        [self.playGifButton setTitle:@"Stop playing" forState:UIControlStateNormal];
        [self setupButton:self.playGifButton withColor:[UIColor ht_alizarinColor] shadowColor:[UIColor ht_pomegranateColor]];
    }
}


- (IBAction)makeGifPressed:(id)sender {
    if (!self.images) {
        return;
    }
    
    // Show progress view
    self.progressView.progress = 0;
    self.progressView.mode = MRProgressOverlayViewModeIndeterminate;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *webPData = [ImageManager webPDataWithImages:self.images duration:[self durationForAnimation]];
        self.animationImage = [YYImage imageWithData:webPData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.playGifButton.alpha = 1;
            }];
            [self.playGifButton setTitle:@"Play a gif" forState:UIControlStateNormal];
            [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
            
            self.imageView.image = self.animationImage;
            [self.progressView dismiss:true completion:^{
                self.progressView = nil;
            }];
        });
    });
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"currentAnimatedImageIndex"]) {
        YYAnimatedImageView *view = (YYAnimatedImageView*)object;
        YYImage *viewImage = (YYImage*)view.image;
        
        NSUInteger currentIndex = view.currentAnimatedImageIndex;
        NSUInteger imagesCount = viewImage.animatedImageFrameCount;
        
        if (currentIndex == imagesCount-1) {

            [UIView animateWithDuration:0.1 animations:^{
                self.playGifButton.alpha = 0;
            } completion:^(BOOL finished) {
                [self.playGifButton setTitle:@"Play a gif" forState:UIControlStateNormal];
                [self setupButton:self.playGifButton withColor:[UIColor ht_mintColor] shadowColor:[UIColor ht_mintDarkColor]];
                [UIView animateWithDuration:0.1 animations:^{
                    self.playGifButton.alpha = 1;
                }];
                
                [self.imageView removeObserver:self forKeyPath:@"currentAnimatedImageIndex"];
            }];
        }
    }
}


- (IBAction)sliderValueChanged:(id)sender {
    [self updateFpsLabel];
    
}

- (IBAction)editPressed:(id)sender {
    
}

- (IBAction)sharePressed:(id)sender {
    if(!self.animationImage) return;
    
    NSString *gifPath = [ImageManager pathForGIFDataWithImages:self.images duration:[self durationForAnimation]];
    NSData *imgData = [NSData dataWithContentsOfFile:gifPath];
    
    UIActivityViewController *shareVC = [[UIActivityViewController alloc] initWithActivityItems:@[imgData] applicationActivities:nil];
    [self presentViewController:shareVC animated:true completion:nil];
}


#pragma mark - Misc

-(float) durationForAnimation {
    
    float value = self.slider.value;
    
    float currentDuration = value * 30;
    if (currentDuration < 1) {
        currentDuration = 1;
    }
    return currentDuration;
}


-(void) updateFpsLabel{
    
    float duration = [self durationForAnimation];
    float fps = self.images.count / duration;
    
    NSString *fpsText = [NSString stringWithFormat:@"%.02f frames per second", fps];
    self.fpsLabel.text = fpsText;
    
    NSString *durationText = [NSString stringWithFormat:@"%02.02f seconds", duration];
    self.secondsLabel.text = durationText;
}


-(void) updateImageView{
    
    UIImage *image = self.images.firstObject;
    CGSize size = image.size;
    
    float ratio = size.width > size.height ? (size.height / size.width) : (size.width / size.height);
    float heigth = floorf(self.view.frame.size.height);
    float width = floorf(heigth * ratio);
    
    CGRect frame = {{(self.view.center.x - width/2), 20},{heigth,width}};
    self.imageView.frame = frame;
    self.imageView.image = image;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.makeGifButton.alpha = 1;
        self.fpsLabel.alpha = 1;
        self.slider.alpha = 1;
        self.secondsLabel.alpha = 1;
    }];
}

-(void) setupButton:(HTPressableButton*)button withColor:(UIColor*)color shadowColor:(UIColor*)shadowColor{
    CGRect frame = {[button convertPoint:button.frame.origin toView:self.view], {button.bounds.size.width, 40}};
    button.frame = frame;
    button.style = HTPressableButtonStyleRounded;
    button.buttonColor = color;
    button.shadowHeight = 6; //(int)(button.frame.size.height * 0.17);
    button.shadowColor = shadowColor;
    //[button createButton];
}

-(MRProgressOverlayView *)progressView{
    if (_progressView) {
        return _progressView;
    }
    MRProgressOverlayView *view = [MRProgressOverlayView showOverlayAddedTo:self.view
                                                                      title:@""
                                                                       mode:MRProgressOverlayViewModeDeterminateCircular
                                                                   animated:true];
    view.tintColor = [UIColor ht_aquaColor];
    
    return _progressView = view;
}

@end
