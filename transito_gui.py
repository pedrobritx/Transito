#!/usr/bin/env python3

import csv
import os
import sys
import threading
import subprocess
import shlex
import shutil
import urllib.request
from urllib.parse import urljoin, urlparse

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


def show_dependency_dialog(missing_tools: list, root_window=None) -> bool:
    """Show a user-friendly dialog for missing dependencies with install options."""
    if not missing_tools:
        return True
    
    # Create a dialog window
    dialog = tk.Toplevel(root_window) if root_window else tk.Tk()
    dialog.title("Missing Dependencies")
    dialog.geometry("500x400")
    dialog.resizable(False, False)
    
    # Center the dialog
    if root_window:
        dialog.transient(root_window)
        dialog.grab_set()
    
    # Main frame
    main_frame = ttk.Frame(dialog, padding="20")
    main_frame.pack(fill=tk.BOTH, expand=True)
    
    # Title
    title_label = ttk.Label(main_frame, text="Missing Required Tools", font=("Arial", 16, "bold"))
    title_label.pack(pady=(0, 10))
    
    # Missing tools list
    tools_text = "\n".join(f"• {tool}" for tool in missing_tools)
    tools_label = ttk.Label(main_frame, text=f"Transito needs these tools:\n\n{tools_text}", 
                           justify=tk.LEFT, font=("Arial", 12))
    tools_label.pack(pady=(0, 20))
    
    # Install instructions
    instructions = """Installation Options:

1. Install via Homebrew (Recommended):
   • Open Terminal
   • Run: brew install ffmpeg
   • Restart Transito

2. Install from official website:
   • Visit: https://ffmpeg.org/download.html
   • Download and install ffmpeg
   • Add to your PATH

3. Use Transito's auto-installer:
   • Click 'Install Now' below
   • Follow the prompts"""
    
    instructions_label = ttk.Label(main_frame, text=instructions, justify=tk.LEFT, 
                                  font=("Arial", 10), foreground="gray")
    instructions_label.pack(pady=(0, 20))
    
    # Buttons frame
    buttons_frame = ttk.Frame(main_frame)
    buttons_frame.pack(fill=tk.X, pady=(0, 10))
    
    install_result = {"installed": False}
    
    def install_now():
        """Attempt to install ffmpeg via Homebrew."""
        brew = which("brew")
        if not brew:
            messagebox.showerror("Homebrew Not Found", 
                               "Homebrew is required for auto-installation.\n\n"
                               "Please install Homebrew first:\n"
                               "https://brew.sh/\n\n"
                               "Then run: brew install ffmpeg")
            return
        
        # Show progress dialog
        progress_dialog = tk.Toplevel(dialog)
        progress_dialog.title("Installing ffmpeg")
        progress_dialog.geometry("400x150")
        progress_dialog.resizable(False, False)
        progress_dialog.transient(dialog)
        progress_dialog.grab_set()
        
        progress_frame = ttk.Frame(progress_dialog, padding="20")
        progress_frame.pack(fill=tk.BOTH, expand=True)
        
        progress_label = ttk.Label(progress_frame, text="Installing ffmpeg via Homebrew...\nThis may take a few minutes.", 
                                 justify=tk.CENTER)
        progress_label.pack(pady=(0, 10))
        
        progress_bar = ttk.Progressbar(progress_frame, mode='indeterminate')
        progress_bar.pack(fill=tk.X, pady=(0, 10))
        progress_bar.start()
        
        def install_thread():
            try:
                cmd = [brew, "install", "ffmpeg"]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)  # 10 min timeout
                
                dialog.after(0, lambda: progress_dialog.destroy())
                
                if result.returncode == 0:
                    # Check if tools are now available
                    all_found = all(which(tool) for tool in missing_tools)
                    if all_found:
                        install_result["installed"] = True
                        dialog.after(0, lambda: messagebox.showinfo("Installation Complete", 
                                                                  "ffmpeg installed successfully!\n\n"
                                                                  "Please restart Transito to use the new installation."))
                        dialog.after(0, lambda: dialog.destroy())
                    else:
                        dialog.after(0, lambda: messagebox.showwarning("Installation Incomplete", 
                                                                      "ffmpeg was installed but some tools are still missing.\n\n"
                                                                      "Please restart your terminal and try again."))
                else:
                    error_msg = result.stderr or "Unknown error occurred"
                    dialog.after(0, lambda: messagebox.showerror("Installation Failed", 
                                                               f"Failed to install ffmpeg:\n\n{error_msg}\n\n"
                                                               "Please try installing manually:\n"
                                                               "brew install ffmpeg"))
            except subprocess.TimeoutExpired:
                dialog.after(0, lambda: progress_dialog.destroy())
                dialog.after(0, lambda: messagebox.showerror("Installation Timeout", 
                                                           "Installation took too long and was cancelled.\n\n"
                                                           "Please try installing manually:\n"
                                                           "brew install ffmpeg"))
            except Exception as e:
                dialog.after(0, lambda: progress_dialog.destroy())
                dialog.after(0, lambda: messagebox.showerror("Installation Error", 
                                                           f"An error occurred during installation:\n\n{str(e)}\n\n"
                                                           "Please try installing manually:\n"
                                                           "brew install ffmpeg"))
        
        threading.Thread(target=install_thread, daemon=True).start()
    
    def open_terminal():
        """Open Terminal with the install command."""
        cmd = "brew install ffmpeg"
        if sys.platform == "darwin":
            subprocess.run(["open", "-a", "Terminal"])
            # Try to copy command to clipboard
            try:
                subprocess.run(["pbcopy"], input=cmd, text=True)
                messagebox.showinfo("Command Copied", f"Command copied to clipboard:\n\n{cmd}\n\n"
                                                    "Paste it in Terminal and press Enter.")
            except:
                messagebox.showinfo("Manual Installation", f"Please run this command in Terminal:\n\n{cmd}")
        else:
            messagebox.showinfo("Manual Installation", f"Please run this command in Terminal:\n\n{cmd}")
    
    def open_website():
        """Open ffmpeg download website."""
        import webbrowser
        webbrowser.open("https://ffmpeg.org/download.html")
    
    # Buttons
    ttk.Button(buttons_frame, text="Install Now", command=install_now).pack(side=tk.LEFT, padx=(0, 10))
    ttk.Button(buttons_frame, text="Open Terminal", command=open_terminal).pack(side=tk.LEFT, padx=(0, 10))
    ttk.Button(buttons_frame, text="Download ffmpeg", command=open_website).pack(side=tk.LEFT, padx=(0, 10))
    ttk.Button(buttons_frame, text="Cancel", command=dialog.destroy).pack(side=tk.RIGHT)
    
    # Wait for dialog to close
    dialog.wait_window()
    
    return install_result["installed"]


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


def _parse_attribute_line(line: str) -> dict[str, str]:
    reader = csv.reader([line])
    attrs: dict[str, str] = {}
    for row in reader:
        for item in row:
            if "=" not in item:
                continue
            key, value = item.split("=", 1)
            value = value.strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            attrs[key.strip()] = value
    return attrs


def _safe_int(value: str | None) -> int | None:
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _safe_float(value: str | None) -> float | None:
    try:
        return float(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _parse_master_playlist(text: str) -> tuple[list[dict], dict[str, list[dict]]]:
    variants: list[dict] = []
    audio_groups: dict[str, list[dict]] = {}
    lines = [line.strip() for line in text.splitlines()]

    for idx, line in enumerate(lines):
        if line.startswith("#EXT-X-STREAM-INF"):
            attrs = _parse_attribute_line(line.split(":", 1)[1] if ":" in line else "")
            uri = None
            cursor = idx + 1
            while cursor < len(lines):
                candidate = lines[cursor].strip()
                cursor += 1
                if not candidate or candidate.startswith("#"):
                    continue
                uri = candidate
                break
            if not uri:
                continue

            width = height = None
            resolution = attrs.get("RESOLUTION")
            if resolution and "x" in resolution.lower():
                parts = resolution.lower().split("x", 1)
                if len(parts) == 2:
                    width = _safe_int(parts[0])
                    height = _safe_int(parts[1])

            variants.append(
                {
                    "uri": uri,
                    "width": width,
                    "height": height,
                    "bandwidth": _safe_int(attrs.get("BANDWIDTH")),
                    "frame_rate": _safe_float(attrs.get("FRAME-RATE")),
                    "audio": attrs.get("AUDIO"),
                    "raw": attrs,
                }
            )
        elif line.startswith("#EXT-X-MEDIA"):
            attrs = _parse_attribute_line(line.split(":", 1)[1] if ":" in line else "")
            if attrs.get("TYPE") != "AUDIO":
                continue
            group_id = attrs.get("GROUP-ID")
            uri = attrs.get("URI")
            if not group_id or not uri:
                continue
            entry = {
                "uri": uri,
                "name": attrs.get("NAME"),
                "default": attrs.get("DEFAULT", "NO").upper() == "YES",
                "language": attrs.get("LANGUAGE"),
            }
            audio_groups.setdefault(group_id, []).append(entry)

    return variants, audio_groups


def _pick_best_variant(variants: list[dict]) -> dict | None:
    if not variants:
        return None

    def sort_key(item: dict) -> tuple[int, int, int, float]:
        height = item.get("height") or 0
        width = item.get("width") or 0
        bandwidth = item.get("bandwidth") or 0
        frame_rate = item.get("frame_rate") or 0.0
        return (height, width, bandwidth, frame_rate)

    return max(variants, key=sort_key)


def prepare_hls_inputs(url: str, headers: dict | None = None) -> tuple[list[str], dict | None]:
    req_headers = {}
    if headers:
        if headers.get("User-Agent"):
            req_headers["User-Agent"] = headers["User-Agent"]
        if headers.get("Referer"):
            req_headers["Referer"] = headers["Referer"]

    try:
        request = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(request, timeout=15) as response:
            text = response.read().decode("utf-8", errors="ignore")
    except Exception:
        return [url], None

    if "#EXT-X-STREAM-INF" not in text:
        return [url], None

    variants, audio_groups = _parse_master_playlist(text)
    chosen = _pick_best_variant(variants)
    if not chosen:
        return [url], None

    video_url = urljoin(url, chosen["uri"])
    audio_url = None
    audio_group = chosen.get("audio")
    if audio_group and audio_group in audio_groups:
        candidates = audio_groups[audio_group]
        preferred = next((entry for entry in candidates if entry.get("default")), None)
        selected = preferred or (candidates[0] if candidates else None)
        if selected and selected.get("uri"):
            audio_url = urljoin(url, selected["uri"])

    info = {
        "width": chosen.get("width"),
        "height": chosen.get("height"),
        "bandwidth": chosen.get("bandwidth"),
        "frame_rate": chosen.get("frame_rate"),
        "audio_group": audio_group,
        "video_url": video_url,
        "audio_url": audio_url,
    }

    inputs = [video_url]
    if audio_url and audio_url not in inputs:
        inputs.append(audio_url)

    return inputs, info


def build_ffmpeg_command(inputs: list[str], output: str, headers: dict | None = None) -> list[str]:
    cmd: list[str] = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-nostdin"]

    header_value = None
    if headers:
        header_pairs = []
        if headers.get("User-Agent"):
            header_pairs.append(f"User-Agent: {headers['User-Agent']}")
        if headers.get("Referer"):
            header_pairs.append(f"Referer: {headers['Referer']}")
        if header_pairs:
            header_value = "\\r\\n".join(header_pairs) + "\\r\\n"

    for input_url in inputs:
        cmd.extend(["-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30"])
        if header_value:
            cmd.extend(["-headers", header_value])
        cmd.extend(["-i", input_url])

    cmd.extend(["-map", "0:v?"])
    if len(inputs) > 1:
        cmd.extend(["-map", "1:a?"])
    else:
        cmd.extend(["-map", "0:a?"])

    cmd.extend([
        "-c", "copy",
        "-bsf:a", "aac_adtstoasc",
        "-movflags", "+faststart",
        output,
    ])

    return cmd


def human_time_ms(ms: int) -> str:
    secs = ms // 1000
    h = secs // 3600
    m = (secs % 3600) // 60
    s = secs % 60
    return f"{h:02d}:{m:02d}:{s:02d}"


class DownloaderApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Transito — HLS Downloader (v0.2.0)")
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

        # Check for missing dependencies and show dialog if needed
        missing_tools = []
        for tool in ("ffmpeg", "ffprobe"):
            if which(tool) is None:
                missing_tools.append(tool)
        
        if missing_tools:
            if not show_dependency_dialog(missing_tools, self.root):
                return  # User cancelled or installation failed
            # Re-check after potential installation
            missing_tools = []
            for tool in ("ffmpeg", "ffprobe"):
                if which(tool) is None:
                    missing_tools.append(tool)
            if missing_tools:
                messagebox.showerror("Missing Dependencies", 
                                   f"Still missing: {', '.join(missing_tools)}\n\n"
                                   "Please install them and restart Transito.")
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
        inputs, variant_info = prepare_hls_inputs(url)
        primary_input = inputs[0] if inputs else url

        duration_ms = self._probe_duration_ms(primary_input)
        if duration_ms is None and primary_input != url:
            duration_ms = self._probe_duration_ms(url)
        self.progress_total_ms = duration_ms

        if self.progress_total_ms:
            self._ui(lambda: self.status_var.set(f"Duration: {human_time_ms(self.progress_total_ms)}"))
        else:
            self._ui(lambda: self.status_var.set("Duration unknown — showing approximate progress."))

        if variant_info:
            stream_bits = []
            if variant_info.get("width") and variant_info.get("height"):
                stream_bits.append(f"{variant_info['width']}x{variant_info['height']}")
            if variant_info.get("bandwidth"):
                stream_bits.append(f"{variant_info['bandwidth'] / 1000:.0f} kbps")
            if variant_info.get("frame_rate"):
                stream_bits.append(f"{variant_info['frame_rate']:.2f} fps")
            if stream_bits:
                details = ", ".join(stream_bits)
                self._ui(lambda text=details: self._append_log(f"Selected stream: {text}\n"))

        cmd = build_ffmpeg_command(inputs, out_path)
        cmd_with_progress = list(cmd)
        cmd_with_progress.insert(-1, "-progress")
        cmd_with_progress.insert(-1, "pipe:1")

        self._ui(lambda: self._append_log("Running:\n  " + " ".join(shlex.quote(x) for x in cmd_with_progress) + "\n\n"))

        try:
            proc = subprocess.Popen(
                cmd_with_progress,
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
    
    # Check dependencies on startup and show dialog if needed
    missing_tools = []
    for tool in ("ffmpeg", "ffprobe"):
        if which(tool) is None:
            missing_tools.append(tool)
    
    if missing_tools:
        if not show_dependency_dialog(missing_tools, root):
            root.destroy()
            return  # User cancelled
    
    app = DownloaderApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
