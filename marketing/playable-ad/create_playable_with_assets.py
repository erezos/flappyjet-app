#!/usr/bin/env python3
"""
Create playable ad with embedded FlappyJet assets
"""

# Read base64 strings
with open('jet_base64_clean.txt', 'r') as f:
    jet_b64 = f.read().strip()

with open('obstacle_base64_clean.txt', 'r') as f:
    obstacle_b64 = f.read().strip()

# Read original HTML
with open('flappyjet-playable.html', 'r') as f:
    html = f.read()

# Find where to inject the image loading code (after resizeCanvas)
injection_point = html.find('resizeCanvas();')
if injection_point == -1:
    print("Error: Could not find injection point")
    exit(1)

# Find the end of the line
injection_point = html.find('\n', injection_point) + 1

# Create the image loading code
image_code = f'''
        // Load embedded FlappyJet assets
        const jetImg = new Image();
        const obstacleImg = new Image();
        let assetsLoaded = 0;
        let useRealAssets = false;
        
        jetImg.onload = () => {{
            assetsLoaded++;
            if (assetsLoaded === 2) {{
                useRealAssets = true;
                console.log("✅ FlappyJet assets loaded!");
            }}
        }};
        
        obstacleImg.onload = () => {{
            assetsLoaded++;
            if (assetsLoaded === 2) {{
                useRealAssets = true;
                console.log("✅ FlappyJet assets loaded!");
            }}
        }};
        
        jetImg.src = "data:image/png;base64,{jet_b64}";
        obstacleImg.src = "data:image/png;base64,{obstacle_b64}";
'''

# Inject the code
new_html = html[:injection_point] + image_code + html[injection_point:]

# Now update the drawJet function to use the real image
old_draw_jet = '''        // Draw jet
        function drawJet() {
            ctx.save();
            ctx.translate(jet.x + jet.width/2, jet.y + jet.height/2);
            ctx.rotate(jet.rotation);
            
            // Jet body (simplified)
            ctx.fillStyle = '#4A90E2';
            ctx.fillRect(-jet.width/2, -jet.height/2, jet.width, jet.height);
            
            // Jet nose
            ctx.fillStyle = '#2E5C8A';
            ctx.beginPath();
            ctx.moveTo(jet.width/2, 0);
            ctx.lineTo(jet.width/2 + 10, 0);
            ctx.lineTo(jet.width/2, -5);
            ctx.closePath();
            ctx.fill();
            
            // Wing
            ctx.fillStyle = '#FF6B6B';
            ctx.fillRect(-5, jet.height/2, 20, 8);
            
            ctx.restore();
        }'''

new_draw_jet = '''        // Draw jet
        function drawJet() {
            ctx.save();
            ctx.translate(jet.x + jet.width/2, jet.y + jet.height/2);
            ctx.rotate(jet.rotation);
            
            if (useRealAssets && jetImg.complete) {
                // Draw real FlappyJet sprite
                ctx.drawImage(jetImg, -jet.width/2, -jet.height/2, jet.width, jet.height);
            } else {
                // Fallback: simplified jet
                ctx.fillStyle = '#4A90E2';
                ctx.fillRect(-jet.width/2, -jet.height/2, jet.width, jet.height);
                
                ctx.fillStyle = '#2E5C8A';
                ctx.beginPath();
                ctx.moveTo(jet.width/2, 0);
                ctx.lineTo(jet.width/2 + 10, 0);
                ctx.lineTo(jet.width/2, -5);
                ctx.closePath();
                ctx.fill();
                
                ctx.fillStyle = '#FF6B6B';
                ctx.fillRect(-5, jet.height/2, 20, 8);
            }
            
            ctx.restore();
        }'''

new_html = new_html.replace(old_draw_jet, new_draw_jet)

# Update drawObstacles to use real image
old_draw_obstacles = '''        // Draw obstacles
        function drawObstacles() {
            ctx.fillStyle = '#2ECC71';
            ctx.strokeStyle = '#27AE60';
            ctx.lineWidth = 3;
            
            obstacles.forEach(obs => {
                // Top obstacle
                ctx.fillRect(obs.x, 0, obstacleWidth, obs.topHeight);
                ctx.strokeRect(obs.x, 0, obstacleWidth, obs.topHeight);
                
                // Bottom obstacle
                ctx.fillRect(obs.x, obs.bottomY, obstacleWidth, canvas.height - obs.bottomY);
                ctx.strokeRect(obs.x, obs.bottomY, obstacleWidth, canvas.height - obs.bottomY);
            });
        }'''

new_draw_obstacles = '''        // Draw obstacles
        function drawObstacles() {
            obstacles.forEach(obs => {
                if (useRealAssets && obstacleImg.complete) {
                    // Draw real FlappyJet obstacle sprites
                    // Top obstacle (flipped)
                    ctx.save();
                    ctx.translate(obs.x + obstacleWidth/2, obs.topHeight);
                    ctx.scale(1, -1);
                    ctx.drawImage(obstacleImg, -obstacleWidth/2, 0, obstacleWidth, obs.topHeight);
                    ctx.restore();
                    
                    // Bottom obstacle
                    ctx.drawImage(obstacleImg, obs.x, obs.bottomY, obstacleWidth, canvas.height - obs.bottomY);
                } else {
                    // Fallback: simple green pipes
                    ctx.fillStyle = '#2ECC71';
                    ctx.strokeStyle = '#27AE60';
                    ctx.lineWidth = 3;
                    
                    ctx.fillRect(obs.x, 0, obstacleWidth, obs.topHeight);
                    ctx.strokeRect(obs.x, 0, obstacleWidth, obs.topHeight);
                    
                    ctx.fillRect(obs.x, obs.bottomY, obstacleWidth, canvas.height - obs.bottomY);
                    ctx.strokeRect(obs.x, obs.bottomY, obstacleWidth, canvas.height - obs.bottomY);
                }
            });
        }'''

new_html = new_html.replace(old_draw_obstacles, new_draw_obstacles)

# Save the new HTML
with open('flappyjet-playable-with-assets.html', 'w') as f:
    f.write(new_html)

print("✅ Created flappyjet-playable-with-assets.html")
print(f"   Jet asset: {len(jet_b64)} bytes")
print(f"   Obstacle asset: {len(obstacle_b64)} bytes")
print(f"   Total HTML size: {len(new_html)} bytes ({len(new_html)/1024:.1f} KB)")
print("\n🎮 Open flappyjet-playable-with-assets.html to see real FlappyJet assets!")
