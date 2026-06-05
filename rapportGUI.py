#!/usr/bin/env python3

import tkinter as tk
from tkinter import font as tkfont
import subprocess
import threading
import re
import os
import sys


SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "getinfo.sh")

#Couleurs
BG          = "#ffffff"   # fond blanc
HEADER_BG   = "#1e3a5f"   # bleu foncé pour les en-têtes de section
HEADER_FG   = "#ffffff"   # texte blanc sur en-tête
KEY_FG      = "#1e3a5f"   # bleu foncé pour les clés
VALUE_FG    = "#222222"   # quasi-noir pour les valeurs
SEP_COLOR   = "#d0d8e8"   # gris-bleu clair pour les séparateurs
LOADING_FG  = "#888888"   # gris pour le message de chargement

#Sections et ordre d'affichage
SECTIONS = [
    ("OS INFORMATION", [
        ("Distribution Linux", "distro"),
        ("Kernel Linux",       "kernel"),
        ("Shell courant",      "shell"),
    ]),
    ("HARDWARE INFORMATION", [
        ("Modèle machine",          "model_name"),
        ("Architecture",            "architecture"),
        ("Modèle CPU",              "model_cpu"),
        ("CPU cores/threads/socket","cpu"),
        ("RAM",                     "ram"),
        ("Disque",                  "disque"),
    ]),
    ("SOFTWARE INFORMATION", [
        ("Paquets installés",       "paquets"),
        ("Processus en cours",      "processus"),
    ]),
    ("NETWORK INFORMATION", [
        ("Nom de la machine",       "hote"),
        ("Nom du réseau (SSID)",    "ssid"),
        ("Adresse IPv4",            "ipv4"),
        ("Adresse MAC",             "mac"),
    ]),
]

class RapportGUI(tk.Tk):
    """Fenêtre principale — lance le script et affiche les résultats."""
    def __init__(self):
        super().__init__()
        self.title("Récupération d'informations système")
        self.configure(bg=BG)
        self.geometry("780x620")
        self.resizable(True, True)

        # Données parsées : clé interne → liste de valeurs
        self.info_data: dict[str, list[str]] = {}

        self._build_ui()
        self._launch_script()

    # ── Construction de l'interface
    def _build_ui(self):
        self.font_title   = tkfont.Font(family="DejaVu Sans", size=13, weight="bold")
        self.font_header  = tkfont.Font(family="DejaVu Sans", size=10, weight="bold")
        self.font_key     = tkfont.Font(family="DejaVu Sans", size=9,  weight="bold")
        self.font_value   = tkfont.Font(family="DejaVu Sans", size=9)
        self.font_loading = tkfont.Font(family="DejaVu Sans", size=10, slant="italic")

        tk.Label(
            self, text="Informations Système Linux",
            font=self.font_title, bg=BG, fg=HEADER_BG, pady=10
        ).pack(fill="x")

        tk.Frame(self, height=2, bg=HEADER_BG).pack(fill="x", padx=20)

        self.loading_label = tk.Label(
            self, text="⏳ Chargement des informations système…",
            font=self.font_loading, bg=BG, fg=LOADING_FG, pady=8
        )
        self.loading_label.pack()

        container = tk.Frame(self, bg=BG)
        container.pack(fill="both", expand=True, padx=20, pady=(0, 10))

        self.canvas = tk.Canvas(container, bg=BG, highlightthickness=0)
        scrollbar = tk.Scrollbar(container, orient="vertical",
                                 command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=scrollbar.set)

        scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)

        # Frame intérieure dans le canvas — c'est là qu'on colle les widgets
        self.inner_frame = tk.Frame(self.canvas, bg=BG)
        self.canvas_window = self.canvas.create_window(
            (0, 0), window=self.inner_frame, anchor="nw"
        )

        # Mise à jour de la scrollregion quand le contenu change de taille
        self.inner_frame.bind("<Configure>", self._on_frame_configure)
        self.canvas.bind("<Configure>", self._on_canvas_configure)

        # Molette de souris
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        self.canvas.bind_all("<Button-4>",   self._on_mousewheel)
        self.canvas.bind_all("<Button-5>",   self._on_mousewheel)

    # ── Lancement du script en arrière-plan ─────────────────────────────────
    def _launch_script(self):
        if not os.path.isfile(SCRIPT_PATH):
            self.loading_label.config(
                text=f"❌ Script introuvable : {SCRIPT_PATH}",
                fg="red"
            )
            return

        # On enrichit le PATH pour que iwgetid, lspci, etc. soient trouvés
        # (même correctif que dans le programme Qt)
        env = os.environ.copy()
        env["PATH"] = env.get("PATH", "") + ":/sbin:/usr/sbin:/usr/local/sbin"

        self.process = subprocess.Popen(
            ["bash", SCRIPT_PATH],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            env=env
        )

        # Thread séparé pour attendre la fin sans geler l'UI
        # → équivalent du signal QProcess::finished()
        t = threading.Thread(target=self._wait_for_script, daemon=True)
        t.start()

    def _wait_for_script(self):
        raw_bytes, _ = self.process.communicate()   # bloque CE thread, pas l'UI
        raw_text = raw_bytes.decode("utf-8", errors="replace")
        self.after(0, self._on_script_finished, raw_text)

    # ── Parsing de la sortie ─────────────────────────────────────────────────
    def _on_script_finished(self, raw_text: str):
        clean = re.sub(r'\x1B\[[0-9;]*m', '', raw_text)

        current_key = None

        for raw_line in clean.splitlines():
            if not raw_line.strip():
                continue

            is_indented = raw_line.startswith((' ', '\t'))

            if is_indented and current_key:
                sub = raw_line.strip()
                # Ignorer séparateurs (====) et titres en majuscules sans ':'
                if not sub:
                    continue
                if re.match(r'^=+$', sub):
                    continue
                if ':' not in sub and sub == sub.upper():
                    continue

                sep = sub.find(':')
                if sep != -1:
                    sk = sub[:sep].strip()
                    sv = sub[sep+1:].strip()
                    self.info_data.setdefault(current_key, []).append(f"{sk} : {sv}")
                else:
                    self.info_data.setdefault(current_key, []).append(sub)
            else:
                sep = raw_line.find(':')
                if sep == -1:
                    continue

                key = raw_line[:sep].strip().lower()
                val = raw_line[sep+1:].strip()

                # Mapping labels script → clés internes (identique au Qt)
                if   "distribution" in key:
                    current_key = "distro"
                elif "kernel" in key or "noyau" in key:
                    current_key = "kernel"
                elif key == "interpreteur de commande (chemin)":
                    current_key = "shell"
                elif "modele du machine" in key:
                    current_key = "model_name"
                elif key == "architecture":
                    current_key = "architecture"
                elif "modele cpu" in key:
                    current_key = "model_cpu"
                elif "socket" in key or "cpu core" in key:
                    current_key = "cpu"
                elif key == "ram":
                    current_key = "ram"
                elif "disque" in key:
                    current_key = "disque"
                elif "paquet" in key:
                    current_key = "paquets"
                elif "processus" in key:
                    current_key = "processus"
                elif "machine" in key or "nom de la machine" in key:
                    current_key = "hote"
                elif "reseau" in key:
                    current_key = "ssid"
                elif "ipv4" in key:
                    current_key = "ipv4"
                elif "mac" in key:
                    current_key = "mac"
                else:
                    current_key = key

                if val:
                    self.info_data.setdefault(current_key, []).append(val)
        self.loading_label.destroy()
        self._render()

    #Rendu des données dans l'interface
    def _render(self):
        """Construit les widgets d'affichage à partir de info_data."""

        for section_title, fields in SECTIONS:
            header = tk.Frame(self.inner_frame, bg=HEADER_BG)
            header.pack(fill="x", pady=(14, 0))
            tk.Label(
                header, text=section_title,
                font=self.font_header, bg=HEADER_BG, fg=HEADER_FG,
                padx=10, pady=5, anchor="w"
            ).pack(fill="x")

            for label, key in fields:
                values = self.info_data.get(key)

                row = tk.Frame(self.inner_frame, bg=BG)
                row.pack(fill="x", padx=2)

                tk.Label(
                    row, text=label,
                    font=self.font_key, bg=BG, fg=KEY_FG,
                    width=28, anchor="w", padx=8, pady=3
                ).pack(side="left")

                if not values:
                    tk.Label(
                        row, text="—",
                        font=self.font_value, bg=BG, fg="#aaaaaa",
                        anchor="w"
                    ).pack(side="left", fill="x", expand=True)
                elif len(values) == 1:
                    tk.Label(
                        row, text=values[0],
                        font=self.font_value, bg=BG, fg=VALUE_FG,
                        anchor="w"
                    ).pack(side="left", fill="x", expand=True)
                else:

                    col = tk.Frame(row, bg=BG)
                    col.pack(side="left", fill="x", expand=True)
                    for v in values:
                        tk.Label(
                            col, text=v,
                            font=self.font_value, bg=BG, fg=VALUE_FG,
                            anchor="w", pady=1
                        ).pack(fill="x")

                # Séparateur fin entre les lignes
                tk.Frame(self.inner_frame, height=1, bg=SEP_COLOR).pack(
                    fill="x", padx=8
                )

    def _on_frame_configure(self, _event):
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _on_canvas_configure(self, event):
        self.canvas.itemconfig(self.canvas_window, width=event.width)

    def _on_mousewheel(self, event):
        if event.num == 4:
            self.canvas.yview_scroll(-1, "units")
        elif event.num == 5:
            self.canvas.yview_scroll(1, "units")
        else:
            self.canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")


#main
if __name__ == "__main__":
    app = RapportGUI()
    app.mainloop()
