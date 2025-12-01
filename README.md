# Audio Book Downloader

A collection of shell scripts for downloading and processing audio content from YouTube, designed specifically for audiobooks and long-form content with chapter support.

## Features

- **YouTube Audio Download**: Extract high-quality MP3 audio from YouTube videos
- **Chapter Support**: Automatically split audiobooks into individual chapter files
- **Cookie Integration**: Uses Firefox browser cookies for accessing restricted content
- **Audio Segmentation**: Cut audio files into segments based on custom time tables
- **Parallel Processing**: Efficient batch processing with concurrent operations
- **Organized Output**: Structured directory organization for downloaded content

## Prerequisites

Before using these scripts, ensure you have the following tools installed:

- **yt-dlp**: Modern YouTube downloader
- **ffmpeg**: Audio/video processing toolkit
- **ffprobe**: Media file analysis (part of ffmpeg)
- **Firefox**: Browser for cookie extraction (if accessing restricted content)

### Installation on macOS

```bash
# Install via Homebrew
brew install yt-dlp ffmpeg

# Or install yt-dlp via pip
pip install yt-dlp
```

### Installation on Linux

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install yt-dlp ffmpeg

# Or install yt-dlp via pip
pip install yt-dlp
```

## Scripts Overview

### 1. yt-download.sh

Downloads audio from YouTube with optional chapter splitting functionality.

**Features:**

- Extracts cookies from Firefox browser for authentication
- Converts videos to MP3 format
- Optional chapter splitting with organized file structure
- Passes through all yt-dlp options

**Usage:**

```bash
./yt-download.sh [OPTIONS] <YouTube_URL>
```

**Options:**

- `-s, --split-chapter`: Enable chapter splitting (creates both full audio and individual chapters)
- `-h, --help`: Show help message
- All other options are passed directly to yt-dlp

**Examples:**

```bash
# Download full audiobook as single file
./yt-download.sh https://youtube.com/watch?v=example

# Download with chapter splitting
./yt-download.sh --split-chapter https://youtube.com/watch?v=example

# Download with custom quality
./yt-download.sh --audio-quality 320K https://youtube.com/watch?v=example
```

**Output Structure (with chapter splitting):**

```
Title [VideoID]/
├── full/
│   └── Title.mp3                    # Complete audiobook
└── 001-Chapter-1-Title.mp3          # Individual chapters
    002-Chapter-2-Title.mp3
    ...
```

### 2. cut-video.sh

Automatically cuts audio/video files into segments based on a time table file.

**Features:**

- Supports both MM:SS and H:MM:SS time formats
- Parallel processing for faster execution
- Automatic filename sanitization
- Colored terminal output for better visibility
- Preserves original audio/video quality

**Usage:**

```bash
./cut-video.sh <time-table.txt> <input-file> [output-directory]
```

**Time Table Format:**
Create a text file with timestamps and titles:

```
0:00 Introduction
5:30 Chapter 1: Getting Started
15:45 Chapter 2: Advanced Topics
32:10 Chapter 3: Best Practices
# Comments are supported
1:05:20 Conclusion
```

**Examples:**

```bash
# Cut audio file using time table
./cut-video.sh chapters.txt audiobook.mp3

# Specify custom output directory
./cut-video.sh chapters.txt audiobook.mp3 ./segments/

# Works with video files too
./cut-video.sh timestamps.txt lecture.mp4
```

**Output:**

```
clips/
├── 001-Introduction.mp3
├── 002-Chapter-1-Getting-Started.mp3
├── 003-Chapter-2-Advanced-Topics.mp3
└── 004-Chapter-3-Best-Practices.mp3
```

## Project Structure

```
audio-book-downloader/
├── README.md                 # This file
├── yt-download.sh           # YouTube audio downloader
├── cut-video.sh             # Audio segmentation tool
├── .gitignore              # Git ignore rules
└── audio-files/            # Downloaded content (ignored by git)
```

## Workflow Examples

### Complete Audiobook Processing

1. **Download with chapters:**

   ```bash
   ./yt-download.sh --split-chapter https://youtube.com/watch?v=audiobook_url
   ```

2. **Manual segmentation (if chapters aren't detected):**

   ```bash
   # First download without splitting
   ./yt-download.sh https://youtube.com/watch?v=audiobook_url

   # Create time table file
   echo "0:00 Prologue" > chapters.txt
   echo "12:30 Chapter 1" >> chapters.txt
   echo "45:15 Chapter 2" >> chapters.txt

   # Cut into segments
   ./cut-video.sh chapters.txt "Title [VideoID].mp3"
   ```

### Batch Processing

```bash
# Download multiple audiobooks
urls=(
    "https://youtube.com/watch?v=book1"
    "https://youtube.com/watch?v=book2"
    "https://youtube.com/watch?v=book3"
)

for url in "${urls[@]}"; do
    ./yt-download.sh --split-chapter "$url"
done
```

## Configuration

### Firefox Cookie Integration

The `yt-download.sh` script automatically extracts cookies from Firefox to access content that requires authentication. Ensure Firefox is installed and you're logged into the required services.

### Customizing Output Quality

You can pass any yt-dlp options to control output quality:

```bash
# High quality audio
./yt-download.sh --audio-quality 320K --audio-format mp3 <URL>

# Specific format selection
./yt-download.sh -f "bestaudio[ext=m4a]" <URL>
```

## Troubleshooting

### Common Issues

1. **yt-dlp not found:**

   ```bash
   # Install yt-dlp
   pip install yt-dlp
   # or
   brew install yt-dlp
   ```

2. **ffmpeg not found:**

   ```bash
   # Install ffmpeg
   brew install ffmpeg  # macOS
   sudo apt install ffmpeg  # Linux
   ```

3. **Permission denied:**

   ```bash
   # Make scripts executable
   chmod +x yt-download.sh cut-video.sh
   ```

4. **Firefox cookies not working:**
   - Ensure Firefox is installed
   - Try logging into the service in Firefox first
   - Check if the content requires specific authentication

## License

This project is open source. Please check the repository for license details.

## Acknowledgments

- Built on top of [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- Uses [FFmpeg](https://ffmpeg.org/) for audio processing
