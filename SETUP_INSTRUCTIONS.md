# Local Machine Setup Instructions

## Prerequisites

- Python 3.7+
- Access to your Obsidian vault on your local filesystem
- Anthropic API key

## Step-by-Step Manual Setup

### 1. Clone the Repository

```bash
cd ~/
git clone <your-repo-url> weekly-review
cd weekly-review
```

### 2. Install Python Dependencies

```bash
pip3 install -r requirements.txt
# or
python3 -m pip install -r requirements.txt
```

### 3. Configure Your Vault Path

Create `config.json` from the example:

```bash
cp config.example.json config.json
```

Edit `config.json` with your actual paths:

```json
{
  "obsidian_vault_path": "/Users/yourname/Documents/ObsidianVault",
  "output_path": "/Users/yourname/Documents/ObsidianVault",
  "anthropic_api_key_env": "ANTHROPIC_API_KEY",
  "model": "claude-sonnet-4-5-20250929",
  "max_tokens": 4096,
  "file_extensions": [".md"],
  "exclude_folders": [".obsidian", ".trash", ".git", "Archive"],
  "days_to_review": 7
}
```

### 4. Set Up Your API Key

**Option A: Add to shell profile (persists across sessions)**

For bash users:
```bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

For zsh users (macOS default):
```bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

**Option B: Set for current session only**
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

### 5. Test the Script

Make it executable and run:

```bash
chmod +x run_weekly_review.py
./run_weekly_review.py
```

Check your Obsidian vault for the generated review file.

### 6. Set Up Cron Job

#### Understanding the Cron Wrapper

The setup script creates a wrapper (`run_weekly_review_cron.sh`) that:
- Loads environment variables (including your API key)
- Changes to the correct directory
- Runs the Python script
- Logs output for debugging

#### Add to Crontab

Open your crontab editor:
```bash
crontab -e
```

Add this line for Sunday at 8 PM:
```bash
0 20 * * 0 /Users/yourname/weekly-review/run_weekly_review_cron.sh
```

**Important:** Replace `/Users/yourname/weekly-review` with the actual path where you cloned the repo.

#### Cron Schedule Reference

Format: `minute hour day_of_month month day_of_week`

Examples:
- `0 20 * * 0` - Sunday at 8:00 PM
- `0 6 * * 1` - Monday at 6:00 AM
- `30 19 * * 0` - Sunday at 7:30 PM
- `0 21 * * 5` - Friday at 9:00 PM
- `0 8 * * 1` - Every Monday at 8:00 AM

Day of week: 0=Sunday, 1=Monday, ..., 6=Saturday

### 7. Verify Cron Job

List your cron jobs:
```bash
crontab -l
```

You should see your weekly review job listed.

### 8. Check Logs

After the first scheduled run, check the log:
```bash
cat ~/weekly-review/weekly_review.log
```

## Troubleshooting

### Cron Job Not Running

**Issue: Nothing happens at scheduled time**

1. Check if cron is running:
```bash
# macOS
sudo launchctl list | grep cron

# Linux
ps aux | grep cron
```

2. Check cron logs:
```bash
# macOS
log show --predicate 'process == "cron"' --last 1h

# Linux
grep CRON /var/log/syslog
```

3. Test the wrapper script manually:
```bash
~/weekly-review/run_weekly_review_cron.sh
```

### Permission Denied

Make scripts executable:
```bash
chmod +x ~/weekly-review/run_weekly_review.py
chmod +x ~/weekly-review/run_weekly_review_cron.sh
chmod +x ~/weekly-review/setup_automation.sh
```

### API Key Not Found

Make sure the environment variable is set in your shell profile AND loaded by cron:

1. Verify it's in your profile:
```bash
cat ~/.bashrc | grep ANTHROPIC_API_KEY
# or
cat ~/.zshrc | grep ANTHROPIC_API_KEY
```

2. Verify it's set in current session:
```bash
echo $ANTHROPIC_API_KEY
```

3. If still not working, hardcode it in the cron wrapper temporarily (LESS SECURE):

Edit `run_weekly_review_cron.sh`:
```bash
export ANTHROPIC_API_KEY="your-actual-key-here"
```

### Obsidian Vault Not Found

Double-check the path in `config.json`:

```bash
# List your vault path to verify it exists
ls -la "/Users/yourname/Documents/ObsidianVault"
```

Make sure:
- The path is absolute (starts with `/`)
- No typos in the path
- No trailing slashes
- The directory exists and is accessible

## macOS-Specific: Granting Cron Access

On macOS, cron needs permission to access files:

1. Go to **System Preferences** → **Security & Privacy** → **Privacy**
2. Select **Full Disk Access**
3. Click the lock to make changes
4. Click **+** and add `/usr/sbin/cron`

Alternatively, you can use launchd (macOS's recommended scheduler):

### Using launchd Instead of Cron (macOS)

Create a launchd plist file:

```bash
cat > ~/Library/LaunchAgents/com.weekly-review.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.weekly-review</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/yourname/weekly-review/run_weekly_review_cron.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>20</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/Users/yourname/weekly-review/weekly_review.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/yourname/weekly-review/weekly_review_error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>ANTHROPIC_API_KEY</key>
        <string>your-api-key-here</string>
    </dict>
</dict>
</plist>
EOF
```

**Replace:**
- `/Users/yourname/` with your actual home directory
- `your-api-key-here` with your actual API key

Load the launchd job:
```bash
launchctl load ~/Library/LaunchAgents/com.weekly-review.plist
```

Check if it's loaded:
```bash
launchctl list | grep weekly-review
```

To unload/disable:
```bash
launchctl unload ~/Library/LaunchAgents/com.weekly-review.plist
```

## Testing Before Sunday

Don't want to wait until Sunday to test? Temporarily change the cron schedule:

```bash
crontab -e
```

Change to run every 5 minutes (for testing):
```bash
*/5 * * * * /Users/yourname/weekly-review/run_weekly_review_cron.sh
```

Watch the log in real-time:
```bash
tail -f ~/weekly-review/weekly_review.log
```

**Remember to change it back to your desired schedule after testing!**

## Getting Notifications

### macOS

Add to `run_weekly_review_cron.sh` (before the script finishes):

```bash
osascript -e 'display notification "Your weekly review is ready!" with title "Weekly Review" sound name "Glass"'
```

### Linux (with notify-send)

```bash
DISPLAY=:0 notify-send "Weekly Review" "Your weekly review is ready!"
```

### Via Email (Universal)

Add to `run_weekly_review_cron.sh`:

```bash
# If successful, send email
if [ $? -eq 0 ]; then
    echo "Weekly review completed at $(date)" | mail -s "Weekly Review Ready" your@email.com
fi
```

## Advanced: Run on Multiple Machines

If you sync your Obsidian vault across machines:

1. Only enable cron on ONE machine (avoid duplicate reviews)
2. Or, add a check in the wrapper script to only run on a specific machine:

```bash
if [ "$(hostname)" != "your-main-computer" ]; then
    exit 0
fi
```

## Success Checklist

- [ ] Repository cloned to local machine
- [ ] Python dependencies installed
- [ ] config.json created with correct vault path
- [ ] ANTHROPIC_API_KEY environment variable set
- [ ] Manual test run successful
- [ ] Review file appears in Obsidian vault
- [ ] Cron job added to crontab
- [ ] Wrapper script has executable permissions
- [ ] (macOS) Full Disk Access granted to cron
- [ ] Log file location confirmed
- [ ] First scheduled run verified

## Need Help?

Check the logs:
```bash
cat ~/weekly-review/weekly_review.log
```

Test manually:
```bash
cd ~/weekly-review
./run_weekly_review.py
```

List cron jobs:
```bash
crontab -l
```
