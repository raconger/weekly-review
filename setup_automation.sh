#!/bin/bash
# Setup script for weekly review automation

set -e

echo "========================================="
echo "Weekly Review Automation Setup"
echo "========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

echo "✅ Python 3 is installed"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3 first."
    exit 1
fi

echo "✅ pip3 is installed"

# Install required Python packages
echo ""
echo "📦 Installing required Python packages..."
pip3 install anthropic

echo ""
echo "✅ Python packages installed"

# Check if config.json exists
if [ ! -f "$SCRIPT_DIR/config.json" ]; then
    echo ""
    echo "⚠️  config.json not found. Creating from example..."
    cp "$SCRIPT_DIR/config.example.json" "$SCRIPT_DIR/config.json"
    echo "✅ Created config.json"
    echo ""
    echo "📝 IMPORTANT: Please edit config.json and set:"
    echo "   - obsidian_vault_path: Path to your Obsidian vault"
    echo "   - output_path: Where to save reviews (usually same as vault)"
    echo ""
    read -p "Press Enter to continue after you've updated config.json..."
fi

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "⚠️  ANTHROPIC_API_KEY environment variable is not set."
    echo ""
    read -p "Enter your Anthropic API key: " api_key

    # Determine shell config file
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        SHELL_CONFIG="$HOME/.profile"
    fi

    echo ""
    echo "Adding ANTHROPIC_API_KEY to $SHELL_CONFIG"
    echo "export ANTHROPIC_API_KEY='$api_key'" >> "$SHELL_CONFIG"
    export ANTHROPIC_API_KEY="$api_key"
    echo "✅ API key configured"
fi

# Make the Python script executable
chmod +x "$SCRIPT_DIR/run_weekly_review.py"
echo "✅ Made run_weekly_review.py executable"

# Setup cron job
echo ""
echo "⏰ Setting up cron job for Sunday at 8 PM..."
echo ""

# Create a wrapper script that sets up the environment
WRAPPER_SCRIPT="$SCRIPT_DIR/run_weekly_review_cron.sh"
cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
# Cron wrapper script for weekly review

# Load environment variables
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi

if [ -f "\$HOME/.zshrc" ]; then
    source "\$HOME/.zshrc"
fi

# Set API key if not already set (fallback)
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

# Run the weekly review
cd "$SCRIPT_DIR"
$SCRIPT_DIR/run_weekly_review.py >> "$SCRIPT_DIR/weekly_review.log" 2>&1

# Optional: Send notification (uncomment and customize)
# osascript -e 'display notification "Your weekly review is ready!" with title "Weekly Review"'
EOF

chmod +x "$WRAPPER_SCRIPT"
echo "✅ Created cron wrapper script"

# Add cron job (Sunday at 8 PM)
CRON_SCHEDULE="0 20 * * 0"
CRON_JOB="$CRON_SCHEDULE $WRAPPER_SCRIPT"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$WRAPPER_SCRIPT"; then
    echo "⚠️  Cron job already exists"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job added: Sunday at 8 PM"
fi

echo ""
echo "========================================="
echo "✨ Setup Complete!"
echo "========================================="
echo ""
echo "Your weekly review will run automatically every Sunday at 8 PM."
echo ""
echo "To test the script manually, run:"
echo "  cd $SCRIPT_DIR"
echo "  ./run_weekly_review.py"
echo ""
echo "To view the cron job:"
echo "  crontab -l"
echo ""
echo "To check the log file:"
echo "  cat $SCRIPT_DIR/weekly_review.log"
echo ""
echo "To customize the schedule, edit your crontab:"
echo "  crontab -e"
echo ""
echo "Current schedule: Sunday at 8 PM (0 20 * * 0)"
echo "  - Minute: 0"
echo "  - Hour: 20 (8 PM)"
echo "  - Day of month: * (any)"
echo "  - Month: * (any)"
echo "  - Day of week: 0 (Sunday)"
echo ""
