# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# Firebase Messaging — platform channel ve reflection için
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Flutter engine — platform channel callback'leri için
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Google ML Kit (receipt scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Annotation'ları koru — reflection tabanlı işlemler için
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
