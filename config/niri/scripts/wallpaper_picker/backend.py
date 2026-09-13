"""
NyxNiri Wallpaper Picker Backend Engine
Executes wallpaper switching for static images and live video wallpapers via DMS IPC.
"""

import os
import sys
import subprocess


def _clear_mpvpaper():
    """Cleanly terminate running mpvpaper instances and wait for process exit."""
    try:
        subprocess.run(["pkill", "-x", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        for _ in range(10):
            res = subprocess.run(["pgrep", "-x", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
            if res.returncode != 0:
                break
            import time
            time.sleep(0.05)
    except Exception:
        pass


def apply_static_wallpaper(path: str) -> bool:
    """Apply static wallpaper via DMS IPC, clear mpvpaper video assignments."""
    try:
        # 1. Terminate any running mpvpaper instances with process wait
        _clear_mpvpaper()

        # 2. Apply static wallpaper via DMS IPC
        subprocess.run(
            ["dms", "ipc", "call", "wallpaper", "set", path],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5, check=False
        )
        return True
    except Exception as e:
        print(f"Error applying static wallpaper: {e}", file=sys.stderr)
        return False


def apply_dynamic_wallpaper(video_path: str, thumb_path: str = None) -> bool:
    """Apply dynamic video wallpaper via mpvpaper."""
    try:
        # 1. Terminate existing mpvpaper instances and wait for exit
        _clear_mpvpaper()

        # 2. If thumbnail is available, set it as static wallpaper first for instant visual feedback
        if thumb_path and os.path.isfile(thumb_path):
            subprocess.run(
                ["dms", "ipc", "call", "wallpaper", "set", thumb_path],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
            )

        # 3. Launch mpvpaper with isolated config
        mpv_opts = "config=no load-scripts=no loop-file=inf panscan=1.0 no-audio hwdec=auto"
        cmd = ["mpvpaper", "--auto-pause", "-o", mpv_opts, "*", video_path]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        print(f"Error applying live wallpaper: {e}", file=sys.stderr)
        return False


def apply_wallpaper(item) -> bool:
    """Polymorphic wallpaper application dispatcher."""
    if item.is_video:
        return apply_dynamic_wallpaper(item.path, item.thumb_path)
    else:
        return apply_static_wallpaper(item.path)
