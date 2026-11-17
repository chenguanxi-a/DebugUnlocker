# DebugUnlocker for 无限轮回 (v1.14.1, bundle: com.wxlh.dmlt.ios)

## 功能
- 一键写入所有去广告/VIP/内购相关 UserDefaults 键（原生 + Unity PlayerPrefs 前缀）
- 伪造 IAP 订单记录
- 广播常见购买成功/恢复购买通知，触发游戏内部刷新逻辑
- 触发方式：三指长按 1 秒 / 右上角连点 5 次

## 编译（GitHub Actions，免 macOS）
1. Fork 本仓库 / 或新建公开仓库推送代码
2. 进 **Actions** 标签 → **Build DebugUnlocker.dylib** → **Run workflow**
3. 等 1~2 分钟，Workflow 变绿 → 点进去 → 底部 **Artifacts** → `DebugUnlocker-dylib.zip` 下载
4. 解压得到 `DebugUnlocker.dylib`

## 注入 IPA（手机端，巨魔注入器）
1. 用 **TrollInstallerX / TrollTools / 巨魔商店自带注入 / TrollFools**
2. 选「注入动态库」→ 原始 IPA：`无限轮回-1.14.1.ipa` → 动态库：`DebugUnlocker.dylib` → 「开始注入」
3. 生成 `无限轮回_Injected.ipa`

## 安装 & 测试
1. 巨魔商店 / TrollInstallerX 安装注入后的 IPA
2. 打开游戏 → **三指长按 1 秒** 或 **右上角连点 5 下**
3. 控制台/悬浮窗显示 `[DebugUnlocker] ✅ Written ...` → 广告消失、VIP 解锁

## 本地编译（可选）
```bash
git clone https://github.com/theos/theos.git $THEOS
cd DebugUnlocker
make package   # 生成 .deb + .dylib
```

## 关键键名来源
- 通用键：`no_ads` `remove_ads` `vip_level` `premium` `pro_unlocked` `subscription_active` 等 30+ 个
- Unity PlayerPrefs 前缀：`unity.com.wxlh.dmlt.ios.` `unity.WXLH.` `unity.com.wxlh.dmlt.` `unity.com.wxlh.` `unity.`
- 游戏特有键：`persient.IAP.order` `IsNeedShowFirstCharge` `IsNeedShowSecondCharge` `HasPurchasedNoAds` 等
- 广播通知：`IAPPurchaseCompleted` `PurchaseSuccessful` `RestorePurchasesFinished` `AdRemoved` `VipStatusChanged` `com.unity.purchasing.purchaseSucceeded` 等