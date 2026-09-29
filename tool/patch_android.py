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
    # Firma SEMPRE con la chiave del repository: così gli aggiornamenti
    # si installano sopra la versione precedente senza conflitti.
    if 'create("fleet")' not in g:
        g = g.replace("    buildTypes {", '''    signingConfigs {
        create("fleet") {
            storeFile = file("../../keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {''', 1)
        g = g.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("fleet")')
        if 'getByName("fleet")' not in g:
            raise SystemExit("Impossibile impostare la firma")
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
    if "fleetKey" not in g:
        g = g.replace("    buildTypes {", '''    signingConfigs {
        fleetKey {
            storeFile file("../../keystore/debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }

    buildTypes {''', 1)
        g = g.replace("signingConfigs.debug", "signingConfigs.fleetKey")
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
# Schermata di avvio nativa: sfondo blu + logo (evita il lampo bianco)
launch = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><color android:color="#0257C3"/></item>
    <item><bitmap android:gravity="center" android:src="@drawable/splash_logo"/></item>
</layer-list>
'''
for d in ("drawable", "drawable-v21"):
    (res / d).mkdir(parents=True, exist_ok=True)
    (res / d / "launch_background.xml").write_text(launch)
styles31 = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">#0257C3</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher_foreground</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
'''
for d in ("values-v31", "values-night-v31"):
    (res / d).mkdir(parents=True, exist_ok=True)
    (res / d / "styles.xml").write_text(styles31)
print("Splash patched")

(res / "raw").mkdir(parents=True, exist_ok=True)
(res / "raw" / "keep.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources xmlns:tools="http://schemas.android.com/tools" '
    'tools:keep="@drawable/ic_stat_notify,@drawable/splash_logo,@mipmap/ic_launcher*" />\n'
)

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
