# Invert PDF Colors as a MacOS Quick Action in finder. 

# Define the paths for input and output PDFs
input_pdf="$1"
output_pdf=~/Downloads/"$(basename "$input_pdf" .pdf)_inverted.pdf"

# Send notification before starting
osascript -e 'display notification "Starting inversion" with title "Invert PDF Colors"'

# Check if the input file exists
if [ ! -f "$input_pdf" ]; then
    osascript -e 'display notification "Input PDF not found" with title "Error Inverting PDF Colors"'
    exit 1
fi

# Run ImageMagick's convert command, capturing both stdout and stderr in the log file
/opt/homebrew/bin/convert -density 250 -channel RGB -negate "$input_pdf" "$output_pdf" > ~/Downloads/log.txt 2>&1

# Check if the output PDF was successfully created
if [ -f "$output_pdf" ]; then
    osascript -e 'display notification "Completed inversion" with title "Invert PDF Colors"'
else
    osascript -e 'display notification "Failed to create output PDF" with title "Error Inverting PDF Colors"'
    echo "Conversion failed. Check ~/Downloads/log.txt for details."
    exit 1
fi


