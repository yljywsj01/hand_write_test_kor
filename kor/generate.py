import os

output_filename = "hangul_syllables_with_unicode.txt"

with open(output_filename, "w", encoding="utf-8") as f:
    for code in range(0xAC00, 0xD7A4):
        ch = chr(code)
        f.write(f"{ch}\tU+{code:04X}\n")

print(f"✅ Successfully created {output_filename}")
