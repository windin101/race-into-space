#!/usr/bin/env python3
"""Build game/data/text/casing.json: how each word of the upstream ALL-CAPS prose is cased
when the game shows it in sentence case. Only words that are not plain lowercase are stored.

    python3 tools/gen_casing.py [--model qwen3:32b-nothink]

Classification is by the local Ollama model, given each word with one example sentence;
HAND overrides it. The game applies the map in TextCase.sentence() (scripts/ui/text_case.gd).
"""
import argparse, json, re, urllib.request
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
TEXT = ROOT / "game/data/text"
OUT = TEXT / "casing.json"
# fixed forms the model must not decide: units, agencies, the game's own abbreviations
HAND = {"MB": "MB", "M.B.": "MB", "M.B.'S": "MB", "MB'S": "MB", "KGB": "KGB", "CIA": "CIA", "MI6": "MI6", "NASA": "NASA",
        "USA": "USA", "US": "US", "USSR": "USSR", "UK": "UK", "UN": "UN", "TV": "TV", "BBC": "BBC", "CCCP": "CCCP", "BOAC": "BOAC",
        "LM": "LM", "EVA": "EVA", "EOR": "EOR", "LOR": "LOR", "R&D": "R&D", "I": "I", "I'M": "I'm", "I'LL": "I'll", "I'VE": "I've", "I'D": "I'd",
        "MOON": "Moon", "EARTH": "Earth", "SOVIET": "Soviet", "SOVIETS": "Soviets", "AMERICAN": "American", "AMERICANS": "Americans",
        "COMMONWEALTH": "Commonwealth", "PRESIDENT": "President", "KNOX-JOHNSTON": "Knox-Johnston", "TODAY": "today", "PREMIER": "Premier", "KREMLIN": "Kremlin", "CONGRESS": "Congress"}

def corpus():
    words, example = {}, {}
    for f in ("news", "events", "endgame", "reviews", "help"):
        def walk(x):
            if isinstance(x, str):
                for sent in re.split(r"(?<=[.!?])\s+", x):
                    for w in re.findall(r"[A-Za-z][A-Za-z0-9.'&-]*[A-Za-z0-9]|[A-Za-z]", sent):
                        k = w.upper().rstrip(".")
                        words[k] = words.get(k, 0) + 1
                        example.setdefault(k, sent[:160])
            elif isinstance(x, dict):
                for kk, v in x.items():
                    if not kk.startswith("_"): walk(v)
            elif isinstance(x, list):
                for v in x: walk(v)
        walk(json.loads((TEXT / f"{f}.json").read_text()))
    return words, example

def ask(model, batch, example):
    lines = "\n".join(f"{w}\t{example[w]}" for w in batch)
    prompt = ("You restore normal English capitalisation to text that was written in ALL CAPS (1960s-70s space race news). "
              "For each WORD below (followed by a tab and an example sentence it appears in), say how it is written mid-sentence in normal English: "
              "'lower' for ordinary words (most words), 'Title' for proper nouns (people, places, nations, organisations, ships, spacecraft, programmes, "
              "days, months), or the exact form for acronyms and abbreviations (e.g. NATO, U.N., Ph.D). "
              "Reply with only a JSON object mapping each WORD exactly as given to its answer.\n\n" + lines)
    body = json.dumps({"model": model, "prompt": prompt, "stream": False, "format": "json", "options": {"temperature": 0}}).encode()
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=900) as r:
        out = json.loads(r.read())
    txt = out.get("response") or out.get("thinking") or "{}"
    return json.loads(txt)

ap = argparse.ArgumentParser(); ap.add_argument("--model", default="qwen3:32b-nothink"); ap.add_argument("--batch", type=int, default=120)
a = ap.parse_args()
words, example = corpus()
todo = sorted(w for w in words if w not in HAND and re.search(r"[A-Z]", w))
print(len(todo), "words to classify")
casing = {}
for i in range(0, len(todo), a.batch):
    batch = todo[i:i + a.batch]
    try:
        res = ask(a.model, batch, example)
    except Exception as e:
        print("batch failed, retrying smaller:", e); res = {}
        for j in range(0, len(batch), 30):
            try: res.update(ask(a.model, batch[j:j + 30], example))
            except Exception as e2: print("  sub-batch failed:", e2)
    for w in batch:
        v = str(res.get(w, "lower"))
        if v == "lower" or v.lower() == w.lower() and v == w.lower():
            continue
        casing[w] = w.capitalize() if v == "Title" else v
    print(f"{min(i + a.batch, len(todo))}/{len(todo)}", flush=True)
# nationalities and faiths the model left lowercase
DEMONYMS = """AFRICAN ARAB ASIANS AUSTRALIAN AUSTRALIANS BRITISH CAMBODIAN CANADIAN CANADIAN CHRISTIAN CUBAN ENGLISH EUROPEAN FRENCH GERMAN INDIAN ISRAELI LENINIST RUSSIAN VIETNAMESE""".split()
HAND.update({w: "-".join(x.capitalize() for x in w.split("-")) for w in DEMONYMS})
# ordinary words the model capitalised from context (headline style); lowercase mid-sentence
COMMON = set("""CANYON CAPTAIN CATHEDRAL CENTER COLONEL DOCTOR FEDERATION FOOTBALL GAMES GENERAL GOVERNOR HILL HOUSE KING LABOR
MARKET MIDNIGHT MINI NAVY OFFENSIVE OPERA PACT PARADE PARTY PEERAGE PENGUIN SENATOR SOCIALISM SOCIALIST SOCIETY STRIP
SUMMER SUMMIT SUPREME TIME TITLE TODAY""".split())
fixed = {}
for k, v in casing.items():
    if k in COMMON:
        continue
    if v.lower() == "acronym":
        v = {"FLT": "Flt", "M": "M", "M.B": "MB"}.get(k, k)
    elif "-" in k and v.lower() == k.lower():
        v = "-".join(part.capitalize() for part in k.split("-"))
    fixed[k] = v
fixed["SR.N1"] = "SR.N1"
casing = fixed
# every programme name in the game is a proper noun, whatever the model thought
for side in json.loads((ROOT / "game/data/hardware.json").read_text())["models"]["basic"].values():
    for group in side.values():
        for spec in group:
            if spec:
                for part in re.split(r"\s+", spec["name"]):
                    if re.fullmatch(r"[A-Z][A-Z0-9-]*", part) and part not in ("I", "II", "A", "B", "C"):
                        casing[part] = part if re.search(r"\d", part) else "-".join(x.capitalize() for x in part.split("-"))   # UR-700, R-7 stay
casing.update(HAND)
OUT.write_text(json.dumps({"_about": "Mid-sentence casing for words of the ALL-CAPS upstream prose; anything absent is lowercase. Built by tools/gen_casing.py (local Ollama, then HAND overrides).",
                           "words": dict(sorted(casing.items()))}, indent=1) + "\n")
print("wrote", OUT, len(casing), "entries")
