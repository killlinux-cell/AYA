@echo off
REM Construit AYA_Laser_Sender.exe pour le PC atelier (Windows)
cd /d "%~dp0"

echo === Installation PyInstaller ===
python -m pip install --upgrade pip pyinstaller
if errorlevel 1 (
  echo ERREUR: Python / pip introuvable
  pause
  exit /b 1
)

echo === Build exe (une seule fenetre console) ===
python -m PyInstaller --noconfirm --clean --onefile --console ^
  --name AYA_Laser_Sender ^
  --distpath dist_laser ^
  --workpath build_laser ^
  --specpath build_laser ^
  laser_tcp_sender.py

if errorlevel 1 (
  echo ERREUR build
  pause
  exit /b 1
)

echo.
if not exist laser_bin mkdir laser_bin
copy /Y dist_laser\AYA_Laser_Sender.exe laser_bin\AYA_Laser_Sender.exe >nul

echo.
echo OK: dist_laser\AYA_Laser_Sender.exe
echo Copie deploy: laser_bin\AYA_Laser_Sender.exe
echo Placez aya_codes_machine.txt a cote de l'exe, puis double-cliquez.
echo Pause par defaut: 10 secondes entre chaque code.
pause
