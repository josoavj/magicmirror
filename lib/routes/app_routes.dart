import 'package:flutter/material.dart';
import 'package:magicmirror/routes/route_names.dart';
import 'package:magicmirror/presentation/screens/home_screen.dart';
import 'package:magicmirror/features/mirror/presentation/screens/mirror_screen.dart';
import 'package:magicmirror/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:magicmirror/features/weather/presentation/screens/weather_screen.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/screens/outfit_suggestion_screen.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/screens/outfit_favorites_screen.dart';
import 'package:magicmirror/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:magicmirror/features/settings/presentation/screens/settings_screen.dart';
import 'package:magicmirror/features/settings/presentation/screens/account_settings_screen.dart';
import 'package:magicmirror/features/settings/presentation/screens/outfit_insights_settings_screen.dart';
import 'package:magicmirror/presentation/screens/about_screen.dart';
import 'package:magicmirror/presentation/screens/privacy_policy_screen.dart';
import 'package:magicmirror/presentation/screens/terms_of_use_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      RouteNames.home: (context) => const HomeScreen(),
      RouteNames.mirror: (context) => const MirrorScreen(),
      RouteNames.agenda: (context) => const AgendaScreen(),
      RouteNames.weather: (context) => const WeatherScreen(),
      RouteNames.outfitSuggestion: (context) => const OutfitSuggestionScreen(),
      RouteNames.outfitFavorites: (context) => const OutfitFavoritesScreen(),
      RouteNames.profile: (context) => const UserProfileScreen(),
      RouteNames.accountSettings: (context) => const AccountSettingsScreen(),
      RouteNames.settings: (context) => const SettingsScreen(),
      RouteNames.outfitInsightsSettings: (context) =>
          const OutfitInsightsSettingsScreen(),
      RouteNames.about: (context) => const AboutScreen(),
      RouteNames.privacy: (context) => const PrivacyPolicyScreen(),
      RouteNames.terms: (context) => const TermsOfUseScreen(),
    };
  }
}
