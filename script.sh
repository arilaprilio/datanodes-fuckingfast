#!/bin/bash
# Skrip Bash untuk mendownload file dengan metode yang sama persis seperti skrip PHP

# Fungsi fetchUrl: Melakukan request GET dengan header tertentu
fetchUrl() {
    local url="$1"
    curl --fail --location --max-time 30 -s \
         -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8' \
         -H 'Accept-Language: en-US,en;q=0.8' \
         -H 'Cache-Control: max-age=0' \
         -H 'Priority: u=0, i' \
         -H 'Sec-CH-UA: "Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"' \
         -H 'Sec-CH-UA-Mobile: ?0' \
         -H 'Sec-CH-UA-Platform: "Windows"' \
         -H 'Sec-Fetch-Dest: document' \
         -H 'Sec-Fetch-Mode: navigate' \
         -H 'Sec-Fetch-Site: none' \
         -H 'Sec-Fetch-User: ?1' \
         -H 'Sec-GPC: 1' \
         -H 'Upgrade-Insecure-Requests: 1' \
         -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36' \
         "$url"
}

# Fungsi getUrlDL: Menghasilkan URL download sesuai domain
getUrlDL() {
    local web="$1"
    if [[ "$web" == *"datanodes.to"* ]]; then
        local url="https://datanodes.to/download"
        local origin="https://datanodes.to/"
        # Ekstrak ID dari URL (mengambil segmen pertama dari path)
        local id
        id=$(echo "$web" | sed -n 's|.*//[^/]\+/\([^/]\+\)/.*|\1|p')

        # Boundary untuk multipart/form-data
        local boundary="----WebKitFormBoundary2s79RKUOHqeHIAiE"
        # Buat payload POST dengan CRLF \r\n
        local post_data=""
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"op\"\r\n\r\n"
        post_data+="download2\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"id\"\r\n\r\n"
        post_data+="${id}\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"rand\"\r\n\r\n"
        post_data+="\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"referer\"\r\n\r\n"
        post_data+="${url}\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"method_free\"\r\n\r\n"
        post_data+="Free Download >>\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"method_premium\"\r\n\r\n"
        post_data+="\r\n"
        post_data+="--${boundary}\r\n"
        post_data+="Content-Disposition: form-data; name=\"dl\"\r\n\r\n"
        post_data+="1\r\n"
        post_data+="--${boundary}--\r\n"

        # Lakukan request POST dengan header yang diperlukan
        response=$(curl --fail -s -X POST "$url" \
          -H 'Accept: */*' \
          -H 'Accept-Language: en-US,en;q=0.7' \
          -H "Content-Type: multipart/form-data; boundary=${boundary}" \
          -H "Origin: ${origin}" \
          -H 'Priority: u=1, i' \
          -H "Referer: ${url}" \
          -H 'Sec-CH-UA: "Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"' \
          -H 'Sec-CH-UA-Mobile: ?0' \
          -H 'Sec-CH-UA-Platform: "Windows"' \
          -H 'Sec-Fetch-Dest: empty' \
          -H 'Sec-Fetch-Mode: cors' \
          -H 'Sec-Fetch-Site: same-origin' \
          -H 'Sec-GPC: 1' \
          -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36' \
          --data-binary "$post_data")

        # Ambil URL download dari respons JSON dan lakukan URL decoding menggunakan python3
        dl_url=$(echo "$response" | jq -r '.url')
        decoded_url=$(python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$dl_url")
        echo "$decoded_url"
    elif [[ "$web" == *"fuckingfast.co"* ]]; then
        # Untuk domain fuckingfast.co, ambil konten halaman dan ekstrak URL dari window.open("...")
        data=$(fetchUrl "$web")
        url=$(echo "$data" | grep -oP 'window\.open\("\K(.*?)"(?="\))')
        echo "$url"
    else
        echo "Unsupported URL: $web" >&2
        return 1
    fi
}

# Main script

read -p "List url file : " input
if [[ ! -f "$input" ]]; then
    echo "File not found !"
    exit 1
fi

echo "File download method :"
echo "1. aria2c (faster)"
echo "2. wget"
echo ""
read -p "(1/2) >> " dl

# Baca semua baris file URL
mapfile -t links < "$input"

read -p "Folder to save the file : " folder
if [[ ! -d "$folder" ]]; then
    mkdir -p "$folder"
fi

for link in "${links[@]}"; do
    # Hapus spasi berlebih
    link=$(echo "$link" | xargs)
    [[ -z "$link" ]] && continue

    urlnya=$(getUrlDL "$link")
    if [[ "$link" == *"datanodes.to"* ]]; then
        # Nama file: ambil basename dari URL
        namafile=$(basename "$link")
    elif [[ "$link" == *"fuckingfast.co"* ]]; then
        # Untuk fuckingfast.co, ambil fragmen URL (bagian setelah #) lalu basename-nya
        fragment="${link##*#}"
        namafile=$(basename "$fragment")
    else
        namafile="downloaded_file"
    fi

    if [[ "$dl" == "1" ]]; then
        aria2c "$urlnya" -o "$folder/$namafile" -x 16 -s 16
    elif [[ "$dl" == "2" ]]; then
        wget -O "$folder/$namafile" "$urlnya"
    else
        echo "Download method not found."
        exit 1
    fi
done
