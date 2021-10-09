#!/usr/bin/env python3
import os
import sys

project_name = None
if len(sys.argv) > 1:
    project_name = sys.argv[1]

if not project_name:
    print('[ERROR]: project_name not set')
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

def switch_andoid_res():
    for item in android_res:
        pass