//
//  CustomAlertView.m
//  CustomAlertView
//
//  Created by Richard on 29/12/2013.
//  Copyright (c) 2013 Peter.
//
//

#import "AHAlertView.h"
#import <QuartzCore/QuartzCore.h>

const static CGFloat kCustomAlertViewDefaultButtonHeight       = 40;
const static CGFloat kCustomAlertViewDefaultButtonSpacerHeight = 1;
const static CGFloat kCustomAlertViewCornerRadius              = 10;
const static CGFloat kCustomMotionEffectExtent                 = 10.0;

#define RADIO_ON @"radiobutton_on"
#define RADIO_OFF @"radiobutton_off"
#define CHECK_ON @"checkbox_on"
#define CHECK_OFF @"checkbox_off"

@interface AHAlertView ()

@property (nonatomic, strong) NSArray *buttonTitles;

/**
 ** Top Area title and Message
 */
@property (nonatomic, strong) NSString *topTitle;
@property (nonatomic, strong) NSString *message;

/**
 ** if use close button
 */
@property (nonatomic, assign) BOOL ifCloseButton;

/**
 ** The parent view this 'dialog' is attached to
 */
@property (nonatomic, strong) UIView *parentView;

/**
 ** dialog's container view
 */
@property (nonatomic, strong) UIView *dialogView;

/**
 ** Container within the dialog
 ** place your ui elements here
 */
@property (nonatomic, strong) UIView *containerView;

/**
 ** Cancel button tag
 */
@property (nonatomic, assign) int cancelButtonTag;

/**
 ** Button Object List
 */
@property (nonatomic, strong) NSArray *buttonList;

/**
 ** checkBox Object Status List
 ** 0=cancel  1=checked
 */
@property (nonatomic, strong) NSArray *checkBoxStatus;

@property (nonatomic, assign) BOOL useMotionEffects;

/**
 ** Button Mode of the dialog
 */
@property (nonatomic, assign) AlertViewMode alertMode;


/**
 ** onButtonTouchUpInside block
 */
@property (copy) void (^onButtonTouchUpInside)(AHAlertView *alertView, int buttonIndex) ;

@end

@implementation AHAlertView

CGFloat buttonHeight = 0;
CGFloat buttonSpacerHeight = 0;


#pragma mark -- initial
- (id)initWithTitle:(NSString*)title andMessage:(NSString*)message andCancelButtonTitle:(NSString*)cancelTitle;
{
    //    return [self initWithParentView:NULL];
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        _topTitle = title;
        _message = message;
        _delegate = self;
        _useMotionEffects = false;
        _ifCloseButton = false;
        _buttonTitles = [NSArray new];
        _buttonList = [NSArray new];
        _alertMode = AlertViewMode_Normal;
        
        if (cancelTitle) {
                //if title != null, add Cancel Button to last.
            _ifCloseButton = YES;
            _cancelButtonTag = 0;
            _buttonTitles = [_buttonTitles arrayByAddingObject:cancelTitle];
        }
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}


#pragma mark -- Create & Run
// Create the dialog view, and animate opening the dialog
- (void)show
{
    [self createTopView];
    _dialogView = [self createDialogContainerView];
    
    _dialogView.layer.shouldRasterize = YES;
    _dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
#if (defined(__IPHONE_7_0))
    if (_useMotionEffects) {
        [self applyMotionEffects];
    }
#endif
    
    _dialogView.layer.opacity = 0.5f;
    _dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    _dialogView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1];
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    [self addSubview:_dialogView];
    
    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (_parentView != NULL) {
        [_parentView addSubview:self];
        
        // Attached to the top most window (make sure we are using the right orientation):
    } else {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;
                
            default:
                break;
        }
        
        [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         _dialogView.layer.opacity = 1.0f;
                         _dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
					 }
					 completion:NULL
     ];
}

// Button has been touched
- (IBAction)customdialogButtonTouchUpInside:(id)sender
{
    if (_alertMode != AlertViewMode_Normal && [sender tag] != _cancelButtonTag) {
        
        NSMutableArray *checkBoxStatusTemp = [_checkBoxStatus mutableCopy];
        
        //u26AA
        if (_alertMode == AlertViewMode_CheckBox) {
            
            UILabel *label = (UILabel*)[self viewWithTag:([sender tag]+50)];
            //            UIImageView *checkImg = (UIImageView*)[self viewWithTag:([sender tag]+50)];
            
            if ([[checkBoxStatusTemp objectAtIndex:[sender tag]]boolValue]) {
                label.text = @"\u2B1C";
                //                checkImg.image = [UIImage imageNamed:CHECK_OFF];
                [checkBoxStatusTemp replaceObjectAtIndex:[sender tag] withObject:@0];
            }
            else {
                label.text = @"\u2611";
                //                checkImg.image = [UIImage imageNamed:CHECK_ON];
                [checkBoxStatusTemp replaceObjectAtIndex:[sender tag] withObject:@1];
            }
        }
        else {
            for (int i=0; i<[checkBoxStatusTemp count]; i++) {
                if ([[checkBoxStatusTemp objectAtIndex:i]boolValue]) {
                    [checkBoxStatusTemp replaceObjectAtIndex:i withObject:@0];
                    
                    UILabel *label = (UILabel*)[self viewWithTag:(i+50)];
                    label.text = @"\u26AA";
                    //                    UIImageView *checkImg = (UIImageView*)[self viewWithTag:(i+50)];
                    //                    checkImg.image = [UIImage imageNamed:RADIO_OFF];
                }
            }
            
            UILabel *label = (UILabel*)[self viewWithTag:([sender tag]+50)];
            //            UIImageView *checkImg = (UIImageView*)[self viewWithTag:([sender tag]+50)];
            if (![[checkBoxStatusTemp objectAtIndex:[sender tag]]boolValue]) {
                label.text = @"\u26AB";
                //                checkImg.image = [UIImage imageNamed:RADIO_ON];
                [checkBoxStatusTemp replaceObjectAtIndex:[sender tag] withObject:@1];
            }
            
        }
        _checkBoxStatus = [NSArray arrayWithArray:checkBoxStatusTemp];
        
        return;
    }
    if (_delegate != NULL) {
        [_delegate customdialogButtonTouchUpInside:self clickedButtonAtIndex:[sender tag]];
    }
    
    if (_onButtonTouchUpInside != NULL) {
        _onButtonTouchUpInside(self, (int)[sender tag]);
    }
}

// Default button behaviour
- (void)customdialogButtonTouchUpInside: (AHAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Clicked! %ld, %ld", (long)buttonIndex, (long)[alertView tag]);
    if (buttonIndex == 0 && _ifCloseButton) {
        [self close];
    }
    
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close
{
    CATransform3D currentTransform = _dialogView.layer.transform;
    
    CGFloat startRotation = [[_dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);
    
    _dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    _dialogView.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         _dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         _dialogView.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
					 }
	 ];
    

}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView *)createDialogContainerView
{
    if (_containerView == NULL) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 150)];
    }
    
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    // For the black background
    [self setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    
    // This is the dialog's container; we attach the custom content and the buttons to this one
    UIView *dialogContainer = [[UIView alloc] initWithFrame:CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height)];
    
    // First, we style the dialog to match the  UIAlertView >>>
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = dialogContainer.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
                       nil];
    
    CGFloat cornerRadius = kCustomAlertViewCornerRadius;
    gradient.cornerRadius = cornerRadius;
    [dialogContainer.layer insertSublayer:gradient atIndex:0];
    
    dialogContainer.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f] CGColor];
    dialogContainer.layer.borderWidth = 1;
    dialogContainer.layer.shadowRadius = cornerRadius + 5;
    dialogContainer.layer.shadowOpacity = 0.1f;
    dialogContainer.layer.shadowOffset = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
    dialogContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    dialogContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:dialogContainer.bounds cornerRadius:cornerRadius].CGPath;
    
    if ([_buttonTitles count] <= 2) {
        // There is a line above the button
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, dialogContainer.bounds.size.height - buttonHeight - buttonSpacerHeight, dialogContainer.bounds.size.width, buttonSpacerHeight)];
        lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
        [dialogContainer addSubview:lineView];
        
        if ([_buttonTitles count] == 2) {
            UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(dialogContainer.bounds.size.width/2-buttonSpacerHeight/2, dialogContainer.bounds.size.height - buttonHeight - buttonSpacerHeight, buttonSpacerHeight, buttonHeight)];
            lineView2.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
            [dialogContainer addSubview:lineView2];
        }
        
        // ^^^
    }
    
    // Add the custom container if there is any
    [dialogContainer addSubview:_containerView];
    
    // Add the buttons too
    [self addButtonsToView:dialogContainer];
    

    dialogContainer.layer.cornerRadius = kCustomAlertViewCornerRadius;
    return dialogContainer;
}


#pragma mark -
#pragma mark -- User Setting
- (void)setSubView: (UIView *)subView
{
    _containerView = subView;
}

- (void)createTopView
{
    if (_containerView != NULL) {
        //已經有客制的，就不再新增
        return;
    }
    
    NSLog(@"createTopView...");
    float containerViewHight = 0;
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, containerViewHight)];
    
    UIView *topPart = [[UIView alloc] initWithFrame:CGRectMake(0, 50, topView.frame.size.width, 50)];
    topPart.backgroundColor = [UIColor whiteColor];
    [topView addSubview:topPart];
    
    if (_topTitle) {
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, containerViewHight+15, topView.frame.size.width-20, 20)];
        titleLabel.text = _topTitle;
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        [topView addSubview:titleLabel];
        
        containerViewHight += 50;
    }
    if (_message) {
        
        UIFont *font = [UIFont systemFontOfSize:16];
        CGSize maximumSize = CGSizeMake(topView.frame.size.width, CGFLOAT_MAX);
        CGSize boundingRect = [_message sizeWithFont:font constrainedToSize:maximumSize lineBreakMode:NSLineBreakByWordWrapping];
        
        UITextView *messageView = [[UITextView alloc] init];
        messageView.autocorrectionType=UITextAutocorrectionTypeNo;
        messageView.frame = CGRectMake(10, 15, topView.frame.size.width-20, boundingRect.height+40);
        messageView.text = _message;
        messageView.font = font;
        messageView.editable = NO;
        messageView.dataDetectorTypes = UIDataDetectorTypeAll;
        messageView.userInteractionEnabled = NO;
        messageView.textAlignment = NSTextAlignmentCenter;
        messageView.textColor = [UIColor darkGrayColor];
        messageView.backgroundColor = [UIColor clearColor];
        [topPart addSubview:messageView];
        
        containerViewHight += boundingRect.height+50;
    }
    
    topPart.frame = CGRectMake(0, 50, 280, containerViewHight-50);
    topView.frame = CGRectMake(0, 0, 280, containerViewHight);
    _containerView = topView;
}

// Helper function: add buttons to container
- (void)addButtonsToView: (UIView *)dialogContainer
{
    if (_alertMode == AlertViewMode_CheckBox && !_ifCloseButton) {
        _buttonTitles = [_buttonTitles arrayByAddingObject:@"Close"];
    }
    
    CGFloat buttonWidth = 0;
    NSMutableArray *buttonTemp = [NSMutableArray new];
    NSMutableArray *checkBoxTemp = [NSMutableArray new];
    
    if ([_buttonTitles count] > 2) {
        buttonWidth = dialogContainer.bounds.size.width;
    }
    else {
        //Less than or equal to 2
        buttonWidth = dialogContainer.bounds.size.width / [_buttonTitles count];
        
        if ([_buttonTitles count] == 2) {
            NSString *okStr = [_buttonTitles objectAtIndex:0];
            NSString *closeStr = [_buttonTitles objectAtIndex:1];
            NSMutableArray *buttonTemp = [NSMutableArray arrayWithObjects:closeStr, okStr, nil];
            _buttonTitles = buttonTemp;
            
            _cancelButtonTag = 0;
        }
    }
    
    for (int i=0; i<[_buttonTitles count]; i++) {
        
        UIButton *clickButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UILabel *checkLabel = nil;
        //        UIImageView *checkImage = nil;
        if ([_buttonTitles count] > 2) {
            // There is a line above the button
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, _containerView.frame.size.height + (buttonHeight+buttonSpacerHeight) * i, dialogContainer.bounds.size.width, buttonSpacerHeight)];
            lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
            [dialogContainer addSubview:lineView];
            // ^^^
            
            [clickButton setFrame:CGRectMake(0, _containerView.frame.size.height+buttonSpacerHeight + (buttonHeight+buttonSpacerHeight) * i, buttonWidth, buttonHeight)];
            
            
            if (_alertMode == AlertViewMode_RadioBox) {
                checkLabel = [[UILabel alloc]initWithFrame:CGRectMake(buttonWidth-30, _containerView.frame.size.height+buttonSpacerHeight+buttonHeight/2-12 + (buttonHeight+buttonSpacerHeight) * i, 25, 25)];
                checkLabel.text = @"\u26AA";
                checkLabel.font = [UIFont systemFontOfSize:16];
                [checkLabel setTag: 50+i];
                
            }
            else if (_alertMode == AlertViewMode_CheckBox){
                checkLabel = [[UILabel alloc]initWithFrame:CGRectMake(buttonWidth-30, _containerView.frame.size.height+buttonSpacerHeight+buttonHeight/2-12 + (buttonHeight+buttonSpacerHeight) * i, 25, 25)];
                checkLabel.text = @"\u2B1C";
                checkLabel.font = [UIFont systemFontOfSize:16];
                [checkLabel setTag: 50+i];
                
            }
        }
        else {
            //小於等於2的
            [clickButton setFrame:CGRectMake(i * buttonWidth, dialogContainer.bounds.size.height - buttonHeight, buttonWidth, buttonHeight)];
        }
        
        
        [clickButton addTarget:self action:@selector(customdialogButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        
        [clickButton setTitle:[_buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        
        UIColor *bColor = [UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f];
        if (i != _cancelButtonTag) {
            if (_buttonColor) {
                bColor = _buttonColor;
            }
            
            if ([_buttonTitles count] > 2) {
                [clickButton setTag:i+1];
            } else {
                [clickButton setTag:i];
            }
            
        }
        else if (_ifCloseButton) {
            if (_cancelButtonColor) {
                bColor = _cancelButtonColor;
            }
            
            _cancelButtonTag = 0;
            
            [clickButton setTag:0];
        }
        else {
            if (_buttonColor) {
                bColor = _buttonColor;
            }
            
            [clickButton setTag:i+1];
        }
        
        if (i == [_buttonTitles count]-1) {
            //Specify rounded edge guide
            UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:clickButton.bounds byRoundingCorners:UIRectCornerBottomLeft |UIRectCornerBottomRight cornerRadii:CGSizeMake(10.0f,10.0f)];
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
            
            maskLayer.frame = clickButton.bounds;
            
            maskLayer.path = maskPath.CGPath;
            
            // set the mask
            clickButton.layer.mask = maskLayer;
        }
        
        [clickButton setTitleColor:bColor forState:UIControlStateNormal];
        [clickButton setTitleColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.5f] forState:UIControlStateHighlighted];
        [clickButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [dialogContainer addSubview:clickButton];
        
        if (_ifCloseButton && i == [_buttonTitles count]-1 && [_buttonTitles count]>2) {
            clickButton.backgroundColor = [UIColor clearColor];
        }
        else if (_ifCloseButton && ([_buttonTitles count] == 2 || [_buttonTitles count] == 1)) {
            //只有兩個按鈕
            clickButton.backgroundColor = [UIColor clearColor];
        }
        else {
            clickButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        }

        
        [buttonTemp addObject:clickButton];
        
        if (checkLabel) {
            if (!(_ifCloseButton && [[_buttonTitles lastObject]isEqual:[_buttonTitles objectAtIndex:i]])) {
                [dialogContainer addSubview:checkLabel];
                [checkBoxTemp addObject:@0];
            }
        }
        
    }
    
    _buttonList = [NSArray arrayWithArray:buttonTemp];
    _checkBoxStatus = [NSArray arrayWithArray:checkBoxTemp];
}

- (void)addButtonTitle:(NSArray*)titles
{
    if ([_buttonTitles count] > 0) {
        _cancelButtonTag = [titles count];
        _buttonTitles = [titles arrayByAddingObjectsFromArray:_buttonTitles];
    }
    else {
        _cancelButtonTag = 0;
        _buttonTitles = titles;
    }
    
    NSLog(@"[buttonTitles count] = %lu, %@", (unsigned long)[_buttonTitles count], _buttonTitles);
}


// Helper function: count and return the dialog's size
- (CGSize)countDialogSize
{
    CGFloat dialogWidth = _containerView.frame.size.width;
    CGFloat dialogHeight = _containerView.frame.size.height;
    if ([_buttonTitles count] > 2) {
        dialogHeight += (buttonHeight + buttonSpacerHeight) * [_buttonTitles count];
    }
    else {
        dialogHeight += (buttonHeight + buttonSpacerHeight);
    }
    
    return CGSizeMake(dialogWidth, dialogHeight);
}

// Helper function: count and return the screen's size
- (CGSize)countScreenSize
{
    if ([_buttonTitles count] > 0) {
        buttonHeight       = kCustomAlertViewDefaultButtonHeight;
        buttonSpacerHeight = kCustomAlertViewDefaultButtonSpacerHeight;
    } else {
        buttonHeight = 0;
        buttonSpacerHeight = 0;
    }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    
    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }
    
    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomMotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomMotionEffectExtent);
    
    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomMotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomMotionEffectExtent);
    
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];
    
    [_dialogView addMotionEffect:motionEffectGroup];
}
#endif



// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification
{
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (_parentView != NULL) {
        return;
    }
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
            break;
            
        default:
            rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
            break;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         _dialogView.transform = rotation;
					 }
					 completion:^(BOOL finished){
                         // fix errors caused by being rotated one too many times
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             UIInterfaceOrientation endInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                             if (interfaceOrientation != endInterfaceOrientation) {
                                 // TODO user moved phone again before than animation ended: rotation animation can introduce errors here
                             }
                         });
                     }
	 ];
    
}

// Handle keyboard show/hide changes
- (void)keyboardWillShow: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         _dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}

- (void)keyboardWillHide: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         _dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}

@end
