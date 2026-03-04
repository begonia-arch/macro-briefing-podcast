#!/bin/bash
# publish_episode_auto.sh
# Fully automatic publishing of macro-briefing episodes

set -e

# Paths
ENGINE_DIR=~/macro-briefing-engine
PUBLIC_DIR=~/macro-briefing-podcast

# 1️⃣ Generate a new random episode folder
EPISODE_DIR=$(openssl rand -hex 24)
mkdir "$PUBLIC_DIR/$EPISODE_DIR"
echo "✅ New episode folder: $EPISODE_DIR"

# 2️⃣ Copy generated content from engine to the new folder
cp "$ENGINE_DIR/output/transcripts/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
cp "$ENGINE_DIR/output/summaries/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
cp "$ENGINE_DIR/output/intelligence/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true

# Optional: copy artwork placeholder
ARTWORK_FILE="$ENGINE_DIR/pipeline/artwork.jpg"
if [ -f "$ARTWORK_FILE" ]; then
    cp "$ARTWORK_FILE" "$PUBLIC_DIR/$EPISODE_DIR/artwork.jpg"
fi

# 3️⃣ Update feed.xml
FEED_FILE="$PUBLIC_DIR/$EPISODE_DIR/feed.xml"
if [ ! -f "$FEED_FILE" ]; then
    echo "<rss><channel><title>Macro Briefing</title></channel></rss>" > "$FEED_FILE"
fi

# 4️⃣ Commit & push
cd "$PUBLIC_DIR"
git add .
git commit -m "Publish new episode: $EPISODE_DIR ($(date +'%Y-%m-%d %H:%M:%S'))" || echo "No changes to commit"
git push

# 5️⃣ Print the public feed URL
echo "✅ Episode published:"
echo "https://begonia-arch.github.io/macro-briefing-podcast/$EPISODE_DIR/feed.xml"
