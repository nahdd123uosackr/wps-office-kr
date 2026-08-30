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
                
                # WPS .ts quirk: win_translations/*.ts have empty <source> and English in <translation>
                # Handle both: prefer source if non-empty, else use translation as English source
                eng_text = None
                src_node = None
                if source is not None and source.text and source.text.strip() != '':
                    eng_text = source.text.strip()
                    src_node = source
                elif translation is not None and translation.text and translation.text.strip() != '':
                    # translation holds English source (common for WPS lconvert-extracted .ts)
                    eng_text = translation.text.strip()
                    src_node = translation  # we will overwrite translation with Korean
                    # Ensure source is populated for completeness
                    if source is not None:
                        source.text = eng_text
                
                if eng_text:
                    total += 1
                    # Determine current Korean value
                    current = translation.text or '' if translation is not None else ''
                    trans_type = translation.get('type', '') if translation is not None else ''
                    
                    # Needs translation if empty, same as English, unfinished, or placeholder [KO]
                    needs = False
                    if not current or current.strip() == eng_text or trans_type == 'unfinished' or current.startswith('[KO]'):
                        needs = True
                    # Also if current has no Hangul, consider needing translation when dictionary has entry
                    if eng_text in dictionary and current != dictionary[eng_text]:
                        needs = True
                    
                    if needs and translation is not None:
                        ko = translate_text(eng_text)
                        if ko and not ko.startswith('[KO]'):
                            translation.text = ko
                            if 'type' in translation.attrib:
                                del translation.attrib['type']
                            translated += 1
                        else:
                            # Keep English if no translation available, don't mark as [KO] to avoid placeholder noise
                            # Only mark if we want to flag missing
                            if ko.startswith('[KO]'):
                                # Don't overwrite with [KO] if we already have English - keep English for better UX
                                # Mark as unfinished only if verbose mode would want it
                                marked += 1
                            else:
                                translation.text = ko
                            # Do not set unfinished to keep English visible
        
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