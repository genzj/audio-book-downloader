#!/bin/zsh

# Usage function
usage() {
    local prog="$1"
    echo "Usage: yt-download.sh [-s | --split-chapter] [other yt-dlp options...] <URL>"
    echo ""
    echo "Options:"
    echo "  -s, --split-chapter    Enable chapter splitting (disabled by default)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  ${prog} https://youtube.com/watch?v=example"
    echo "  ${prog} --split-chapter https://youtube.com/watch?v=example"
}

# Help function
show_help() {
    local prog="$1"
    usage "$prog"
    echo ""
    echo "This script downloads audio from YouTube using yt-dlp with the following features:"
    echo "- Extracts cookies from Firefox browser"
    echo "- Converts to MP3 format"
    echo "- Organizes files in structured directories"
    echo ""
    echo "When --split-chapter is enabled:"
    echo "  - Splits audio into individual chapter files"
    echo "  - Creates both full audio file and individual chapters"
    echo "  - Uses chapter-specific naming convention"
    echo ""
    echo "When --split-chapter is disabled (default):"
    echo "  - Downloads only the full audio file"
    echo "  - No chapter splitting"
    echo ""
    echo "All other options are passed directly to yt-dlp."
}

# Initialize variables
prog="${0}"
split_chapters=false
yt_dlp_args=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--split-chapter)
            split_chapters=true
            shift
            ;;
        -h|--help)
            show_help "${prog}"
            exit 0
            ;;
        *)
            # Add all other arguments to yt-dlp args array
            yt_dlp_args+=("$1")
            shift
            ;;
    esac
done

# Check if URL is provided
if [[ ${#yt_dlp_args[@]} -eq 0 ]]; then
    echo "Error: No URL provided"
    echo ""
    usage "${prog}"
    exit 1
fi

# Build yt-dlp command based on options
yt_dlp_cmd=(
    yt-dlp
    --cookies-from-browser firefox
)

# Add chapter splitting options if enabled
if [[ "$split_chapters" == true ]]; then
    yt_dlp_cmd+=(
        --split-chapter
        -o "%(title)s [%(id)s]/full/%(title)s.%(ext)s"
        -o "chapter:%(title)s [%(id)s]/%(section_number)03d-%(section_title)s.%(ext)s"
    )
fi

# Add format and remaining arguments
yt_dlp_cmd+=(
    --preset-alias mp3
    "${yt_dlp_args[@]}"
)

# Execute the command
echo "${yt_dlp_cmd[@]}"
"${yt_dlp_cmd[@]}"
