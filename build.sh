#!/bin/sh

RESULT=$(docker-compose build)
IMAGE_ID=$(echo $CONTAINER_LIST | cut -d ' ' -f1)


for i in $RESULT
do
    if [ "$i" = "Successfully" ]; then
        echo "Build successful"
        IMAGE_ID=$(echo "$RESULT" | grep "Successfully built" | awk '{print $3}')
        IMAGE_NAME=$(docker images | grep "$IMAGE_ID" | awk '{print $1":"$2}')
        echo "Scanning image..."
        result=$(curl -X POST -H "Content-Type: application/json" -d '{"image_id":"'$IMAGE_ID'"}' http://localhost:8000/image/scan | jq -r ".scan_result[].Severity")

        #이미지 스캔 진행, 진행 과정 중 CRITICAL 발견 시 CD 중지
        for i in $result
        do
            if [ "$i" = "CRITICAL" ]; then
                echo "CRITICAL VULNERAVILITY"
                exit 1                
            fi
        done

        #스캔 결과에 따른 이미지 사이닝 진행
        signing=$(curl -X POST -H "Content-Type: application/json" -d '{"image_id":"'$IMAGE_ID'"}' http://localhost:8000/image/signing_image)
        isSigned=$(curl $signing | awk '{print length($0)}')
        
        #사이닝 결과가 정상적일 경우 검증 실행 결과 리턴
        if [ -z "$isSigned" ]; then
            echo "SIGNING SUCCESS"
            verify=$(curl -X POST -H "Content-Type: application/json" -d '{"image_id":"'$IMAGE_ID'"}' http://localhost:8000/image/verify_image)
            echo $verify        
        else 
            echo "SIGNING FAILED"
            exit 1                
        fi

        docker-compose up -d
        exit 0  
    fi
done
