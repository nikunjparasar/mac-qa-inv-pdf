#!/bin/zsh
# Invert PDF Colors as a macOS Quick Action in Finder.

send_notification() {
    local message="$1"
    local title="$2"
    osascript -e "display notification \"$message\" with title \"$title\""
}

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

check_disk_space() {
    local available_space=$(df -Pk . | awk 'NR==2 {print $4}')
    if (( available_space < 100000 )); then
        send_notification "Insufficient disk space. Operation canceled." "Error"
        log_message "Error: Insufficient disk space."
        exit 1
    fi
    log_message "Sufficient disk space available: $available_space KB"
}

user_confirmation() {
    osascript <<EOD
        set userChoice to display dialog "Do you want to proceed with inverting the PDF colors?" buttons {"Cancel", "Proceed"} default button "Proceed"
        return button returned of userChoice
EOD
}

input_pdf="$1"
output_folder=~/Downloads  # Default output folder
output_pdf="$output_folder/$(basename "$input_pdf" .pdf)_inverted.pdf"
log_file=~/Downloads/pdf_invert_log_$(date '+%Y%m%d_%H%M%S').txt
backup_pdf="${input_pdf%.*}_backup.pdf"

send_notification "Starting PDF color inversion." "Invert PDF Colors"
log_message "Starting inversion for file: $input_pdf"

if [ ! -f "$input_pdf" ]; then
    send_notification "Input PDF not found." "Error Inverting PDF Colors"
    log_message "Error: Input file not found."
    exit 1
fi

output_folder=$(osascript -e 'choose folder with prompt "Choose an output folder for the inverted PDF"' 2>/dev/null)
if [ "$?" -eq 0 ]; then
    output_pdf="$output_folder/$(basename "$input_pdf" .pdf)_inverted.pdf"
    log_message "Custom output folder selected: $output_folder"
else
    log_message "Using default output folder: ~/Downloads"
fi

user_choice=$(user_confirmation)
if [[ "$user_choice" == "Cancel" ]]; then
    send_notification "Operation canceled by the user." "Invert PDF Colors"
    log_message "Operation canceled by user."
    exit 0
fi

check_disk_space

log_message "Creating a backup of the input file at: $backup_pdf"
cp "$input_pdf" "$backup_pdf"
if [ $? -ne 0 ]; then
    send_notification "Failed to create backup." "Error"
    log_message "Error: Backup creation failed."
    exit 1
fi
log_message "Backup created successfully."

if ! command -v /opt/homebrew/bin/convert &> /dev/null; then
    send_notification "ImageMagick not installed." "Error Inverting PDF Colors"
    log_message "Error: ImageMagick (convert command) not found."
    exit 1
fi

log_message "Running ImageMagick command..."
/opt/homebrew/bin/convert -density 250 -channel RGB -negate "$input_pdf" "$output_pdf" >> "$log_file" 2>&1
conversion_status=$?

if [ $conversion_status -eq 0 ] && [ -f "$output_pdf" ]; then
    send_notification "PDF color inversion completed successfully!" "Invert PDF Colors"
    log_message "Success: Output file created at $output_pdf"
else
    send_notification "Failed to create output PDF." "Error Inverting PDF Colors"
    log_message "Error: Conversion failed. Check log for details."

    retry_choice=$(osascript -e 'display dialog "Conversion failed. Would you like to retry?" buttons {"No", "Retry"} default button "Retry"')
    if [[ "$retry_choice" == "Retry" ]]; then
        log_message "Retrying the conversion..."
        /opt/homebrew/bin/convert -density 250 -channel RGB -negate "$input_pdf" "$output_pdf" >> "$log_file" 2>&1
        if [ $? -eq 0 ]; then
            send_notification "Retry successful. PDF inversion completed!" "Invert PDF Colors"
            log_message "Retry successful: Output file created at $output_pdf"
        else
            send_notification "Retry failed. Check log for more info." "Error Inverting PDF Colors"
            log_message "Error: Retry failed. Check log file for details."
            echo "Retry failed. Check the log file at $log_file for details."
            exit 1
        fi
    else
        log_message "User opted not to retry."
        exit 1
    fi
fi

open "$output_pdf"

log_message "Inversion process completed."
exit 0



