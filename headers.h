/**
 * @Author: Dana Buehre <creaturesurvive>
 * @Date:   24-09-2017 12:26:38
 * @Email:  dbuehre@me.com
 * @Filename: headers.h
 * @Last modified by:   creaturesurvive
 * @Last modified time: 24-09-2017 1:59:27
 * @Copyright: Copyright © 2014-2017 CreatureSurvive
 */


#import "PTCProvider.h"
#import <UIKit/UIKit.h>
#import <UIFont.h>
#import "AudioToolbox/AudioToolbox.h"

@protocol NCNotificationSectionList
@required
- (void)clearAllSections;
@end

@interface NCNotificationListViewController : UICollectionViewController
@property(nonatomic, retain) UILabel *refreshLabel;
@property(nonatomic, retain) UIColor *refreshColor;
@property(nonatomic, retain) NSString *pullString;
@property(nonatomic, retain) NSString *releaseString;
@property(nonatomic, assign) BOOL isRefreshing;
@property(nonatomic, assign) BOOL isClearing;
- (void)refreshForCurrentOffset:(CGFloat)offset;
- (void)updateRefreshLabel;
- (void)hideRefreshLabel;
- (void)clearNotifications;
- (void)prepairForRefresh;
- (void)addRefreshLabelIfNecessary;
- (void)prepairRefreshLabelForReuse;
- (void)prepairCollectionViewForReuse;
@end

@interface NCNotificationPriorityListViewController : NCNotificationListViewController
@end

@interface NCNotificationSectionListViewController : NCNotificationListViewController {
    id<NCNotificationSectionList> _sectionList;
}
- (void)sectionHeaderViewDidReceiveClearAllAction:(id)arg1;
@end

@interface SBDashBoardViewControllerBase : UIViewController
@end

@interface SBDashBoardNotificationListViewController : SBDashBoardViewControllerBase
- (void)_clearContentIncludingPersistent:(BOOL)clearPersistant;
@end
