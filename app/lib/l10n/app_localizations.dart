import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Constella'**
  String get appTitle;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Clear night'**
  String get greetingNight;

  /// No description provided for @mascotSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, your cosmic companion'**
  String mascotSemanticLabel(String name);

  /// No description provided for @mascotSpeechSky.
  ///
  /// In en, this message translates to:
  /// **'The sky is waiting.\nShall we open the portal?'**
  String get mascotSpeechSky;

  /// No description provided for @mascotSpeechFocus.
  ///
  /// In en, this message translates to:
  /// **'I am ready to focus!\nLet\'s set up a timer.'**
  String get mascotSpeechFocus;

  /// No description provided for @enterCosmicNight.
  ///
  /// In en, this message translates to:
  /// **'Enter the Cosmic Night'**
  String get enterCosmicNight;

  /// No description provided for @cosmicNightHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the sky'**
  String get cosmicNightHint;

  /// No description provided for @tabSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get tabSky;

  /// No description provided for @tabConstellations.
  ///
  /// In en, this message translates to:
  /// **'Constellations'**
  String get tabConstellations;

  /// No description provided for @tabFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get tabFocus;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @constellationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your constellations'**
  String get constellationsTitle;

  /// No description provided for @constellationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No constellations yet'**
  String get constellationsEmptyTitle;

  /// No description provided for @constellationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Open the Cosmic Night, then connect the city lights to draw your first shape.'**
  String get constellationsEmptyBody;

  /// No description provided for @arPortalOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the sky portal…'**
  String get arPortalOpening;

  /// No description provided for @arCloseP.
  ///
  /// In en, this message translates to:
  /// **'Close the portal'**
  String get arCloseP;

  /// No description provided for @arPortalOpen.
  ///
  /// In en, this message translates to:
  /// **'Portal open'**
  String get arPortalOpen;

  /// No description provided for @arCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to open the Cosmic Night.'**
  String get arCameraDenied;

  /// No description provided for @arCameraDeniedAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get arCameraDeniedAction;

  /// No description provided for @arCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get arCameraUnavailable;

  /// No description provided for @arDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Drag between the lights to draw'**
  String get arDrawHint;

  /// No description provided for @focusSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get focusSessionTitle;

  /// No description provided for @mascotReadyToFocus.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready to focus with you'**
  String mascotReadyToFocus(String name);

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTime;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @decreaseDuration.
  ///
  /// In en, this message translates to:
  /// **'Decrease duration'**
  String get decreaseDuration;

  /// No description provided for @increaseDuration.
  ///
  /// In en, this message translates to:
  /// **'Increase duration'**
  String get increaseDuration;

  /// No description provided for @startFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get startFocusSession;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @giveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get giveUp;

  /// No description provided for @mascotFocusing.
  ///
  /// In en, this message translates to:
  /// **'Shh… {name} is focusing.'**
  String mascotFocusing(String name);

  /// No description provided for @mascotPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused. Ready when you are.'**
  String get mascotPaused;

  /// No description provided for @sessionCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionCompleteTitle;

  /// No description provided for @sessionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes of {category}. Nice work.'**
  String sessionCompleteBody(int minutes, String category);

  /// No description provided for @stardustEarned.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Stardust'**
  String stardustEarned(int amount);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @giveUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Give up this session?'**
  String get giveUpTitle;

  /// No description provided for @giveUpBody.
  ///
  /// In en, this message translates to:
  /// **'No Stardust is awarded for an unfinished session.'**
  String get giveUpBody;

  /// No description provided for @giveUpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get giveUpConfirm;

  /// No description provided for @giveUpCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get giveUpCancel;

  /// No description provided for @arTapToAddNode.
  ///
  /// In en, this message translates to:
  /// **'Tap the city lights to drop nodes'**
  String get arTapToAddNode;

  /// No description provided for @arDragToConnect.
  ///
  /// In en, this message translates to:
  /// **'Drag between nodes to draw'**
  String get arDragToConnect;

  /// No description provided for @constellationNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name this shape'**
  String get constellationNameHint;

  /// No description provided for @constellationNameExample.
  ///
  /// In en, this message translates to:
  /// **'City Bridge'**
  String get constellationNameExample;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @constellationSaved.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" saved to your shapes'**
  String constellationSaved(String name);

  /// No description provided for @nodesAndLines.
  ///
  /// In en, this message translates to:
  /// **'{nodes} nodes · {lines} lines'**
  String nodesAndLines(int nodes, int lines);

  /// No description provided for @stardustTitle.
  ///
  /// In en, this message translates to:
  /// **'Stardust Energy'**
  String get stardustTitle;

  /// No description provided for @stardustCaption.
  ///
  /// In en, this message translates to:
  /// **'{current} of {next} to the next tier'**
  String stardustCaption(int current, int next);

  /// No description provided for @focusMinutesTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focused'**
  String focusMinutesTotal(int minutes);

  /// No description provided for @sessionRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get sessionRemainingLabel;

  /// No description provided for @sessionCompleteBodyShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes under the night sky.'**
  String sessionCompleteBodyShort(int minutes);

  /// No description provided for @constellationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No shapes yet} =1{1 shape} other{{count} shapes}}'**
  String constellationsCount(int count);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello, I am {name}'**
  String onboardingWelcomeTitle(String name);

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'I will keep you company while you explore the sky above your city.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the Cosmic Night'**
  String get onboardingPortalTitle;

  /// No description provided for @onboardingPortalBody.
  ///
  /// In en, this message translates to:
  /// **'Point your phone at the sky and tap the glowing orb. Daylight folds away and the stars come through.'**
  String get onboardingPortalBody;

  /// No description provided for @onboardingDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw your own constellations'**
  String get onboardingDrawTitle;

  /// No description provided for @onboardingDrawBody.
  ///
  /// In en, this message translates to:
  /// **'Connect the city lights into a shape, give it a name, and it joins your collection.'**
  String get onboardingDrawBody;

  /// No description provided for @onboardingCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Constella needs your camera'**
  String get onboardingCameraTitle;

  /// No description provided for @onboardingCameraBody.
  ///
  /// In en, this message translates to:
  /// **'The night sky is drawn over what your camera sees. Nothing is recorded and nothing leaves your phone.'**
  String get onboardingCameraBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @renameConstellation.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameConstellation;

  /// No description provided for @deleteConstellation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConstellation;

  /// No description provided for @deleteConstellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConstellationTitle(String name);

  /// No description provided for @deleteConstellationBody.
  ///
  /// In en, this message translates to:
  /// **'This shape is removed from your collection. Stardust already earned stays.'**
  String get deleteConstellationBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {mode}'**
  String appearanceLabel(String mode);

  /// No description provided for @arCameraRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get arCameraRetry;

  /// No description provided for @arCameraDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'If the prompt no longer appears, turn the camera on in Settings › Apps › Constella › Permissions.'**
  String get arCameraDeniedHint;

  /// No description provided for @focusEntry.
  ///
  /// In en, this message translates to:
  /// **'Start a focus session'**
  String get focusEntry;

  /// No description provided for @focusEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Focus while the cosmos keeps you company'**
  String get focusEntryHint;

  /// No description provided for @tabStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get tabStars;

  /// No description provided for @starAimHint.
  ///
  /// In en, this message translates to:
  /// **'Point the crosshair at a star'**
  String get starAimHint;

  /// No description provided for @starSearching.
  ///
  /// In en, this message translates to:
  /// **'Reading the sky…'**
  String get starSearching;

  /// No description provided for @starNothingHere.
  ///
  /// In en, this message translates to:
  /// **'No bright star in the crosshair'**
  String get starNothingHere;

  /// No description provided for @starNothingHereBody.
  ///
  /// In en, this message translates to:
  /// **'Move slowly. Only stars down to magnitude 5 are in the catalogue.'**
  String get starNothingHereBody;

  /// No description provided for @starOffBy.
  ///
  /// In en, this message translates to:
  /// **'{deg}° from centre'**
  String starOffBy(String deg);

  /// No description provided for @starMagnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get starMagnitude;

  /// No description provided for @starDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get starDistance;

  /// No description provided for @starLightYears.
  ///
  /// In en, this message translates to:
  /// **'{value} light years'**
  String starLightYears(String value);

  /// No description provided for @starDistanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not known'**
  String get starDistanceUnknown;

  /// No description provided for @starSpectralType.
  ///
  /// In en, this message translates to:
  /// **'Spectral type'**
  String get starSpectralType;

  /// No description provided for @starConstellation.
  ///
  /// In en, this message translates to:
  /// **'Constellation'**
  String get starConstellation;

  /// No description provided for @starAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get starAltitude;

  /// No description provided for @starNeedsLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Constella needs your rough location'**
  String get starNeedsLocationTitle;

  /// No description provided for @starNeedsLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Which stars are above you depends on where you stand. Approximate location is enough — Constella never asks for precise location, and nothing is stored or sent anywhere.'**
  String get starNeedsLocationBody;

  /// No description provided for @starAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get starAllowLocation;

  /// No description provided for @starLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Without location, Constella cannot tell which stars are up.'**
  String get starLocationDenied;

  /// No description provided for @starLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this phone.'**
  String get starLocationServiceOff;

  /// No description provided for @starOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get starOpenSettings;

  /// No description provided for @starNoCompass.
  ///
  /// In en, this message translates to:
  /// **'This phone has no compass'**
  String get starNoCompass;

  /// No description provided for @starNoCompassBody.
  ///
  /// In en, this message translates to:
  /// **'Identifying a star needs a magnetometer to know which way you are facing. This device does not report one.'**
  String get starNoCompassBody;

  /// No description provided for @starBelowHorizon.
  ///
  /// In en, this message translates to:
  /// **'below the horizon'**
  String get starBelowHorizon;

  /// No description provided for @cosmicNightPurpose.
  ///
  /// In en, this message translates to:
  /// **'City lights wash out the stars. The portal shows the sky that is really above you right now.'**
  String get cosmicNightPurpose;

  /// No description provided for @starCatcherPurpose.
  ///
  /// In en, this message translates to:
  /// **'Aim the crosshair at any star. Constella names it from where you stand and the time on your phone, with no internet.'**
  String get starCatcherPurpose;

  /// No description provided for @arPortalTip.
  ///
  /// In en, this message translates to:
  /// **'Everything above the horizon becomes night sky. Buildings and ground stay as they are.'**
  String get arPortalTip;

  /// No description provided for @lightCaught.
  ///
  /// In en, this message translates to:
  /// **'Bright light caught'**
  String get lightCaught;

  /// No description provided for @lightCaughtHint.
  ///
  /// In en, this message translates to:
  /// **'Tap it to drop a node there'**
  String get lightCaughtHint;

  /// No description provided for @catchStar.
  ///
  /// In en, this message translates to:
  /// **'Catch this star'**
  String get catchStar;

  /// No description provided for @starCaught.
  ///
  /// In en, this message translates to:
  /// **'Caught!'**
  String get starCaught;

  /// No description provided for @starAlreadyCaught.
  ///
  /// In en, this message translates to:
  /// **'Already in your collection'**
  String get starAlreadyCaught;

  /// No description provided for @starCatchPraise.
  ///
  /// In en, this message translates to:
  /// **'Who gave you permission to find that one?'**
  String get starCatchPraise;

  /// No description provided for @starCatchPraiseDim.
  ///
  /// In en, this message translates to:
  /// **'That one is barely visible from a city.'**
  String get starCatchPraiseDim;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get statDistance;

  /// No description provided for @statMagnitude.
  ///
  /// In en, this message translates to:
  /// **'BRIGHTNESS'**
  String get statMagnitude;

  /// No description provided for @statConstellation.
  ///
  /// In en, this message translates to:
  /// **'CONSTELLATION'**
  String get statConstellation;

  /// No description provided for @claimStardust.
  ///
  /// In en, this message translates to:
  /// **'Claim {amount} Stardust'**
  String claimStardust(int amount);

  /// No description provided for @starCollectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} caught'**
  String starCollectionCount(int count);

  /// No description provided for @closeCelebration.
  ///
  /// In en, this message translates to:
  /// **'Keep looking'**
  String get closeCelebration;

  /// No description provided for @snapShutter.
  ///
  /// In en, this message translates to:
  /// **'Take a cosmic snap'**
  String get snapShutter;

  /// No description provided for @snapTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Snap'**
  String get snapTitle;

  /// No description provided for @snapFacingStar.
  ///
  /// In en, this message translates to:
  /// **'Facing {constellation}, {degrees}° above the horizon.'**
  String snapFacingStar(String constellation, String degrees);

  /// No description provided for @snapFacingPlain.
  ///
  /// In en, this message translates to:
  /// **'Facing {point}, {degrees}° above the horizon.'**
  String snapFacingPlain(String point, String degrees);

  /// No description provided for @snapBelowHorizon.
  ///
  /// In en, this message translates to:
  /// **'Pointed below the horizon, toward {point}.'**
  String snapBelowHorizon(String point);

  /// No description provided for @snapBrightest.
  ///
  /// In en, this message translates to:
  /// **'Brightest in frame: {star}, about {years} light years away.'**
  String snapBrightest(String star, String years);

  /// No description provided for @snapNoStar.
  ///
  /// In en, this message translates to:
  /// **'No catalogued star bright enough to name in this frame.'**
  String get snapNoStar;

  /// No description provided for @snapShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get snapShare;

  /// No description provided for @snapClose.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get snapClose;

  /// No description provided for @snapFailed.
  ///
  /// In en, this message translates to:
  /// **'The snap could not be taken. Try again.'**
  String get snapFailed;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'id':
      return AppL10nId();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
