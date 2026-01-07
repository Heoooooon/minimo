#!/bin/bash

# PocketBase 서버 시작 스크립트
# 사용법: ./start.sh

cd "$(dirname "$0")"

echo "🚀 PocketBase 서버 시작..."
echo "📂 Admin UI: http://127.0.0.1:8090/_/"
echo "🔗 API: http://127.0.0.1:8090/api/"
echo ""
echo "⚠️  처음 실행 시 Admin UI에서 관리자 계정을 생성하세요."
echo "⚠️  그 후 'aquariums' 컬렉션을 생성하세요."
echo ""

./pocketbase serve --http=127.0.0.1:8090
