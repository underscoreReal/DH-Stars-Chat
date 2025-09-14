# DH-Stars-Chat

[![Stars](https://img.shields.io/github/stars/underscoreReal/DH-Stars-Chat?style=social)](https://github.com/underscoreReal/DH-Stars-Chat)

A Roblox script for **Da Hood** that converts PNG images to 3D parts in stars chat viewport

## 🚀 Features
- **PNG to Parts Magic**: Upload PNGs and watch 'em transform into buildable Roblox parts.
- **Da Hood Optimized**: Tailored for the chaos of Da Hood—quick load, low lag.
- **High quality**: IT CAN F**KING SUPPORT 1000x1000 IMAGE IF ITS 2-4 FLAT COLORS
- **F\*\*k unnamed**: It can do better than unnamed enchancements

## 🎮 Executing it
1. Grab a executor (e.g [Zenith](https://zenith.win/), [Wave](https://getwave.gg/) or any executors with 100% SUNC)
2. Copy the script 
```lua
_G.DHStarsPNG2Parts = {
    MAX_PARTS = 5000, -- safety cap on predicted parts (conservative)
    PIXELS_WAIT = 50, -- yield frequency
    MAX_ATTEMPTS = 20, -- fail-safe: don't loop forever
    MIN_SHRINK_FACTOR = 0.75, -- shirnk percentage
    WAIT_BEFORE_NEXT_ATTEMPT = 0.1, -- seconds to wait before next downscale attempt
    RAW_IMAGE_DATA = game:HttpGet("http://placehold.co/1000x1000.png") -- or readfile("img.png")
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/underscoreReal/DH-Stars-Chat/main/main.lua"))()
```
3. Paste it and edit the cfg (especially ``RAW_IMAGE_DATA``) to preferences
4. Execute

## 📸 Showcase
![VRqf6xVjrZ](https://github.com/user-attachments/assets/ad81e436-56b4-4beb-8af7-f49b4c9c2514)


## 🤝 Contributing
Fork it, PR your wild ideas! No toxicity, please—keep it fun.


Made with 💖 by [underscoreReal](https://github.com/underscoreReal). Stars appreciated ⭐
