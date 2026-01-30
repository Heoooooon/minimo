#!/bin/bash

cd "$(dirname "$0")"

if [ ! -f ./minimo-backend ]; then
    echo "빌드 중..."
    go build -o minimo-backend .
fi

echo "PocketBase 서버 시작..."
echo "Admin UI: http://127.0.0.1:8090/_/"
echo "API: http://127.0.0.1:8090/api/"
echo "Custom API: http://127.0.0.1:8090/api/community/"
echo ""

./minimo-backend serve --http=127.0.0.1:8090
