# Android Audio Compression Guide

## Overview
This guide helps you create Android-optimized audio files for better performance.

## Large Music Files to Compress
The following files are >1MB and should be compressed for Android:

1. `legend.mp3` (5.1MB)
2. `space_cadet.mp3` (4.8MB) 
3. `void_master.mp3` (3.4MB)
4. `storm_ace.mp3` (3.1MB)
5. `sky_rookie.mp3` (2.9MB)

## Compression Options

### Option 1: Using FFmpeg (Recommended)
```bash
# Install FFmpeg if not already installed
# macOS: brew install ffmpeg

# Compress each file to 128kbps (good quality, smaller size)
ffmpeg -i assets/audio/legend.mp3 -b:a 128k assets/audio/android_optimized/legend.mp3
ffmpeg -i assets/audio/space_cadet.mp3 -b:a 128k assets/audio/android_optimized/space_cadet.mp3
ffmpeg -i assets/audio/void_master.mp3 -b:a 128k assets/audio/android_optimized/void_master.mp3
ffmpeg -i assets/audio/storm_ace.mp3 -b:a 128k assets/audio/android_optimized/storm_ace.mp3
ffmpeg -i assets/audio/sky_rookie.mp3 -b:a 128k assets/audio/android_optimized/sky_rookie.mp3
```

### Option 2: Using Online Tools
1. Upload files to online MP3 compressor
2. Set bitrate to 128kbps
3. Download and place in `assets/audio/android_optimized/`

## Expected Results
- Original files: ~20MB total
- Compressed files: ~5-8MB total (60-70% reduction)
- Quality: Still good for mobile gaming

## Activation
Once compressed files are created, update the `_getOptimizedAssetPath` method in `platform_audio_manager.dart` to actually use them.
