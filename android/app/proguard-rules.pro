# Flutter Local Notifications - Critical for Android push notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# AndroidX Work Manager - Required for scheduled notifications
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Timezone data - Critical for accurate notification scheduling
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**
-keep class org.threeten.bp.zone.** { *; }

# Flutter Local Notifications specific classes
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.utils.** { *; }

# Android Notification Components
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# AlarmManager and scheduling
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

# Firebase Analytics (if used with notifications)
-keep class com.google.firebase.analytics.** { *; }
-dontwarn com.google.firebase.analytics.**

# Preserve notification payload data
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep notification receiver classes
-keep class * extends android.content.BroadcastReceiver {
    public <init>(...);
}

# Preserve Flutter plugin registrant
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent obfuscation of notification-related enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Google Play Core - Fix for R8 missing classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Additional R8 compatibility rules
-dontwarn java.lang.invoke.StringConcatFactory
