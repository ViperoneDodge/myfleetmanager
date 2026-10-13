import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
IOS = ROOT / "ios"
TARGET = "15.5"

plist = IOS / "Runner" / "Info.plist"
if plist.exists():
    p = plist.read_text()
    keys = {
        "NSCameraUsageDescription": "MyFleetManager uses the camera to photograph your vehicles and documents and to scan group invitation QR codes.",
        "NSPhotoLibraryUsageDescription": "MyFleetManager uses your photos to choose vehicle pictures, documents and QR code images.",
        "CFBundleDisplayName": "MyFleetManager",
    }
    for k, v in keys.items():
        if f"<key>{k}</key>" in p:
            p = re.sub(rf"(<key>{k}</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{v}\g<2>", p)
        else:
            p = p.replace("<dict>", f"<dict>\n\t<key>{k}</key>\n\t<string>{v}</string>", 1)
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
