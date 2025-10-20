#!/usr/bin/env python3

import os
import sys
import threading
import subprocess
import shlex
import shutil
from urllib.parse import urlparse

try:
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox
    from tkinter.scrolledtext import ScrolledText
except Exception:
    brew = shutil.which("brew")
    if sys.platform == "darwin" and brew:
        ver = f"{sys.version_info.major}.{sys.version_info.minor}"
        pkg = f"python-tk@{ver}"
        print("Tkinter not available.")
        _auto_install = os.environ.get("HLS_DOWNLOADER_AUTO_INSTALL", "0").lower() in ("1", "true", "yes") or any(
            a in ("--auto-install", "--yes", "-y") for a in sys.argv
        )
        if _auto_install:
            print(f"Auto-install enabled: installing '{pkg}' via Homebrew...")
            code = subprocess.call([brew, "install", pkg])
            if code == 0:
                try:
                    import tkinter as tk
                    from tkinter import ttk, filedialog, messagebox
                    from tkinter.scrolledtext import ScrolledText
                except Exception:
                    print("Installation finished but tkinter still isn't importable.", file=sys.stderr)
                    sys.exit(1)
            else:
                print(f"Homebrew install failed (exit code {code}). Please run: brew install {pkg}", file=sys.stderr)
                sys.exit(1)
        else:
            try:
                ans = input(f"Install {pkg} via Homebrew now? [y/N]: ").strip().lower()
            except Exception:
                ans = "n"
            if ans == "y":
                code = subprocess.call([brew, "install", pkg])
                if code == 0:
                    try:
                        import tkinter as tk
                        from tkinter import ttk, filedialog, messagebox
                        from tkinter.scrolledtext import ScrolledText
                    except Exception:
                        print("Installation finished but tkinter still isn't importable.", file=sys.stderr)
                        sys.exit(1)
                else:
                    print(f"Homebrew install failed (exit code {code}). Please run: brew install {pkg}", file=sys.stderr)
                    sys.exit(1)

    print("Error: Tkinter not available. On macOS, install Python from python.org or install tkinter via Homebrew.", file=sys.stderr)
    sys.exit(1)


AUTO_INSTALL = os.environ.get("HLS_DOWNLOADER_AUTO_INSTALL", "0").lower() in ("1", "true", "yes") or any(
    a in ("--auto-install", "--yes", "-y") for a in sys.argv
)


def which(bin_name: str) -> str | None:
    return shutil.which(bin_name)


def ensure_prereqs(interactive: bool = True, auto_install: bool = False) -> None:
    missing = []
    for tool in ("ffmpeg", "ffprobe"):
        if which(tool) is None:
            missing.append(tool)

    if not missing:
        return

    brew = which("brew")
    if brew:
        if auto_install:
            cmd = [brew, "install", "ffmpeg"]
            code = subprocess.call(cmd)
            if code != 0:
                print("Homebrew install failed (exit code", code, "). Please install ffmpeg manually:")
                print("  brew install ffmpeg")
                sys.exit(1)
            for tool in ("ffmpeg", "ffprobe"):
                if which(tool) is None:
                    print(f"{tool} still missing after install. Please install it manually.")
                    sys.exit(1)
            return
        elif interactive:
            try:
                ans = input("Install ffmpeg via Homebrew now? [y/N]: ").strip().lower()
            except Exception:
                ans = "n"
            if ans == "y":
                cmd = [brew, "install", "ffmpeg"]
                code = subprocess.call(cmd)
                if code != 0:
                    print("Homebrew install failed (exit code", code, "). Please install ffmpeg manually:")
                    print("  brew install ffmpeg")
                    sys.exit(1)
                for tool in ("ffmpeg", "ffprobe"):
                    if which(tool) is None:
                        print(f"{tool} still missing after install. Please install it manually.")
                        sys.exit(1)
                return

    print("Required tools missing: " + ", ".join(missing), file=sys.stderr)
    if not brew:
        print("Homebrew not found. On macOS, install Homebrew first: https://brew.sh/", file=sys.stderr)
        print("Then run: brew install ffmpeg", file=sys.stderr)
    else:
        print("Install ffmpeg with: brew install ffmpeg", file=sys.stderr)
    raise SystemExit(1)


def guess_filename_from_url(url: str, ext: str = "mp4") -> str:
    try:
        path = urlparse(url).path
        base = os.path.basename(path)
        if base.lower().endswith(".m3u8"):
            base = base[:-5]
        if not base:
            base = "video"
        return f"{base}.{ext}"
    except Exception:
        return f"video.{ext}"


def human_time_ms(ms: int) -> str:
    secs = ms // 1000
    h = secs // 3600
    m = (secs % 3600) // 60
    s = secs % 60
    return f"{h:02d}:{m:02d}:{s:02d}"


class DownloaderApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Transito — HLS Downloader (v0.1.0)")
        self.root.geometry("700x500")

        self.url_var = tk.StringVar()
        self.out_var = tk.StringVar()
        self.status_var = tk.StringVar(value="Ready")
        self.progress_total_ms = None

        self._build_ui()

    def _build_ui(self):
        pad = {"padx": 10, "pady": 8}

        url_lbl = ttk.Label(self.root, text="M3U8 URL:")
        url_lbl.grid(row=0, column=0, sticky="w", **pad)
        url_entry = ttk.Entry(self.root, textvariable=self.url_var)
        url_entry.grid(row=0, column=1, columnspan=2, sticky="ew", **pad)

        out_lbl = ttk.Label(self.root, text="Save to:")
        out_lbl.grid(row=1, column=0, sticky="w", **pad)
        out_entry = ttk.Entry(self.root, textvariable=self.out_var)
        out_entry.grid(row=1, column=1, sticky="ew", **pad)
        browse_btn = ttk.Button(self.root, text="Choose…", command=self.choose_output)
        browse_btn.grid(row=1, column=2, sticky="e", **pad)

        self.dl_btn = ttk.Button(self.root, text="Download", command=self.start_download)
        self.dl_btn.grid(row=2, column=1, sticky="e", **pad)
        self.open_btn = ttk.Button(self.root, text="Open Folder", command=self.open_folder, state=tk.DISABLED)
        self.open_btn.grid(row=2, column=2, sticky="e", **pad)

        self.pb = ttk.Progressbar(self.root, orient="horizontal", mode="determinate")
        self.pb.grid(row=3, column=0, columnspan=3, sticky="ew", **pad)
        self.status = ttk.Label(self.root, textvariable=self.status_var)
        self.status.grid(row=4, column=0, columnspan=3, sticky="w", **pad)

        self.log = ScrolledText(self.root, height=18, wrap=tk.WORD)
        self.log.grid(row=5, column=0, columnspan=3, sticky="nsew", padx=10, pady=(0,10))

        self.root.columnconfigure(1, weight=1)
        self.root.rowconfigure(5, weight=1)

    def choose_output(self):
        url = self.url_var.get().strip()
        default_name = guess_filename_from_url(url or "video.m3u8")
        initial_dir = os.path.expanduser("~/Downloads")
        path = filedialog.asksaveasfilename(
            title="Save As",
            defaultextension=".mp4",
            initialfile=default_name,
            initialdir=initial_dir,
            filetypes=[("MP4 Video", ".mp4"), ("Matroska Video", ".mkv"), ("All Files", "*.*")],
        )
        if path:
            self.out_var.set(path)

    def start_download(self):
        url = self.url_var.get().strip()
        if not url:
            messagebox.showerror("Missing URL", "Please paste a .m3u8 URL.")
            return

        try:
            ensure_prereqs(interactive=True)
        except SystemExit:
            messagebox.showerror("Missing prerequisites", "ffmpeg/ffprobe are required. See terminal for instructions.")
            return

        out_path = self.out_var.get().strip()
        if not out_path:
            guessed = guess_filename_from_url(url, "mp4")
            out_path = os.path.join(os.path.expanduser("~/Downloads"), guessed)
            self.out_var.set(out_path)

        os.makedirs(os.path.dirname(out_path), exist_ok=True)

        self.log.delete("1.0", tk.END)
        self.status_var.set("Probing duration…")
        self.pb.configure(mode="determinate", value=0, maximum=100)
        self.dl_btn.configure(state=tk.DISABLED)
        self.open_btn.configure(state=tk.DISABLED)

        threading.Thread(target=self._run_download, args=(url, out_path), daemon=True).start()

    def open_folder(self):
        out_path = self.out_var.get().strip()
        if not out_path:
            return
        folder = os.path.dirname(os.path.abspath(out_path))
        if sys.platform.startswith("darwin"):
            subprocess.call(["open", folder])
        elif os.name == "nt":
            os.startfile(folder)
        else:
            subprocess.call(["xdg-open", folder])

    def _probe_duration_ms(self, url: str) -> int | None:
        if which("ffprobe") is None:
            return None
        try:
            cmd = [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1",
                url,
            ]
            out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True).strip()
            if out:
                dur_sec = float(out)
                if dur_sec > 0:
                    return int(dur_sec * 1000)
        except Exception:
            pass
        return None

    def _run_download(self, url: str, out_path: str):
        self.progress_total_ms = self._probe_duration_ms(url)
        if self.progress_total_ms:
            self._ui(lambda: self.status_var.set(f"Duration: {human_time_ms(self.progress_total_ms)}"))
        else:
            self._ui(lambda: self.status_var.set("Duration unknown — showing approximate progress."))

        cmd = [
            "ffmpeg",
            "-hide_banner", "-loglevel", "warning",
            "-nostdin",
            "-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30",
            "-i", url,
            "-map", "0",
            "-c", "copy",
            "-bsf:a", "aac_adtstoasc",
            "-movflags", "+faststart",
            "-progress", "pipe:1",
            out_path,
        ]

        self._ui(lambda: self._append_log("Running:\n  " + " ".join(shlex.quote(x) for x in cmd) + "\n\n"))

        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )
        except FileNotFoundError:
            self._ui(lambda: messagebox.showerror("ffmpeg not found", "Install ffmpeg and try again."))
            self._ui(self._reset_buttons)
            return

        threading.Thread(target=self._read_progress, args=(proc,), daemon=True).start()
        threading.Thread(target=self._read_stderr, args=(proc,), daemon=True).start()

        code = proc.wait()
        if code == 0 and os.path.exists(out_path):
            self._ui(lambda: self.status_var.set(f"✅ Done: {out_path}"))
            self._ui(lambda: self.pb.configure(value=100))
            self._ui(lambda: self.open_btn.configure(state=tk.NORMAL))
        else:
            self._ui(lambda: self.status_var.set(f"❌ ffmpeg exited with code {code}"))
        self._ui(self._reset_buttons)

    def _read_progress(self, proc: subprocess.Popen):
        total = self.progress_total_ms or 0
        if proc.stdout is None:
            return
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            if line.startswith("out_time_ms="):
                try:
                    out_ms = int(line.split("=", 1)[1]) // 1000
                    if total > 0:
                        pct = max(0, min(100, (out_ms / total) * 100))
                        self._ui(lambda v=pct: self.pb.configure(value=v))
                        self._ui(lambda v=out_ms: self.status_var.set(f"Downloading… {human_time_ms(v)} / {human_time_ms(total)}"))
                    else:
                        self._ui(lambda: self.pb.configure(mode="indeterminate"))
                        self._ui(self.pb.start)
                except Exception:
                    pass
            elif line.startswith("progress=") and line.endswith("end"):
                if total > 0:
                    self._ui(lambda: self.pb.configure(value=100))

    def _read_stderr(self, proc: subprocess.Popen):
        if proc.stderr is None:
            return
        for line in proc.stderr:
            self._ui(lambda s=line: self._append_log(s))

    def _append_log(self, text: str):
        self.log.insert(tk.END, text)
        self.log.see(tk.END)

    def _reset_buttons(self):
        self.dl_btn.configure(state=tk.NORMAL)

    def _ui(self, fn):
        self.root.after(0, fn)


def main():
    root = tk.Tk()
    try:
        if sys.platform == "darwin":
            root.tk.call("tk", "scaling", 1.2)
    except Exception:
        pass
    app = DownloaderApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
