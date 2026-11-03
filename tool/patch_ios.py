import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
IOS = ROOT / "ios"
TARGET = "15.5"
TEAM = "C4WH22N952"

plist = IOS / "Runner" / "Info.plist"
if plist.exists():
    p = plist.read_text()
    keys = {
        "NSCameraUsageDescription": "MyFleetManager uses the camera to photograph your vehicles and documents and to scan group invitation QR codes.",
        "NSPhotoLibraryUsageDescription": "MyFleetManager uses your photos to choose vehicle pictures, documents and QR code images.",
        "NSFaceIDUsageDescription": "MyFleetManager uses Face ID to unlock the app when you turn on the lock in Settings.",
        "NSUserTrackingUsageDescription": "MyFleetManager uses this identifier only to show ads that are more relevant to you in the free version.",
        "CFBundleDisplayName": "MyFleetManager",
        "GADApplicationIdentifier": re.search(r"iosAppId\s*=\s*'([^']+)'", (ROOT / "lib" / "ads_config.dart").read_text()).group(1),
    }
    for k, v in keys.items():
        if f"<key>{k}</key>" in p:
            p = re.sub(rf"(<key>{k}</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{v}\g<2>", p)
        else:
            p = p.replace("<dict>", f"<dict>\n\t<key>{k}</key>\n\t<string>{v}</string>", 1)
    gs = ROOT / "tool" / "GoogleService-Info.plist"
    if gs.exists() and "<key>CFBundleURLTypes</key>" not in p:
        g = gs.read_text()
        rev = re.search(r"<key>REVERSED_CLIENT_ID</key>\s*<string>([^<]+)</string>", g).group(1)
        cid = re.search(r"<key>CLIENT_ID</key>\s*<string>([^<]+)</string>", g).group(1)
        p = p.replace("<dict>", f"<dict>\n\t<key>GIDClientID</key>\n\t<string>{cid}</string>\n\t<key>CFBundleURLTypes</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>CFBundleTypeRole</key>\n\t\t\t<string>Editor</string>\n\t\t\t<key>CFBundleURLSchemes</key>\n\t\t\t<array>\n\t\t\t\t<string>{rev}</string>\n\t\t\t</array>\n\t\t</dict>\n\t</array>", 1)
    if "<key>ITSAppUsesNonExemptEncryption</key>" not in p:
        p = p.replace("<dict>", "<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>", 1)
    if "<key>SKAdNetworkItems</key>" not in p:
        p = p.replace("<dict>", "<dict>\n\t<key>SKAdNetworkItems</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>SKAdNetworkIdentifier</key>\n\t\t\t<string>cstr6suwn9.skadnetwork</string>\n\t\t</dict>\n\t</array>", 1)
    plist.write_text(p)
    print("Patched", plist)

podfile = IOS / "Podfile"
if podfile.exists():
    pf = podfile.read_text()
    pf = re.sub(r"^#?\s*platform :ios, '[^']*'", f"platform :ios, '{TARGET}'", pf, flags=re.M)
    if "IPHONEOS_DEPLOYMENT_TARGET" not in pf:
        pf = pf.replace(
            "    flutter_additional_ios_build_settings(target)",
            "    flutter_additional_ios_build_settings(target)\n"
            "    target.build_configurations.each do |config|\n"
            f"      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '{TARGET}'\n"
            "    end",
        )
    podfile.write_text(pf)
    print("Patched", podfile)

pbx = IOS / "Runner.xcodeproj" / "project.pbxproj"
if pbx.exists():
    t = pbx.read_text()
    t = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", f"IPHONEOS_DEPLOYMENT_TARGET = {TARGET};", t)
    t = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = it\.myfleet\.myfleetmanager;", "PRODUCT_BUNDLE_IDENTIFIER = it.myfleet.myfleetmanager;", t)
    pbx.write_text(t)
    print("Patched", pbx)

ent = IOS / "Runner" / "Runner.entitlements"
if (IOS / "Runner").exists():
    ent.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n'
        "<dict>\n"
        "\t<key>aps-environment</key>\n"
        "\t<string>production</string>\n"
        "\t<key>com.apple.developer.applesignin</key>\n"
        "\t<array>\n"
        "\t\t<string>Default</string>\n"
        "\t</array>\n"
        "</dict>\n"
        "</plist>\n"
    )
    print("Wrote", ent)

if pbx.exists():
    t = pbx.read_text()
    if "CODE_SIGN_ENTITLEMENTS" not in t:
        t = t.replace(
            "INFOPLIST_FILE = Runner/Info.plist;",
            "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;",
        )
        pbx.write_text(t)
        print("Entitlements set in", pbx)
    t = pbx.read_text()
    if "DEVELOPMENT_TEAM = " + TEAM not in t:
        t = re.sub(r"\n\s*DEVELOPMENT_TEAM = [^;]*;", "", t)
        t = t.replace(
            "INFOPLIST_FILE = Runner/Info.plist;",
            f"CODE_SIGN_STYLE = Automatic;\n\t\t\t\tDEVELOPMENT_TEAM = {TEAM};\n\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;",
        )
        pbx.write_text(t)
        print("Signing team set in", pbx)
    t = pbx.read_text()
    if "Apple Distribution" not in t:
        def dist(m):
            body = m.group(0)
            if m.group(1) in ("Release", "Profile") and "INFOPLIST_FILE = Runner/Info.plist;" in body:
                body = body.replace(
                    "INFOPLIST_FILE = Runner/Info.plist;",
                    '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";\n\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;',
                )
            return body
        t = re.sub(r"/\* (Debug|Release|Profile) \*/ = \{\s*isa = XCBuildConfiguration;.*?\n\t\t\};", dist, t, flags=re.S)
        pbx.write_text(t)
        print("Distribution identity set in", pbx)
