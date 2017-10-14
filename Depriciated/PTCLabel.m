/**
 * @Author: Dana Buehre <creaturesurvive>
 * @Date:   19-09-2017 12:25:48
 * @Email:  dbuehre@me.com
 * @Filename: PTCLabel.m
 * @Last modified by:   creaturesurvive
 * @Last modified time: 24-09-2017 1:57:27
 * @Copyright: Copyright © 2014-2017 CreatureSurvive
 */


#include "PTCLabel.h"

@implementation PTCLabel

- (id)init {
    if ((self = [super init])) {
        [self _newLabel];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _newLabel];
    }
    return self;
}

- (void)_newLabel {
    NSMutableParagraphStyle *attributedStringParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    attributedStringParagraphStyle.alignment = NSTextAlignmentCenter;

    CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"];
    NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"];

    self.refreshString = [[PTCProvider sharedProvider] objectForKey:@"kPTCRefreshString"];
    self.pullString = [[PTCProvider sharedProvider] objectForKey:@"kPTCPullString"];
    self.paragraphStyle = attributedStringParagraphStyle;
    self.activationHeight = [[PTCProvider sharedProvider] floatForKey:@"kPTCActivationHeight"];
    self.font = [UIFont loadFontWithName:fontName size:fontSize];

    self.textAlignment = NSTextAlignmentCenter;
    self.text = self.pullString;

    self.textColor = [UIColor clearColor];
    [self hide];
}

- (void)hide {
    self.textColor = [UIColor clearColor];
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
    self.hidden = YES;
}

- (void)show {
    self.hidden = NO;
    self.textColor = [[PTCProvider sharedProvider] colorForKey:@"kPTCFontColor"];
}

- (void)refreshForDragEnded {
    if (self.isRefreshing) {

        AudioServicesPlaySystemSound(1520);
        self.textColor = [UIColor clearColor];
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
    }
}

- (void)refreshForOffset:(CGFloat)offset {
    CGFloat height = self.activationHeight;
    CGFloat alpha = -offset/height;

    if (alpha <= 0) {
        [self hide];
        return;
    } else if (self.hidden) {
        [self show];
    }

    self.textColor = [self.refreshColor colorWithAlphaComponent:alpha];
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, alpha < 0.8 ? alpha : 0.8, alpha < 0.8 ? alpha : 0.8);
    self.frame = CGRectMake(0, offset, self.frame.size.width, height);

    if (alpha >= 0.8f) {
        if (!self.isRefreshing) {
            self.isRefreshing = YES;
            AudioServicesPlaySystemSound(1520);
            self.text = self.refreshString;
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:1.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self updateLabel];
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            } completion:nil];
        }
    } else {
        if (self.isRefreshing) {
            self.isRefreshing = NO;
            AudioServicesPlaySystemSound(1519);
            self.text = self.pullString;
        }
    }
}

- (void)updateLabel {
    self.attributedText = [[NSAttributedString alloc] initWithString:self.text
                                                          attributes:@{NSForegroundColorAttributeName:self.textColor,
                                                                       NSParagraphStyleAttributeName:self.paragraphStyle,
                                                                       NSFontAttributeName:self.font}];
}

@end
