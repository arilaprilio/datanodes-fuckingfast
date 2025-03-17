<?php
function fetchUrl($url) {
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);

    $headers = [
        'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language: en-US,en;q=0.8',
        'Cache-Control: max-age=0',
        'Priority: u=0, i',
        'Sec-CH-UA: "Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
        'Sec-CH-UA-Mobile: ?0',
        'Sec-CH-UA-Platform: "Windows"',
        'Sec-Fetch-Dest: document',
        'Sec-Fetch-Mode: navigate',
        'Sec-Fetch-Site: none',
        'Sec-Fetch-User: ?1',
        'Sec-GPC: 1',
        'Upgrade-Insecure-Requests: 1',
        'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36'
    ];

    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    $response = curl_exec($ch);

    if (curl_errno($ch)) {
        $error = 'Curl Error: ' . curl_error($ch);
        curl_close($ch);
        return $error;
    }

    curl_close($ch);
    return $response;
}

function getUrlDL($web) {
    if (strstr($web, "datanodes.to")) {
        $url = "https://datanodes.to/download";
        $origin = "https://datanodes.to/";
        $parse = parse_url($web);
        preg_match("/\/(.*?)\//", $parse['path'], $match);
        $id = $match[1];
    } elseif (strstr($web, "fuckingfast.co")) {
        $data = fetchUrl($web);
        preg_match('/window\.open\("(.*?)"\)/i', $data, $match);
        $url = $match[1];
        return $url;
    }
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    $headers = [
        'Accept: */*',
        'Accept-Language: en-US,en;q=0.7',
        'Content-Type: multipart/form-data; boundary=----WebKitFormBoundary2s79RKUOHqeHIAiE',
        'Origin: ' . $origin,
        'Priority: u=1, i',
        'Referer: ' . $url,
        'Sec-CH-UA: "Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
        'Sec-CH-UA-Mobile: ?0',
        'Sec-CH-UA-Platform: "Windows"',
        'Sec-Fetch-Dest: empty',
        'Sec-Fetch-Mode: cors',
        'Sec-Fetch-Site: same-origin',
        'Sec-GPC: 1',
        'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36'
    ];
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $data = "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"op\"\r\n\r\n" .
            "download2\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"id\"\r\n\r\n" .
            $id . "\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"rand\"\r\n\r\n" .
            "\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"referer\"\r\n\r\n" .
            $url . "\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"method_free\"\r\n\r\n" .
            "Free Download >>\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"method_premium\"\r\n\r\n" .
            "\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE\r\n" .
            "Content-Disposition: form-data; name=\"dl\"\r\n\r\n" .
            "1\r\n" .
            "------WebKitFormBoundary2s79RKUOHqeHIAiE--\r\n";

    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);

    $response = curl_exec($ch);

    if (curl_errno($ch)) {
        echo 'Error: ' . curl_error($ch);
    } else {
        $json = json_decode($response, true);
        return urldecode($json['url']);
    }

    curl_close($ch);
}

$input = readline("List url file : ");
if (!file_exists($input)) {
    die("File not found !");
}
echo "File download method :\n";
echo "1. aria2c (faster)\n";
echo "2. wget\n\n";
$dl = readline("(1/2) >> ");
$exp = explode("\n", file_get_contents($input));
$folder = readline("Folder to save the file : ");
if (!file_exists($folder)) {
    @mkdir($folder);
}
foreach ($exp as $link) {
    $urlnya = getUrlDL($link);
    if (strstr($link, "datanodes.to")) {
        $namafile = basename($link);
    } elseif (strstr($link, "fuckingfast.co")) {
        $parsed_url = parse_url($link, PHP_URL_FRAGMENT);
        $namafile = basename($parsed_url);
    }
    if ($dl === "1") {
        passthru("aria2c '".$urlnya."' -o '".$folder."/".$namafile."' -x 16 -s 16");
    } elseif ($dl === "2") {
        passthru("wget -O '".$folder."/".$namafile."' '".$urlnya."'");
    } else {
        die("Download method not found.");
    }
}
