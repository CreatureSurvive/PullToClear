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
%property(nonatomic, retain) NSString *pullString;
%property(nonatomic, retain) NSString *releaseString;
%property(nonatomic, assign) BOOL isRefreshing;
%property(nonatomic, assign) BOOL isClearing;

- (void)viewDidLoad {
    %orig;
    [self addRefreshLabelIfNecessary];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self prepairRefreshLabelForReuse];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;
    if (!self.refreshLabel) {
        [self addRefreshLabelIfNecessary];
    }
    
    [self refreshForCurrentOffset:scrollView.contentOffset.y];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate  {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;
    if (!self.refreshLabel) return;
    
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
    CGFloat clearHeight = [[PTCProvider sharedProvider] floatForKey:@"kPTCClearHeight"];
    CGFloat alpha = -offset/height;
    CGFloat bravo = -offset/clearHeight;

    if (alpha <= 0.2) {
        [self hideRefreshLabel];
        if (self.isClearing) {
            self.isClearing = NO;
            [self clearNotifications];
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
            self.refreshLabel.text = self.releaseString;
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:8 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self updateRefreshLabel];
                self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            } completion:nil];
        }
        self.collectionView.alpha = 1 - (alpha - 0.8);
    } else {
        if (self.isRefreshing) {
            self.isRefreshing = NO;
            AudioServicesPlaySystemSound(1519);
            self.refreshLabel.text = self.pullString;
        }
    }
}

%new -(void)updateRefreshLabel {
    NSMutableParagraphStyle *attributedStringParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    attributedStringParagraphStyle.alignment = NSTextAlignmentCenter;
    @try {
    self.refreshLabel.attributedText = [[NSAttributedString alloc] initWithString:self.refreshLabel.text
                                                                       attributes:@{NSForegroundColorAttributeName:self.refreshLabel.textColor,
                                                                                    NSParagraphStyleAttributeName:attributedStringParagraphStyle,
                                                                                    NSFontAttributeName:self.refreshLabel.font}];
    } @catch(NSException *e) {
        CSAlertLog(@"PTC %@", e.description); 
    }
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
    [self performSelector:@selector(prepairCollectionViewForReuse) withObject:nil afterDelay:0.5];
}

%new - (void)addRefreshLabelIfNecessary {
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    if (!self.refreshLabel) {

        CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"];
        NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"];

        self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, [[PTCProvider sharedProvider] floatForKey:@"kPTCActivationHeight"])];
        self.refreshLabel.textAlignment = NSTextAlignmentCenter;
        self.refreshLabel.font = [UIFont loadFontWithName:fontName size:fontSize];
        [self.collectionView addSubview:self.refreshLabel];
    }
    [self prepairRefreshLabelForReuse];
}

%new - (void)prepairRefreshLabelForReuse {
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;
    
    self.collectionView.alpha = 1;
    CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"];
    NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"];
    self.pullString = [[PTCProvider sharedProvider] objectForKey:@"kPTCPullString"];
    self.releaseString = [[PTCProvider sharedProvider] objectForKey:@"kPTCReleaseString"];
    self.refreshLabel.font = [UIFont loadFontWithName:fontName size:fontSize];
    self.refreshColor = [[PTCProvider sharedProvider] colorForKey:@"kPTCFontColor"];
    self.refreshLabel.text = self.pullString;
    [self hideRefreshLabel];
}

%new - (void)prepairCollectionViewForReuse {
    self.collectionView.alpha = 1;
}

%end

%ctor {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/NCLink10.dylib", RTLD_NOW);
}
