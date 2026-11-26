/// English + Myanmar UI strings. Catalogue titles are never translated; only
/// application chrome is.
class AppStrings {
  const AppStrings(this.language);

  final String language;

  bool get my => language == 'my';

  String _t(String en, String mm) => my ? mm : en;

  static const _myDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];

  /// Formats a count with thousands separators, using Myanmar numerals when
  /// the UI language is Myanmar.
  String n(num value) {
    final s = value.round().toString();
    final neg = s.startsWith('-');
    final digits = neg ? s.substring(1) : s;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final out = '${neg ? '-' : ''}$buf';
    if (!my) return out;
    return out.replaceAllMapped(
      RegExp(r'\d'),
      (m) => _myDigits[int.parse(m.group(0)!)],
    );
  }

  // Brand & navigation
  String get appName => _t('Dhamma Echo', 'ဓမ္မပဲ့တင်သံ');
  String get tabHome => _t('Home', 'ပင်မ');
  String get tabBrowse => _t('Browse', 'စူးစမ်း');
  String get tabSearch => _t('Search', 'ရှာဖွေ');
  String get tabLibrary => _t('Library', 'စာကြည့်တိုက်');

  // Home
  String get continueListening => _t('CONTINUE LISTENING', 'ဆက်လက်နားဆင်ရန်');
  String get resumeBadge => _t('RESUME', 'ပြန်ဖွင့်မည်');
  String get nothingToResume =>
      _t('Nothing to resume yet', 'ဆက်လက်ဖွင့်ရန် မရှိသေးပါ');
  String get nothingToResumeBody => _t(
    'Start any talk and it will wait for you here.',
    'တရားတော်တစ်ခုခု စတင်နားဆင်ပါက ဤနေရာတွင် ပြန်လည်တွေ့ရပါမည်။',
  );
  String get exploreArchive =>
      _t('EXPLORE THE ARCHIVE', 'တရားတော်အမျိုးအစားများ');
  String get audioTalks => _t('Audio Talks', 'အသံတရားတော်');
  String get videoTalks => _t('Video Talks', 'ဗီဒီယိုတရား');
  String get ebooks => _t('eBooks', 'ဓမ္မစာအုပ်');
  String get abhidhamma => _t('Abhidhamma', 'အဘိဓမ္မာ');
  String audioCountLine(int c) => _t('${n(c)} MP3/WMA', '${n(c)} ခု');
  String videoCountLine(int c) => _t('${n(c)} MP4/WMV', '${n(c)} ခု');
  String ebookCountLine(int c) => _t('${n(c)} PDF/DOC', '${n(c)} အုပ်');
  String abhidhammaCountLine(int c) => _t('${n(c)} Teachings', '${n(c)} ခု');
  String get featuredTeachers =>
      _t('FEATURED TEACHERS', 'အထူးတင်ဆက် ဆရာတော်များ');
  String get viewAll => _t('View all', 'အားလုံးကြည့်မည်');
  String get featuredCollections =>
      _t('FEATURED COLLECTIONS', 'အထူးစုစည်းမှုများ');
  String itemsCount(int c) => _t('${n(c)} items', '${n(c)} ခု');

  // Browse
  String get browse => _t('Browse', 'စူးစမ်းရန်');
  String get kindAudio => _t('Audio', 'အသံ');
  String get kindVideo => _t('Video', 'ဗီဒီယို');
  String get kindEbooks => _t('eBooks', 'စာအုပ်');
  String get kindTeachers => _t('Teachers', 'ဆရာတော်များ');
  String get filterAll => _t('All', 'အားလုံး');
  String get filterMyanmar => _t('Myanmar', 'မြန်မာ');
  String get filterEnglish => _t('English', 'အင်္ဂလိပ်');
  String get filterMp3 => _t('MP3 only', 'MP3 သာ');
  String get filterMp4 => _t('MP4 only', 'MP4 သာ');
  String get filterPdf => _t('PDF', 'PDF');
  String itemsTotal(int c) => _t('${n(c)} items', '${n(c)} ခု');
  String ebooksTotal(int c) => _t('${n(c)} eBooks', '${n(c)} အုပ်');
  String get teachersAndSources =>
      _t('Teachers & Sources', 'ဆရာတော်များနှင့် ရင်းမြစ်များ');
  String teachersTotal(int c) => _t('${n(c)} teachers', '${n(c)} ပါး');
  String get featuredTop =>
      _t('FEATURED TEACHERS  ·  TOP OF LIST', 'အထူးတင်ဆက် ဆရာတော်များ');
  String get featuredBadge => _t('Featured', 'အထူး');
  String teachingsCollections(int t, int c) => _t(
    '${n(t)} teachings · ${n(c)} collections',
    'တရားတော် ${n(t)} ခု · စုစည်းမှု ${n(c)} ခု',
  );
  String get loadMore => _t('Load more', 'ထပ်မံတင်ရန်');
  String get nothingFound => _t('Nothing found', 'မတွေ့ပါ');
  String get nothingFoundBody => _t(
    'Try a different filter or search term.',
    'အခြားစစ်ထုတ်မှု သို့မဟုတ် စကားလုံးဖြင့် ရှာကြည့်ပါ။',
  );

  // Search
  String get search => _t('Search', 'ရှာဖွေရန်');
  String get searchHint =>
      _t('Search talks, teachers, books', 'တရားတော်၊ ဆရာတော်၊ စာအုပ် ရှာပါ');
  String resultsInCatalogue(int c) =>
      _t('${n(c)} results in local catalogue', 'စာရင်းတွင် ရလဒ် ${n(c)} ခု');
  String get searchPrompt => _t(
    'Search all 47,960 entries offline.',
    'မှတ်တမ်း ၄၇,၉၆၀ ခုလုံးကို အင်တာနက်မလိုဘဲ ရှာဖွေနိုင်ပါသည်။',
  );

  // Teacher & collection detail
  String get teachers => _t('Teachers', 'ဆရာတော်များ');
  String get featuredTeacher => _t('FEATURED TEACHER', 'အထူးတင်ဆက် ဆရာတော်');
  String get tabCollections => _t('Collections', 'စုစည်းမှုများ');
  String tracksOrdered(int c) =>
      _t('${n(c)} tracks · Ordered series', 'တရားတော် ${n(c)} ပုဒ် · စဉ်လိုက်');
  String get audioBadge => _t('AUDIO', 'အသံ');
  String get videoBadge => _t('VIDEO', 'ဗီဒီယို');
  String get ebookBadge => _t('EBOOK', 'စာအုပ်');
  String get collection => _t('Collection', 'စုစည်းမှု');
  String get audioSeries => _t('AUDIO SERIES', 'အသံစုစည်းမှု');
  String get videoSeries => _t('VIDEO SERIES', 'ဗီဒီယိုစုစည်းမှု');
  String get ebookSeries => _t('EBOOK SERIES', 'စာအုပ်စုစည်းမှု');
  String tracksCount(int c) => _t('${n(c)} tracks', 'ပုဒ် ${n(c)}');
  String get playAll => _t('Play All', 'အားလုံးဖွင့်မည်');
  String get downloadSeries => _t('Download Series', 'စုစည်းမှု ဒေါင်းလုဒ်');
  String trackOrder(int from, int to, int total) => _t(
    'TRACK ORDER  ·  ${n(from)} – ${n(to)} OF ${n(total)}',
    'စဉ်အတိုင်း  ·  ${n(total)} ပုဒ်တွင် ${n(from)} – ${n(to)}',
  );
  String get downloadSeriesTitle =>
      _t('Download whole series?', 'စုစည်းမှုတစ်ခုလုံး ဒေါင်းလုဒ်လုပ်မလား?');
  String downloadSeriesBody(int count) => _t(
    '$count talks will be saved to this device. This may use significant storage and data.',
    'တရားတော် $count ပုဒ်ကို ဤစက်တွင် သိမ်းဆည်းမည်။ သိုလှောင်မှုနှင့် ဒေတာ များစွာ အသုံးပြုနိုင်ပါသည်။',
  );
  String get cancel => _t('Cancel', 'မလုပ်တော့ပါ');
  String get download => _t('Download', 'ဒေါင်းလုဒ်');
  String get confirmDownload => _t('Download all', 'အားလုံးဒေါင်းလုဒ်');

  // Player
  String get nowPlayingMp3 => _t('NOW PLAYING · MP3', 'ယခုဖွင့်နေသည် · MP3');
  String get offlineReady => _t('OFFLINE READY', 'အော့ဖ်လိုင်း အသင့်');
  String get speed => _t('Speed', 'အမြန်နှုန်း');
  String sleepLabel(String? v) =>
      v == null ? _t('Sleep', 'အိပ်ချိန်') : _t('Sleep $v', 'အိပ်ချိန် $v');
  String get queue => _t('Queue', 'စာရင်း');
  String get saved => _t('Saved', 'သိမ်းထား');
  String get offline => _t('Offline', 'အော့ဖ်လိုင်း');
  String get nowPlaying => _t('Now Playing', 'ယခုဖွင့်နေသည်');
  String get queueAndSleep =>
      _t('Queue & Sleep Timer', 'စာရင်းနှင့် အိပ်ချိန်');
  String get sleepTimerHeader => _t(
    'SLEEP TIMER  ·  STOPS PLAYBACK AUTOMATICALLY',
    'အိပ်ချိန်သတ်မှတ်ခြင်း  ·  အလိုအလျောက် ရပ်မည်',
  );
  String get timerOff => _t('Off', 'ပိတ်');
  String get timerEnd => _t('End', 'ဆုံးလျှင်');
  String timerRemaining(int minutes) =>
      _t('$minutes min remaining on timer', 'အိပ်ချိန်ကျန်ရှိ $minutes မိနစ်');
  String get timerEndOfTrack =>
      _t('Stops at the end of this talk', 'ဤတရားတော်ဆုံးလျှင် ရပ်မည်');
  String upNext(int c) =>
      _t('UP NEXT  ·  $c TALKS IN QUEUE', 'ဆက်လက်ဖွင့်မည်  ·  စာရင်း $c ပုဒ်');
  String get clear => _t('Clear', 'ရှင်းမည်');
  String get queueEmpty => _t('Queue is empty', 'စာရင်းတွင် မရှိပါ');
  String get playbackError => _t(
    'This file could not be played. Check your connection or try again.',
    'ဤဖိုင်ကို မဖွင့်နိုင်ပါ။ အင်တာနက်ကို စစ်ဆေးပြီး ထပ်မံကြိုးစားပါ။',
  );

  // Video
  String get video => _t('Video', 'ဗီဒီယို');
  String get videoMp4 => _t('VIDEO · MP4', 'ဗီဒီယို · MP4');
  String get languageMyanmarBadge => _t('MYANMAR', 'မြန်မာ');
  String get languageEnglishBadge => _t('ENGLISH', 'အင်္ဂလိပ်');
  String get downloadMp4 => _t('Download MP4', 'MP4 ဒေါင်းလုဒ်');
  String get save => _t('Save', 'သိမ်းမည်');
  String get unsave => _t('Saved', 'သိမ်းထားသည်');
  String get source => _t('Source', 'ရင်းမြစ်');
  String get moreVideos =>
      _t('MORE VIDEOS FROM THIS TEACHER', 'ဤဆရာတော်၏ အခြားဗီဒီယိုများ');
  String get fullscreen => _t('Fullscreen', 'မျက်နှာပြင်အပြည့်');

  // Reader
  String pageOf(int page, int total) =>
      _t('Page $page of $total', 'စာမျက်နှာ ${n(page)} / ${n(total)}');
  String get tintLight => _t('Light', 'အလင်း');
  String get tintSepia => _t('Sepia', 'ဆီးပီးယား');
  String get tintDark => _t('Dark', 'အမှောင်');
  String get readerError =>
      _t('This book could not be opened.', 'ဤစာအုပ်ကို မဖွင့်နိုင်ပါ။');

  // Library
  String get myLibrary => _t('My Library', 'ကျွန်ုပ်၏ စာကြည့်တိုက်');
  String savedTab(int c) => _t('Saved (${n(c)})', 'သိမ်းထား (${n(c)})');
  String get historyTab => _t('History', 'မှတ်တမ်း');
  String downloadsTab(int c) =>
      _t('Downloads (${n(c)})', 'ဒေါင်းလုဒ် (${n(c)})');
  String get offlineStorage => _t(
    'OFFLINE STORAGE · APP-PRIVATE',
    'အော့ဖ်လိုင်းသိုလှောင်မှု · ဤအက်ပ်သီးသန့်',
  );
  String storageUsed(String size) => _t('$size used', '$size အသုံးပြုထား');
  String storageBreakdown(int audio, int video, int pdf, bool wifi) => _t(
    '$audio MP3 talks · $video MP4 · $pdf PDF · Wi-Fi only ${wifi ? 'ON' : 'OFF'}',
    'MP3 $audio · MP4 $video · PDF $pdf · Wi-Fi သာ ${wifi ? 'ဖွင့်' : 'ပိတ်'}',
  );
  String downloadingPct(int pct) =>
      _t('Downloading… $pct%', 'ဒေါင်းလုဒ်လုပ်နေသည်… $pct%');
  String get readyOffline => _t('READY OFFLINE', 'အော့ဖ်လိုင်း အသင့်');
  String get retry => _t('Retry', 'ထပ်ကြိုးစား');
  String get failed => _t('Failed', 'မအောင်မြင်ပါ');
  String get waitingWifi => _t('Waiting for Wi-Fi', 'Wi-Fi စောင့်နေသည်');
  String get nothingSaved => _t('Nothing saved yet', 'သိမ်းထားသည် မရှိသေးပါ');
  String get nothingSavedBody => _t(
    'Bookmark any audio talk, video, or eBook to keep it here locally on your device.',
    'အသံ၊ ဗီဒီယို သို့မဟုတ် စာအုပ်ကို သိမ်းထားပါက ဤစက်ထဲတွင်သာ ဤနေရာ၌ ထားရှိပါမည်။',
  );
  String get browseCatalogue =>
      _t('Browse the Catalogue', 'စာရင်းကို ကြည့်မည်');
  String get noHistory =>
      _t('No listening history yet', 'နားဆင်မှတ်တမ်း မရှိသေးပါ');
  String get noDownloads => _t('No downloads yet', 'ဒေါင်းလုဒ် မရှိသေးပါ');
  String get noDownloadsBody => _t(
    'Downloaded talks, videos and books play without a connection.',
    'ဒေါင်းလုဒ်လုပ်ထားသော တရားတော်၊ ဗီဒီယိုနှင့် စာအုပ်များကို အင်တာနက်မလိုဘဲ ဖွင့်နိုင်သည်။',
  );
  String get youAreOffline => _t('You are offline', 'အင်တာနက် မရှိပါ');
  String get offlineBody => _t(
    'Browse all 47,960 catalogue entries anytime. Play downloaded talks or reconnect to stream.',
    'စာရင်း ၄၇,၉၆၀ ခုလုံးကို အချိန်မရွေး ကြည့်နိုင်ပါသည်။ ဒေါင်းလုဒ်လုပ်ထားသည်များကို ဖွင့်ပါ သို့မဟုတ် အင်တာနက်ပြန်ချိတ်ပါ။',
  );
  String get clearDownloadsTitle =>
      _t('Clear all downloads?', 'ဒေါင်းလုဒ်အားလုံး ရှင်းမလား?');
  String get clearDownloadsBody => _t(
    'Downloaded files will be removed from this device.',
    'ဒေါင်းလုဒ်ဖိုင်များကို ဤစက်မှ ဖယ်ရှားမည်။',
  );
  String get remove => _t('Remove', 'ဖယ်ရှား');

  // Settings
  String get settings => _t('Settings', 'ဆက်တင်');
  String get back => _t('Back', 'နောက်သို့');
  String get languageAndAppearance =>
      _t('LANGUAGE & APPEARANCE', 'ဘာသာစကားနှင့် ပုံစံ');
  String get appLanguage => _t('App Language', 'အက်ပ်ဘာသာစကား');
  String get theme => _t('Theme', 'အသွင်အပြင်');
  String get themeSystem => _t('System', 'စနစ်အတိုင်း');
  String get themeLight => _t('Light', 'အလင်း');
  String get themeDark => _t('Dark', 'အမှောင်');
  String get playbackAndOffline =>
      _t('PLAYBACK & OFFLINE', 'ဖွင့်ခြင်းနှင့် အော့ဖ်လိုင်း');
  String get defaultSpeed => _t('Default playback speed', 'ပုံမှန်ဖွင့်နှုန်း');
  String get wifiOnly =>
      _t('Download over Wi-Fi only', 'Wi-Fi ဖြင့်သာ ဒေါင်းလုဒ်');
  String get showLegacy =>
      _t('Show legacy formats (WMA/WMV)', 'ဖိုင်အဟောင်းများ ပြမည် (WMA/WMV)');
  String get aboutAndPrivacy =>
      _t('ABOUT & PRIVACY', 'အကြောင်းနှင့် ကိုယ်ရေးလုံခြုံမှု');
  String get privacyBadge =>
      _t('100% LOCAL · ZERO TRACKING', '၁၀၀% ဤစက်တွင်သာ · ခြေရာခံမှု မရှိ');
  String bundledCatalogue(int c) => _t(
    'Bundled catalogue: ${n(c)} items',
    'ထည့်သွင်းပြီး စာရင်း: ${n(c)} ခု',
  );
  String privacyBody(int teachers, int collections) => _t(
    '${n(teachers)} teachers · ${n(collections)} collections · No accounts, no ads, no analytics. Favorites, resume positions, and downloads stay on your device.',
    'ဆရာတော် ${n(teachers)} ပါး · စုစည်းမှု ${n(collections)} ခု · အကောင့်၊ ကြော်ငြာ၊ ခြေရာခံမှု မရှိပါ။ သိမ်းဆည်းမှု၊ ဆက်ဖွင့်ရန်နေရာနှင့် ဒေါင်းလုဒ်များသည် ဤစက်တွင်သာ ရှိပါသည်။',
  );

  // Legacy detail
  String get mediaDetail => _t('Media Detail', 'အသေးစိတ်');
  String legacyBadge(String fmt) => _t('LEGACY · $fmt', 'ဖိုင်အဟောင်း · $fmt');
  String get playbackUnsupported =>
      _t('Playback not supported in-app', 'အက်ပ်အတွင်း ဖွင့်၍မရပါ');
  String get playbackUnsupportedBody => _t(
    'WMV, WMA, and DOC files cannot be decoded natively on mobile. Open the original source link in your browser or external player.',
    'WMV၊ WMA နှင့် DOC ဖိုင်များကို ဖုန်းတွင် တိုက်ရိုက်မဖွင့်နိုင်ပါ။ မူရင်းလင့်ခ်ကို ဘရောက်ဇာ သို့မဟုတ် အခြားပလေယာဖြင့် ဖွင့်ပါ။',
  );
  String get openOriginal =>
      _t('Open Original in Browser', 'မူရင်းကို ဘရောက်ဇာတွင် ဖွင့်မည်');
  String get copySourceUrl => _t('Copy Source URL', 'လင့်ခ်ကူးမည်');
  String get urlCopied => _t('Source URL copied', 'လင့်ခ်ကူးယူပြီးပါပြီ');
  String get cannotOpenLink =>
      _t('Could not open the link', 'လင့်ခ်ကို မဖွင့်နိုင်ပါ');
  String get playTalk => _t('Play Talk', 'တရားတော်ဖွင့်မည်');

  // Common
  String get loading => _t('Loading…', 'ဖွင့်နေသည်…');
  String get errorGeneric =>
      _t('Something went wrong', 'တစ်စုံတစ်ရာ မှားယွင်းသွားပါသည်');
  String get offlineBadge => _t('Offline', 'အော့ဖ်လိုင်း');
  String get browserBadge => _t('Browser', 'ဘရောက်ဇာ');
  String get wifiRequired => _t(
    'Wi-Fi only is on. Connect to Wi-Fi or turn it off in Settings.',
    'Wi-Fi သာ ဖွင့်ထားသည်။ Wi-Fi ချိတ်ပါ သို့မဟုတ် ဆက်တင်တွင် ပိတ်ပါ။',
  );
  String get downloadStarted => _t('Download started', 'ဒေါင်းလုဒ် စတင်ပါပြီ');
  String downloadsQueued(int c) =>
      _t('$c downloads queued', 'ဒေါင်းလုဒ် $c ခု စီစဉ်ပြီး');
  String get saveFailed => _t('Could not save', 'မသိမ်းနိုင်ပါ');
}
