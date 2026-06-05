#!/bin/bash
# Gateway Form Auto-Submit Script
# Handles redirects to SSL inspection gateway forms and saves cookies

# Configuration
COOKIE_FILE="${GATEWAY_COOKIE_FILE:-$HOME/.gateway_cookies.txt}"
TEMP_FILE="/tmp/gateway_response_$$"
VERBOSE="${VERBOSE:-1}"


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    if [ "$VERBOSE" = "1" ]; then
        echo -e "${GREEN}[Gateway Wrapper Info]${NC} $*" >&2
    fi
}

error() {
    echo -e "${RED}[Gateway Wrapper Error]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[Gateway Wrapper Warning]${NC} $*" >&2
}

# Determine which curl command to use based on how script was called
SCRIPT_NAME="$(basename "$0")"
if [ "$SCRIPT_NAME" = "gateway-curl.sh" ]; then
    warn "Warning: You are running the script directly."
    warn "For automatic handling of gateway forms, please use 'curl' command which is symlinked to this script."
    
    # if /usr/bin/curl.real exist, use it
    if [ -x /usr/bin/curl.real ]; then
        warn "Detected /usr/bin/curl.real, using it for actual requests"
        CURL_CMD="/usr/bin/curl.real"
    elif [ -L /usr/bin/curl ] && [ "$(readlink /usr/bin/curl)" = "$(readlink -f "$0")" ]; then
        error "Detected /usr/bin/curl is symlinked to this script. This may cause infinite recursion."
        exit 1
    else
        warn "Using /usr/bin/curl directly"
        CURL_CMD="/usr/bin/curl"
    fi
elif [ "$SCRIPT_NAME" = "curl" ]; then
    warn "Running as 'curl', using /usr/bin/curl.real for actual requests"
    CURL_CMD="/usr/bin/curl.real"
else
    error "Could not determine underlying curl command."
    exit 1
fi 

# Show all arguments for debugging
log "Script called with arguments: $*"

# Parse HTML form fields using grep and sed
parse_form_field() {
    local response_file="$1"
    local field_name="$2"
    grep -oP "name=\"${field_name}\" value=\"\K[^\"]*" "$response_file" 2>/dev/null || \
    grep -oP "name='${field_name}' value='\K[^']*" "$response_file" 2>/dev/null || true
}

# Check if response is a gateway redirect form
is_gateway_form() {
    local response_file="$1"
    grep -q "gateway.zscaler" "$response_file" 2>/dev/null && \
    grep -q "_sm_ctn" "$response_file" 2>/dev/null
}

# Extract form action URL
get_form_action() {
    local response_file="$1"
    grep -oP '<form[^>]*action="https://gateway\.[^"]*' "$response_file" | \
    grep -oP 'https://[^"]*' | head -1
}

submit_gateway_form() {
    local response_file="$1"
    
    log "Detected gateway form, extracting fields..."
    
    # Extract form fields
    local form_action=$(get_form_action "$response_file")
    local sm_url=$(parse_form_field "$response_file" "_sm_url")
    local sm_rid=$(parse_form_field "$response_file" "_sm_rid")
    local sm_cat=$(parse_form_field "$response_file" "_sm_cat")
    
    if [ -z "$form_action" ]; then
        error "Could not extract form action URL"
        return 1
    fi
    
    log "Form action: $form_action"
    log "Target URL: $sm_url"
    log "Request ID: $sm_rid"
    log "Category: $sm_cat"
    
    # Build query string
    local query=""
    [ -n "$sm_url" ] && query="${query}_sm_url=$(printf '%s' "$sm_url" | jq -sRr @uri)"
    [ -n "$sm_rid" ] && query="${query}&_sm_rid=$(printf '%s' "$sm_rid" | jq -sRr @uri)"
    [ -n "$sm_cat" ] && query="${query}&_sm_cat=$(printf '%s' "$sm_cat" | jq -sRr @uri)"
    
    # Remove leading & if present
    query="${query#&}"
    
    local submit_url="${form_action}?${query}"
    
    log "Submitting gateway form to: $submit_url"

    "$CURL_CMD" -L -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
        -H "User-Agent: Chrome/90.0 (X11; Linux x86_64)" \
        "$submit_url" > /dev/null
    
    if [ $? -eq 0 ]; then
        log "Gateway form submitted, cookies saved to: $COOKIE_FILE"
        return 0
    else
        error "Gateway form submission failed"
        return 1
    fi
}

# Find URL from arguments (must start with http:// or https://)
find_url() {
    local url=""
    for arg in "$@"; do
        if [[ "$arg" =~ ^https?:// ]]; then
            if [ -n "$url" ]; then
                warn "Multiple URLs found, using first one: $url"
            else
                url="$arg"
                log "Found URL: $url"
            fi
        fi
    done
    
    if [ -z "$url" ]; then
        return 1
    fi
    
    echo "$url"
    return 0
}

# Get all non-URL arguments
get_non_url_args() {
    local args=()
    for arg in "$@"; do
        if [[ ! "$arg" =~ ^https?:// ]]; then
            args+=("$arg")
        fi
    done
    
    # Return array as separate arguments
    printf '%s\n' "${args[@]}"
}

# Get value of a named argument (e.g., -o, --output)
# Usage: get_arg_value "-o" "--output" "${args[@]}"
get_arg_value() {
    local arg_names=()
    local search_args=()
    local found_separator=false
    
    # Separate argument names from the array to search
    for arg in "$@"; do
        if [ "$found_separator" = true ]; then
            search_args+=("$arg")
        elif [ "$arg" = "--" ]; then
            found_separator=true
        else
            arg_names+=("$arg")
        fi
    done
    
    # If no separator, assume last element onwards are search args
    if [ "$found_separator" = false ]; then
        search_args=("${arg_names[@]}")
        arg_names=()
        return 1
    fi
    
    # Search for the argument value
    local skip_next=false
    for ((i=0; i<${#search_args[@]}; i++)); do
        if [ "$skip_next" = true ]; then
            skip_next=false
            continue
        fi
        
        for name in "${arg_names[@]}"; do
            if [ "${search_args[$i]}" = "$name" ]; then
                if [ $((i+1)) -lt ${#search_args[@]} ]; then
                    echo "${search_args[$((i+1))]}"
                    return 0
                fi
                skip_next=true
                break
            fi
        done
    done
    
    return 1
}

# Check if argument exists in array
# Usage: has_arg "-v" "--verbose" "${args[@]}"
has_arg() {
    local arg_names=()
    local search_args=()
    local found_separator=false
    
    # Separate argument names from the array to search
    for arg in "$@"; do
        if [ "$found_separator" = true ]; then
            search_args+=("$arg")
        elif [ "$arg" = "--" ]; then
            found_separator=true
        else
            arg_names+=("$arg")
        fi
    done
    
    # If no separator, treat all as search args (no names to find)
    if [ "$found_separator" = false ]; then
        return 1
    fi
    
    # Search for the argument
    for search_arg in "${search_args[@]}"; do
        for name in "${arg_names[@]}"; do
            if [ "$search_arg" = "$name" ]; then
                return 0
            fi
        done
    done
    
    return 1
}

# Remove argument and its value from array
# Usage: remove_arg "-o" "--output" "${args[@]}"
# Output: Returns filtered array via stdout (one per line)
remove_arg() {
    local arg_names=()
    local search_args=()
    local found_separator=false
    
    # Separate argument names from the array to search
    for arg in "$@"; do
        if [ "$found_separator" = true ]; then
            search_args+=("$arg")
        elif [ "$arg" = "--" ]; then
            found_separator=true
        else
            arg_names+=("$arg")
        fi
    done
    
    # If no separator, return empty
    if [ "$found_separator" = false ]; then
        return 1
    fi
    
    # Extract single letter flags (e.g., "-f" -> "f", "-o" -> "o")
    local single_letters=()
    for name in "${arg_names[@]}"; do
        if [[ "$name" =~ ^-([a-zA-Z])$ ]]; then
            single_letters+=("${BASH_REMATCH[1]}")
        fi
    done
    
    # Filter out the argument and its value
    local result=()
    local skip_next=false
    for ((i=0; i<${#search_args[@]}; i++)); do
        if [ "$skip_next" = true ]; then
            skip_next=false
            continue
        fi
        
        local matched=false
        local current_arg="${search_args[$i]}"
        
        # Check for exact match first (e.g., "-o" or "--output")
        for name in "${arg_names[@]}"; do
            if [ "$current_arg" = "$name" ]; then
                matched=true
                skip_next=true
                log "Removed $name parameter from curl arguments"
                break
            fi
        done
        
        # If no exact match, check for clubbed single-letter args (e.g., "-fXo")
        if [ "$matched" = false ] && [[ "$current_arg" =~ ^-[a-zA-Z]{2,}$ ]]; then
            local modified_arg="$current_arg"
            local needs_skip=false
            
            # Remove each matching single letter from the clubbed argument
            for letter in "${single_letters[@]}"; do
                if [[ "$modified_arg" =~ $letter ]]; then
                    modified_arg="${modified_arg//$letter/}"
                    log "Removed -$letter from clubbed argument ${search_args[$i]}"
                    
                    # Check if this letter is at the end (might have a separate value next)
                    if [[ "${search_args[$i]}" =~ $letter$ ]] && [ $((i+1)) -lt ${#search_args[@]} ]; then
                        # Check if next arg is not another flag
                        if [[ ! "${search_args[$((i+1))]}" =~ ^- ]]; then
                            needs_skip=true
                        fi
                    fi
                fi
            done
            
            # If we removed all letters, the arg becomes just "-", so skip it
            if [ "$modified_arg" = "-" ]; then
                matched=true
                if [ "$needs_skip" = true ]; then
                    skip_next=true
                fi
            # If we removed some letters, add the modified arg
            elif [ "$modified_arg" != "$current_arg" ]; then
                result+=("$modified_arg")
                matched=true
                if [ "$needs_skip" = true ]; then
                    skip_next=true
                fi
            fi
        fi
        
        if [ "$matched" = false ]; then
            result+=("${search_args[$i]}")
        fi
    done
    
    printf '%s\n' "${result[@]}"
}

# Main curl wrapper function
gateway_curl() {
    local output_file=""
    
    # Validate that we have at least one argument
    if [ $# -eq 0 ]; then
        error "No URL provided"
        return 1
    fi
    
    # Find URL from arguments
    local url
    url=$(find_url "$@")
    if [ -z "$url" ]; then
        error "No URL found in arguments. URLs must start with http:// or https://"
        return 1
    fi


    # Get all non-URL arguments
    local extra_args=()
    args=$(get_non_url_args "$@")
    
    # Find output file if -o/--output is specified
    output_file=$(get_arg_value "-o" "--output" -- $(echo "${args[@]}" | tr '\n' ' ') || true)

    # Remove -o parameter from extra_args if present (we'll handle it separately)
    local new=()
    new=$(remove_arg "-o" "--output" "-f" "--fail" -- $(echo "${args[@]}" | tr '\n' ' '))
    
    log "Fetching: $url to $TEMP_FILE with arguments: $(echo "${new[@]}" | tr '\n' ' ')"
    
    # First request - check for redirect
   "$CURL_CMD" -c "$COOKIE_FILE" -b "$COOKIE_FILE" -o "$TEMP_FILE" \
        --location \
        -H "User-Agent: Chrome/90.0 (X11; Linux x86_64)" \
        $(echo "${new[@]}" | tr '\n' ' ') \
        "$url" 
        
    # Check if we got a Zscaler form
    if is_gateway_form "$TEMP_FILE"; then
        log "Gateway redirect detected, processing..."
        
        # Submit the form
        if submit_gateway_form "$TEMP_FILE"; then
            log "Retrying original request with cookies..."
            
            # Retry original request with saved cookies
            "$CURL_CMD" --location-trusted -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
                $(echo "${args[@]}" | tr '\n' ' ') \
                "$url"
        else
            error "Failed to process gateway redirect"
            cat "$TEMP_FILE"
            rm -f "$TEMP_FILE"
            return 1
        fi
    else
        log "No Zscaler gateway detected, returning response from $TEMP_FILE"
        if [ -n "$output_file" ] && [ "$output_file" != "-" ]; then
            log "Moving temp file to specified output location: $output_file"
            mv "$TEMP_FILE" "$output_file"
        else
            cat "$TEMP_FILE"
            rm -f "$TEMP_FILE"
        fi
    fi

}

# Show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [curl options] <URL>
   or: $(basename "$0") <URL> [curl options]

Wrapper around curl that automatically handles SSL inspection gateway forms.
Detects redirects to gateway authentication forms, submits the form, saves
cookies, and retries the original request. URL can be placed anywhere in the arguments.

Environment Variables:
    GATEWAY_COOKIE_FILE  Path to cookie file (default: ~/.gateway_cookies.txt)
  VERBOSE              Set to 1 to enable verbose output

Examples:
  $(basename "$0") https://example.com/file.tar.gz
  $(basename "$0") -H "Accept: application/json" https://example.com/api/data
  $(basename "$0") https://example.com/api/data -H "Accept: application/json"
  VERBOSE=1 $(basename "$0") https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh

EOF
}


    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi
    
    gateway_curl "$@"
    