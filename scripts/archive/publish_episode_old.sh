#!/bin/bash
# publish_episode.sh
# Auto-publish macro-briefing episodes to public podcast repo

set -e

# Paths
ENGINE_DIR=~/macro-briefing-engine
PUBLIC_DIR=~/macro-briefing-podcast

# Current episode folder (replace with your actual folder name)
EPISODE_DIR=c2513000701c8aca6bcff4735b1ba46b93581ac8522fb2ed

# Copy generated content from engine to public repo
cp "$ENGINE_DIR/output/transcripts/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
cp "$ENGINE_DIR/output/summaries/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
cp "$ENGINE_DIR/output/intelligence/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true

# Optional: copy artwork
cp "$ENGINE_DIR/pipeline/artwork.jpg" "$PUBLIC_DIR/$EPISODE_DIR/artwork.jpg"

# Commit and push
cd "$PUBLIC_DIR"
git add .
git commit -m "Publish new episode content: $(date +'%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"
git push

# Print the feed URL
echo "✅ Episode published:"
echo "https://begonia-arch.github.io/macro-briefing-podcast/$EPISODE_DIR/feed.xml"
