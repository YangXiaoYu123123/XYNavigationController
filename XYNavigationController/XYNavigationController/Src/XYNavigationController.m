//
//  MLNavigationController.m
//  MultiLayerNavigation
//
//  Created by Feather Chan on 13-4-12.
//  Copyright (c) 2013年 Feather Chan. All rights reserved.
//

#define KEY_WINDOW  [[UIApplication sharedApplication]keyWindow]
#define TOP_VIEW  [[UIApplication sharedApplication]keyWindow].rootViewController.view


#import "XYNavigationController.h"
#import <QuartzCore/QuartzCore.h>

@interface XYNavigationController ()
{
    CGPoint startTouch;
    
    UIImageView *lastScreenShotView;
    UIView *blackMask;
}

@property (nonatomic,retain) UIView *backgroundView;
@property (nonatomic,retain) NSMutableArray *screenShotsList;

@property (nonatomic,assign) BOOL isMoving;

@end

@implementation XYNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        // Custom initialization
        
        self.screenShotsList = [[[NSMutableArray alloc]initWithCapacity:2]autorelease];
        self.canDragBack = YES;
    }
    return self;
}

- (void)dealloc
{
    self.screenShotsList = nil;
    
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
    
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // draw a shadow for navigation view to differ the layers obviously.
    // using this way to draw shadow will lead to the low performace
    // the best alternative way is making a shadow image.
    //
    //self.view.layer.shadowColor = [[UIColor blackColor]CGColor];
    //self.view.layer.shadowOffset = CGSizeMake(5, 5);
    //self.view.layer.shadowRadius = 5;
    //self.view.layer.shadowOpacity = 1;
    
    UIImageView *shadowImageView = [[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"leftside_shadow_bg"]]autorelease];
    shadowImageView.frame = CGRectMake(-10, 0, 10, TOP_VIEW.frame.size.height);
    [TOP_VIEW addSubview:shadowImageView];
    
    UIPanGestureRecognizer *recognizer = [[[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                                 action:@selector(paningGestureReceive:)]autorelease];
    recognizer.delegate = self;
    [recognizer delaysTouchesBegan];
    [self.view addGestureRecognizer:recognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:(BOOL)animated];
    
    if (self.screenShotsList.count == 0) {
        
        UIImage *capturedImage = [self capture];
        
        if (capturedImage) {
            [self.screenShotsList addObject:capturedImage];
        }
    }
}

// override the push method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIImage *capturedImage = [self capture];
    
    if (capturedImage) {
        [self.screenShotsList addObject:capturedImage];
    }

    [super pushViewController:viewController animated:animated];
}

// override the pop method
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    [self.screenShotsList removeLastObject];
    
    return [super popViewControllerAnimated:animated];
}

#pragma mark - Utility Methods -

// get the current view screen shot
- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(TOP_VIEW.bounds.size, TOP_VIEW.opaque, 0.0);
    [TOP_VIEW.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

// set lastScreenShotView 's position and alpha when paning
- (void)moveViewWithX:(float)x
{
    NSLog(@"Move to:%f",x);
    
    float alpha;
    CGPoint center = lastScreenShotView.center;
    CGRect frame = TOP_VIEW.frame;
    frame.origin.x += x;
    NSLog(@"frame = %@",NSStringFromCGRect(frame));
    TOP_VIEW.frame = frame;
        
        //float scale = (x/6400)+0.95;
    alpha = 0.4 - (x/800);
    center.x = frame.origin.x/4+TOP_VIEW.frame.size.width/4;
    NSLog(@"center = %@",NSStringFromCGPoint(center));
    lastScreenShotView.center = center;
    blackMask.alpha = alpha;
    
}

- (void)movePopFinish{
    CGRect frame = TOP_VIEW.frame;
    frame.origin.x = 320;
    TOP_VIEW.frame = frame;
    
    lastScreenShotView.center = CGPointMake(frame.origin.x/4+TOP_VIEW.frame.size.width/4, lastScreenShotView.center.y);
}
- (void)movePushFinish{
    CGRect frame = TOP_VIEW.frame;
    frame.origin.x = 0;
    TOP_VIEW.frame = frame;
    
    lastScreenShotView.center = CGPointMake(frame.origin.x/4+TOP_VIEW.frame.size.width/4, lastScreenShotView.center.y);
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.viewControllers.count <= 1 || !self.canDragBack) return NO;
    
    return YES;
}

#pragma mark - Gesture Recognizer -

- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer
{
    // If the viewControllers has only one vc or disable the interaction, then return.
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    // we get the touch position by the window's coordinate
    
    CGPoint tranPoint = [recoginzer translationInView:KEY_WINDOW];
    NSLog(@"tranPoint = %@",NSStringFromCGPoint(tranPoint));
    
    if (tranPoint.x<0) {
        if (recoginzer.state == UIGestureRecognizerStateBegan) {
            
            self.isMoving = YES;
        
            [self pushViewController:[(id<XYNavigarionControllerDelegate>)self.mlDelegate whenDragPop] animated:NO];
            [self moveViewWithX:320];
            
            if (!self.backgroundView)
            {
                CGRect frame = TOP_VIEW.frame;
                
                self.backgroundView = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)]autorelease];
                [TOP_VIEW.superview insertSubview:self.backgroundView belowSubview:TOP_VIEW];
                
                blackMask = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)]autorelease];
                blackMask.backgroundColor = [UIColor blackColor];
                [self.backgroundView addSubview:blackMask];
            }
            
            self.backgroundView.hidden = NO;
            
            if (lastScreenShotView) [lastScreenShotView removeFromSuperview];
            
            UIImage *lastScreenShot = [self.screenShotsList lastObject];
            lastScreenShotView = [[[UIImageView alloc]initWithImage:lastScreenShot]autorelease];
            [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
        }
        else if (recoginzer.state == UIGestureRecognizerStateEnded){
            if (TOP_VIEW.frame.origin.x<TOP_VIEW.frame.size.width/2) {
                [UIView animateWithDuration:0.3 animations:^{
                    [self movePushFinish];
                } completion:^(BOOL finished) {
                    CGRect frame = TOP_VIEW.frame;
                    frame.origin.x = 0;
                    TOP_VIEW.frame = frame;
                    
                    _isMoving = NO;
                    self.backgroundView.hidden = YES;
                }];
            }else{
                [UIView animateWithDuration:0.3 animations:^{
                    [self movePopFinish];
                } completion:^(BOOL finished) {
                    _isMoving = NO;
                    self.backgroundView.hidden = YES;
                }];
            }
            return;
        }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
            [UIView animateWithDuration:0.3 animations:^{
                [self movePopFinish];
            } completion:^(BOOL finished) {
                _isMoving = NO;
                self.backgroundView.hidden = YES;
            }];
            return;
        }
    }else{
        if (recoginzer.state == UIGestureRecognizerStateBegan) {
            
            _isMoving = YES;
            
            if (!self.backgroundView)
            {
                CGRect frame = TOP_VIEW.frame;
                
                self.backgroundView = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)]autorelease];
                [TOP_VIEW.superview insertSubview:self.backgroundView belowSubview:TOP_VIEW];
                
                blackMask = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)]autorelease];
                blackMask.backgroundColor = [UIColor blackColor];
                [self.backgroundView addSubview:blackMask];
            }
            
            self.backgroundView.hidden = NO;
            
            if (lastScreenShotView) [lastScreenShotView removeFromSuperview];
            
            UIImage *lastScreenShot = [self.screenShotsList lastObject];
            lastScreenShotView = [[[UIImageView alloc]initWithImage:lastScreenShot]autorelease];
            [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
            
            //End paning, always check that if it should move right or move left automatically
        }else if (recoginzer.state == UIGestureRecognizerStateEnded){
            
            if (TOP_VIEW.frame.origin.x > TOP_VIEW.frame.size.width/2)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    [self movePopFinish];
                } completion:^(BOOL finished) {
                    
                    [self popViewControllerAnimated:NO];
                    CGRect frame = TOP_VIEW.frame;
                    frame.origin.x = 0;
                    TOP_VIEW.frame = frame;
                    
                    _isMoving = NO;
                    self.backgroundView.hidden = YES;
                    
                }];
            }
            else
            {
                [UIView animateWithDuration:0.3 animations:^{
                    [self movePushFinish];
                } completion:^(BOOL finished) {
                    _isMoving = NO;
                    self.backgroundView.hidden = YES;
                }];
                
            }
            return;
            
            // cancal panning, alway move to left side automatically
        }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
            
            [UIView animateWithDuration:0.3 animations:^{
                [self movePushFinish];
            } completion:^(BOOL finished) {
                _isMoving = NO;
                self.backgroundView.hidden = YES;
            }];
            
            return;
        }

    }
    // begin paning, show the backgroundView(last screenshot),if not exist, create it.
    // it keeps move with touch
    if (_isMoving) {
        [self moveViewWithX:tranPoint.x];
    }
    [recoginzer setTranslation:CGPointZero inView:KEY_WINDOW];
}

@end
