/**
 * @Author: Dana Buehre <creaturesurvive>
 * @Date:   06-08-2017 2:08:52
 * @Email:  dbuehre@me.com
 * @Filename: Tweak.xm
 * @Last modified by:   creaturesurvive
 * @Last modified time: 25-09-2017 11:29:38
 * @Copyright: Copyright © 2014-2017 CreatureSurvive
 */


#include "headers.h"

%hook SBDashBoardNotificationListViewController

- (void)viewDidLoad {
    %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear) name:@"kPTCClear" object:nil];
}

- (void)dealloc {
    %orig;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

%new - (void)clear {
    [self _clearContentIncludingPersistent:YES];
}

%end

%hook NCNotificationListViewController
%property(nonatomic, retain) UILabel *refreshLabel;
%property(nonatomic, retain) UIColor *refreshColor;
%property(nonatomic, assign) BOOL isRefreshing;
%property(nonatomic, assign) BOOL isClearing;

- (void)viewDidLoad {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    if (!self.refreshLabel) {

        CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"] ? : 17.0f;
        NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"] ? : @".SFUIDisplay-Regular";

        self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, [[PTCProvider sharedProvider] floatForKey:@"kPTCActivationHeight"])];
        self.refreshLabel.textAlignment = NSTextAlignmentCenter;
        self.refreshLabel.text = @"Pull To Clear";
        self.refreshLabel.font = [UIFont loadFontWithName:fontName size:fontSize] ? : [UIFont systemFontOfSize:17];
        [self.collectionView addSubview:self.refreshLabel];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    self.collectionView.alpha = 1;
    CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"] ? : 17.0f;
    NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"] ? : @".SFUIDisplay-Regular";

    self.refreshLabel.font = [UIFont loadFontWithName:fontName size:fontSize] ? : [UIFont systemFontOfSize:17];
    self.refreshColor = [[PTCProvider sharedProvider] colorForKey:@"kPTCFontColor"] ? : [UIColor lightTextColor];
    [self hideRefreshLabel];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    [self refreshForCurrentOffset:scrollView.contentOffset.y];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate  {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    if (self.isRefreshing) {

        AudioServicesPlaySystemSound(1520);
        self.refreshLabel.textColor = [UIColor clearColor];
        self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);

        //[self clearNotifications];
        self.isClearing = YES;
    }
}

%new - (void)refreshForCurrentOffset: (CGFloat)offset {
    CGFloat height = [[PTCProvider sharedProvider] floatForKey:@"kPTCActivationHeight"];
    CGFloat clearHeight = 150;
    CGFloat alpha = -offset/height;
    CGFloat bravo = -offset/clearHeight;

    if (alpha <= 0.2) {
        if (self.isClearing) {
            self.isClearing = NO;
            [self clearNotifications];
        }
        if (alpha <= 0) {
            [self hideRefreshLabel];
        }
        return;
    }

    if (self.refreshLabel.hidden) {
        self.refreshLabel.hidden = NO;
    }

    if (self.isClearing) {
        self.collectionView.alpha = alpha-0.1;
    }

    self.refreshLabel.textColor = [self.refreshColor colorWithAlphaComponent:alpha];
    self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, alpha < 0.8 ? alpha : 0.8, alpha < 0.8 ? alpha : 0.8);
    self.refreshLabel.frame = CGRectMake(0, offset, self.collectionView.frame.size.width, height);

    if (bravo >= 1) {
        [self clearNotifications];
        return;
    }

    if (alpha >= 0.8f) {
        if (!self.isRefreshing) {
            self.isRefreshing = YES;
            AudioServicesPlaySystemSound(1520);
            self.refreshLabel.text = @"Release To Clear";
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:8 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self updateRefreshLabel];
                self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            } completion:nil];
        }
    } else {
        if (self.isRefreshing) {
            self.isRefreshing = NO;
            AudioServicesPlaySystemSound(1519);
            self.refreshLabel.text = @"Pull To Clear";
        }
    }
}

%new -(void)updateRefreshLabel {
    NSMutableParagraphStyle *attributedStringParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    attributedStringParagraphStyle.alignment = NSTextAlignmentCenter;

    self.refreshLabel.attributedText = [[NSAttributedString alloc] initWithString:self.refreshLabel.text
                                                                       attributes:@{NSForegroundColorAttributeName:self.refreshLabel.textColor,
                                                                                    NSParagraphStyleAttributeName:attributedStringParagraphStyle,
                                                                                    NSFontAttributeName:self.refreshLabel.font}];
}

%new - (void)hideRefreshLabel {
    self.refreshLabel.textColor = [UIColor clearColor];
    self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
    self.refreshLabel.hidden = YES;
}

%new - (void)clearNotifications {
    if ([self class] == NSClassFromString(@"NCNotificationSectionListViewController")) {
        [(NCNotificationSectionListViewController *) self sectionHeaderViewDidReceiveClearAllAction:nil];
    } else if ([self class] == NSClassFromString(@"NCNotificationPriorityListViewController")) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kPTCClear" object:nil userInfo:nil];
    }
    [self prepairForRefresh];
}

%new - (void)prepairForRefresh {
    self.isClearing = NO;
    self.isRefreshing = NO;

}

%end
