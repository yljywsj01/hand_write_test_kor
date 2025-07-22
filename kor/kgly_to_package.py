import re
import json

# 輸入檔案名
input_file = 'kglyphlist.js'

# 輸出 package 名稱
package_name = '韓文包'

with open(input_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 擷取 JS 中的大括號內容
match = re.search(r'{[\s\S]*}', content)
if not match:
    raise ValueError('無法從檔案中提取 JSON 區塊')

# 將內容轉為 Python dict
glyph_dict = json.loads(match.group())

# 取出所有 key（即 "uniXXXX"）
unicode_keys = list(glyph_dict.keys())

# 寫檔 JS 的 glyphList 格式
with open("korean_package.js", "w", encoding="utf-8") as f:
    f.write(f'"{package_name}": {json.dumps(unicode_keys, ensure_ascii=False)},\n')