#!/usr/bin/env python3
"""
Generate Localizable.strings from en.lproj (machine translation via Google).
Preserves ru.lproj from the repo. One API batch per target language for speed.

  pip install deep-translator
  python3 Scripts/generate_localizations.py
"""

from __future__ import annotations

import re
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "Bugs/Resources/en.lproj/Localizable.strings"
RU_PATH = ROOT / "Bugs/Resources/ru.lproj/Localizable.strings"
OUT_ROOT = ROOT / "Bugs/Resources"

LOCALES: list[tuple[str, str]] = [
    ("zh-Hans", "zh-CN"),
    ("zh-Hant", "zh-TW"),
    ("es", "es"),
    ("hi", "hi"),
    ("ar", "ar"),
    ("fr", "fr"),
    ("pt-BR", "pt"),
    ("de", "de"),
    ("ja", "ja"),
    ("ko", "ko"),
    ("id", "id"),
    ("tr", "tr"),
    ("vi", "vi"),
    ("it", "it"),
    ("th", "th"),
    ("pl", "pl"),
    ("nl", "nl"),
    ("uk", "uk"),
    ("ro", "ro"),
    ("el", "el"),
    ("he", "iw"),  # Google code for Hebrew
    ("sv", "sv"),
    ("cs", "cs"),
    ("hu", "hu"),
    ("da", "da"),
    ("fi", "fi"),
    ("ms", "ms"),
    ("bn", "bn"),
    ("ur", "ur"),
    ("fa", "fa"),
    ("sw", "sw"),
    ("sk", "sk"),
    ("nb", "no"),
    ("fil", "tl"),
]

LINE_RE = re.compile(
    r'^"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?P<val>(?:[^"\\]|\\.)*)"\s*;\s*$'
)
SPEC_RE = re.compile(r"(%lld|%@|%%)")
SEP = "\n__BUGS_L10N_SPLIT__\n"
# Google Translate web API limit per request (~5000 chars); stay under with margin.
MAX_BATCH_CHARS = 4200


def unescape_strings_literal(s: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            n = s[i + 1]
            if n == "n":
                out.append("\n")
                i += 2
            elif n == '"':
                out.append('"')
                i += 2
            elif n == "\\":
                out.append("\\")
                i += 2
            else:
                out.append(s[i])
                i += 1
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def escape_strings_literal(s: str) -> str:
    return (
        s.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "")
    )


def protect_specs(s: str) -> tuple[str, list[str]]:
    specs: list[str] = []

    def repl(m: re.Match[str]) -> str:
        specs.append(m.group(1))
        return f"⟪{len(specs) - 1}⟫"

    return SPEC_RE.sub(repl, s), specs


def restore_specs(s: str, specs: list[str]) -> str:
    for i, sp in enumerate(specs):
        s = s.replace(f"⟪{i}⟫", sp)
    return s


def parse_en_structure() -> tuple[list[str], list[tuple[str, str]]]:
    """Returns (raw_lines_for_non_kv, list of (key, en_plain) in order)."""
    lines = EN_PATH.read_text(encoding="utf-8").splitlines()
    kv_ordered: list[tuple[str, str]] = []
    for line in lines:
        m = LINE_RE.match(line.strip())
        if m:
            kv_ordered.append(
                (
                    unescape_strings_literal(m.group("key")),
                    unescape_strings_literal(m.group("val")),
                )
            )
    return lines, kv_ordered


def build_file_for_locale(en_lines: list[str], translations: list[str]) -> str:
    it = iter(translations)
    out_lines: list[str] = []
    for line in en_lines:
        m = LINE_RE.match(line.strip())
        if not m:
            out_lines.append(line)
            continue
        key = unescape_strings_literal(m.group("key"))
        trans = next(it)
        out_lines.append(f'"{escape_strings_literal(key)}" = "{escape_strings_literal(trans)}";')
    return "\n".join(out_lines) + "\n"


def translate_batch(target_code: str, masked_parts: list[str]) -> list[str]:
    from deep_translator import GoogleTranslator

    t = GoogleTranslator(source="en", target=target_code)

    def translate_blob(blob: str) -> str:
        for attempt in range(5):
            try:
                return t.translate(blob)
            except Exception as e:
                msg = str(e)
                if len(msg) > 200:
                    msg = msg[:200] + "…"
                print(f"  batch retry {attempt}: {msg}")
                time.sleep(2.0 * (attempt + 1))
        return blob

    # Chunk by size so each request stays under API limit.
    chunks: list[list[str]] = []
    cur: list[str] = []
    cur_len = 0
    for p in masked_parts:
        add = len(p) + (len(SEP) if cur else 0)
        if cur and cur_len + add > MAX_BATCH_CHARS:
            chunks.append(cur)
            cur = [p]
            cur_len = len(p)
        else:
            if cur:
                cur_len += len(SEP) + len(p)
            else:
                cur_len = len(p)
            cur.append(p)
    if cur:
        chunks.append(cur)

    translated_parts: list[str] = []
    for chunk in chunks:
        blob = SEP.join(chunk)
        out_blob = translate_blob(blob)
        parts = out_blob.split(SEP)
        if len(parts) != len(chunk):
            print(
                f"  split mismatch {target_code}: chunk {len(parts)} vs {len(chunk)}; per-string fallback"
            )
            for p in chunk:
                translated_parts.append(translate_blob(p).strip())
                time.sleep(0.04)
        else:
            translated_parts.extend(p.strip() for p in parts)
        time.sleep(0.15)

    return translated_parts


def main() -> None:
    try:
        from deep_translator import GoogleTranslator  # noqa: F401
    except ImportError:
        print("pip install deep-translator")
        raise SystemExit(1)

    en_lines, kv_ordered = parse_en_structure()
    n = len(kv_ordered)
    print(f"Parsed {n} string entries from en")

    en_out = OUT_ROOT / "en.lproj/Localizable.strings"
    en_out.parent.mkdir(parents=True, exist_ok=True)
    en_out.write_text(EN_PATH.read_text(encoding="utf-8"), encoding="utf-8")
    print("Wrote en")

    if RU_PATH.exists():
        ru_out = OUT_ROOT / "ru.lproj/Localizable.strings"
        ru_out.parent.mkdir(parents=True, exist_ok=True)
        ru_out.write_text(RU_PATH.read_text(encoding="utf-8"), encoding="utf-8")
        print("Wrote ru (preserved)")

    masked_block: list[tuple[str, list[str]]] = []
    for _, en_val in kv_ordered:
        m, sp = protect_specs(en_val)
        masked_block.append((m, sp))

    masked_parts = [m for m, _ in masked_block]

    for folder, code in LOCALES:
        print(f"Translating → {folder} ({code})…")
        translated_masked = translate_batch(code, masked_parts)
        final: list[str] = []
        for i, (tm, specs) in enumerate(masked_block):
            raw = translated_masked[i] if i < len(translated_masked) else masked_parts[i]
            final.append(restore_specs(raw, specs))

        text = build_file_for_locale(en_lines, final)
        path = OUT_ROOT / f"{folder}.lproj/Localizable.strings"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"  wrote {path}")
        time.sleep(0.3)

    print("Done.")


if __name__ == "__main__":
    main()
