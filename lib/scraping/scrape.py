from urllib.parse import urljoin
import re
import requests
from bs4 import BeautifulSoup

BASE = "https://animalrestaurant.fandom.com"
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; AnimalRestaurantTracker/1.0)"}

def _is_wiki_article(href: str) -> bool:
    return bool(href) and href.startswith("/wiki/") and ":" not in href

def discover_regular_customer_urls() -> list[str]:
    url = "https://animalrestaurant.fandom.com/wiki/Regular_Customers"
    html = requests.get(url, headers=HEADERS, timeout=30).text
    soup = BeautifulSoup(html, "html.parser")

    content = soup.select_one("div.mw-parser-output")
    if not content:
        return []

    urls = set()

    # Regular customers page has a big table. We only take links inside tables.
    for a in content.select("table a[href]"):
        href = a.get("href", "")
        if not _is_wiki_article(href):
            continue

        absu = urljoin(BASE, href.split("#")[0])

        # Skip obvious non-customer pages
        if absu.endswith("/wiki/Regular_Customers"):
            continue
        if absu.endswith("/wiki/Customers"):
            continue

        urls.add(absu)

    return sorted(urls)
