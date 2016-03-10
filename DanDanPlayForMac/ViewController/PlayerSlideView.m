//
//  PlayerSlideView.m
//  test
//
//  Created by JimHuang on 16/2/2.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "PlayerSlideView.h"
@interface PlayerSlideView()
@property (strong, nonatomic) NSView *progressSliderView;
@property (strong, nonatomic) NSView *bufferSliderView;
@end


@implementation PlayerSlideView
{
    NSColor *_backGroundColor;
    NSColor *_progressSliderColor;
    NSColor *_bufferSliderColor;
    CGFloat _progress;
    CGFloat _bufferProgress;
}
#pragma mark - 方法
- (void)updateCurrentProgress:(CGFloat)progress{
    CGSize size = self.frame.size;
    size.width *= progress;
    _progress = progress;
    self.progressSliderView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)updateBufferProgress:(CGFloat)progress{
    CGSize size = self.frame.size;
    size.width *= progress;
    _bufferProgress = progress;
    self.bufferSliderView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize{
    [super resizeWithOldSuperviewSize:oldSize];
    [self updateCurrentProgress:_progress];
    [self updateBufferProgress:_bufferProgress];
}

- (void)mouseDragged:(NSEvent *)theEvent{
    CGFloat value = [self progressValueWithPoint:theEvent.locationInWindow];
    if (value >= 0 && value <= 1){
        if ([self.delegate respondsToSelector:@selector(playerSliderDraggedEnd:playerSliderView:)]) {
            [self updateCurrentProgress: value];
            [self.delegate playerSliderDraggedEnd: value playerSliderView: self];
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    CGFloat value = [self progressValueWithPoint:theEvent.locationInWindow];
    if (value >= 0 && value <= 1){
        if ([self.delegate respondsToSelector:@selector(playerSliderTouchEnd:playerSliderView:)]) {
            [self updateCurrentProgress: value];
            [self.delegate playerSliderTouchEnd: value playerSliderView: self];
        }
    }
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setWantsLayer: YES];
    self.layer.backgroundColor = self.backGroundColor.CGColor;
}

- (void)setBackGroundColor:(NSColor *)backGroundColor{
    _backGroundColor = backGroundColor;
    self.layer.backgroundColor = backGroundColor.CGColor;
}

- (void)setProgressSliderColor:(NSColor *)progressSliderColor{
    _progressSliderColor = progressSliderColor;
    self.progressSliderView.layer.backgroundColor = progressSliderColor.CGColor;
}

- (void)setBufferSliderColor:(NSColor *)bufferSliderColor{
    _bufferSliderColor = bufferSliderColor;
    self.bufferSliderView.layer.backgroundColor = bufferSliderColor.CGColor;
}

- (CGFloat)progressValueWithPoint:(CGPoint)point{
    point = [self convertPoint:point fromView:[NSApp keyWindow].contentView];
    return point.x / self.frame.size.width;
}

#pragma mark - 懒加载

- (NSColor *)progressSliderColor {
    if(_progressSliderColor == nil) {
        _progressSliderColor = [NSColor colorWithRed:0.2102 green:0.5623 blue:0.9201 alpha:1];
    }
    return _progressSliderColor;
}

- (NSColor *)backGroundColor{
    if (_backGroundColor == nil) {
        _backGroundColor = [NSColor gridColor];
    }
    return _backGroundColor;
}

- (NSColor *)bufferSliderColor {
    if(_bufferSliderColor == nil) {
        _bufferSliderColor = [NSColor darkGrayColor];
    }
    return _bufferSliderColor;
}

- (NSView *)progressSliderView {
	if(_progressSliderView == nil) {
		_progressSliderView = [[NSView alloc] init];
        [_progressSliderView setWantsLayer: YES];
        _progressSliderView.layer.backgroundColor = self.progressSliderColor.CGColor;
        [self addSubview: _progressSliderView];
	}
	return _progressSliderView;
}

- (NSView *)bufferSliderView {
	if(_bufferSliderView == nil) {
		_bufferSliderView = [[NSView alloc] init];
        [_bufferSliderView setWantsLayer: YES];
        _bufferSliderView.layer.backgroundColor = self.bufferSliderColor.CGColor;
        [self addSubview: _bufferSliderView positioned:NSWindowBelow relativeTo:self.progressSliderView];
	}
	return _bufferSliderView;
}

@end
