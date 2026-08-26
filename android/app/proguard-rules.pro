# flutter_local_notifications persists scheduled notifications via Gson
# reflection (TypeToken<List<...>>). R8 strips the generic signature
# info that reflection needs unless explicitly kept, which crashes the
# app the first time it tries to read back a previously-scheduled
# notification (see LocalNotificationRepository).
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature
-keepattributes *Annotation*

# flutter_webrtc — package's own recommended release-build rules.
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }
-keep class org.jni_zero.** { *; }

# google_mobile_ads pulls in androidx.work (WorkManager), which builds its
# Room-backed WorkDatabase via reflection (Class.getDeclaredConstructor())
# — R8 strips the Room-generated *_Impl class's no-arg constructor since
# nothing calls it directly, which crashes app startup
# (NoSuchMethodException: WorkDatabase_Impl.<init>). Room-generated
# classes in general hit this same reflection pattern.
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
