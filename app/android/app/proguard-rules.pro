# --- Google Mobile Ads (google_mobile_ads) ---
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# --- WorkManager + Room ---
# Pulled in transitively: google_mobile_ads -> play-services-ads
#   -> play-services-ads-identifier -> androidx.work:work-runtime.
# WorkManager auto-initializes at startup via androidx.startup, and Room creates
# its generated *_Impl database by reflection. R8 full mode (AGP 8/9) strips
# those classes, crashing the release build with:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keepclassmembers class * extends androidx.room.RoomDatabase { <init>(); }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# androidx.startup initializers are referenced from the manifest / reflection.
-keep class androidx.startup.** { *; }
