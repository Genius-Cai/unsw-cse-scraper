#!/bin/bash
# Download YouTube lecture videos for a UNSW CSE course
# Usage: ./download-videos.sh <playlist_url> [save_dir] [format]
# Example: ./download-videos.sh "https://www.youtube.com/playlist?list=PLxxx" ~/UNSW/COMP2521/lectures/videos
# Formats: video (default), audio, both

set -euo pipefail

PLAYLIST="${1:?Usage: $0 <playlist_url> [save_dir] [format: video|audio|both]}"
SAVE_DIR="${2:-./lectures/videos}"
FORMAT="${3:-video}"

# Check yt-dlp
if ! command -v yt-dlp &>/dev/null; then
    echo "ERROR: yt-dlp not found. Install with: brew install yt-dlp"
    exit 1
fi

echo "=== YouTube Lecture Downloader ==="
echo "Playlist: ${PLAYLIST}"
echo "Save to: ${SAVE_DIR}"
echo "Format: ${FORMAT}"
echo ""

# List videos first
echo "=== Video List ==="
yt-dlp --flat-playlist \
    --print "%(playlist_index)s. %(title)s" \
    "$PLAYLIST" 2>/dev/null
echo ""

VIDEO_COUNT=$(yt-dlp --flat-playlist --print id "$PLAYLIST" 2>/dev/null | wc -l | tr -d ' ')
echo "Total: ${VIDEO_COUNT} videos"
echo ""

read -p "Proceed with download? [y/N] " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

case "$FORMAT" in
    video)
        mkdir -p "${SAVE_DIR}"
        yt-dlp \
            -o "${SAVE_DIR}/%(playlist_index)s-%(title)s.%(ext)s" \
            --format 'bestvideo[height<=1080]+bestaudio/best' \
            --write-subs --sub-langs en \
            --write-description \
            --no-overwrites \
            --progress \
            "$PLAYLIST"
        ;;
    audio)
        mkdir -p "${SAVE_DIR/videos/audio}"
        yt-dlp \
            -o "${SAVE_DIR/videos/audio}/%(playlist_index)s-%(title)s.%(ext)s" \
            --extract-audio --audio-format mp3 --audio-quality 128K \
            --no-overwrites \
            --progress \
            "$PLAYLIST"
        ;;
    both)
        mkdir -p "${SAVE_DIR}" "${SAVE_DIR/videos/audio}"
        echo "--- Downloading video ---"
        yt-dlp \
            -o "${SAVE_DIR}/%(playlist_index)s-%(title)s.%(ext)s" \
            --format 'bestvideo[height<=1080]+bestaudio/best' \
            --write-subs --sub-langs en \
            --no-overwrites \
            --progress \
            "$PLAYLIST"
        echo ""
        echo "--- Extracting audio ---"
        yt-dlp \
            -o "${SAVE_DIR/videos/audio}/%(playlist_index)s-%(title)s.%(ext)s" \
            --extract-audio --audio-format mp3 --audio-quality 128K \
            --no-overwrites \
            --progress \
            "$PLAYLIST"
        ;;
    *)
        echo "Unknown format: ${FORMAT}. Use: video, audio, or both"
        exit 1
        ;;
esac

echo ""
echo "=== Done ==="
du -sh "${SAVE_DIR}" 2>/dev/null
