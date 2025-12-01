#!/bin/zsh

# cut-video.sh - Automatically cut audio/video files based on time table
# Usage: ./cut-video.sh <time-table.txt> <input-file.mp3|mp4> [<output-dir>]

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to convert time format (MM:SS or H:MM:SS) to seconds
time_to_seconds() {
    local time_str="$1"
    local total_seconds=0

    # Split by colon and process from right to left
    IFS=':' read -A time_parts <<< "$time_str"
    local num_parts=${#time_parts[@]}

    if [[ $num_parts -eq 2 ]]; then
        # MM:SS format
        total_seconds=$((${time_parts[2]} + ${time_parts[1]} * 60))
    elif [[ $num_parts -eq 3 ]]; then
        # H:MM:SS format
        total_seconds=$((${time_parts[3]} + ${time_parts[2]} * 60 + ${time_parts[1]} * 3600))
    else
        print_error "Invalid time format: $time_str"
        return 1
    fi

    echo $total_seconds
}

# Function to sanitize filename
sanitize_filename() {
    local title="$1"
    # Remove special characters and replace spaces with dashes
    echo "$title" | sed 's/[^a-zA-Z0-9\[\] ]//g' | sed 's/ \+/-/g' | sed 's/^-\+\|-\+$//g'
}

# Function to get file extension
get_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# Function to get total duration of input file
get_duration() {
    local input_file="$1"
    ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null | cut -d. -f1
}

# Function to process a single segment
process_segment() {
    local id="$1"
    local title="$2"
    local start_time="$3"
    local end_time="$4"
    local input_file="$5"
    local extension="$6"
    local output_dir="$7"

    local sanitized_title=$(sanitize_filename "$title")
    local output_file="${output_dir}/${id}-${sanitized_title}.${extension}"

    print_status "Processing: $output_file (${start_time} to ${end_time})"

    if [[ -n "$end_time" ]]; then
        # Cut from start_time to end_time
        local duration=$((end_time - start_time))
        ffmpeg -i "$input_file" -ss "$start_time" -t "$duration" -c copy "$output_file" -y -loglevel error
    else
        # Cut from start_time to end of file
        ffmpeg -i "$input_file" -ss "$start_time" -c copy "$output_file" -y -loglevel error
    fi

    if [[ $? -eq 0 ]]; then
        print_success "Created: $output_file"
    else
        print_error "Failed to create: $output_file"
        return 1
    fi
}

# Main function
main() {
    # Check arguments
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        print_error "Usage: $0 <time-table.txt> <input-file.mp3|mp4> [<output-dir>]"
        exit 1
    fi

    local time_table="$1"
    local input_file="$2"
    local output_dir="$3"

    # Validate input files
    if [[ ! -f "$time_table" ]]; then
        print_error "Time table file not found: $time_table"
        exit 1
    fi

    if [[ ! -f "$input_file" ]]; then
        print_error "Input file not found: $input_file"
        exit 1
    fi

    # Check if ffmpeg is available
    if ! command -v ffmpeg &> /dev/null; then
        print_error "ffmpeg is not installed or not in PATH"
        exit 1
    fi

    if ! command -v ffprobe &> /dev/null; then
        print_error "ffprobe is not installed or not in PATH"
        exit 1
    fi

    local extension=$(get_extension "$input_file")
    print_status "Input file: $input_file (.$extension)"
    print_status "Time table: $time_table"

    # Determine output directory
    if [[ -z "$output_dir" ]]; then
        # Get base directory and filename of input file
        local input_dir="$(dirname "$input_file")"
        local input_basename="$(basename "$input_file" .${extension})"
        local sanitized_basename=$(sanitize_filename "$input_basename")
        output_dir="${input_dir}/${sanitized_basename}"
    fi

    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        print_status "Creating output directory: $output_dir"
        mkdir -p "$output_dir"
        if [[ $? -ne 0 ]]; then
            print_error "Failed to create output directory: $output_dir"
            exit 1
        fi
        print_success "Created output directory: $output_dir"
    else
        print_status "Using existing output directory: $output_dir"
    fi

    # Get total duration for reference
    local total_duration=$(get_duration "$input_file")
    print_status "Total duration: ${total_duration} seconds"

    # Parse time table and prepare segments
    local -a segments
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        ((line_num++)) || true

        # Parse line: "MM:SS Title" or "H:MM:SS Title"
        local timestamp=$(echo "$line" | cut -d' ' -f1)
        local title=$(echo "$line" | cut -d' ' -f2-)

        if [[ "$timestamp" =~ ^[0-9]+:[0-9]+$ ]] || [[ "$timestamp" =~ ^[0-9]+:[0-9]+:[0-9]+$ ]]; then
            local start_seconds=$(time_to_seconds "$timestamp")

            if [[ $? -ne 0 ]]; then
                print_error "Failed to parse timestamp: $timestamp"
                continue
            fi

            local id=$(printf "%03d" $line_num)
            segments+=("$id|$title|$start_seconds")

            print_status "Parsed: [$id] $title at ${start_seconds}s"
        else
            print_warning "Skipping invalid line: $line"
        fi
    done < "$time_table"

    if [[ ${#segments[@]} -eq 0 ]]; then
        print_error "No valid segments found in time table"
        exit 1
    fi

    print_status "Found ${#segments[@]} segments to process"

    # Process segments in parallel
    local -a pids
    local max_jobs=4  # Limit concurrent jobs to avoid overwhelming the system
    local job_count=0

    for i in {1..${#segments[@]}}; do
        IFS='|' read -A segment_parts <<< "${segments[$i]}"
        local id="${segment_parts[1]}"
        local title="${segment_parts[2]}"
        local start_time="${segment_parts[3]}"
        local end_time=""

        # Calculate end time (start time of next segment, or end of file)
        if [[ $i -lt ${#segments[@]} ]]; then
            IFS='|' read -A next_segment_parts <<< "${segments[$((i+1))]}"
            end_time="${next_segment_parts[3]}"
        fi

        # Wait if we've reached max concurrent jobs
        if [[ $job_count -ge $max_jobs ]]; then
            # Wait for any job to complete (zsh compatible)
            wait
            job_count=0
        fi

        # Start processing in background
        process_segment "$id" "$title" "$start_time" "$end_time" "$input_file" "$extension" "$output_dir" &
        pids+=($!)
        ((job_count++)) || true
    done

    # Wait for all remaining jobs to complete
    print_status "Waiting for all segments to complete..."
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    print_success "All segments processed successfully!"
    print_status "Output files created with pattern: XXX-Title.$extension"
}

# Run main function with all arguments
main "$@"
