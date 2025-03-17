#!/usr/bin/env python3
import os
import re
import sys
import json
import urllib.parse
import subprocess
import requests

def fetchUrl(url):
    headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.8',
        'Cache-Control': 'max-age=0',
        'Priority': 'u=0, i',
        'Sec-CH-UA': '"Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
        'Sec-CH-UA-Mobile': '?0',
        'Sec-CH-UA-Platform': '"Windows"',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Sec-GPC': '1',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36'
    }
    try:
        r = requests.get(url, headers=headers, allow_redirects=True, timeout=30)
        r.raise_for_status()
        return r.text
    except requests.RequestException as e:
        return f"Curl Error: {str(e)}"

def getUrlDL(web):
    if "datanodes.to" in web:
        url = "https://datanodes.to/download"
        origin = "https://datanodes.to/"
        # Ekstrak ID dari URL dengan mengambil segmen pertama dari path
        parsed = urllib.parse.urlparse(web)
        match = re.search(r'/([^/]+)/', parsed.path)
        if match:
            id_value = match.group(1)
        else:
            print("Error extracting id from URL:", web, file=sys.stderr)
            return None

        payload = {
            'op': 'download2',
            'id': id_value,
            'rand': '',
            'referer': url,
            'method_free': 'Free Download >>',
            'method_premium': '',
            'dl': '1'
        }
        headers = {
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.7',
            # requests akan membuat header Content-Type multipart/form-data sendiri
            'Origin': origin,
            'Priority': 'u=1, i',
            'Referer': url,
            'Sec-CH-UA': '"Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
            'Sec-CH-UA-Mobile': '?0',
            'Sec-CH-UA-Platform': '"Windows"',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-GPC': '1',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36'
        }
        try:
            r = requests.post(url, data=payload, headers=headers)
            r.raise_for_status()
            json_data = r.json()
            if 'url' in json_data:
                # URL decoding
                return urllib.parse.unquote(json_data['url'])
            else:
                print("Error: 'url' not found in response JSON", file=sys.stderr)
                return None
        except requests.RequestException as e:
            print("Error during POST request:", e, file=sys.stderr)
            return None
        except json.JSONDecodeError:
            print("Error decoding JSON response", file=sys.stderr)
            return None

    elif "fuckingfast.co" in web:
        data = fetchUrl(web)
        match = re.search(r'window\.open\("([^"]+)"\)', data, re.IGNORECASE)
        if match:
            return match.group(1)
        else:
            print("Error: Could not find download URL in the response for", web, file=sys.stderr)
            return None
    else:
        print("Unsupported URL:", web, file=sys.stderr)
        return None

def main():
    input_file = input("List url file : ").strip()
    if not os.path.isfile(input_file):
        print("File not found!")
        sys.exit(1)

    print("File download method :")
    print("1. aria2c (faster)")
    print("2. wget")
    print("")
    dl_method = input("(1/2) >> ").strip()

    with open(input_file, "r") as f:
        links = f.read().splitlines()

    folder = input("Folder to save the file : ").strip()
    if not os.path.isdir(folder):
        os.makedirs(folder, exist_ok=True)

    for link in links:
        link = link.strip()
        if not link:
            continue

        dl_url = getUrlDL(link)
        if not dl_url:
            continue

        # Tentukan nama file sesuai dengan domain
        if "datanodes.to" in link:
            filename = os.path.basename(link)
        elif "fuckingfast.co" in link:
            # Untuk domain ini, ambil fragmen URL (bagian setelah '#' jika ada)
            parsed = urllib.parse.urlparse(link)
            filename = os.path.basename(parsed.fragment) if parsed.fragment else "downloaded_file"
        else:
            filename = "downloaded_file"

        output_path = os.path.join(folder, filename)
        print(f"Downloading {dl_url} to {output_path}")

        if dl_method == "1":
            subprocess.run(["aria2c", dl_url, "-o", output_path, "-x", "16", "-s", "16"])
        elif dl_method == "2":
            subprocess.run(["wget", "-O", output_path, dl_url])
        else:
            print("Download method not found.")
            sys.exit(1)

if __name__ == "__main__":
    main()
