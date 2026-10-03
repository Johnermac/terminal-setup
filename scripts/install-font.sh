#!/usr/bin/env bash
set -euo pipefail

FONT_VERSION=${FONT_VERSION:-v3.4.0}
FONT_NAME=${FONT_NAME:-JetBrainsMono}
URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_NAME}.zip"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSLo "$tmp/font.zip" "$URL"
unzip -qo "$tmp/font.zip" -d "$tmp/font"

case "$(uname -s)" in
  Darwin) dest="$HOME/Library/Fonts/$FONT_NAME" ;;
  *) dest="$HOME/.local/share/fonts/$FONT_NAME" ;;
esac

mkdir -p "$dest"
find "$tmp/font" -name '*.ttf' -exec cp -f {} "$dest/" \;
command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$dest" >/dev/null
echo "installed to $dest"

grep -qi microsoft /proc/version 2>/dev/null || exit 0
command -v powershell.exe >/dev/null 2>&1 || {
  echo "powershell.exe not reachable; install the font on Windows manually" >&2
  exit 0
}

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
" || echo "windows install failed; open the extracted folder and right-click Install" >&2

echo "set the font in your terminal emulator: JetBrainsMono Nerd Font"
