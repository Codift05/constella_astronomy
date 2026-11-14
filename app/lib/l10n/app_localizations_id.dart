// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppL10nId extends AppL10n {
  AppL10nId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Constella';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat sore';

  @override
  String get greetingNight => 'Malam cerah';

  @override
  String mascotSemanticLabel(String name) {
    return '$name, pendamping kosmikmu';
  }

  @override
  String get mascotSpeechSky => 'Langit sudah menunggu.\nBuka portalnya?';

  @override
  String get mascotSpeechFocus => 'Aku siap fokus!\nAyo atur timernya.';

  @override
  String get enterCosmicNight => 'Masuk ke Malam Kosmik';

  @override
  String get cosmicNightHint => 'Arahkan kamera ke langit';

  @override
  String get tabSky => 'Langit';

  @override
  String get tabConstellations => 'Rasi';

  @override
  String get tabFocus => 'Fokus';

  @override
  String get back => 'Kembali';

  @override
  String get constellationsTitle => 'Rasi bintangmu';

  @override
  String get constellationsEmptyTitle => 'Belum ada rasi bintang';

  @override
  String get constellationsEmptyBody =>
      'Buka Malam Kosmik, lalu sambungkan lampu-lampu kota untuk menggambar bentuk pertamamu.';

  @override
  String get arOrbHint => 'Ketuk orb untuk membuka portal';

  @override
  String get arCloseP => 'Tutup portal';

  @override
  String get arPortalOpen => 'Portal terbuka';

  @override
  String get arCameraDenied =>
      'Akses kamera dibutuhkan untuk membuka Malam Kosmik.';

  @override
  String get arCameraDeniedAction => 'Buka pengaturan';

  @override
  String get arCameraUnavailable => 'Tidak ada kamera di perangkat ini.';

  @override
  String get arDrawHint => 'Tarik antar cahaya untuk menggambar';

  @override
  String get focusSessionTitle => 'Sesi Fokus';

  @override
  String mascotReadyToFocus(String name) {
    return '$name siap fokus bersamamu';
  }

  @override
  String get focusTime => 'Durasi fokus';

  @override
  String get minutesUnit => 'menit';

  @override
  String get decreaseDuration => 'Kurangi durasi';

  @override
  String get increaseDuration => 'Tambah durasi';

  @override
  String get startFocusSession => 'Mulai sesi fokus';

  @override
  String get pause => 'Jeda';

  @override
  String get resume => 'Lanjut';

  @override
  String get giveUp => 'Menyerah';

  @override
  String mascotFocusing(String name) {
    return 'Ssst… $name sedang fokus.';
  }

  @override
  String get mascotPaused => 'Dijeda. Lanjut kapan pun kamu siap.';

  @override
  String get sessionCompleteTitle => 'Sesi selesai';

  @override
  String sessionCompleteBody(int minutes, String category) {
    return '$minutes menit $category. Kerja bagus.';
  }

  @override
  String stardustEarned(int amount) {
    return '+$amount Stardust';
  }

  @override
  String get done => 'Selesai';

  @override
  String get giveUpTitle => 'Menyerah dari sesi ini?';

  @override
  String get giveUpBody => 'Sesi yang tidak selesai tidak mendapat Stardust.';

  @override
  String get giveUpConfirm => 'Menyerah';

  @override
  String get giveUpCancel => 'Lanjut fokus';

  @override
  String get arTapToAddNode => 'Ketuk lampu kota untuk menaruh node';

  @override
  String get arDragToConnect => 'Tarik antar node untuk menggambar';

  @override
  String get constellationNameHint => 'Beri nama bentuk ini';

  @override
  String get constellationNameExample => 'Jembatan Kota';

  @override
  String get save => 'Simpan';

  @override
  String get undo => 'Batalkan';

  @override
  String constellationSaved(String name) {
    return '\"$name\" tersimpan ke koleksimu';
  }

  @override
  String nodesAndLines(int nodes, int lines) {
    return '$nodes node · $lines garis';
  }

  @override
  String get stardustTitle => 'Stardust Energy';

  @override
  String stardustCaption(int current, int next) {
    return '$current dari $next menuju tingkat berikutnya';
  }

  @override
  String focusMinutesTotal(int minutes) {
    return '$minutes menit fokus';
  }

  @override
  String get sessionRemainingLabel => 'tersisa';

  @override
  String sessionCompleteBodyShort(int minutes) {
    return '$minutes menit di bawah langit malam.';
  }

  @override
  String constellationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bentuk',
      zero: 'Belum ada bentuk',
    );
    return '$_temp0';
  }

  @override
  String onboardingWelcomeTitle(String name) {
    return 'Halo, aku $name';
  }

  @override
  String get onboardingWelcomeBody =>
      'Aku akan menemanimu menjelajahi langit di atas kotamu.';

  @override
  String get onboardingPortalTitle => 'Buka Malam Kosmik';

  @override
  String get onboardingPortalBody =>
      'Arahkan ponselmu ke langit lalu ketuk orb bercahaya. Siang terlipat, bintang-bintang muncul.';

  @override
  String get onboardingDrawTitle => 'Gambar rasi bintangmu sendiri';

  @override
  String get onboardingDrawBody =>
      'Sambungkan lampu-lampu kota menjadi sebuah bentuk, beri nama, dan ia masuk ke koleksimu.';

  @override
  String get onboardingCameraTitle => 'Constella butuh kameramu';

  @override
  String get onboardingCameraBody =>
      'Langit malam digambar di atas apa yang dilihat kameramu. Tidak ada yang direkam dan tidak ada yang keluar dari ponselmu.';

  @override
  String get onboardingNext => 'Lanjut';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get onboardingSkip => 'Lewati';

  @override
  String get renameConstellation => 'Ganti nama';

  @override
  String get deleteConstellation => 'Hapus';

  @override
  String deleteConstellationTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get deleteConstellationBody =>
      'Bentuk ini dibuang dari koleksimu. Stardust yang sudah didapat tetap tinggal.';

  @override
  String get cancel => 'Batal';

  @override
  String get appearanceSystem => 'Ikut sistem';

  @override
  String get appearanceLight => 'Terang';

  @override
  String get appearanceDark => 'Gelap';

  @override
  String appearanceLabel(String mode) {
    return 'Tampilan: $mode';
  }

  @override
  String get arCameraRetry => 'Coba lagi';

  @override
  String get arCameraDeniedHint =>
      'Kalau dialog izinnya tidak muncul lagi, nyalakan kamera di Setelan › Aplikasi › Constella › Izin.';

  @override
  String get focusEntry => 'Mulai sesi fokus';

  @override
  String get focusEntryHint => 'Fokus ditemani langit malam';

  @override
  String get tabStars => 'Bintang';

  @override
  String get starAimHint => 'Arahkan bidikan ke bintang';

  @override
  String get starSearching => 'Membaca langit…';

  @override
  String get starNothingHere => 'Tidak ada bintang terang di bidikan';

  @override
  String get starNothingHereBody =>
      'Gerakkan pelan-pelan. Katalognya hanya memuat bintang sampai magnitudo 5.';

  @override
  String starOffBy(String deg) {
    return '$deg° dari tengah';
  }

  @override
  String get starMagnitude => 'Magnitudo';

  @override
  String get starDistance => 'Jarak';

  @override
  String starLightYears(String value) {
    return '$value tahun cahaya';
  }

  @override
  String get starDistanceUnknown => 'Belum diketahui';

  @override
  String get starSpectralType => 'Tipe spektral';

  @override
  String get starConstellation => 'Rasi';

  @override
  String get starAltitude => 'Ketinggian';

  @override
  String get starNeedsLocationTitle =>
      'Constella perlu tahu posisimu secara kasar';

  @override
  String get starNeedsLocationBody =>
      'Bintang yang ada di atasmu bergantung pada tempatmu berdiri. Lokasi perkiraan sudah cukup — Constella tidak pernah meminta lokasi presisi, dan tidak ada yang disimpan atau dikirim ke mana pun.';

  @override
  String get starAllowLocation => 'Izinkan lokasi';

  @override
  String get starLocationDenied =>
      'Tanpa lokasi, Constella tidak bisa tahu bintang mana yang sedang terbit.';

  @override
  String get starLocationServiceOff =>
      'Layanan lokasi di ponsel ini sedang mati.';

  @override
  String get starOpenSettings => 'Buka setelan';

  @override
  String get starNoCompass => 'Ponsel ini tidak punya kompas';

  @override
  String get starNoCompassBody =>
      'Mengenali bintang butuh magnetometer untuk tahu kamu menghadap ke mana. Perangkat ini tidak melaporkannya.';

  @override
  String get starBelowHorizon => 'di bawah ufuk';
}
