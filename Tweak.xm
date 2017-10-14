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

//
// ─── NCNOTIFICATIONLISTVIEWCONTROLLER ───────────────────────────────────────────
//

%hook NCNotificationListViewController
// ─── PROPERTIES ─────────────────────────────────────────────────────────────────
%property(nonatomic, retain) UILabel *refreshLabel;
%property(nonatomic, retain) UIColor *refreshColor;
%property(nonatomic, retain) NSString *pullString;
%property(nonatomic, retain) NSString *releaseString;
%property(nonatomic, assign) BOOL isRefreshing;
%property(nonatomic, assign) BOOL isClearing;


// ────────────────────────────────────────────────────────────────────────────────
// ideally we will initialize our label here, however NCLink10 used AutoHook for
// all its hooking and that prevents these from being invoked. i attempted to fix
// this by hooking -(void)hook_viewDidLoad or -(void)original_viewDidLoad but that
// did not work. if anyone knows a fix, let me know.
// ────────────────────────────────────────────────────────────────────────────────

- (void)viewDidLoad {
    %orig;
    [self addRefreshLabelIfNecessary];
}

// ────────────────────────────────────────────────────────────────────────────────
// if we started scrolling we should configure our label according to the scroll
// distance
// ────────────────────────────────────────────────────────────────────────────────
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    [self refreshForCurrentOffset:scrollView.contentOffset.y];
}

// ────────────────────────────────────────────────────────────────────────────────
// if our drag ended while we were in the refreshing state, we should invoke our
// haptic feedback, hide the label and prepair to clear notifications
// ────────────────────────────────────────────────────────────────────────────────
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate  {
    %orig;
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    if (self.isRefreshing) {
        AudioServicesPlaySystemSound(1520);
        self.refreshLabel.textColor = [UIColor clearColor];
        self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);

        self.isClearing = YES;
    }
}

%new - (void)refreshForCurrentOffset: (CGFloat)offset {
    // ────────────────────────────────────────────────────────────────────────────────
    // a hackish solution to NCLink10 preventing the label from appearing
    // ────────────────────────────────────────────────────────────────────────────────
    if (!self.refreshLabel) {
        [self addRefreshLabelIfNecessary];
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // calculate the pull and release percentages based on our scroll offset
    // ────────────────────────────────────────────────────────────────────────────────
    CGFloat height = [[PTCProvider sharedProvider] floatForKey:@"kPTCActivationHeight"];
    CGFloat clearHeight = [[PTCProvider sharedProvider] floatForKey:@"kPTCClearHeight"];
    CGFloat alpha = -offset/height;
    CGFloat bravo = -offset/clearHeight;

    // ────────────────────────────────────────────────────────────────────────────────
    // if the scroll percentage is less than 1/5 our pull height then we can go ahead
    // and hide our label its to small to see anyway, we also return control to sender.
    // if we are already in the clearing state, we should also clear the notifications
    // ────────────────────────────────────────────────────────────────────────────────
    if (alpha <= 0.2) {
        [self hideRefreshLabel];
        if (self.isClearing) {
            self.isClearing = NO;
            [self clearNotifications];
        }
        return;
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // at this point there is no reason for our label to be hidden
    // ────────────────────────────────────────────────────────────────────────────────
    if (self.refreshLabel.hidden) {
        self.refreshLabel.hidden = NO;
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // if our lebel is clearing (drag is past our puul height) then we need to start
    // lowering the alpha of the notification view until it pops, just some asthetics
    // ────────────────────────────────────────────────────────────────────────────────
    if (self.isClearing) {
        self.collectionView.alpha = alpha-0.2;
    }

    // ────────────────────────────────────────────────────────────────────────────────
    // we've made it this far now time to configure our labels transparancy, scale, &
    // position based on our percentages calculated above
    // ───────────────────────────────────────────���────────────────────────────────────
    self.refreshLabel.textColor = [self.refreshColor colorWithAlphaComponent:alpha];
    self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, alpha < 0.8 ? alpha : 0.8, alpha < 0.8 ? alpha : 0.8);
    self.refreshLabel.frame = CGRectMake(0, offset, self.collectionView.frame.size.width, height);

    // ────────────────────────────────────────────────────────────────────────────────
    // if weve scroled past our clear height, we should clear our notifications
    // ────────────────────────────────────────────────────────────────────────────────
    if (bravo >= 1) {
        [self clearNotifications];

        // ────────────────────────────────────────────────────────────────────────────────
        // if we've scrolled past 4/5 of our pull height, and we're not already in the
        // release state pop our release string with a little spring animation. we also
        // invoke haptic feedback for the pop and start lowering the alpha for the
        // notification view.
        // ────────────────────────────────────────────────────────────────────────────────
    } else if (alpha >= 0.8f) {
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

        // ────────────────────────────────────────────────────────────────────────────────
        // if our scroll percentage is less than 4/5 our release pull threshold, and it's
        // in the refresh state, we should change it back to the pull state.
        // ────────────────────────────────────────────────────────────────────────────────
    } else {
        if (self.isRefreshing) {
            self.isRefreshing = NO;
            AudioServicesPlaySystemSound(1519);
            self.refreshLabel.text = self.pullString;
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────────
// sets our refresh label with the appropriate string for its current scroll
// percentage.
// ────────────────────────────────────────────────────────────────────────────────
%new -(void)updateRefreshLabel {
    NSMutableParagraphStyle *attributedStringParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    attributedStringParagraphStyle.alignment = NSTextAlignmentCenter;

    // ────────────────────────────────────────────────────────────────────────────────
    // due to tweaks such as NCLink10 breaking thing and preventing properties from
    // being set, we should catch the exception and display it rather than just crashing
    // ────────────────────────────────────────────────────────────────────────────────
    @try {
        self.refreshLabel.attributedText = [[NSAttributedString alloc] initWithString:self.refreshLabel.text
                                                                           attributes:@{NSForegroundColorAttributeName:self.refreshLabel.textColor,
                                                                                        NSParagraphStyleAttributeName:attributedStringParagraphStyle,
                                                                                        NSFontAttributeName:self.refreshLabel.font}];
    } @catch (NSException *error) {
        CSAlertLog(@"PTC ERROR, failed to set attributedText %@", error.description);
    }
}

// ────────────────────────────────────────────────────────────────────────────────
// hides the refresh label
// ────────────────────────────────────────────────────────────────────────────────
%new - (void)hideRefreshLabel {
    self.refreshLabel.textColor = [UIColor clearColor];
    self.refreshLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
    self.refreshLabel.hidden = YES;
}
// ────────────────────────────────────────────────────────────────────────────────
// clears notifications in the appropriate manor according to what class we are in.
// ────────────────────────────────────────────────────────────────────────────────
%new - (void)clearNotifications {
    if ([self class] == NSClassFromString(@"NCNotificationSectionListViewController")) {
        [(NCNotificationSectionListViewController *) self sectionHeaderViewDidReceiveClearAllAction:nil];
    } else if ([self class] == NSClassFromString(@"NCNotificationPriorityListViewController")) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kPTCClear" object:nil userInfo:nil];
    }
    // ────────────────────────────────────────────────────────────────────────────────
    // we should prepair our label to be reused now that the notification view has been
    // dismissed.
    // ────────────────────────────────────────────────────────────────────────────────
    [self prepairForRefresh];
}

// ────────────────────────────────────────────────────────────────────────────────
// resets values back to default so our label is ready next time we need it
// ───────────────────────────────────────────────────────────────────────────���────
%new - (void)prepairForRefresh {
    self.isClearing = NO;
    self.isRefreshing = NO;
    [self performSelector:@selector(prepairCollectionViewForReuse) withObject:nil afterDelay:0.5];
}

// ────────────────────────────────────────────────────────────────────────────────
// adds the refresh label to our notification scroll view if it doesnt already
// exitst and PTC is enabled
// ────────────────────────────────────────────────────────────────────────────────
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
    // ────────────────────────────────────────────────────────────────────────────────
    // we need to make sure all properties are properly set after adding the label
    // ────────────────────────────────────────────────────────────────────────────────
    [self prepairRefreshLabelForReuse];
}

// ────────────────────────────────────────────────────────────────────────────────
// ensures all properties are setup befor we try and access any of them. this also
// ensures that the notification view will not be transparent when appearing.
// ────────────────────────────────────────────────────────────────────────────────
%new - (void)prepairRefreshLabelForReuse {
    if (![[PTCProvider sharedProvider] boolForKey:@"kPTCEnabled"]) return;

    CGFloat fontSize = [[PTCProvider sharedProvider] floatForKey:@"kPTCFontSize"];
    NSString *fontName = [[PTCProvider sharedProvider] stringForKey:@"kPTCFontName"];
    self.pullString = [[PTCProvider sharedProvider] objectForKey:@"kPTCPullString"];
    self.releaseString = [[PTCProvider sharedProvider] objectForKey:@"kPTCReleaseString"];
    self.refreshLabel.font = [UIFont loadFontWithName:fontName size:fontSize];
    self.refreshColor = [[PTCProvider sharedProvider] colorForKey:@"kPTCFontColor"];
    self.refreshLabel.text = self.pullString;

    // ────────────────────────────────────────────────────────────────────────────────
    // ensure that our notification view is not transparent when it comes into view
    // ────────────────────────────────────────────────────────────────────────────────
    [self prepairCollectionViewForReuse];

    // ────────────────────────────────────────────────────────────────────────────────
    // we only just added the label and no scroll should be detected yet, we can go
    // ahead and hide our label until we need it
    // ────────────────────────────────────────────────────────────────────────────────
    [self hideRefreshLabel];
}

// ────────────────────────────────────────────────────────────────────────────────
// resets the alpha for our notification view
// ────────────────────────────────────────────────────────────────────────────────
%new - (void)prepairCollectionViewForReuse {
    self.collectionView.alpha = 1;
}

%end

//
// ─── SBDASHBOARDNOTIFICATIONLISTVIEWCONTROLLER ──────────────────────────────────
//

%hook SBDashBoardNotificationListViewController

// ────────────────────────────────────────────────────────────────────────────────
// register for CLEAR notifications when we load our view, this will be resopnsible
// for clearing notifications on the lockscreen when notified
// ────────────────────────────────────────────────────────────────────────────────
- (void)viewDidLoad {
    %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear) name:@"kPTCClear" object:nil];
}

// ────────────────────────────────────────────────────────────────────────────────
// we never want to leave a stray notification observer, remove it durring dealloc
// ────────────────────────────────────────────────────────────────────────────────
- (void)dealloc {
    %orig;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// ────────────────────────────────────────────────────────────────────────────────
// clears all lockscreen notifications
// ────────────────────────────────────────────────────────────────────────────────
%new - (void)clear {
    [self _clearContentIncludingPersistent:YES];
}

%end
