#!/usr/bin/env bash
# Installs JetBrainsMono Nerd Font.
#   Linux  : ~/.local/share/fonts + fc-cache
#   WSL    : also installs per-user on Windows (no admin) via registry, since the
#            glyphs are rendered by the Windows terminal emulator, not by WSL.
set -euo pipefail

FONT_VERSION=${FONT_VERSION:-v3.4.0}
FONT_NAME=JetBrainsMono
URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_NAME}.zip"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "==> downloading $FONT_NAME Nerd Font $FONT_VERSION"
curl -sSfLo "$tmp/font.zip" "$URL"
unzip -qo "$tmp/font.zip" -d "$tmp/font"

# --- Linux side ---
dest="$HOME/.local/share/fonts/$FONT_NAME"
mkdir -p "$dest"
find "$tmp/font" -name '*.ttf' -exec cp -f {} "$dest/" \;
command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$dest" >/dev/null
echo "  installed to $dest"

# --- Windows side (WSL only) ---
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "done."
  exit 0
fi

command -v powershell.exe >/dev/null 2>&1 || {
  echo "! powershell.exe not reachable; install the font on Windows manually" >&2
  exit 0
}

echo "==> installing on Windows (per-user, no admin)"
winstage=$(wslpath -w "$tmp/font")

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
  \$src = '$winstage'
  \$dst = Join-Path \$env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  New-Item -ItemType Directory -Force -Path \$dst | Out-Null
  \$key = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  Get-ChildItem -Path \$src -Filter *.ttf -Recurse | ForEach-Object {
    Copy-Item \$_.FullName -Destination \$dst -Force
    \$name = [System.IO.Path]::GetFileNameWithoutExtension(\$_.Name) + ' (TrueType)'
    New-ItemProperty -Path \$key -Name \$name -PropertyType String \
      -Value (Join-Path \$dst \$_.Name) -Force | Out-Null
  }
  Write-Host '  fonts registered for current Windows user'
" || echo "! Windows install failed; open the extracted folder and right-click > Install" >&2

cat <<'NEXT'

Last step (manual, ~10s): set the font in your terminal emulator.
  Windows Terminal: Settings -> your profile -> Appearance -> Font face
                    -> "JetBrainsMono Nerd Font", size 14
Restart Windows Terminal if the font isn't listed yet.
NEXT
