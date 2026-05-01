# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Realtime
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# Google Play Core (référencé par le moteur Flutter, absent en dehors du Play Store)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
