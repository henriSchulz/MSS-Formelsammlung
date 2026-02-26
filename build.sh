#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. LaTeX kompilieren ────────────────────────────────────────────────────
echo "[1/4] Kompiliere LaTeX..."
pdflatex -interaction=nonstopmode -file-line-error main.tex
echo "      Fertig: main.pdf"
echo ""

# ── 2. Build-Artefakte bereinigen ──────────────────────────────────────────
echo "[2/4] Bereinige Build-Artefakte..."
python3 cleanup.py
echo ""

# ── 3. A4-Layout erstellen (2 A3-Seiten pro A4-Seite) ──────────────────────
echo "[3/4] Erstelle A4-Layout (2×A3 pro A4-Seite) mit pdfjam..."
pdfjam \
    --nup 1x2 \
    --a4paper \
    --no-landscape \
    --delta "0 0" \
    --quiet \
    --outfile "MSS_Formelsammlung.pdf" \
    "main.pdf"
echo "      Layout erstellt."
echo ""

# ── 3b. Ghostscript – Druckqualität maximieren (600 DPI) ───────────────────
echo "      Optimiere Druckqualität (600 DPI)..."
mv MSS_Formelsammlung.pdf _tmp_gs.pdf
gs \
    -dNOPAUSE -dBATCH -dQUIET \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.7 \
    -dPDFSETTINGS=/prepress \
    -dColorImageResolution=600 \
    -dGrayImageResolution=600 \
    -dMonoImageResolution=1200 \
    -dColorImageDownsampleType=/Bicubic \
    -dGrayImageDownsampleType=/Bicubic \
    -dEmbedAllFonts=true \
    -dSubsetFonts=true \
    -sOutputFile="MSS_Formelsammlung.pdf" \
    "_tmp_gs.pdf"
rm _tmp_gs.pdf
echo "      Druckqualität optimiert."
echo ""

# ── 3c. Trennlinien + Seitenzahlen hinzufügen ──────────────────────────────
echo "      Füge Trennlinien und Seitenzahlen hinzu..."
python3 - <<'PYEOF'
import sys, os, tempfile
import fitz  # PyMuPDF

INPUT = "MSS_Formelsammlung.pdf"
doc = fitz.open(INPUT)
total = doc.page_count

for i, page in enumerate(doc):
    w = page.rect.width
    h = page.rect.height
    mid_y = h / 2

    # Trennlinie in der Mitte
    page.draw_line(
        fitz.Point(14, mid_y),
        fitz.Point(w - 14, mid_y),
        color=(0.4, 0.4, 0.4),
        width=0.8,
        dashes="[4 3]",
    )

    # Seitenzahl unten rechts
    page_num = f"{i + 1} / {total}"
    font_size = 8
    text_width = fitz.get_text_length(page_num, fontname="Helvetica", fontsize=font_size)
    page.insert_text(
        fitz.Point(w - 10 - text_width, h - 10),
        page_num,
        fontsize=font_size,
        fontname="Helvetica",
        color=(0.3, 0.3, 0.3),
    )

dir_ = os.path.dirname(os.path.abspath(INPUT))
with tempfile.NamedTemporaryFile(suffix=".pdf", dir=dir_, delete=False) as tmp:
    tmp_path = tmp.name
doc.save(tmp_path, garbage=4, deflate=True, clean=True)
doc.close()
os.replace(tmp_path, INPUT)
print(f"      Dekorationen hinzugefügt: {total} Seiten.")
PYEOF
echo ""

# ── 4. Ergebnis ─────────────────────────────────────────────────────────────
PAGES=$(pdfinfo MSS_Formelsammlung.pdf 2>/dev/null | grep "^Pages:" | awk '{print $2}')
SIZE=$(du -sh MSS_Formelsammlung.pdf | cut -f1)
echo "============================================"
echo "[4/4] Fertig!"
echo "  Ausgabe: MSS_Formelsammlung.pdf"
echo "  Seiten:  $PAGES A4-Seiten"
echo "  Größe:   $SIZE"
echo "============================================"
