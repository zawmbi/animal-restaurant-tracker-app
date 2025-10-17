import pandas as pd
from bs4 import BeautifulSoup
from io import StringIO

input_html = "recipes.html"
output_csv = "animal_restaurant_recipes_full.csv"

with open(input_html, "r", encoding="utf-8") as f:
    soup = BeautifulSoup(f, "html.parser")

tables = soup.find_all("table")
dfs = []

for table in tables:
    html_str = StringIO(str(table))
    df = pd.read_html(html_str)[0]
    dfs.append(df)

df_all = pd.concat(dfs, ignore_index=True)

# Flatten possible multi-level headers
df_all.columns = [
    " ".join(c).strip() if isinstance(c, tuple) else c.strip()
    for c in df_all.columns
]

# Clean up all columns
for col in df_all.columns:
    df_all[col] = (
        df_all[col].astype(str)
        .str.replace(r"\s+", " ", regex=True)
        .str.strip()
    )

df_all.to_csv(output_csv, index=False, encoding="utf-8-sig")
print(f"✅ Exported {len(df_all)} rows to {output_csv}")
