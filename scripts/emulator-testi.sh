#!/usr/bin/env bash
# Emülatörde çalışır: APK'yı kurar, açar, dokunuşlarla oynar, ekran görüntüsü ve ölçüm alır.
set -u
mkdir -p out
P=com.terlikgalaksisi.oyun
adb wait-for-device
adb shell settings put global window_animation_scale 0; adb shell settings put global transition_animation_scale 0; adb shell settings put global animator_duration_scale 0
adb logcat -c
adb shell settings put system accelerometer_rotation 0
adb shell cmd window user-rotation lock 1 || adb shell settings put system user_rotation 1
sleep 2
adb install -r TerlikGalaksisi.apk | tee out/kurulum.txt
adb shell wm size | tee out/ekran.txt
adb shell dumpsys window displays | grep -E 'mCurrentRotation|rotation=' | head -3 | tee -a out/ekran.txt
adb shell am start -W -n $P/.MainActivity | tee out/baslat.txt
sleep 6; adb exec-out screencap -p > out/01-logo.png
sleep 4; adb exec-out screencap -p > out/02-logo-son.png
# menü / hikaye: ekrana dokun, birkaç kez ilerle
sleep 1
W=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f1); H=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f2)
if [ "$H" -gt "$W" ]; then T=$W; W=$H; H=$T; fi
echo "ekran(yatay) $W x $H" | tee -a out/ekran.txt
adb exec-out screencap -p > out/00-acilis-ekran.png
tap(){ adb shell input tap $1 $2; sleep ${3:-1}; }
tap $((W/2)) $((H/2)) 2; adb exec-out screencap -p > out/03-menu.png
for i in 1 2 3 4 5 6 7 8; do tap $((W/2)) $((H*3/4)) 1; done
adb exec-out screencap -p > out/04-sonra.png
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do tap $((W/2)) $((H*3/4)) 1; done
sleep 3; adb exec-out screencap -p > out/05-oyun-oncesi.png
# oyun içinde joystick: basılı tut ve sürükle
for i in 1 2 3; do adb shell input swipe $((W/4)) $((H*2/3)) $((W/4+250)) $((H/2)) 600; adb shell input swipe $((W/4)) $((H*2/3)) $((W/4-100)) $((H*2/3)) 600; done
adb exec-out screencap -p > out/06-oyun.png
adb shell dumpsys gfxinfo $P reset >/dev/null
for i in $(seq 1 12); do adb shell input swipe $((W/4)) $((H*2/3)) $((W/4+200)) $((H/2-80)) 700; adb shell input swipe $((W/4+200)) $((H/2)) $((W/4-100)) $((H*2/3)) 700; done
adb exec-out screencap -p > out/07-oyun2.png
adb shell dumpsys gfxinfo $P | tee out/gfxinfo.txt | grep -E "Total frames|Janky|percentile|Number (Missed|High)" || true
adb shell dumpsys window | grep -iE "mCurrentFocus|mSystemBarsAppearance|isFullscreen|statusBar.*(isVisible|visible)" | head -8 | tee out/pencere.txt
adb shell dumpsys activity activities | grep -iE "requestedOrientation|mLastReportedConfiguration|screenOrientation" | head -5 | tee out/yon.txt
adb shell pidof $P | tee out/pid.txt
adb shell dumpsys meminfo $P | grep -E "TOTAL|Native Heap|Java Heap" | head -4 | tee out/bellek.txt
adb logcat -d > out/logcat-tam.txt
grep -E "AndroidRuntime|FATAL|ANR in|Process .* has died|CONSOLE|chromium.*(Error|error)|Uncaught" out/logcat-tam.txt | head -40 | tee out/hatalar.txt
echo "BITTI"
