//
//  HBMyWorkView.m
//  LeaderDiandu
//
//  Created by xijun on 15/9/20.
//  Copyright (c) 2015年 hxj. All rights reserved.
//

#import "HBMyWorkView.h"
#import "HBTestWorkManager.h"
#import "HBOptionView.h"
#import "HBOptionButton.h"
#import "MBHudUtil.h"
#import <AVFoundation/AVAudioPlayer.h>

#define KTagSelectionBegin  1527

typedef enum : NSUInteger {
    HBQuestionTypeText,
    HBQuestionTypeTAP,
    HBQuestionTypeTAA,
} HBQuestionType;

typedef enum : NSUInteger {
    HBSelectionTypePic,
    HBSelectionTypeText,
    HBSelectionTypeText4,
} HBSelectionType;

@interface HBMyWorkView () <HBOptionViewDelegate, HBOptionButtonDelegate, AVAudioPlayerDelegate>
{
    UILabel *_titleLabel;
    UILabel *_descLabel;
    UIButton *_finishButton;
    UIButton *_descButton;
    UIImageView *_descImg;
    
    UIImageView *_leftImg;
    UIImageView *_rightImg;
    
    UIButton *_leftButton;
    UIButton *_rightButton;
    
    UIView *_questionView;
    
    HBQuestionType _questionType;
    HBSelectionType _selectionType;
    
    BOOL isOptionSelected;  //是否选中一个选项
    NSInteger selAnswerIndex;//选中的是哪一项
}

@property (nonatomic, strong)AVAudioPlayer *audioPlayer;
@property (nonatomic, strong)UIView *selectionView;

@end

@implementation HBMyWorkView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI:frame];
    }
    return self;
}

- (void)initUI:(CGRect)frame
{
    UIFont *font = [UIFont systemFontOfSize:22];
    
    float controlX = 20;
    float controlY = 0;
    float controlW = frame.size.width - controlX*2;
    float controlH = 220;
    [self initQuestionView:CGRectMake(controlX, controlY, controlW, controlH)];
    
    controlH = 40;
    NSInteger margin = 20;
    if ([[UIDevice currentDevice] isIphone5]) {
        margin = 20;
    }
    controlY = frame.size.height-margin-controlH;
    _finishButton = [[UIButton alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
//    [_finishButton.layer setMasksToBounds:YES];
//    [_finishButton.layer setCornerRadius:5.0];
//    _finishButton.backgroundColor = [UIColor greenColor];
    [_finishButton setBackgroundImage:[UIImage imageNamed:@"test-btn-normal"] forState:UIControlStateNormal];
    [_finishButton setBackgroundImage:[UIImage imageNamed:@"test-btn-press"] forState:UIControlStateHighlighted];
    _finishButton.titleLabel.font = font;
    [_finishButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_finishButton];
}

- (void)initQuestionView:(CGRect)frame
{
    _questionView = [[UIView alloc] initWithFrame:frame];
    _questionView.backgroundColor = [UIColor clearColor];
    [_questionView.layer setMasksToBounds:YES];
    [_questionView.layer setCornerRadius:10.0];
    [_questionView.layer setBorderWidth:2.0];
    [_questionView.layer setBorderColor:[UIColor colorWithHex:0xff8903].CGColor];
    [self addSubview:_questionView];
    
    float controlX = 10;
    float controlY = 20;
    float controlW = frame.size.width - controlX*2;
    float controlH = 20;
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor colorWithHex:0xff8903];
    _titleLabel.font = [UIFont boldSystemFontOfSize:22];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [_questionView addSubview:_titleLabel];
    
    controlY += controlH + 10;
    controlH = 60;
    _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    _descLabel.backgroundColor = [UIColor clearColor];
    _descLabel.textColor = [UIColor colorWithHex:0x817b72];
    _descLabel.font = [UIFont systemFontOfSize:22];
    _descLabel.textAlignment = NSTextAlignmentCenter;
    _descLabel.numberOfLines = 0;
    [_questionView addSubview:_descLabel];

    controlY += controlH + 10;
    controlX += (controlW - 80) / 2;
    controlW = controlH = 80;
    _descButton = [[UIButton alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    [_descButton addTarget:self action:@selector(voiceBtnTouched:) forControlEvents:UIControlEventTouchUpInside];
    [_questionView addSubview:_descButton];
    
    _descImg = [[UIImageView alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH)];
    _descImg.hidden = YES;
    [_questionView addSubview:_descImg];
}

- (void)initSelectionView:(NSArray *)optionArray
{
    if (_selectionView) {
        NSArray *subViews = [_selectionView subviews];
        for (UIView *view in subViews) {
            [view removeFromSuperview];
        }
    } else {
        CGRect rect = _questionView.frame;
        float selY = CGRectGetMaxY(rect);
        float controlH = CGRectGetMinY(_finishButton.frame) - selY;
        _selectionView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rect), selY, CGRectGetWidth(rect), controlH)];
        [self addSubview:_selectionView];
    }
    
    float controlW = 110;
    float controlH = 80;
    float controlX = 0;
    CGRect frame = _selectionView.frame;
    float controlY = (frame.size.height-controlH) / 2;
    NSInteger count = [optionArray count];
    if (count == 4) {
        controlY = (frame.size.height-controlH*2-20) / 2;
    }
    for (NSInteger i=0; i<count; i++) {
        id obj = optionArray[i];
        if (i%2 == 1) {
            controlX = frame.size.width - controlW;
        } else {
            controlX = 0;
            controlY += controlH*(i/2) + 10;
        }
        if ([obj isKindOfClass:[UIImage class]]) {
            HBOptionView *view = [[HBOptionView alloc] initWithFrame:CGRectMake(controlX, controlY, controlW, controlH) image:obj];
            view.tag = KTagSelectionBegin+i;
            view.delegate = self;
            [_selectionView addSubview:view];
        } else {
            controlW = 140;
            if ([[UIDevice currentDevice] isIphone5]) {
                controlW = 120;
            }
            controlH = 60;
            [self createSelectionButton:CGRectMake(controlX, controlY, controlW, controlH) tag:KTagSelectionBegin+i title:obj];
        }
    }
    if (count == 0) {
        //判断题
        controlW = controlH;
        controlX = (frame.size.width - controlW*2)/4;
        [self createJudgeButton:CGRectMake(controlX, controlY, controlW, controlH) tag:KTagSelectionBegin normal:@"test-btn-right-normal" press:@"test-btn-right-press" selected:@"test-btn-right-selected"];
        controlX += controlX*2 + controlW;
        [self createJudgeButton:CGRectMake(controlX, controlY, controlW, controlH) tag:KTagSelectionBegin normal:@"test-btn-wrong-normal" press:@"test-btn-wrong-press" selected:@"test-btn-wrong-selected"];
    }
}

- (void)createJudgeButton:(CGRect)frame tag:(NSInteger)tag normal:(NSString *)normaol press:(NSString *)press selected:(NSString *)sel
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.tag = tag;
    [button setBackgroundImage:[UIImage imageNamed:normaol] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:press] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIImage imageNamed:sel] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(selectionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [_selectionView addSubview:button];
}

- (void)createSelectionButton:(CGRect)frame tag:(NSInteger)tag title:(NSString *)title
{
    HBOptionButton *button = [[HBOptionButton alloc] initWithFrame:frame title:title];
    button.tag = tag;
    button.delegate = self;
//    [button addTarget:self action:@selector(selectionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//    [button setTitle:title forState:UIControlStateNormal];
//    button.titleLabel.numberOfLines = 0;
//    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [_selectionView addSubview:button];
}

- (void)updateData:(NSDictionary *)dict byScore:(NSString *)score
{
    isOptionSelected = NO;
    
    NSString *typeStr = dict[@"Type"];
    [self updateTitle:typeStr];
    
    _descLabel.text = dict[@"Text"];
    CGRect rect = _descLabel.frame;
    if (_questionType == HBQuestionTypeText) {
        rect = _questionView.bounds;
        rect.origin.x = 10;
        rect.size.width -= 20;
        _descLabel.frame = rect;
        _descButton.hidden = YES;
        _descImg.hidden = YES;
    } else if (_questionType == HBQuestionTypeTAA) {
        _descButton.hidden = NO;
        _descImg.hidden = YES;
        CGSize size = [_descLabel.text boundingRectWithSize:rect.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_descLabel.font} context:nil].size;
        rect.size.height = size.height;
        _descLabel.frame = rect;
        [_descButton setBackgroundImage:[UIImage imageNamed:@"test-btn-sound-normal"] forState:UIControlStateNormal];
        [_descButton setBackgroundImage:[UIImage imageNamed:@"test-btn-sound-press"] forState:UIControlStateHighlighted];
    } else if (_questionType == HBQuestionTypeTAP) {
        CGSize size = [_descLabel.text boundingRectWithSize:rect.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_descLabel.font} context:nil].size;
        rect.origin.y = CGRectGetMaxY(_titleLabel.frame) + 10;
        rect.size.height = size.height;
        _descLabel.frame = rect;
        
        _descButton.hidden = YES;
        _descImg.hidden = NO;
        UIImage *image = [_workManager getPictureByDict:dict];
        _descImg.image = image;
        CGSize imgSize = image.size;
        imgSize = CGSizeMake(imgSize.width/3, imgSize.height/3);
        rect = _questionView.bounds;
        float controlX = (rect.size.width-imgSize.width) / 2;
        float controlY = rect.size.height-imgSize.height-10;
        _descImg.frame = CGRectMake(controlX, controlY, imgSize.width, imgSize.height);
    }
    
    NSArray *optionsArr = [_workManager getOptionArray:dict];
    [self initSelectionView:optionsArr];
    
    //若不是最后一题，显示“下一题”，若是最后一题，则未提交过的显示“交作业”。已提交过的显示“完成”
    BOOL isLast = [_workManager isLastObject];
    if (isLast) {
        if (score) {
            [_finishButton setTitle:@"完成" forState:UIControlStateNormal];
        } else {
            [_finishButton setTitle:@"交作业" forState:UIControlStateNormal];
        }
        [_finishButton setBackgroundImage:[UIImage imageNamed:@"test-btn-finish-normal"] forState:UIControlStateNormal];
        [_finishButton setBackgroundImage:[UIImage imageNamed:@"test-btn-finish-press"] forState:UIControlStateHighlighted];
    } else {
        [_finishButton setTitle:@"下一题" forState:UIControlStateNormal];
    }
}

- (void)updateTitle:(NSString *)type
{
    NSString *title = nil;
    if ([type isEqualToString:@"act"]) {
        title = @"听音选择正确的文字";
        _questionType = HBQuestionTypeTAA;
        _selectionType = HBSelectionTypeText;
    } else if ([type isEqualToString:@"acp"]) {
        title = @"听音选择正确的图片";
        _questionType = HBQuestionTypeTAA;
        _selectionType = HBSelectionTypePic;
    } else if ([type isEqualToString:@"pcp"]) {
        title = @"看图选择匹配的图片";
        _questionType = HBQuestionTypeTAP;
        _selectionType = HBSelectionTypePic;
    } else if ([type isEqualToString:@"pct"]) {
        title = @"看图选择匹配的内容";
        _questionType = HBQuestionTypeTAP;
        _selectionType = HBSelectionTypeText;
    } else if ([type isEqualToString:@"p2p"]) {
        title = @"连接匹配的图片";
        _questionType = HBQuestionTypeTAP;
        _selectionType = HBSelectionTypePic;
    } else if ([type isEqualToString:@"t2t"]) {
        title = @"连接匹配的文字";
        _questionType = HBQuestionTypeText;
        _selectionType = HBSelectionTypeText;
    } else if ([type isEqualToString:@"p2t"]) {
        title = @"连接匹配的图片和文字";
        _questionType = HBQuestionTypeTAP;
        _selectionType = HBSelectionTypeText;
    } else if ([type isEqualToString:@"t2p"]) {
        title = @"连接匹配的文字和图片";
        _questionType = HBQuestionTypeText;
        _selectionType = HBSelectionTypePic;
    } else if ([type isEqualToString:@"judge"]) {
        title = @"判断对错";
        _questionType = HBQuestionTypeTAP;
        _selectionType = HBSelectionTypePic;
    }
    _titleLabel.text = [NSString stringWithFormat:@"%ld.%@", _workManager.selIndex+1, title];
}

- (BOOL)isQuestionRightByDict:(NSDictionary *)dict
{
    BOOL isRight = NO;
    NSInteger answer = [dict[@"Answer"] integerValue];
    if ([dict[@"Type"] isEqualToString:@"judge"]) {
        //判断题，answer为1或0，选择index=0为对，index=1为错
        if (selAnswerIndex == !answer) {
            isRight = YES;
        }
    } else {
        if (selAnswerIndex+1 == answer) {
            isRight = YES;
        }
    }
    
    return isRight;
}

- (void)playAudio:(NSString *)audioFile
{
    if (_audioPlayer) {
        [_audioPlayer play];
        return;
    }
    NSString *ext = [audioFile pathExtension];
    if ([ext length] == 0) {
        audioFile = [NSString stringWithFormat:@"%@.mp3", audioFile];
    }
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioFile] error:&error];
//    self.audioPlayer.delegate = self;
    if (!error) {
        [_audioPlayer play];
    } else {
        [MBHudUtil showTextView:@"没有找到资源" inView:nil];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag && _audioPlayer) {
//        BOOL isPlaying = _audioPlayer.isPlaying;
//        [_audioPlayer stop];
    }
}

- (void)voiceBtnTouched:(id)sender
{
    NSString *audioFile = [_workManager getAudioFile];
    [self playAudio:audioFile];
}

- (void)buttonAction:(id)sender
{
    if (isOptionSelected == NO) {
        [MBHudUtil showTextView:@"您还没有完成这道题哦" inView:nil];
        return;
    }
    if (_audioPlayer) {
        [_audioPlayer stop];
        self.audioPlayer = nil;
    }
    if (self.delegate) {
        [self.delegate onTouchFinishedButton];
    }
}

- (void)selectionBtnAction:(id)sender
{
    isOptionSelected = NO;
    NSInteger i = 0;
    NSArray *subViews = [_selectionView subviews];
    for (UIView *view in subViews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button == sender) {
                isOptionSelected = YES;
                button.selected = YES;
                selAnswerIndex = i;
            } else {
                button.selected = NO;
            }
            i++;
        }
    }
}

- (void)setOptionButtonSelected:(id)sender
{
    [self selectionBtnAction:sender];
}

#pragma ---HBOptionViewDelegate---

- (void)setOptionViewSelected:(HBOptionView *)optionView
{
    isOptionSelected = NO;
    NSInteger i = 0;
    NSArray *subViews = [_selectionView subviews];
    for (UIView *view in subViews) {
        if ([view isKindOfClass:[HBOptionView class]]) {
            if (view == optionView) {
                isOptionSelected = YES;
                [optionView setSelected:YES];
                selAnswerIndex = i;
            } else {
                [(HBOptionView *)view setSelected:NO];
            }
            i++;
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
