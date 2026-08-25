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
