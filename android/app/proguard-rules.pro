# Aturan Standar Proguard untuk Flutter Release
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Jika kamu menggunakan package mobile_scanner, tambahkan ini agar kameranya tidak crash setelah di-minify
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
# Abaikan missing classes dari komponen Play Store Deferred yang tidak dipakai
-dontwarn com.google.android.play.core.**