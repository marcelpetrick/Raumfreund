// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Raumfreund';

  @override
  String get actionSettings => '设置';

  @override
  String get actionAbout => '关于 Raumfreund';

  @override
  String get actionShop => '星星商店';

  @override
  String get actionBack => '返回';

  @override
  String get statusIdle => '准备好了——开始测量吧';

  @override
  String get statusStarting => '正在开始测量…';

  @override
  String get statusStopping => '正在停止测量…';

  @override
  String get statusGreen => '一切都很好，很安静！';

  @override
  String get statusYellow => '请再小声一点';

  @override
  String get statusRed => '哎呀，太吵了！';

  @override
  String get statusSleeping => 'Mia 睡着了——测量已暂停';

  @override
  String get statusWaking => 'Mia 正在醒来…';

  @override
  String get sleepingHint => '应用在后台时，Raumfreund 不使用麦克风。你一回到应用，Mia 就会醒来并继续测量。';

  @override
  String get statusError => '无法测量';

  @override
  String get zoneGreen => '绿色——安静舒适';

  @override
  String get zoneYellow => '黄色——有点吵';

  @override
  String get zoneRed => '红色——太吵了';

  @override
  String alarmCountdown(int seconds) {
    return '$seconds 秒后提醒';
  }

  @override
  String alarmCountdownSemantics(int seconds) {
    return '$seconds 秒后提醒';
  }

  @override
  String get alarmImminent => '马上就要提醒了';

  @override
  String get alarmFired => '已提醒';

  @override
  String get alarmPlaying => '正在提醒——测量短暂暂停';

  @override
  String get measureStart => '开始测量';

  @override
  String get measureStop => '停止测量';

  @override
  String get measureBusy => '请稍候…';

  @override
  String gaugeValue(int value) {
    return '$value dB';
  }

  @override
  String get gaugeNoValue => '– dB';

  @override
  String get gaugeEstimated => '估计值';

  @override
  String get gaugeSemanticsLabel => '音量，估计值';

  @override
  String gaugeSemanticsValue(int value, String zone) {
    return '$value 分贝，$zone';
  }

  @override
  String get gaugeSemanticsNoValue => '没有测量值';

  @override
  String get timelineTitle => '最近 10 分钟';

  @override
  String get timelineMinus10 => '−10 分钟';

  @override
  String get timelineMinus5 => '−5 分钟';

  @override
  String get timelineNow => '现在';

  @override
  String timelineSummary(int max, int average, int greenPercent) {
    return '图表中的点是 10 秒平均值：最高 $max dB，平均 $average dB，$greenPercent% 的点在绿色区域';
  }

  @override
  String get timelineEmpty => '还没有测量值';

  @override
  String get alarmOutputFailed => '无法播放提示音。测量会继续进行。';

  @override
  String get signalThin => '测量受到干扰——测量值太少。手机可能在限制麦克风。';

  @override
  String get kittyIdle => 'Mia 舒舒服服地坐着等待';

  @override
  String get kittyHappy => 'Mia 很开心，正在呼噜呼噜';

  @override
  String get kittyUneasy => 'Mia 有点不安，她觉得太吵了';

  @override
  String get kittyScared => 'Mia 很害怕——实在太吵了';

  @override
  String get kittySleeping => 'Mia 在睡觉，等你回来';

  @override
  String get kittyAwaySign => '太吵了——Mia 躲起来了';

  @override
  String kittyWearing(String items) {
    return 'Mia 拥有：$items';
  }

  @override
  String get accessoryBow => '蝴蝶结';

  @override
  String get accessoryScarf => '围巾';

  @override
  String get accessoryHat => '派对帽';

  @override
  String get accessoryCushion => '坐垫';

  @override
  String get accessoryMouse => '玩具老鼠';

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 颗星星',
      zero: '还没有星星',
    );
    return '$_temp0';
  }

  @override
  String starsWithTotal(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新得 $count 颗星星',
      zero: '还没有新星星',
    );
    return '$_temp0 · 星星商店里共 $total 颗';
  }

  @override
  String get starsHint => '连续安静一分钟（绿灯）就得到一颗星星';

  @override
  String get starsHintQuickTest => '星星测试模式：连续安静 5 秒得到一颗星星';

  @override
  String starsProgress(int percent) {
    return '下一颗星星：已完成 $percent%';
  }

  @override
  String get starsJustEarned => '新星星！';

  @override
  String get errorPermissionDeniedTitle => '未获得麦克风权限';

  @override
  String get errorPermissionDeniedBody =>
      'Raumfreund 需要麦克风来估计音量。声音只会被短暂分析，绝不会保存或发送。';

  @override
  String get errorPermanentlyDeniedTitle => '麦克风已被永久禁止';

  @override
  String get errorPermanentlyDeniedBody =>
      '麦克风权限已被永久拒绝。请在 Android 应用设置的“权限”中允许使用麦克风。';

  @override
  String get errorMicrophoneBusyTitle => '麦克风被占用';

  @override
  String get errorMicrophoneBusyBody =>
      '另一个应用正在使用麦克风，例如通话或录音；或者 Android 快捷设置中的“麦克风使用权限”已关闭。请关闭那个应用或打开该开关，然后再试一次。';

  @override
  String get errorRecordingAbortedTitle => '测量已中断';

  @override
  String get errorRecordingAbortedBody => '测量意外中断了。重新开始就好。';

  @override
  String get errorUnavailableTitle => '没有可用的麦克风';

  @override
  String get errorUnavailableBody => '在这台设备上找不到可用的麦克风。';

  @override
  String get errorNoReadingsTitle => '没有测量值';

  @override
  String get errorNoReadingsBody =>
      '麦克风目前没有传来数值，或只有完全静音，所以测量已停止。可能是 Android 快捷设置中的“麦克风使用权限”已关闭，或者麦克风没有反应。请检查后重新开始测量。';

  @override
  String get errorOpenSettings => '打开设置';

  @override
  String get errorRetry => '重试';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsThresholdsHeading => '音量阈值';

  @override
  String get settingsYellowLabel => '黄灯起始值';

  @override
  String get settingsRedLabel => '红灯起始值';

  @override
  String settingsDbValue(int value) {
    return '$value dB';
  }

  @override
  String settingsDecrease(String name) {
    return '$name：降低 1 dB';
  }

  @override
  String settingsIncrease(String name) {
    return '$name：提高 1 dB';
  }

  @override
  String get settingsThresholdsHint => '黄色总是低于红色。如果把一个界限移过另一个，另一个会自动跟着移动。';

  @override
  String get settingsCalibrationHeading => '校准';

  @override
  String get settingsCalibrationLabel => '修正值';

  @override
  String settingsCalibrationValue(String value) {
    return '$value dB';
  }

  @override
  String get settingsCalibrationExplanation =>
      '不同手机的麦克风灵敏度不同。把一台声级计直接放在手机旁边，制造一个稳定的声音（例如白噪声或风扇声）。比较 Raumfreund 和声级计的读数，在这里把差值设为修正值，保存后再检查一次。显示的数值仍然只是估计值。';

  @override
  String get settingsAlarmHeading => '提醒';

  @override
  String get settingsAlarmDelayLabel => '提醒等待时间';

  @override
  String settingsSecondsValue(int value) {
    return '$value 秒';
  }

  @override
  String get settingsAlarmDelayDecrease => '提醒等待时间缩短 1 秒';

  @override
  String get settingsAlarmDelayIncrease => '提醒等待时间延长 1 秒';

  @override
  String settingsAlarmDelayRule(int seconds, int min, int max, int standard) {
    return '提醒规则：黄灯持续亮 $seconds 秒（或红灯持续亮 $seconds 秒）时会发出提醒。短暂安静一下不会中断计时。灯在黄、红之间切换或变回绿色时，计时重新开始；每次提醒后也会重新计时——如果一直很吵，会再次提醒。可设置 $min 到 $max 秒，默认 $standard 秒。';
  }

  @override
  String get settingsAlarmSound => '提示音';

  @override
  String get settingsAlarmSoundHint => '简短、友好的提示音';

  @override
  String get settingsVibration => '振动';

  @override
  String get settingsVibrationHint => '短暂振动（如果设备支持）';

  @override
  String get settingsStarTestHeading => '星星测试';

  @override
  String get settingsStarTestMode => '快速星星测试模式';

  @override
  String get settingsStarTestModeHint =>
      '在绿色区域保持 5 秒就能得到一颗星星，而不是 60 秒。这些星星也会进入星星商店。默认关闭；已收集的星星会保留。';

  @override
  String get settingsSave => '保存';

  @override
  String get settingsRetrySave => '重新保存';

  @override
  String get settingsSaveError => '保存失败。你的更改还在——请再试一次。';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsDefaults => '默认值';

  @override
  String get settingsDefaultsApplied => '已填入默认值——请保存以应用。';

  @override
  String get aboutTitle => '关于 Raumfreund';

  @override
  String get aboutTagline => '适合共享空间的友好音量红绿灯。';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutBuild => '构建';

  @override
  String aboutBuildValue(int buildNumber, String commit) {
    return '$buildNumber（提交 $commit）';
  }

  @override
  String get aboutAuthor => '作者';

  @override
  String get aboutEmail => '电子邮件';

  @override
  String get aboutProject => '项目';

  @override
  String get aboutLicense => '许可证';

  @override
  String get aboutLicenseValue => 'GNU GPL v3.0 (GPL-3.0-only)';

  @override
  String get aboutPrivacyHeading => '隐私';

  @override
  String get aboutPrivacyBody =>
      'Raumfreund 完全离线运行。麦克风信号只会在内存中短暂地换算成一个音量数字，然后立即丢弃——不会保存或发送任何声音。设备上只保存设置和星星。没有账户，没有广告，没有跟踪。';

  @override
  String get aboutMeasurementHeading => '关于测量';

  @override
  String get aboutMeasurementBody =>
      '显示的数值是根据手机麦克风估算的。Raumfreund 不是经过检定的声级计，不适用于职业安全或专业鉴定。';

  @override
  String get aboutLicensesButton => '开源许可证';

  @override
  String get shopTitle => '星星商店';

  @override
  String shopBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你有 $count 颗星星',
      zero: '你还没有星星',
    );
    return '$_temp0';
  }

  @override
  String get shopLoading => '正在加载星星…';

  @override
  String get shopLoadFailed => '暂时无法加载星星。恢复后才能购买和给 Mia 物品。';

  @override
  String get shopSaveFailed => '保存没有成功。你的星星会保留；下次打开应用或星星商店时，以及下次更改时会再试一次。';

  @override
  String get shopDismiss => '隐藏';

  @override
  String get shopBuy => '购买';

  @override
  String get shopEquip => '给 Mia';

  @override
  String get shopUnequip => '收回';

  @override
  String shopMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还差 $count 颗星星',
    );
    return '$_temp0';
  }

  @override
  String get shopWorn => 'Mia 正在用';

  @override
  String get shopOwned => '已购买';

  @override
  String shopPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 颗星星',
    );
    return '$_temp0';
  }

  @override
  String shopConfirmTitle(String item, String price) {
    return '用 $price 购买“$item”？';
  }

  @override
  String get shopConfirmBuy => '购买';

  @override
  String get shopConfirmCancel => '取消';

  @override
  String get settingsResetHeading => '教师专用';

  @override
  String get settingsResetBody =>
      '删除所有星星和在星星商店里买过的所有物品。此操作立即生效，不属于“保存”或“取消”——点“取消”也无法撤销。';

  @override
  String get settingsResetButton => '重置星星';

  @override
  String get settingsResetConfirmTitle => '删除所有星星和已购买的物品？';

  @override
  String get settingsResetConfirmBody => '此操作无法撤销。';

  @override
  String get settingsResetConfirm => '删除';

  @override
  String get settingsResetDone => '所有星星和已购买的物品都已删除。';

  @override
  String get settingsResetNotReady => '星星还在加载中。请稍后再试。';

  @override
  String get settingsResetSaveFailed =>
      '星星已重置，但保存没有成功。稍后会再试一次——在此之前重启应用，旧的星星可能会回来。';

  @override
  String get settingsLanguageHeading => '语言';

  @override
  String get settingsLanguageHint => '语言会立即切换并马上保存，与“保存”和“取消”无关。';

  @override
  String get settingsLanguageSaveFailed => '语言已切换，但无法保存。下次启动应用时会使用之前的语言。';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageChinese => '中文（简体）';
}
