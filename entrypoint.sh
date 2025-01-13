#!/bin/bash

tightvncserver :1
DISPLAY=:1 /opt/android-sdk/emulator/emulator -avd Pixel_4_API_30 -gpu "$1" swiftshader_indirect