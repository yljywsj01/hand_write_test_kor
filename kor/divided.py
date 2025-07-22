import unicodedata
from collections import defaultdict

# 判斷是否為韓文字（完整音節）
def is_hangul_syllable(ch):
    return 0xAC00 <= ord(ch) <= 0xD7A3

# 判斷是否為子音/母音（자모）
def is_jamo(ch):
    return 0x1100 <= ord(ch) <= 0x11FF or 0x3130 <= ord(ch) <= 0x318F

# 第一步：統計所有字符出現次數
char_freq = defaultdict(int)

with open("ko_full.txt", "r", encoding="utf-8") as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) != 2:
            continue
        word, count = parts
        count = int(count)
        for ch in word:
            char_freq[ch] += count

# 第二步：分類
jamo_list = []
syllable_list = []

for ch, freq in char_freq.items():
    if is_jamo(ch):
        jamo_list.append((ch, freq))
    elif is_hangul_syllable(ch):
        syllable_list.append((ch, freq))

# 排序
jamo_list.sort(key=lambda x: -x[1])           # 자모按照頻率
syllable_list.sort(key=lambda x: -x[1])       # 韓文字按照頻率

# 第三步：分成 15 份
total_groups = 15
output_files = [f"hangul_part_{i:02}.txt" for i in range(total_groups)]

# 第一份 = 자모
with open(output_files[0], "w", encoding="utf-8") as f:
    for ch, freq in jamo_list:
        f.write(ch + "\n")

# 剩下的 14 份平均分配 syllable
group_size = len(syllable_list) // (total_groups - 1) + 1

for i in range(1, total_groups):
    start = (i - 1) * group_size
    end = i * group_size
    group = syllable_list[start:end]

    with open(output_files[i], "w", encoding="utf-8") as f:
        for ch, freq in group:
            f.write(f"{ch}\tU+{ord(ch):04X}\n")

print("✅ 所有分組已完成並儲存為 hangul_part_00.txt ~ hangul_part_14.txt")
