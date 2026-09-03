#!/usr/bin/env python3
"""
Envoi automatique des codes AYA vers la machine laser (TCP).

Usage (sur le PC de l'atelier, même réseau que la machine) :

  python laser_tcp_sender.py --host 192.168.0.100 --port 8950 --file aya_codes_machine.txt

Format envoyé (comme Network Debug Assistant) :
  SM https://monuniversaya.com/scan?code=CODE\\r\\n

IMPORTANT
- Ne pas envoyer tous les codes d'un coup : 1 code → pause / SMX → code suivant.
- SMX peut être un heartbeat (récurrent) OU un ACK : utilisez --mode interval
  si SMX arrive en continu sans lien avec chaque envoi.
- La reprise est automatique via le fichier --progress (défaut: laser_progress.json).
"""

from __future__ import annotations

import argparse
import json
import socket
import sys
import time
from pathlib import Path
from typing import List, Optional


DEFAULT_HOST = "192.168.0.100"
DEFAULT_PORT = 8950
BASE_URL = "https://monuniversaya.com/scan?code="


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

    def wait_for_smx(self, timeout: float) -> bool:
        """Attend la prochaine occurrence de SMX dans le flux reçu."""
        if not self.sock:
            return False
        deadline = time.time() + timeout
        self.sock.settimeout(0.2)
        while time.time() < deadline:
            if "SMX" in self._buffer:
                # Consomme jusqu'au premier SMX
                idx = self._buffer.find("SMX")
                self._buffer = self._buffer[idx + 3 :]
                self.sock.settimeout(self.timeout)
                return True
            try:
                data = self.sock.recv(4096)
                if not data:
                    break
                self._buffer += data.decode("ascii", errors="ignore")
            except socket.timeout:
                continue
            except OSError:
                break
        self.sock.settimeout(self.timeout)
        return False

    def send_code(self, code: str) -> None:
        if not self.sock:
            raise RuntimeError("Non connecté")
        payload = build_payload(code)
        self.sock.sendall(payload)
        print(f"  → {payload.decode('ascii', errors='ignore').rstrip()}")


def run(args: argparse.Namespace) -> int:
    codes_path = Path(args.file)
    if not codes_path.exists():
        print(f"[ERREUR] Fichier introuvable: {codes_path}")
        return 1

    codes = load_codes(codes_path)
    if not codes:
        print("[ERREUR] Aucun code dans le fichier.")
        return 1

    progress_path = Path(args.progress)
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
    print(f"[INFO] Mode: {args.mode} | interval={args.interval_ms}ms | wait_smx={args.wait_smx_ms}ms")
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
                    # Vide le buffer avant envoi (évite de compter un vieux SMX)
                    client.drain(0.05)
                    client._buffer = ""
                    client.send_code(code)

                    if args.mode == "smx":
                        ok = client.wait_for_smx(args.wait_smx_ms / 1000.0)
                        if not ok:
                            raise TimeoutError(f"Pas de SMX sous {args.wait_smx_ms} ms")
                        print("  ← SMX")
                    else:
                        # Mode interval : pause fixe (recommandé si SMX est un heartbeat)
                        time.sleep(max(args.interval_ms, 50) / 1000.0)
                        # Lecture non bloquante pour log
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
    parser.add_argument("--host", default=DEFAULT_HOST, help="IP machine laser (défaut: 192.168.0.100)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Port TCP (défaut: 8950)")
    parser.add_argument("--file", "-f", required=True, help="Fichier TXT/CSV des codes (1 code/ligne)")
    parser.add_argument("--progress", default="laser_progress.json", help="Fichier de reprise")
    parser.add_argument(
        "--mode",
        choices=["interval", "smx"],
        default="interval",
        help="interval=pause fixe (recommandé si SMX heartbeat) | smx=attendre SMX après chaque envoi",
    )
    parser.add_argument("--interval-ms", type=int, default=1000, help="Pause entre codes (mode interval)")
    parser.add_argument("--wait-smx-ms", type=int, default=3000, help="Timeout attente SMX (mode smx)")
    parser.add_argument("--timeout", type=float, default=10.0, help="Timeout socket (s)")
    parser.add_argument("--retries", type=int, default=3, help="Tentatives par code")
    parser.add_argument("--from-index", type=int, default=None, help="Forcer l'index de départ (0-based)")
    parser.add_argument("--reset-progress", action="store_true", help="Recommencer depuis le début")
    parser.add_argument("--stop-on-error", action="store_true", help="Arrêter si un code échoue")
    parser.add_argument("--limit", type=int, default=None, help="Envoyer au plus N codes (test)")
    args = parser.parse_args()
    sys.exit(run(args))


if __name__ == "__main__":
    main()
