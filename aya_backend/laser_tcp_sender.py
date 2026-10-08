#!/usr/bin/env python3
"""
Envoi automatique des codes AYA vers la machine laser (TCP).

Usage (sur le PC de l'atelier, même réseau que la machine) :

  # Double-clic sur AYA_Laser_Sender.exe
  # ou :
  AYA_Laser_Sender.exe
  python laser_tcp_sender.py --file aya_codes_machine.txt

Comportement par défaut (notice machine) :
  1. SM  = enregistrer le contenu (réponse SMX = données reçues, PAS imprimé)
  2. SGT = déclencher l'impression de cette capsule
  3. MK  = impression terminée, seulement alors le code suivant

Format envoyé :
  SM https://monuniversaya.com/scan?code=CODE\\r\\n
  SGT\\r\\n

IMPORTANT
- Un seul code en vol : le suivant part seulement après le retour.
- La reprise est automatique via le fichier --progress (défaut: laser_progress.json).
- --mode interval reste disponible (pause fixe) si besoin.
"""

from __future__ import annotations

import argparse
import json
import socket
import sys
import time
from pathlib import Path
from typing import List, Optional


DEFAULT_HOST = "192.168.0.101"
DEFAULT_PORT = 8950
DEFAULT_INTERVAL_MS = 10000
DEFAULT_ACCEPT = "SMX"  # données enregistrées, impression pas encore faite
DEFAULT_TRIGGER = "SGT"  # déclenche vraiment le marquage (STY ne le fait pas)
DEFAULT_ACK = "MK"  # notification « marquage terminé »
DEFAULT_ACK_TIMEOUT_MS = 180000  # 3 min max pour un marquage
DEFAULT_FILE = "aya_codes_machine.txt"
BASE_URL = "https://monuniversaya.com/scan?code="


def app_dir() -> Path:
    """Dossier de l'exe (PyInstaller) ou du script."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def load_codes(path: Path) -> List[str]:
    codes: List[str] = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        code = line.strip()
        if not code or code.startswith("#"):
            continue
        # Accepte CSV "code;points;..." → première colonne
        if ";" in code:
            code = code.split(";")[0].strip()
        if "," in code and not code.isdigit():
            code = code.split(",")[0].strip()
        if code.lower() == "code":
            continue
        codes.append(code)
    return codes


def build_payload(code: str) -> bytes:
    # Exactement le format testé dans Network Debug Assistant
    return f"SM {BASE_URL}{code}\r\n".encode("ascii", errors="ignore")


def load_progress(path: Path) -> dict:
    if not path.exists():
        return {"last_index": -1, "last_code": None, "sent": 0, "failed": []}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {"last_index": -1, "last_code": None, "sent": 0, "failed": []}


def save_progress(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


class LaserClient:
    def __init__(self, host: str, port: int, timeout: float = 10.0):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.sock: Optional[socket.socket] = None
        self._buffer = ""

    def connect(self) -> None:
        self.close()
        self.sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self.sock.settimeout(self.timeout)
        self._buffer = ""
        print(f"[OK] Connecté à {self.host}:{self.port}")

    def close(self) -> None:
        if self.sock is not None:
            try:
                self.sock.close()
            except Exception:
                pass
            self.sock = None

    def drain(self, seconds: float = 0.4) -> str:
        """Lit ce qui arrive (ex. SMX heartbeat) sans bloquer longtemps."""
        if not self.sock:
            return ""
        end = time.time() + seconds
        chunks: List[str] = []
        self.sock.settimeout(0.15)
        while time.time() < end:
            try:
                data = self.sock.recv(4096)
                if not data:
                    break
                chunks.append(data.decode("ascii", errors="ignore"))
            except socket.timeout:
                continue
            except OSError:
                break
        self.sock.settimeout(self.timeout)
        text = "".join(chunks)
        self._buffer += text
        return text

    def wait_for_token(self, token: str, timeout: float) -> str:
        """Attend un retour arrivé APRÈS l'appel (le buffer doit être vidé avant l'envoi)."""
        if not self.sock:
            return ""
        deadline = time.time() + timeout
        self.sock.settimeout(0.3)
        while time.time() < deadline:
            idx = self._buffer.find(token)
            if idx >= 0:
                snippet = self._buffer[: idx + len(token)]
                self._buffer = self._buffer[idx + len(token) :]
                self.sock.settimeout(self.timeout)
                return snippet
            try:
                data = self.sock.recv(4096)
                if not data:
                    break
                text = data.decode("ascii", errors="ignore")
                self._buffer += text
                preview = text.strip().replace("\r", " ").replace("\n", " ")
                if preview:
                    print(f"  ← {preview[:120]}")
            except socket.timeout:
                continue
            except OSError:
                break
        self.sock.settimeout(self.timeout)
        return ""

    def send_line(self, text: str) -> None:
        if not self.sock:
            raise RuntimeError("Non connecté")
        if not text.endswith("\r\n"):
            text += "\r\n"
        self.sock.sendall(text.encode("ascii", errors="ignore"))
        print(f"  → {text.rstrip()}")

    def send_code(self, code: str) -> None:
        payload = build_payload(code).decode("ascii", errors="ignore")
        self.send_line(payload.rstrip("\r\n"))


def run(args: argparse.Namespace) -> int:
    base = app_dir()
    codes_path = Path(args.file)
    if not codes_path.is_absolute():
        codes_path = base / codes_path
    if not codes_path.exists():
        print(f"[ERREUR] Fichier introuvable: {codes_path}")
        print(f"Placez {DEFAULT_FILE} à côté de l'exe / script : {base}")
        return 1

    codes = load_codes(codes_path)
    if not codes:
        print("[ERREUR] Aucun code dans le fichier.")
        return 1

    progress_path = Path(args.progress)
    if not progress_path.is_absolute():
        progress_path = base / progress_path
    progress = load_progress(progress_path)
    start_index = progress.get("last_index", -1) + 1

    if args.from_index is not None:
        start_index = max(0, int(args.from_index))
    if args.reset_progress:
        start_index = 0
        progress = {"last_index": -1, "last_code": None, "sent": 0, "failed": []}
        save_progress(progress_path, progress)

    total = len(codes)
    print(f"[INFO] {total} codes chargés depuis {codes_path.name}")
    print(f"[INFO] Reprise à l'index {start_index} (code #{start_index + 1})")
    print(
        f"[INFO] Mode: {args.mode} | ack={args.ack!r} | "
        f"timeout_ack={args.wait_smx_ms}ms | interval={args.interval_ms}ms"
    )
    print(f"[INFO] Machine: {args.host}:{args.port}")
    print("-" * 60)

    client = LaserClient(args.host, args.port, timeout=args.timeout)
    try:
        client.connect()
        # Laisse arriver les SMX de démarrage / heartbeat
        drained = client.drain(0.8)
        if drained.strip():
            print(f"[RX démarrage] {drained.strip()[:120]!r}")
    except OSError as exc:
        print(f"[ERREUR] Connexion impossible: {exc}")
        print("Vérifiez IP/port, câble réseau, et que Network Debug Assistant n'est pas déjà connecté.")
        return 1

    sent_ok = 0
    try:
        for i in range(start_index, total):
            code = codes[i]
            n = i + 1
            print(f"[{n}/{total}] {code}")

            retries = 0
            while True:
                try:
                    # Vide les vieux retours pour ne pas les prendre comme « imprimé »
                    client.drain(0.15)
                    client._buffer = ""
                    client.send_code(code)

                    if args.mode == "smx":
                        print("  … attente SMX (données reçues, capsule pas encore imprimée)…")
                        accepted = client.wait_for_token(DEFAULT_ACCEPT, args.accept_ms / 1000.0)
                        if not accepted:
                            raise TimeoutError(
                                f"Pas de {DEFAULT_ACCEPT} sous {args.accept_ms} ms"
                            )
                        print("  ✓ données acceptées (SMX)")
                        # SMX et MK peuvent arriver collés : ne pas renvoyer SGT dans ce cas
                        if args.ack in client._buffer:
                            client.wait_for_token(args.ack, 2.0)
                            print(f"  ✓ capsule imprimée ({args.ack} déjà reçu)")
                        else:
                            client.send_line(args.trigger)
                            print(f"  … attente {args.ack} (fin d'impression de cette capsule)…")
                            done = client.wait_for_token(args.ack, args.wait_smx_ms / 1000.0)
                            if not done:
                                raise TimeoutError(
                                    f"Pas de {args.ack!r} sous {args.wait_smx_ms} ms "
                                    "(impression non confirmée)"
                                )
                            print("  ✓ capsule imprimée, code suivant")
                    else:
                        time.sleep(max(args.interval_ms, 50) / 1000.0)
                        rx = client.drain(0.05)
                        if rx.strip():
                            print(f"  ← {rx.strip()[:80]!r}")

                    progress["last_index"] = i
                    progress["last_code"] = code
                    progress["sent"] = progress.get("sent", 0) + 1
                    save_progress(progress_path, progress)
                    sent_ok += 1
                    break
                except (OSError, TimeoutError) as exc:
                    retries += 1
                    print(f"  ! Échec ({exc}) — tentative {retries}/{args.retries}")
                    if retries >= args.retries:
                        failed = progress.setdefault("failed", [])
                        failed.append({"index": i, "code": code, "error": str(exc)})
                        save_progress(progress_path, progress)
                        if args.stop_on_error:
                            print("[STOP] Arrêt demandé (--stop-on-error).")
                            return 2
                        print("  → Code ignoré, on continue.")
                        break
                    try:
                        client.connect()
                        client.drain(0.5)
                    except OSError as reconnect_exc:
                        print(f"  ! Reconnexion échouée: {reconnect_exc}")
                        time.sleep(1.0)

            if args.limit and sent_ok >= args.limit:
                print(f"[INFO] Limite atteinte ({args.limit}).")
                break

    except KeyboardInterrupt:
        print("\n[STOP] Interrompu (Ctrl+C). La reprise reprendra au prochain code.")
        return 130
    finally:
        client.close()
        save_progress(progress_path, progress)

    print("-" * 60)
    print(f"[FIN] Envoyés cette session: {sent_ok}")
    print(f"[FIN] Dernier index: {progress.get('last_index')} ({progress.get('last_code')})")
    print(f"[FIN] Progress sauvegardé: {progress_path}")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Envoi TCP des codes AYA vers la machine laser")
    parser.add_argument("--host", default=DEFAULT_HOST, help="IP machine laser (défaut: 192.168.0.101)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Port TCP (défaut: 8950)")
    parser.add_argument(
        "--file",
        "-f",
        default=DEFAULT_FILE,
        help=f"Fichier TXT/CSV des codes (défaut: {DEFAULT_FILE} à côté de l'exe)",
    )
    parser.add_argument("--progress", default="laser_progress.json", help="Fichier de reprise")
    parser.add_argument(
        "--mode",
        choices=["smx", "interval"],
        default="smx",
        help="smx=SM puis SGT, attendre MK (défaut) | interval=pause fixe",
    )
    parser.add_argument(
        "--trigger",
        default=DEFAULT_TRIGGER,
        help="Commande qui déclenche l'impression (défaut: SGT). STY ne marque pas.",
    )
    parser.add_argument(
        "--ack",
        default=DEFAULT_ACK,
        help="Texte « impression terminée » (défaut: MK). SMX veut seulement dire données reçues.",
    )
    parser.add_argument(
        "--accept-ms",
        type=int,
        default=15000,
        help="Temps max pour recevoir SMX après l'envoi des données (défaut: 15000)",
    )
    parser.add_argument(
        "--interval-ms",
        type=int,
        default=DEFAULT_INTERVAL_MS,
        help="Pause entre codes en ms, seulement en --mode interval",
    )
    parser.add_argument(
        "--wait-smx-ms",
        type=int,
        default=DEFAULT_ACK_TIMEOUT_MS,
        help="Temps max d'attente du retour laser en ms (défaut: 180000 = 3 min)",
    )
    parser.add_argument("--timeout", type=float, default=15.0, help="Timeout socket (s)")
    parser.add_argument("--retries", type=int, default=3, help="Tentatives par code")
    parser.add_argument("--from-index", type=int, default=None, help="Forcer l'index de départ (0-based)")
    parser.add_argument("--reset-progress", action="store_true", help="Recommencer depuis le début")
    parser.add_argument("--stop-on-error", action="store_true", help="Arrêter si un code échoue")
    parser.add_argument("--limit", type=int, default=None, help="Envoyer au plus N codes (test)")
    parser.add_argument(
        "--no-pause",
        action="store_true",
        help="Ne pas attendre Entrée à la fin (utile en script)",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("  AYA Laser Sender — un code à la fois")
    if args.mode == "smx":
        print("  SM = données, SGT = imprimer, MK = capsule terminée")
        print(f"  Timeout impression : {args.wait_smx_ms / 1000:.0f} s")
    else:
        print(f"  Pause fixe entre codes : {args.interval_ms / 1000:.0f} s")
    print("=" * 60)

    code = 0
    try:
        code = run(args)
    except Exception as exc:
        print(f"[ERREUR fatale] {exc}")
        code = 1
    finally:
        if not args.no_pause:
            try:
                input("\nAppuyez sur Entrée pour fermer...")
            except EOFError:
                pass
    sys.exit(code)


if __name__ == "__main__":
    main()
