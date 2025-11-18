#!/bin/bash
# Setup script for weekly review automation (Ollama version)

set -e

echo "========================================="
echo "Weekly Review Automation Setup (Ollama)"
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

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo ""
    echo "❌ Ollama is not installed"
    echo ""
    echo "Please install Ollama:"
    echo "  macOS/Linux: https://ollama.ai/download"
    echo "  or run: curl -fsSL https://ollama.ai/install.sh | sh"
    echo ""
    read -p "Press Enter after you've installed Ollama..."
fi

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo ""
    echo "⚠️  Ollama is installed but not running"
    echo ""
    echo "Starting Ollama in the background..."
    nohup ollama serve > /dev/null 2>&1 &
    sleep 3

    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "❌ Could not start Ollama automatically"
        echo "Please start Ollama manually in a separate terminal:"
        echo "  ollama serve"
        echo ""
        read -p "Press Enter after Ollama is running..."
    fi
fi

echo "✅ Ollama is running"
echo ""

# Check available models
echo "🔍 Checking available models..."
AVAILABLE_MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "import sys, json; models = json.load(sys.stdin).get('models', []); print('\n'.join([m['name'] for m in models]))" 2>/dev/null || echo "")

if [ -z "$AVAILABLE_MODELS" ]; then
    echo "⚠️  No models found"
    echo ""
    echo "Recommended models:"
    echo "  - llama3.1:70b (Best quality, requires 40GB+ RAM)"
    echo "  - llama3.1:8b (Good balance, requires 8GB RAM)"
    echo "  - llama3.1:3b (Lightweight, requires 4GB RAM)"
    echo ""
    read -p "Enter model name to download [llama3.1:8b]: " MODEL_NAME
    MODEL_NAME=${MODEL_NAME:-llama3.1:8b}

    echo ""
    echo "📦 Downloading $MODEL_NAME (this may take several minutes)..."
    ollama pull "$MODEL_NAME"

    if [ $? -eq 0 ]; then
        echo "✅ Model downloaded successfully"
    else
        echo "❌ Failed to download model"
        exit 1
    fi
else
    echo "✅ Found models:"
    echo "$AVAILABLE_MODELS" | sed 's/^/   - /'
    echo ""

    # Set default model to the first available
    DEFAULT_MODEL=$(echo "$AVAILABLE_MODELS" | head -n 1)
    echo "Will use: $DEFAULT_MODEL"
    MODEL_NAME="$DEFAULT_MODEL"
fi

echo ""

# Install required Python packages
echo "📦 Installing required Python packages..."
pip3 install -r "$SCRIPT_DIR/requirements.ollama.txt"

echo ""
echo "✅ Python packages installed"

# Check if config.json exists
if [ ! -f "$SCRIPT_DIR/config.json" ]; then
    echo ""
    echo "⚠️  config.json not found. Creating from Ollama example..."
    cp "$SCRIPT_DIR/config.ollama.example.json" "$SCRIPT_DIR/config.json"

    # Update model in config if we have one
    if [ ! -z "$MODEL_NAME" ]; then
        python3 -c "import json; c = json.load(open('$SCRIPT_DIR/config.json')); c['model'] = '$MODEL_NAME'; json.dump(c, open('$SCRIPT_DIR/config.json', 'w'), indent=2)"
    fi

    echo "✅ Created config.json"
    echo ""
    echo "📝 IMPORTANT: Please edit config.json and set:"
    echo "   - obsidian_vault_path: Path to your Obsidian vault"
    echo "   - output_path: Where to save reviews (usually same as vault)"
    echo ""
    read -p "Press Enter to continue after you've updated config.json..."
fi

# Make the Python script executable
chmod +x "$SCRIPT_DIR/run_weekly_review_ollama.py"
echo "✅ Made run_weekly_review_ollama.py executable"

# Setup cron job
echo ""
echo "⏰ Setting up cron job for Sunday at 8 PM..."
echo ""

# Create a wrapper script for cron
WRAPPER_SCRIPT="$SCRIPT_DIR/run_weekly_review_ollama_cron.sh"
cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
# Cron wrapper script for weekly review (Ollama)

# Make sure Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    # Try to start Ollama
    nohup ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Run the weekly review
cd "$SCRIPT_DIR"
$SCRIPT_DIR/run_weekly_review_ollama.py >> "$SCRIPT_DIR/weekly_review.log" 2>&1

# Optional: Send notification (uncomment and customize)
# macOS:
# osascript -e 'display notification "Your weekly review is ready!" with title "Weekly Review"'
# Linux:
# DISPLAY=:0 notify-send "Weekly Review" "Your weekly review is ready!"
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
echo "💰 Cost: Completely FREE (runs locally)"
echo "🔒 Privacy: All data stays on your machine"
echo ""
echo "To test the script manually, run:"
echo "  cd $SCRIPT_DIR"
echo "  ./run_weekly_review_ollama.py"
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
echo ""
echo "⚠️  Note: Make sure Ollama stays running or set it to start on boot"
echo ""
