# Flutter Proguard Rules for Aurora Alarm
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.example.aurora_alarm.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# android_alarm_manager_plus
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-dontwarn dev.fluttercommunity.plus.androidalarmmanager.**

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# Google Play Core Deferred Components (Suppressed)
-dontwarn com.google.android.play.core.**
