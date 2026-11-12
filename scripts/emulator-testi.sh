#!/usr/bin/env bash
# Emülatörde çalışır: APK'yı kurar, açar, dokunuşlarla oynar, ekran görüntüsü ve ölçüm alır.
set -u
mkdir -p out
P=com.terlikgalaksisi.oyun
adb wait-for-device
adb shell settings put global hide_error_dialogs 1
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1
adb shell input keyevent KEYCODE_HOME
sleep 40   # emülatör ve başlatıcı otursun
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
# Android'in "tam ekran" bilgilendirmesini kapat
tap $((W*64/100)) $((H*49/100)) 1
tap $((W/2)) $((H/2)) 2; adb exec-out screencap -p > out/03-menu.png
# hikâye ve haritayı geç: GEÇ düğmesi, Enter ve ortaya dokunma karışık
for i in $(seq 1 90); do
  tap $((W*81/100)) $((H*6/100)) 0.5
  adb shell input keyevent 66; sleep 0.4
  adb shell input keyevent 8; sleep 0.4
  [ $((i % 6)) -eq 0 ] && tap $((W/2)) $((H/2)) 1
  [ $i -eq 10 ] && adb exec-out screencap -p > out/04-sonra.png
  [ $i -eq 40 ] && adb exec-out screencap -p > out/05-oyun-oncesi.png
  [ $i -eq 80 ] && adb exec-out screencap -p > out/06-oyun.png
done
sleep 2
# haritadan bölümü başlat: ortaya dokun (kalkış), girişi geç
for i in $(seq 1 45); do
  tap $((W/2)) $((H/2)) 1
  tap $((W*81/100)) $((H*6/100)) 0.5
  adb shell input keyevent 66; sleep 0.5
  [ $i -eq 8 ] && adb exec-out screencap -p > out/06b-bolum-girisi.png
done
sleep 5; adb exec-out screencap -p > out/06-oyun.png
# oyun içinde joystick: basılı tutup sürükle
for i in 1 2 3; do adb shell input swipe $((W/4)) $((H*2/3)) $((W/4+300)) $((H/2)) 700; adb shell input swipe $((W/4)) $((H*2/3)) $((W/4-150)) $((H*2/3)) 700; done
adb exec-out screencap -p > out/07-oyun2.png
adb shell dumpsys gfxinfo $P reset >/dev/null
for i in $(seq 1 10); do adb shell input swipe $((W/4)) $((H*2/3)) $((W/4+250)) $((H/2-80)) 800; adb shell input swipe $((W/4+250)) $((H/2)) $((W/4-100)) $((H*2/3)) 800; done
adb exec-out screencap -p > out/08-oyun3.png
adb shell dumpsys gfxinfo $P | tee out/gfxinfo.txt | grep -E "Total frames|Janky|percentile|Number (Missed|High)" || true
adb shell dumpsys window | grep -iE "mCurrentFocus|mSystemBarsAppearance|isFullscreen|statusBar.*(isVisible|visible)" | head -8 | tee out/pencere.txt
adb shell dumpsys activity activities | grep -iE "requestedOrientation|mLastReportedConfiguration|screenOrientation" | head -5 | tee out/yon.txt
adb shell pidof $P | tee out/pid.txt
adb shell dumpsys meminfo $P | grep -E "TOTAL|Native Heap|Java Heap" | head -4 | tee out/bellek.txt
adb logcat -d > out/logcat-tam.txt
grep -E "AndroidRuntime|FATAL|ANR in|Process .* has died|CONSOLE|chromium.*(Error|error)|Uncaught" out/logcat-tam.txt | head -40 | tee out/hatalar.txt
echo "BITTI"
# yeniden calistir 1794492734
