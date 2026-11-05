#!/usr/bin/env bash
# Gate de qualidade dos design tokens recebidos do cicd-create-tokens.
# Roda no CI (PR) e antes de cada deploy. Sem a pasta (antes do primeiro sync), não faz nada.
set -euo pipefail

DIR="${1:-design-tokens}"
if [ ! -d "$DIR" ]; then
  echo "Pasta $DIR ainda não existe (nenhum sync feito). Nada a validar."
  exit 0
fi

FILE="$DIR/values/colors.xml"
[ -f "$FILE" ] || { echo "::error::Esperado $FILE"; exit 1; }
python3 - "$FILE" <<'EOF'
import re, sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
assert root.tag == 'resources', 'raiz deve ser <resources>'
colors = root.findall('color')
assert colors, 'nenhuma <color> encontrada'
names = [c.get('name') for c in colors]
assert len(names) == len(set(names)), 'nomes duplicados'
for c in colors:
    assert re.fullmatch(r'[a-z][a-z0-9_]*', c.get('name') or ''), f"nome inválido: {c.get('name')}"
    assert re.fullmatch(r'#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})', (c.text or '').strip()), f"cor inválida: {c.get('name')}"
print(f'OK: {len(colors)} cores válidas em colors.xml')
EOF
