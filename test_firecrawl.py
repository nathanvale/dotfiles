import requests

url = "https://api.firecrawl.dev/v1/scrape"

payload = {
    "url": "https://www.google.com",
    "formats": ["markdown", "html"],
    "onlyMainContent": False
}

headers = {
    "Authorization": "Bearer fc-0cc6f584cb514db0a55baf2b24012eef",
    "Content-Type": "application/json"
}

response = requests.post(url, json=payload, headers=headers)

print(response.json())
