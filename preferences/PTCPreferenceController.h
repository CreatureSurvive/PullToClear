#import <libCSPreferences.h>
// ────────────────────────────────────────────────────────────────────────────────
// all preference bundles using libCSPreferences should have this and a .m file to
// give the bunle an executable, there is no need to do anything further with this
// CSPreferences will handle all that for you
// ────────────────────────────────────────────────────────────────────────────────
@interface PTCPreferenceController : CSPListController
@end
