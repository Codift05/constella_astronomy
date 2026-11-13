// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Constella';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Clear night';

  @override
  String mascotSemanticLabel(String name) {
    return '$name, your cosmic companion';
  }

  @override
  String get mascotSpeechSky =>
      'The sky is waiting.\nShall we open the portal?';

  @override
  String get mascotSpeechFocus =>
      'I am ready to focus!\nLet\'s set up a timer.';

  @override
  String get enterCosmicNight => 'Enter the Cosmic Night';

  @override
  String get cosmicNightHint => 'Point your camera at the sky';

  @override
  String get tabSky => 'Sky';

  @override
  String get tabConstellations => 'Shapes';

  @override
  String get tabFocus => 'Focus';

  @override
  String get back => 'Back';

  @override
  String get constellationsTitle => 'Your constellations';

  @override
  String get constellationsEmptyTitle => 'No constellations yet';

  @override
  String get constellationsEmptyBody =>
      'Open the Cosmic Night, then connect the city lights to draw your first shape.';

  @override
  String get arOrbHint => 'Tap the orb to open the portal';

  @override
  String get arCloseP => 'Close the portal';

  @override
  String get arPortalOpen => 'Portal open';

  @override
  String get arCameraDenied =>
      'Camera access is needed to open the Cosmic Night.';

  @override
  String get arCameraDeniedAction => 'Open settings';

  @override
  String get arCameraUnavailable => 'No camera found on this device.';

  @override
  String get arDrawHint => 'Drag between the lights to draw';

  @override
  String get focusSessionTitle => 'Focus Session';

  @override
  String mascotReadyToFocus(String name) {
    return '$name is ready to focus with you';
  }

  @override
  String get focusTime => 'Focus time';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get decreaseDuration => 'Decrease duration';

  @override
  String get increaseDuration => 'Increase duration';

  @override
  String get startFocusSession => 'Start focus session';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get giveUp => 'Give up';

  @override
  String mascotFocusing(String name) {
    return 'Shh… $name is focusing.';
  }

  @override
  String get mascotPaused => 'Paused. Ready when you are.';

  @override
  String get sessionCompleteTitle => 'Session complete';

  @override
  String sessionCompleteBody(int minutes, String category) {
    return '$minutes minutes of $category. Nice work.';
  }

  @override
  String stardustEarned(int amount) {
    return '+$amount Stardust';
  }

  @override
  String get done => 'Done';

  @override
  String get giveUpTitle => 'Give up this session?';

  @override
  String get giveUpBody => 'No Stardust is awarded for an unfinished session.';

  @override
  String get giveUpConfirm => 'Give up';

  @override
  String get giveUpCancel => 'Keep going';

  @override
  String get arTapToAddNode => 'Tap the city lights to drop nodes';

  @override
  String get arDragToConnect => 'Drag between nodes to draw';

  @override
  String get constellationNameHint => 'Name this shape';

  @override
  String get constellationNameExample => 'City Bridge';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String constellationSaved(String name) {
    return '\"$name\" saved to your shapes';
  }

  @override
  String nodesAndLines(int nodes, int lines) {
    return '$nodes nodes · $lines lines';
  }

  @override
  String get stardustTitle => 'Stardust Energy';

  @override
  String stardustCaption(int current, int next) {
    return '$current of $next to the next tier';
  }

  @override
  String focusMinutesTotal(int minutes) {
    return '$minutes min focused';
  }

  @override
  String get sessionRemainingLabel => 'remaining';

  @override
  String sessionCompleteBodyShort(int minutes) {
    return '$minutes minutes under the night sky.';
  }

  @override
  String constellationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shapes',
      one: '1 shape',
      zero: 'No shapes yet',
    );
    return '$_temp0';
  }

  @override
  String onboardingWelcomeTitle(String name) {
    return 'Hello, I am $name';
  }

  @override
  String get onboardingWelcomeBody =>
      'I will keep you company while you explore the sky above your city.';

  @override
  String get onboardingPortalTitle => 'Open the Cosmic Night';

  @override
  String get onboardingPortalBody =>
      'Point your phone at the sky and tap the glowing orb. Daylight folds away and the stars come through.';

  @override
  String get onboardingDrawTitle => 'Draw your own constellations';

  @override
  String get onboardingDrawBody =>
      'Connect the city lights into a shape, give it a name, and it joins your collection.';

  @override
  String get onboardingCameraTitle => 'Constella needs your camera';

  @override
  String get onboardingCameraBody =>
      'The night sky is drawn over what your camera sees. Nothing is recorded and nothing leaves your phone.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s go';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get renameConstellation => 'Rename';

  @override
  String get deleteConstellation => 'Delete';

  @override
  String deleteConstellationTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteConstellationBody =>
      'This shape is removed from your collection. Stardust already earned stays.';

  @override
  String get cancel => 'Cancel';

  @override
  String get appearanceSystem => 'Follow system';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String appearanceLabel(String mode) {
    return 'Appearance: $mode';
  }

  @override
  String get arCameraRetry => 'Try again';

  @override
  String get arCameraDeniedHint =>
      'If the prompt no longer appears, turn the camera on in Settings › Apps › Constella › Permissions.';
}
