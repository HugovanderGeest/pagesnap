import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'library_title': 'Library',
      'account_title': 'Account',
      'scan_button': 'Scan Page',
      'identify_button': 'Identify',
      'scanning_tips_title': 'SCANNING TIPS',
      'scanning_tips_1': 'Good lighting — avoid shadows',
      'scanning_tips_2': 'Hold the phone steady above the page',
      'scanning_tips_3': 'Scan text-heavy pages (not the cover)',
      'scanning_tips_4': 'Latin/European alphabet works best',
      'status_no_camera': 'No camera found on this device.',
      'status_align_page': 'Align the page inside the frame and tap the shutter',
      'status_reading_text': 'Reading text from images…',
      'status_could_not_read': 'Could not read text',
      'words_extracted': 'words extracted',
      'from_pages': 'from scanned pages',
      'book_title_label': 'BOOK TITLE',
      'book_title_hint': 'Optional — leave blank for auto title',
      'save_read_now': 'SAVE & READ NOW',
      'add_to_library': 'ADD TO LIBRARY ONLY',
      'scan_again': 'Scan Again',
      'paste_title': 'Camera OCR not available',
      'paste_subtitle': 'Paste or type the text you want to read at speed:',
      'paste_hint': 'Paste your text here…',
      'continue_button': 'CONTINUE',
      'back_scanner': 'Back to Scanner',
      'sign_in': 'SIGN IN',
      'create_account': 'CREATE ACCOUNT',
      'or_continue_with': 'OR CONTINUE WITH',
      'email_hint': 'Email',
      'password_hint': 'Password',
      'check_email_link': 'Check your email for the login link!',
      'unexpected_error': 'Unexpected error occurred',
      'slogan': 'READ AT THE SPEED OF THOUGHT.',
    },
    'nl': {
      'library_title': 'Bibliotheek',
      'account_title': 'Account',
      'scan_button': 'Pagina Scannen',
      'identify_button': 'Identificeren',
      'scanning_tips_title': 'SCANTIPS',
      'scanning_tips_1': 'Goede belichting — vermijd schaduwen',
      'scanning_tips_2': 'Houd de telefoon stil boven de pagina',
      'scanning_tips_3': 'Scan pagina\'s met veel tekst (niet de kaft)',
      'scanning_tips_4': 'Latijnse/Europese alfabetten werken het best',
      'status_no_camera': 'Geen camera gevonden op dit apparaat.',
      'status_align_page': 'Lijn de pagina uit in het kader en tik op de sluiter',
      'status_reading_text': 'Tekst uit afbeeldingen lezen…',
      'status_could_not_read': 'Kon de tekst niet lezen',
      'words_extracted': 'woorden geëxtraheerd',
      'from_pages': 'uit gescande pagina\'s',
      'book_title_label': 'BOEKTITEL',
      'book_title_hint': 'Optioneel — laat leeg voor automatische titel',
      'save_read_now': 'OPSLAAN & NU LEZEN',
      'add_to_library': 'ALLEEN AAN BIBLIOTHEEK TOEVOEGEN',
      'scan_again': 'Opnieuw Scannen',
      'paste_title': 'Camera OCR niet beschikbaar',
      'paste_subtitle': 'Plak of typ de tekst die je wilt snellezen:',
      'paste_hint': 'Plak je tekst hier…',
      'continue_button': 'DOORGAAN',
      'back_scanner': 'Terug naar Scanner',
      'sign_in': 'INLOGGEN',
      'create_account': 'ACCOUNT AANMAKEN',
      'or_continue_with': 'OF GA DOOR MET',
      'email_hint': 'E-mailadres',
      'password_hint': 'Wachtwoord',
      'check_email_link': 'Check je e-mail voor de inloglink!',
      'unexpected_error': 'Er is een onverwachte fout opgetreden',
      'slogan': 'LEES OP DE SNELHEID VAN GEDACHTEN.',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'nl'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
