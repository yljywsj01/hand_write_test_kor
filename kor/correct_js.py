import os

input_folder = 'kor_hand'  # 資料夾名稱（請確認已放正確）
output_file = "kglyphlist.js"

korean_chars = set()

# 收集所有韓文字符
for filename in sorted(os.listdir(input_folder)):
    if filename.endswith(".txt"):
        with open(os.path.join(input_folder, filename), "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                for ch in line:
                    if ch.strip():  # 排除空白
                        korean_chars.add(ch)

# 生成 glyphMap
with open(output_file, "w", encoding="utf-8") as out:
    out.write("const glyphMap = {\n")
    for i, ch in enumerate(sorted(korean_chars)):
        hex_code = f"{ord(ch):04X}"
        line = f'  "uni{hex_code}": {{"c":"{ch}","w":"K","n":"{ch}"}}'
        line += ",\n" if i < len(korean_chars) - 1 else "\n"
        out.write(line)
    out.write("};\n")

print(f"✅ 成功產生 {output_file}，共 {len(korean_chars)} 個韓文字元。")