#!/bin/bash
#
# k4cs.sh — K4 Config.xml Setup
# Parses a K4 test/admin URL and installs K4 Config.xml to the correct paths.
# Remembers previously used servers and selections.
#

set -euo pipefail

# --- Defaults ---
DRY_RUN=false
URL=""
DEFAULT_SELECTIONS=""
HISTORY_DIR="$HOME/Library/Application Support/k4cs"
HISTORY_FILE="$HISTORY_DIR/history"
MAX_HISTORY=10

# --- Product/Version options (defined early for use in history display) ---
declare -a labels=()
declare -a products=()
declare -a versions=()

labels+=("InCopy 2024")   ; products+=("K4 Edit")   ; versions+=("2024")
labels+=("InDesign 2024") ; products+=("K4 Layout") ; versions+=("2024")
labels+=("InCopy 2025")   ; products+=("K4 Edit")   ; versions+=("2025")
labels+=("InDesign 2025") ; products+=("K4 Layout") ; versions+=("2025")

# --- Usage ---
usage() {
  cat <<EOF
k4cs — Install K4 Config.xml files from a server URL

Usage:
  k4cs [--url <URL>] [--dry-run]

Modes:
  k4cs --url <URL>    Parse URL, prompt for products/versions, install configs
  k4cs                Pick from recent servers with remembered defaults

Options:
  --url <URL>   K4 test or admin URL (admin URLs are auto-converted)
  --dry-run     Show what would be created without writing files
  -h, --help    Show this help

Examples:
  k4cs --url https://example.com:8443/K4Server/test/
  k4cs --url https://example.com/K4Server/admin/ --dry-run
  k4cs            # pick from recent servers, accept defaults with Enter

History:
  Selections are saved to ~/Library/Application Support/k4cs/history
  and recalled when running without --url.
EOF
  exit 0
}

# --- History functions ---
hist_urls=()
hist_selections=()

load_history() {
  hist_urls=()
  hist_selections=()
  if [[ -f "$HISTORY_FILE" ]]; then
    while IFS=$'\t' read -r h_url h_sel; do
      hist_urls+=("$h_url")
      hist_selections+=("$h_sel")
    done < "$HISTORY_FILE"
  fi
}

save_history() {
  local new_url="$1"
  local new_sel="$2"
  mkdir -p "$HISTORY_DIR"
  local tmp
  tmp="$(mktemp "$HISTORY_DIR/history.XXXXXX")"
  # Write the new entry first
  printf '%s\t%s\n' "$new_url" "$new_sel" > "$tmp"
  # Append existing entries, skipping duplicate
  local count=1
  if [[ -f "$HISTORY_FILE" ]]; then
    while IFS=$'\t' read -r h_url h_sel; do
      if [[ "$h_url" != "$new_url" ]]; then
        printf '%s\t%s\n' "$h_url" "$h_sel" >> "$tmp"
        count=$((count + 1))
        if [[ $count -ge $MAX_HISTORY ]]; then
          break
        fi
      fi
    done < "$HISTORY_FILE"
  fi
  mv "$tmp" "$HISTORY_FILE"
}

# Format selection numbers into readable label list, e.g. "2 4" → "InDesign 2024, InDesign 2025"
format_selections() {
  local sel="$1"
  local result=""
  for num in $sel; do
    local idx=$((num - 1))
    if [[ $idx -ge 0 && $idx -lt ${#labels[@]} ]]; then
      if [[ -n "$result" ]]; then
        result+=", "
      fi
      result+="${labels[$idx]}"
    fi
  done
  echo "$result"
}

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      usage
      ;;
  esac
done

# --- If no URL, show server picker ---
if [[ -z "$URL" ]]; then
  load_history

  if [[ ${#hist_urls[@]} -eq 0 ]]; then
    printf "Enter URL: "
    read -r URL
    if [[ -z "$URL" ]]; then
      echo "No URL provided. Exiting."
      exit 0
    fi
  else
    echo ""
    echo "Recent servers:"
    for i in "${!hist_urls[@]}"; do
      sel_display="$(format_selections "${hist_selections[$i]}")"
      echo "  $((i+1))) ${hist_urls[$i]}  [${sel_display}]"
    done
    echo "  $((${#hist_urls[@]}+1))) Enter new URL"

    printf "> "
    read -r pick

    if [[ -z "$pick" ]]; then
      echo "No selection made. Exiting."
      exit 0
    fi

    if ! [[ "$pick" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid selection." >&2
      exit 1
    fi

    new_url_option=$(( ${#hist_urls[@]} + 1 ))
    if [[ "$pick" -eq "$new_url_option" ]]; then
      printf "Enter URL: "
      read -r URL
      if [[ -z "$URL" ]]; then
        echo "No URL provided. Exiting."
        exit 0
      fi
    elif [[ "$pick" -ge 1 && "$pick" -le ${#hist_urls[@]} ]]; then
      idx=$((pick - 1))
      URL="${hist_urls[$idx]}"
      DEFAULT_SELECTIONS="${hist_selections[$idx]}"
    else
      echo "Error: Selection out of range." >&2
      exit 1
    fi
  fi
fi

# --- Validate URL ---
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: Invalid URL. Only http or https URLs are allowed." >&2
  exit 1
fi

# --- Parse URL ---
without_scheme="${URL#*://}"
protocol="${URL%%://*}"
host_port="${without_scheme%%/*}"
url_path="/${without_scheme#*/}"

if [[ "$without_scheme" == "$host_port" ]]; then
  url_path="/"
fi

if [[ "$host_port" == *:* ]]; then
  address="${host_port%%:*}"
  port="${host_port##*:}"
else
  address="$host_port"
  if [[ "$protocol" == "https" ]]; then
    port=443
  else
    port=80
  fi
fi

if [[ -z "$address" ]]; then
  echo "Error: Could not extract hostname from URL." >&2
  exit 1
fi

# --- Convert admin URL to test URL path ---
full_path="$url_path"
admin_converted=false

if [[ "$full_path" == *"admin/"* ]]; then
  full_path="${full_path/admin\//test/}"
  admin_converted=true
elif [[ "$full_path" =~ admin$ ]]; then
  full_path="${full_path%admin}test/"
  admin_converted=true
fi

if [[ "$full_path" == *"test/"* ]]; then
  path="${full_path%%test/*}"
  if [[ "$path" != */ ]]; then
    path="${path}/"
  fi
else
  path="$full_path"
fi

if $admin_converted; then
  echo "Note: Admin URL detected and converted for K4 configuration."
fi

# --- Generate XML ---
xml="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<config version=\"2\">
  <servers>
    <server name=\"${address}\" protocol=\"${protocol}\" address=\"${address}\" port=\"${port}\" path=\"${path}\" />
  </servers>

  <inCopyPrintSettings outputMode=\"default\" imageData=\"default\" pagePosition=\"default\" />

  <!--
    <proxy url=\"http://localhost:8585\"/>
  -->
</config>"

# --- Display parsed info ---
echo ""
echo "Server: ${protocol}://${address}:${port}${path}"
echo ""

# --- Multi-select prompt with defaults ---
if [[ -n "$DEFAULT_SELECTIONS" ]]; then
  echo "Select configurations (space-separated numbers, 'a' for all, Enter for defaults [${DEFAULT_SELECTIONS}]):"
  for i in "${!labels[@]}"; do
    num=$((i+1))
    marker=""
    # Check if this number is in the defaults
    for d in $DEFAULT_SELECTIONS; do
      if [[ "$d" == "$num" ]]; then
        marker="  *"
        break
      fi
    done
    echo "  ${num}) ${labels[$i]}${marker}"
  done
else
  echo "Select configurations to install (space-separated numbers, or 'a' for all):"
  for i in "${!labels[@]}"; do
    echo "  $((i+1))) ${labels[$i]}"
  done
fi

printf "> "
read -r selection

# Apply defaults if empty input and defaults exist
if [[ -z "$selection" ]]; then
  if [[ -n "$DEFAULT_SELECTIONS" ]]; then
    selection="$DEFAULT_SELECTIONS"
  else
    echo "No selection made. Exiting."
    exit 0
  fi
fi

# Parse selection
declare -a selected=()
if [[ "$selection" == "a" || "$selection" == "A" ]]; then
  for i in "${!labels[@]}"; do
    selected+=("$i")
  done
  # Build selection string for history
  selection_string=""
  for i in "${!labels[@]}"; do
    selection_string+="$((i+1)) "
  done
  selection_string="${selection_string% }"
else
  selection_string="$selection"
  for num in $selection; do
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid selection '$num'. Use numbers or 'a' for all." >&2
      exit 1
    fi
    index=$((num - 1))
    if [[ $index -lt 0 || $index -ge ${#labels[@]} ]]; then
      echo "Error: Selection '$num' is out of range." >&2
      exit 1
    fi
    selected+=("$index")
  done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "No selection made. Exiting."
  exit 0
fi

# --- Install configs ---
echo ""
for idx in "${selected[@]}"; do
  product="${products[$idx]}"
  version="${versions[$idx]}"
  target_dir="$HOME/Library/Preferences/vjoon/K4/${product}/${version}"
  target_file="${target_dir}/K4 Config.xml"

  if $DRY_RUN; then
    echo "[dry-run] Would create: ${target_file}"
  else
    mkdir -p "$target_dir"
    printf '%s' "$xml" > "$target_file"
    echo "✓ Created: ${target_file}"
  fi
done

# --- Save to history (skip on dry-run) ---
if ! $DRY_RUN; then
  save_history "$URL" "$selection_string"
fi
