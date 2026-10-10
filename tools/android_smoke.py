"""Android install/launch/background/Back/relaunch smoke, not full gameplay acceptance."""
import pathlib
import subprocess
import sys
import time
from android_ui import immersive_confirm_center, launcher_anr_close_center

PACKAGE = "com.binhdoantihon.game"
APK = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/binh-doan-ti-hon-debug.apk")
OUT = pathlib.Path("build/android-smoke")
OUT.mkdir(parents=True, exist_ok=True)

def adb(*args, binary=False):
    return subprocess.check_output(["adb", *args], timeout=60, text=not binary)

def alive(label):
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        try:
            pid = adb("shell", "pidof", PACKAGE).strip()
            if pid:
                time.sleep(2)
                if adb("shell", "pidof", PACKAGE).strip() == pid:
                    print(f"PASS: {label}", flush=True)
                    return
        except subprocess.CalledProcessError:
            pass
        time.sleep(0.5)
    raise RuntimeError(f"Android process absent/unstable: {label}")

def launch():
    adb("shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")

def profile():
    import json
    text = adb("shell", "run-as", PACKAGE, "cat", "files/profile.json")
    wrapper = json.loads(text)
    import hashlib
    assert hashlib.sha256(wrapper["payload"].encode()).hexdigest() == wrapper["checksum"]
    return json.loads(wrapper["payload"])

adb("wait-for-device")
assert adb("get-serialno").strip().startswith("emulator-"), "This coordinate smoke is for a disposable CI emulator"
adb("shell", "wm", "size", "480x854")
adb("shell", "wm", "density", "160")
adb("install", "-r", str(APK))
adb("logcat", "-c")
previous_confirmation = adb("shell", "settings", "get", "secure", "immersive_mode_confirmations").strip()
# AOSP CTS uses this setting in disposable fixtures to prevent fullscreen education blocking input.
adb("shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed")
try:
    adb("shell", "uiautomator", "dump", "/sdcard/bdth-ui.xml")
    startup_xml = adb("shell", "cat", "/sdcard/bdth-ui.xml")
    (OUT / "startup-ui.xml").write_text(startup_xml)
    launcher_close = launcher_anr_close_center(startup_xml)
    if launcher_close:
        adb("shell", "input", "tap", str(launcher_close[0]), str(launcher_close[1]))
        time.sleep(2)
        print("FIXTURE: closed observed Pixel Launcher ANR; game ANR is not dismissed", flush=True)
    launch()
    alive("launch")
    # Wait for the startup menu to create a valid durable profile.
    deadline = time.monotonic() + 20
    while True:
        try:
            saved = profile()
            break
        except (subprocess.CalledProcessError, ValueError):
            if time.monotonic() >= deadline:
                raise
            time.sleep(0.5)
    # First fullscreen launch has a real Android overlay that consumes touches.
    adb("shell", "uiautomator", "dump", "/sdcard/bdth-ui.xml")
    system_xml = adb("shell", "cat", "/sdcard/bdth-ui.xml")
    (OUT / "main-ui.xml").write_text(system_xml)
    center = immersive_confirm_center(system_xml)
    if center is not None:
        adb("shell", "input", "tap", str(center[0]), str(center[1]))
        time.sleep(2)
        print("PASS: Android fullscreen confirmation dismissed", flush=True)
    (OUT / "main.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
    def toggle_music(expected):
        adb("shell", "input", "tap", "240", "181")
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            changed = profile()
            if changed["settings"]["music"] == expected:
                print("PASS: real touch changed durable music setting", flush=True)
                return changed
            time.sleep(0.25)
        (OUT / "touch-failure.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
        raise RuntimeError("Real UI touch did not change the saved setting; frozen UI or coordinate mismatch")
    # Fixed 480x854 fixture matches rendered UI; a frozen process cannot pass this assertion.
    adb("shell", "input", "tap", "240", "618")
    time.sleep(1)
    saved = toggle_music(not saved["settings"]["music"])
    adb("shell", "input", "keyevent", "KEYCODE_HOME")
    alive("background")
    launch()
    alive("return from background")
    saved = toggle_music(not saved["settings"]["music"])
    adb("shell", "input", "keyevent", "KEYCODE_BACK")
    alive("Back from menu")
    adb("shell", "input", "tap", "240", "618")
    time.sleep(1)
    saved = toggle_music(not saved["settings"]["music"])
    adb("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(1)
    adb("shell", "input", "tap", "240", "453")  # Continue stage 1
    time.sleep(1)
    adb("shell", "input", "tap", "365", "803")  # Sticky Start button
    time.sleep(2)
    adb("shell", "input", "tap", "240", "480")  # Valid player-base deployment
    deadline = time.monotonic() + 10
    while "deploy" not in profile()["tutorial"]:
        if time.monotonic() >= deadline:
            (OUT / "deploy-failure.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
            raise RuntimeError("Actual Android deployment did not complete tutorial action")
        time.sleep(0.25)
    adb("shell", "input", "tap", "240", "813")  # Bomb skill selection
    adb("shell", "input", "tap", "240", "480")
    time.sleep(1)
    (OUT / "battle.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
    saved = profile()
    print("PASS: actual Android touch deployed a unit and persisted tutorial action", flush=True)
    adb("shell", "input", "keyevent", "KEYCODE_HOME")
    launch()
    alive("battle background and return")
    adb("shell", "input", "keyevent", "KEYCODE_BACK")
    (OUT / "battle-back.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
    adb("shell", "am", "force-stop", PACKAGE)
    launch()
    alive("relaunch after process stop")
    assert profile() == saved, "Profile differs after relaunch"
    log = adb("logcat", "-d")
    assert "FATAL EXCEPTION" not in log and "Fatal signal" not in log, "Android runtime crash"
    assert "SCRIPT ERROR:" not in log, "Godot script error"
    print("ANDROID SMOKE PASS: install, launch, Home/return, Back, durable profile", flush=True)
finally:
    (OUT / "logcat.txt").write_text(adb("logcat", "-d"))
    adb("shell", "wm", "size", "reset")
    adb("shell", "wm", "density", "reset")
    if previous_confirmation == "null":
        adb("shell", "settings", "delete", "secure", "immersive_mode_confirmations")
    else:
        adb("shell", "settings", "put", "secure", "immersive_mode_confirmations", previous_confirmation)
