/**
 * @Author: Dana Buehre <creaturesurvive>
 * @Date:   19-09-2017 12:30:52
 * @Email:  dbuehre@me.com
 * @Filename: PTCLabel.h
 * @Last modified by:   creaturesurvive
 * @Last modified time: 24-09-2017 1:34:37
 * @Copyright: Copyright © 2014-2017 CreatureSurvive
 */


#import "PTCProvider.h"
#import <UIFont.h>
#import "AudioToolbox/AudioToolbox.h"


@interface PTCLabel : UILabel
@property (nonatomic, strong) NSString *refreshString;
@property (nonatomic, strong) NSString *pullString;
@property (nonatomic, strong) NSParagraphStyle *paragraphStyle;
@property (nonatomic, strong) UIColor *refreshColor;
@property (nonatomic, assign) CGFloat activationHeight;
@property (nonatomic, assign) BOOL isRefreshing;

- (void)refreshForOffset:(CGFloat)offset;
- (void)refreshForDragEnded;
- (void)hide;
- (void)show;
- (void)updateLabel;

@end
