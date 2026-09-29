"""Adatta i file Android/iOS generati da `flutter create` alle esigenze dell'app.
Eseguito automaticamente da GitHub Actions prima della compilazione."""
import pathlib
import re
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "android" / "app"

# ---------------------------------------------------------------- Gradle
kts = APP / "build.gradle.kts"
groovy = APP / "build.gradle"
if kts.exists():
    g = kts.read_text()
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
    g = re.sub(r"ndkVersion\s*=\s*flutter\.ndkVersion", 'ndkVersion = "27.0.12077973"', g)
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
    if "desugar_jdk_libs" not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g)
    print("Patched", kts)
elif groovy.exists():
    g = groovy.read_text()
    g = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", "minSdk = 23", g)
    g = re.sub(r"ndkVersion\s*=?\s*flutter\.ndkVersion", 'ndkVersion = "27.0.12077973"', g)
    if "coreLibraryDesugaringEnabled" not in g:
        g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
    if "desugar_jdk_libs" not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g)
    print("Patched", groovy)
else:
    raise SystemExit("build.gradle non trovato")

# Regole R8 per le notifiche programmate (evita crash in release)
(APP / "proguard-rules.pro").write_text(
    """-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.android.play.core.**
"""
)

# ---------------------------------------------------------------- Manifest
man = APP / "src" / "main" / "AndroidManifest.xml"
m = man.read_text()
perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""
if "POST_NOTIFICATIONS" not in m:
    m = m.replace("<application", perms + "    <application", 1)
receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in m:
    m = m.replace("</application>", receivers + "    </application>", 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="MyFleetManager"', m, count=1)
man.write_text(m)
print("Patched", man)

# ---------------------------------------------------------------- Icone
icons = ROOT / "tool" / "icons"
res = APP / "src" / "main" / "res"
if icons.exists():
    for d in icons.iterdir():
        if d.is_dir():
            (res / d.name).mkdir(parents=True, exist_ok=True)
            for f in d.iterdir():
                shutil.copy(f, res / d.name / f.name)
    print("Icons copied")

# ---------------------------------------------------------------- iOS
plist = ROOT / "ios" / "Runner" / "Info.plist"
if plist.exists():
    p = plist.read_text()
    extra = """	<key>NSCameraUsageDescription</key>
	<string>Serve per fotografare i tuoi veicoli.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Serve per scegliere la foto dei tuoi veicoli.</string>
"""
    if "NSCameraUsageDescription" not in p:
        p = p.replace("<dict>", "<dict>\n" + extra, 1)
    plist.write_text(p)
    print("Patched", plist)
