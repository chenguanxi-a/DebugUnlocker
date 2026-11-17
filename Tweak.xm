// DebugUnlocker/Tweak.xm
// 编译：GitHub Actions (macos-latest) -> make package
// 产出：DebugUnlocker.dylib -> 巨魔注入器注入 IPA -> 装包
// 触发：三指长按 1s / 右上角连点 5 次

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL gInjected = NO;

// ====== 完整键名库：UserDefaults 原生 + Unity PlayerPrefs 前缀 + 游戏存档索引 ======
static NSArray<NSString *> *const kUserDefaultsKeys = @[
    // 通用去广告/VIP 键（原生 UserDefaults）
    @"no_ads", @"remove_ads", @"ads_removed", @"purchased_noads", @"iap_noads",
    @"ad_remove", @"hide_ads", @"disable_ads", @"free_remove_ads",
    @"ads_disabled", @"noads", @"removeads", @"ad_free",
    @"is_vip", @"vip_level", @"vip", @"premium", @"pro_unlocked", @"unlock_all",
    @"full_version", @"pro_version", @"premium_unlocked", @"is_premium",
    @"subscription_active", @"sub_active", @"is_subscriber",
    @"all_unlocked", @"god_mode", @"unlimited_coins", @"unlimited_gems",
    @"unlimited_diamonds", @"infinite_coins", @"infinite_gems",
    // 游戏自定义键（从 plist 推导）
    @"persient.IAP.order", @"IsNeedShowFirstCharge", @"IsNeedShowSecondCharge",
    @"HasPurchasedNoAds", @"HasVip", @"IsPremiumUser", @"AdFreeVersion",
    @"RemoveAdsPurchased", @"NoAdsForever", @"VipForever"
];

// Unity PlayerPrefs 在 iOS 上的实际键名前缀
static NSArray<NSString *> *const kUnityPrefixes = @[
    @"unity.com.wxlh.dmlt.ios.",
    @"unity.WXLH.",
    @"unity.com.wxlh.dmlt.",
    @"unity.com.wxlh.",
    @"unity."
];

static inline void WriteAllKeys()
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    // 1️⃣ 原生键
    for (NSString *k in kUserDefaultsKeys) {
        [ud setInteger:1 forKey:k];
        [ud setBool:YES forKey:k];
        [ud setObject:@"true" forKey:k];
    }

    // 2️⃣ Unity PlayerPrefs 前缀键（Unity 在 iOS 上会把 PlayerPrefs 写到 UserDefaults，键名加前缀）
    for (NSString *prefix in kUnityPrefixes) {
        for (NSString *k in kUserDefaultsKeys) {
            NSString *fullKey = [prefix stringByAppendingString:k];
            [ud setInteger:1 forKey:fullKey];
            [ud setBool:YES forKey:fullKey];
            [ud setObject:@"true" forKey:fullKey];
        }
    }

    // 3️⃣ 清空/伪造 IAP 订单记录（防止校验）
    [ud setObject:@{@"orderId": @"debug_unlock", @"productId": @"no_ads"} forKey:@"persient.IAP.order"];
    for (NSString *prefix in kUnityPrefixes) {
        [ud setObject:@{@"orderId": @"debug_unlock", @"productId": @"no_ads"} forKey:[prefix stringByAppendingString:@"persient.IAP.order"]];
    }

    // 4️⃣ 触发服务端同步（游戏若有「恢复购买/刷新状态」接口，强制调一次）
    // 通过 NSNotificationCenter 广播常见通知名
    NSArray *notifNames = @[
        @"IAPPurchaseCompleted", @"PurchaseSuccessful", @"RestorePurchasesFinished",
        @"AdRemoved", @"VipStatusChanged", @"UserDataUpdated",
        @"com.unity.purchasing.purchaseSucceeded", @"SKPaymentTransactionStatePurchased"
    ];
    for (NSString *n in notifNames) {
        [[NSNotificationCenter defaultCenter] postNotificationName:n object:nil userInfo:@{@"productId": @"no_ads", @"status": @"purchased"}];
    }

    [ud synchronize];
    NSLog(@"[DebugUnlocker] ✅ Written %lu native keys + Unity prefixes + IAP order + notifications", (unsigned long)kUserDefaultsKeys.count);
}

// ====== Hook 入口 ======
__attribute__((constructor))
static void InstallHook()
{
    if (gInjected) return;
    gInjected = YES;

    Class targetCls = objc_getClass("UnityAppController");
    if (!targetCls) {
        unsigned int count = 0;
        Class *classes = objc_copyClassList(&count);
        for (unsigned int i = 0; i < count; ++i) {
            const char *name = class_getName(classes[i]);
            if (strstr(name, "AppController")) {
                targetCls = classes[i];
                NSLog(@"[DebugUnlocker] Found AppController: %s", name);
                break;
            }
        }
        free(classes);
    }
    if (!targetCls) { NSLog(@"[DebugUnlocker] ❌ AppController not found"); return; }

    SEL sel = @selector(application:didFinishLaunchingWithOptions:);
    Method orig = class_getInstanceMethod(targetCls, sel);
    if (!orig) return;

    class_addMethod(targetCls, @selector(xxx_didFinishLaunchingWithOptions:),
                    method_getImplementation(orig), method_getTypeEncoding(orig));
    method_exchangeImplementations(orig,
        class_getInstanceMethod(targetCls, @selector(xxx_didFinishLaunchingWithOptions:)));
}

- (BOOL)xxx_didFinishLaunchingWithOptions:(UIApplication *)app launchOptions:(NSDictionary *)opts
{
    BOOL ret = [self xxx_didFinishLaunchingWithOptions:app launchOptions:opts];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) return;

        // 三指长按
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(debugUnlockGesture:)];
        lpgr.numberOfTouchesRequired = 3;
        lpgr.minimumPressDuration = 1.0f;
        lpgr.allowableMovement = 50;
        [win addGestureRecognizer:lpgr];

        // 右上角隐形按钮五连击
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(win.bounds.size.width - 22, 22, 22, 22);
        btn.alpha = 0.01f;
        btn.tag = 0;
        [btn addTarget:self action:@selector(debugUnlockTap:) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];

        NSLog(@"[DebugUnlocker] 🎮 Ready: 3-finger long-press OR 5×tap top-right");
    });

    return ret;
}

- (void)debugUnlockGesture:(UIGestureRecognizer *)g { if (g.state == UIGestureRecognizerStateBegan) WriteAllKeys(); }

- (void)debugUnlockTap:(UIButton *)sender { sender.tag++; if (sender.tag >= 5) { WriteAllKeys(); sender.tag = 0; } }