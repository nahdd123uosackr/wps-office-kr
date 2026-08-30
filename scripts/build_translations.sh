#!/bin/bash
# build_translations.sh - Build-time Korean translation pipeline
# Usage: ./build_translations.sh <src_ts_dir> <out_qm_dir>

set -euo pipefail

SRC_TS_DIR="${1:-}"
OUT_QM_DIR="${2:-}"
DICT_FILE="${3:-}"

if [[ -z "$SRC_TS_DIR" || -z "$OUT_QM_DIR" ]]; then
  echo "Usage: $0 <src_ts_dir> <out_qm_dir> [dict_file]"
  exit 1
fi

# Default dict file location (relative to build)
if [[ -z "$DICT_FILE" ]]; then
  DICT_FILE="${OUT_QM_DIR}/../translation_dict.json"
fi

mkdir -p "$OUT_QM_DIR"

echo "=== Build-time Korean Translation Pipeline ==="
echo "Source TS: $SRC_TS_DIR"
echo "Output QM: $OUT_QM_DIR"
echo "Dictionary: $DICT_FILE"

# Load dictionary
if [[ -f "$DICT_FILE" ]]; then
    echo "Loading dictionary..."
    dict_entries=$(jq 'length' "$DICT_FILE")
    echo "Dictionary entries: $dict_entries"
else
    echo "No dictionary found, creating empty"
    echo "{}" > "$DICT_FILE"
fi

# Check for argostranslate
if python3 -c "import argostranslate" 2>/dev/null; then
    HAS_ARGOS=1
    echo "ArgosTranslate: Available"
else
    HAS_ARGOS=0
    echo "ArgosTranslate: Not available (will mark missing as [KO])"
fi

# Python script for merge + translate
cat > /tmp/merge_translate.py << 'PYEOF'
#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import json
import sys
import os

SRC_DIR = sys.argv[1]
OUT_DIR = sys.argv[2]
DICT_FILE = sys.argv[3]
HAS_ARGOS = int(sys.argv[4])

# Load dictionary
with open(DICT_FILE, 'r', encoding='utf-8') as f:
    dictionary = json.load(f)

# Setup argostranslate
translation_engine = None
if HAS_ARGOS:
    try:
        import argostranslate.package
        import argostranslate.translate
        installed = argostranslate.translate.get_installed_languages()
        en_lang = next((l for l in installed if l.code == 'en'), None)
        ko_lang = next((l for l in installed if l.code == 'ko'), None)
        if en_lang and ko_lang:
            translation_engine = en_lang.get_translation(ko_lang)
            print("ArgosTranslate engine ready")
        else:
            print("Korean model not installed")
    except Exception as e:
        print(f"ArgosTranslate init failed: {e}")

def translate_text(text):
    if not text or text.strip() == '':
        return text
    if text in dictionary:
        return dictionary[text]
    if translation_engine:
        try:
            result = translation_engine.translate(text)
            if result and result != text:
                dictionary[text] = result
                return result
        except Exception:
            pass
    return f"[KO] {text}"

def process_ts_file(ts_path, out_dir):
    try:
        tree = ET.parse(ts_path)
        root = tree.getroot()
        
        # Set Korean language
        root.set('language', 'ko_KR')
        
        translated = 0
        marked = 0
        total = 0
        
        for context in root.findall('context'):
            for message in context.findall('message'):
                source = message.find('source')
                translation = message.find('translation')
                
                if source is not None and source.text:
                    src = source.text.strip()
                    total += 1
                    
                    if translation is not None:
                        current = translation.text or ''
                        trans_type = translation.get('type', '')
                        
                        # Needs translation if empty, same as source, or unfinished
                        if not current or current == src or trans_type == 'unfinished':
                            ko = translate_text(src)
                            if ko and not ko.startswith('[KO]'):
                                translation.text = ko
                                if 'type' in translation.attrib:
                                    del translation.attrib['type']
                                translated += 1
                            else:
                                translation.text = ko
                                translation.set('type', 'unfinished')
                                marked += 1
        
        # Write merged .ts
        out_ts = os.path.join(out_dir, os.path.basename(ts_path).replace('.ts', '_ko.ts'))
        tree.write(out_ts, encoding='utf-8', xml_declaration=True)
        
        # Compile to .qm
        out_qm = os.path.join(out_dir, os.path.basename(ts_path).replace('.ts', '.qm'))
        import subprocess
        result = subprocess.run(['lrelease', out_ts, '-qm', out_qm], 
                               capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"  ✓ {os.path.basename(ts_path)}: {total} strings, {translated} translated, {marked} marked")
        else:
            print(f"  ✗ {os.path.basename(ts_path)}: compile failed - {result.stderr}")
        
        return translated, marked
        
    except Exception as e:
        print(f"  ✗ {os.path.basename(ts_path)}: error - {e}")
        return 0, 0

if __name__ == '__main__':
    import glob
    
    total_translated = 0
    total_marked = 0
    
    for ts_file in glob.glob(os.path.join(SRC_DIR, '*.ts')):
        t, m = process_ts_file(ts_file, OUT_DIR)
        total_translated += t
        total_marked += m
    
    # Save updated dictionary
    with open(DICT_FILE, 'w', encoding='utf-8') as f:
        json.dump(dictionary, f, ensure_ascii=False, indent=2)
    
    print(f"\n=== Complete ===")
    print(f"Total translated: {total_translated}")
    print(f"Total marked [KO]: {total_marked}")
    print(f"Dictionary size: {len(dictionary)}")
    print(f"Output .qm files in: {OUT_DIR}")
PYEOF

chmod +x /tmp/merge_translate.py

echo "Running merge + translate..."
python3 /tmp/merge_translate.py "$SRC_TS_DIR" "$OUT_QM_DIR" "$DICT_FILE" "$HAS_ARGOS"

echo "=== Pipeline Complete ==="
ls -la "$OUT_QM_DIR"/*.qm 2>/dev/null | head -20