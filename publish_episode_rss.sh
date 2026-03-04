#!/bin/bash
# publish_episode_rss.sh
# Multi-channel + title filter support
# Copies outputs, applies filters, updates RSS, commits & pushes

set -e

# -----------------------------
# CONFIG
# -----------------------------
ENGINE_DIR=~/macro-briefing-engine
PUBLIC_DIR=~/macro-briefing-podcast
CONFIG_CHANNELS="$ENGINE_DIR/config/channels.txt"   # ChannelName|ChannelID|TitleFilter
CHANNEL_IMAGES="$ENGINE_DIR/channel_images"
SUMMARY_FILE="$ENGINE_DIR/output/summaries/latest_summary.txt"
EPISODE_TITLE_FILE="$ENGINE_DIR/output/latest_title.txt"  # episode title

# -----------------------------
# 0️⃣ Read channels.txt
# -----------------------------
if [ ! -f "$CONFIG_CHANNELS" ]; then
    echo "❌ channels.txt not found at $CONFIG_CHANNELS"
    exit 1
fi

while IFS='|' read -r CHANNEL_NAME CHANNEL_ID TITLE_FILTER; do
    # skip empty lines
    [[ -z "$CHANNEL_NAME" || -z "$CHANNEL_ID" ]] && continue

    echo "🎯 Processing channel: $CHANNEL_NAME ($CHANNEL_ID)"

    # -----------------------------
    # 0️⃣a Read episode title
    # -----------------------------
    if [ ! -f "$EPISODE_TITLE_FILE" ]; then
        echo "❌ Episode title not found at $EPISODE_TITLE_FILE"
        continue
    fi
    EPISODE_TITLE=$(cat "$EPISODE_TITLE_FILE" | tr -d '\n')

    # -----------------------------
    # 0️⃣b Apply title filter if exists
    # -----------------------------
    if [[ -n "$TITLE_FILTER" ]]; then
        MATCH=false
        IFS=',' read -ra FILTERS <<< "$TITLE_FILTER"
        for keyword in "${FILTERS[@]}"; do
            if [[ "$EPISODE_TITLE" == *"$keyword"* ]]; then
                MATCH=true
                break
            fi
        done
        if [[ "$MATCH" == false ]]; then
            echo "⏭️ Skipping episode \"$EPISODE_TITLE\" — no matching keyword in filter: $TITLE_FILTER"
            continue
        fi
    fi

    # -----------------------------
    # 1️⃣ Create new episode folder
    # -----------------------------
    EPISODE_DIR=$(openssl rand -hex 24)
    mkdir -p "$PUBLIC_DIR/$EPISODE_DIR"
    echo "✅ New episode folder: $EPISODE_DIR"

    # -----------------------------
    # 2️⃣ Copy outputs from engine
    # -----------------------------
    cp "$ENGINE_DIR/output/transcripts/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
    cp "$ENGINE_DIR/output/summaries/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
    cp "$ENGINE_DIR/output/intelligence/"* "$PUBLIC_DIR/$EPISODE_DIR/" 2>/dev/null || true
    echo "✅ Copied transcripts, summaries, and intelligence outputs"

    # -----------------------------
    # 3️⃣ Copy channel thumbnail as artwork
    # -----------------------------
    ARTWORK_FILE="$PUBLIC_DIR/$EPISODE_DIR/artwork.jpg"
    THUMBNAIL="$CHANNEL_IMAGES/$CHANNEL_ID.jpg"

    if [ -f "$THUMBNAIL" ]; then
        cp "$THUMBNAIL" "$ARTWORK_FILE"
        echo "✅ Artwork set from channel thumbnail: $ARTWORK_FILE"
    else
        echo "⚠️ Channel thumbnail not found at $THUMBNAIL"
        echo "Artwork will be missing for this episode"
    fi

    # -----------------------------
    # 4️⃣ Read summary for description
    # -----------------------------
    if [ -f "$SUMMARY_FILE" ]; then
        DESCRIPTION=$(cat "$SUMMARY_FILE" | tr -d '\n' | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    else
        DESCRIPTION="Episode of $CHANNEL_NAME."
    fi

    # -----------------------------
    # 5️⃣ Create episode feed.xml
    # -----------------------------
    EPISODE_FEED="$PUBLIC_DIR/$EPISODE_DIR/feed.xml"
    cat <<EOL > "$EPISODE_FEED"
<rss version="2.0">
<channel>
<title>$EPISODE_TITLE</title>
<link>https://begonia-arch.github.io/macro-briefing-podcast/$EPISODE_DIR/feed.xml</link>
<description>$DESCRIPTION</description>
</channel>
</rss>
EOL
    echo "✅ Episode feed created at $EPISODE_FEED"

    # -----------------------------
    # 6️⃣ Update master RSS feed
    # -----------------------------
    FEED_FILE="$PUBLIC_DIR/feed.xml"
    DATE_NOW=$(date -R)

    if [ ! -f "$FEED_FILE" ]; then
    cat <<EOL > "$FEED_FILE"
<rss version="2.0">
<channel>
<title>$CHANNEL_NAME</title>
<link>https://begonia-arch.github.io/macro-briefing-podcast/</link>
<description>$CHANNEL_NAME Podcast</description>
</channel>
</rss>
EOL
    fi

    TEMP_FEED=$(mktemp)
    awk -v ep="$EPISODE_DIR" -v title="$EPISODE_TITLE" -v date="$DATE_NOW" -v desc="$DESCRIPTION" '{
        if ($0 ~ /<\/channel>/) {
            print "  <item>"
            print "    <title>" title "</title>"
            print "    <link>https://begonia-arch.github.io/macro-briefing-podcast/" ep "/feed.xml</link>"
            print "    <pubDate>" date "</pubDate>"
            print "    <description>" desc "</description>"
            print "  </item>"
        }
        print
    }' "$FEED_FILE" > "$TEMP_FEED"
    mv "$TEMP_FEED" "$FEED_FILE"
    echo "✅ Master RSS feed updated at $FEED_FILE"

    # -----------------------------
    # 7️⃣ Commit & push
    # -----------------------------
    cd "$PUBLIC_DIR"
    git add .
    git commit -m "Publish new episode: $EPISODE_DIR ($(date +'%Y-%m-%d %H:%M:%S'))" || echo "No changes to commit"
    git push
    echo "✅ Episode published and pushed"

    # -----------------------------
    # 8️⃣ Print URLs
    # -----------------------------
    echo "🌐 Episode URL:"
    echo "https://begonia-arch.github.io/macro-briefing-podcast/$EPISODE_DIR/feed.xml"
    echo "🌐 Master RSS feed:"
    echo "https://begonia-arch.github.io/macro-briefing-podcast/feed.xml"

done < "$CONFIG_CHANNELS"
