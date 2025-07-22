import pandas as pd
import unicodedata
import re
from collections import defaultdict
import json

CHOSUNG_LIST = [chr(code) for code in range(0x1100, 0x1113)]
JUNGSUNG_LIST = [chr(code) for code in range(0x1161, 0x1176)]
JONGSUNG_LIST = [chr(code) for code in range(0x11A8, 0x11C3)]
HANGUL_PARTS = set(CHOSUNG_LIST + JUNGSUNG_LIST + JONGSUNG_LIST)

def is_non_composable(char):
    return char in HANGUL_PARTS

def get_unicode_id(char):
    return f"uni{ord(char):04X}"

def load_all_csv_and_merge():
    file_list = [
        "all_speakers_frequency_counts_final.csv",
        "adult_frequency_counts_final.csv",
        "children_frequency_counts_final.csv",
        "elderly_frequency_counts_final.csv"
    ]

    freq_dict = defaultdict(float)
    for file in file_list:
        df = pd.read_csv(file)
        for _, row in df.iterrows():
            word = str(row["WORD"])
            count = float(row["COUNT_ADJUST"])
            if all('\uac00' <= c <= '\ud7a3' for c in word):
                for char in word:
                    freq_dict[char] += count

    freq_df = pd.DataFrame(list(freq_dict.items()), columns=["WORD", "COUNT_ADJUST"])
    freq_df = freq_df.sort_values("COUNT_ADJUST", ascending=False).reset_index(drop=True)
    return freq_df

def generate_non_composable_group():
    return sorted([get_unicode_id(ch) for ch in HANGUL_PARTS])

def group_words(words_df, base_limit=400, max_groups=7):
    grouped = {}
    seen = set()
    group_id = 2
    i = 0

    while group_id <= (1 + max_groups) and i < len(words_df):
        current_group = set()
        while len(current_group) < base_limit and i < len(words_df):
            word = words_df.loc[i, "WORD"]
            if word not in seen:
                seen.add(word)
                current_group.add(word)
            i += 1
        grouped[f"韓文包-{group_id}"] = sorted([get_unicode_id(w) for w in current_group])
        group_id += 1

    return grouped, seen

def get_all_hangul_syllables():
    return {chr(code) for code in range(0xAC00, 0xD7A4)}

def main():
    print("讀取中...")
    words_df = load_all_csv_and_merge()

    result = {}
    result["韓文包-1"] = generate_non_composable_group()

    grouped, seen = group_words(words_df)

    result.update(grouped)

    all_hangul_chars = get_all_hangul_syllables()
    unseen_chars = sorted(all_hangul_chars - seen)
    result["韓文包-9"] = [get_unicode_id(w) for w in unseen_chars]

    with open("korean_font_groups.json", "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=None, separators=(',', ': '))
        f.write("\n")  # 加一個換行符號

    print("✅ 分組完成！已輸出 korean_font_groups.json")

if __name__ == "__main__":
    main()
