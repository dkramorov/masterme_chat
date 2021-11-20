#!/usr/bin/env python3
import os
import sys
import shutil

project_name = None
if len(sys.argv) > 1:
    project_name = sys.argv[1]

if not project_name:
    print('[ERROR]: project_name not set')
    exit()

if not project_name in ('8800', '223'):
    print('[ERROR]: project_name incorrect')
    exit()

android_folder = 'android/app/src/main/res'
mac_folder = 'macos/Runner/Assets.xcassets'
ios_folder = 'ios/Runner/Assets.xcassets'

android_res = (
    'drawable/app_icon.png',
    'mipmap-hdpi/ic_launcher.png',
    'mipmap-hdpi/logo.png',
    'mipmap-mdpi/ic_launcher.png',
    'mipmap-mdpi/logo.png',
    'mipmap-xhdpi/ic_launcher.png',
    'mipmap-xhdpi/logo.png',
    'mipmap-xxhdpi/ic_launcher.png',
    'mipmap-xxhdpi/logo.png',
    'mipmap-xxxhdpi/ic_launcher.png',
)

mac_res = (
    'AppIcon.appiconset',
)

ios_res = (
    'AppIcon.appiconset',
    'LaunchImage.imageset',
)

def switch_android_res():
    """Switch anroid resources"""
    for item in android_res:
        dest_file = os.path.join(android_folder, item)
        if not os.path.exists(dest_file):
            print('[ERROR]: file not found', dest_file)
        source_file = os.path.join(android_folder, item.replace('.png', '%s.png' % project_name))
        if not os.path.exists(source_file):
            print('[ERROR]: file not found', source_file)
        os.unlink(dest_file)
        shutil.copyfile(source_file, dest_file)
        #print(source_file, '->', dest_file)
    manifest_fname = 'AndroidManifest.xml'
    manifest_folder = os.path.split(android_folder)[0]
    dest_file = os.path.join(manifest_folder, manifest_fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(manifest_folder, manifest_fname.replace('.xml', '%s.xml' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

    gradle_fname = 'build.gradle'
    main_folder = os.path.split(manifest_folder)[0]
    src_folder = os.path.split(main_folder)[0]
    root_folder = os.path.split(src_folder)[0]

    dest_file = os.path.join(src_folder, gradle_fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(src_folder, gradle_fname + project_name)
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

    google_services_fname = 'google-services.json'
    dest_file = os.path.join(src_folder, google_services_fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(src_folder, google_services_fname.replace('.json', '%s.json' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

    key_properties = 'key.properties'
    dest_file = os.path.join(root_folder, key_properties)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(root_folder, key_properties.replace('.properties', '%s.properties' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)


def switch_mac_res():
    """Switch mac resources"""
    for item in mac_res:
        dest_file = os.path.join(mac_folder, item)
        if not os.path.exists(dest_file):
            print('[ERROR]: file not found', dest_file)
        source_file = os.path.join(mac_folder, '%s%s' % (item, project_name))
        if not os.path.exists(source_file):
            print('[ERROR]: file not found', source_file)
        shutil.rmtree(dest_file)
        shutil.copytree(source_file, dest_file)
        #print(source_file, '->', dest_file)

def switch_ios_res():
    """Switch mac resources"""
    for item in ios_res:
        dest_file = os.path.join(ios_folder, item)
        if not os.path.exists(dest_file):
            print('[ERROR]: file not found', dest_file)
        source_file = os.path.join(ios_folder, '%s%s' % (item, project_name))
        if not os.path.exists(source_file):
            print('[ERROR]: file not found', source_file)
        shutil.rmtree(dest_file)
        shutil.copytree(source_file, dest_file)
        #print(source_file, '->', dest_file)

    runner_folder = os.path.split(ios_folder)[0]

    google_services_fname = 'GoogleService-Info.plist'
    dest_file = os.path.join(runner_folder, google_services_fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(runner_folder, google_services_fname.replace('.plist', '%s.plist' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

    info_plist_fname = 'Info.plist'
    dest_file = os.path.join(runner_folder, info_plist_fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(runner_folder, info_plist_fname.replace('.plist', '%s.plist' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

def switch_constants():
    """Switch constants file"""
    folder = 'lib'
    fname = 'constants.dart'
    dest_file = os.path.join(folder, fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(folder, fname.replace('.dart', '%s.dart' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)

    # Assets folder
    folder = 'assets'
    for fname in (
        'app_icons/appstore.png',
        'app_icons/playstore.png',
        'misc/icon.png',
    ):
        dest_file = os.path.join(folder, fname)
        if not os.path.exists(dest_file):
            print('[ERROR]: file not found', dest_file)
        source_file = os.path.join(folder, fname.replace('.png', '%s.png' % project_name))
        if not os.path.exists(source_file):
            print('[ERROR]: file not found', source_file)
        os.unlink(dest_file)
        shutil.copyfile(source_file, dest_file)

    fname = 'svg/bp_header_login.svg'
    dest_file = os.path.join(folder, fname)
    if not os.path.exists(dest_file):
        print('[ERROR]: file not found', dest_file)
    source_file = os.path.join(folder, fname.replace('.svg', '%s.svg' % project_name))
    if not os.path.exists(source_file):
        print('[ERROR]: file not found', source_file)
    os.unlink(dest_file)
    shutil.copyfile(source_file, dest_file)



switch_android_res()
switch_mac_res()
switch_ios_res()
switch_constants()
