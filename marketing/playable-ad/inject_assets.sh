#!/bin/bash

# Read base64 strings
JET_B64=$(cat jet_base64_clean.txt)
OBSTACLE_B64=$(cat obstacle_base64_clean.txt)

# Create updated HTML with embedded assets
cp flappyjet-playable.html flappyjet-playable-with-assets.html

# Add image loading code after the canvas setup
sed -i.bak '/resizeCanvas();/a\
\
        \/\/ Load embedded assets\
        const jetImg = new Image();\
        const obstacleImg = new Image();\
        let assetsLoaded = 0;\
        \
        jetImg.onload = () => {\
            assetsLoaded++;\
            if (assetsLoaded === 2) console.log("Assets loaded!");\
        };\
        \
        obstacleImg.onload = () => {\
            assetsLoaded++;\
            if (assetsLoaded === 2) console.log("Assets loaded!");\
        };\
        \
        jetImg.src = "data:image/png;base64,'"$JET_B64"'";\
        obstacleImg.src = "data:image/png;base64,'"$OBSTACLE_B64"'";
' flappyjet-playable-with-assets.html

echo "✅ Assets injected into flappyjet-playable-with-assets.html"
