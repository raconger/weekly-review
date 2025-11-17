# Obsidian Weekly Review System

An automated weekly review system for your Obsidian vault that acts as both an executive assistant and personal coach. This system analyzes your vault activity, compiles tasks, identifies themes, and provides constructive feedback to help you show up as your best self.

## What It Does

Every week (or on-demand), this system:

- **📊 Analyzes** all notes and files modified in the past 7 days
- **✅ Compiles** completed and pending tasks in markdown format
- **🎯 Identifies** highlights, wins, and key themes
- **🔍 Provides coaching** on areas where you could show up better
- **🔄 Tracks patterns** across multiple weeks
- **📝 Generates** a comprehensive markdown report with actionable insights

The output is a structured markdown file that drops into your Obsidian vault, ready for review Monday morning.

## Features

- **Executive Summary**: Week at a glance with key stats
- **Task Tracking**: Completed and pending actions organized clearly
- **Highlights & Wins**: Celebrates your achievements
- **Growth Coaching**: Honest, constructive feedback on improvement areas
- **Pattern Recognition**: Identifies recurring themes across weeks
- **Action-Oriented**: Suggests specific priorities for the coming week
- **Automated**: Runs on a schedule (Sunday evenings by default)

## Requirements

- Python 3.7 or higher
- Obsidian vault (local filesystem access)
- Anthropic API key ([Get one here](https://console.anthropic.com/))
- Unix-like system with cron (Linux, macOS) or Task Scheduler (Windows)

## Quick Start

### 1. Clone or Download This Repository

```bash
git clone https://github.com/yourusername/weekly-review.git
cd weekly-review
```

### 2. Install Dependencies

```bash
pip3 install -r requirements.txt
```

### 3. Configure Your Setup

Copy the example configuration:

```bash
cp config.example.json config.json
```

Edit `config.json` with your details:

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

### 4. Set Your API Key

Add your Anthropic API key to your environment:

```bash
export ANTHROPIC_API_KEY='your-api-key-here'
```

To make it permanent, add it to your shell profile:

```bash
# For bash
echo "export ANTHROPIC_API_KEY='your-api-key-here'" >> ~/.bashrc
source ~/.bashrc

# For zsh
echo "export ANTHROPIC_API_KEY='your-api-key-here'" >> ~/.zshrc
source ~/.zshrc
```

### 5. Test Run

Run the weekly review manually to test:

```bash
./run_weekly_review.py
```

Check your Obsidian vault for a file named `YYYY-MM-DD Weekly Review.md`.

### 6. Set Up Automation (Optional but Recommended)

Run the setup script to automate weekly reviews:

```bash
chmod +x setup_automation.sh
./setup_automation.sh
```

This will:
- Install Python dependencies
- Configure your API key
- Create a cron job for Sunday at 8 PM
- Set up logging

## Configuration Options

### config.json Fields

| Field | Description | Default |
|-------|-------------|---------|
| `obsidian_vault_path` | Full path to your Obsidian vault | Required |
| `output_path` | Where to save weekly reviews | Same as vault path |
| `anthropic_api_key_env` | Environment variable name for API key | `ANTHROPIC_API_KEY` |
| `model` | Claude model to use | `claude-sonnet-4-5-20250929` |
| `max_tokens` | Maximum tokens for response | `4096` |
| `file_extensions` | File types to analyze | `[".md"]` |
| `exclude_folders` | Folders to ignore | `[".obsidian", ".trash", ".git"]` |
| `days_to_review` | Days to look back | `7` |

## Scheduling Options

### Default Schedule: Sunday at 8 PM

The setup script configures a cron job for Sunday at 8 PM, so your review is ready Monday morning.

### Custom Schedule

Edit your crontab to change the schedule:

```bash
crontab -e
```

Cron schedule format: `minute hour day month day-of-week`

Examples:
- `0 20 * * 0` - Sunday at 8 PM (default)
- `0 6 * * 1` - Monday at 6 AM
- `30 19 * * 0` - Sunday at 7:30 PM
- `0 21 * * 5` - Friday at 9 PM

### Windows Task Scheduler

For Windows users, create a scheduled task:

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., Weekly, Sunday, 8 PM)
4. Action: Start a program
5. Program: `python`
6. Arguments: `C:\path\to\run_weekly_review.py`
7. Start in: `C:\path\to\weekly-review`

## File Structure

```
weekly-review/
├── README.md                          # This file
├── requirements.txt                   # Python dependencies
├── config.example.json                # Example configuration
├── config.json                        # Your configuration (create this)
├── weekly-review-prompt.md            # The prompt template
├── run_weekly_review.py               # Main execution script
├── setup_automation.sh                # Automation setup script
├── run_weekly_review_cron.sh          # Cron wrapper (auto-generated)
└── weekly_review.log                  # Log file (auto-generated)
```

## Customizing the Prompt

The review behavior is controlled by `weekly-review-prompt.md`. You can customize:

- The analysis focus areas
- The coaching tone and style
- The output format and sections
- What patterns to look for

Edit this file to personalize how your weekly reviews are generated.

## Output Format

Each weekly review includes:

- **Week at a Glance**: Executive summary
- **Completed Actions**: Tasks you finished (checkbox format)
- **Pending Tasks**: What still needs attention
- **Highlights & Wins**: Notable achievements
- **Key Themes**: Major patterns that emerged
- **Areas for Growth**: Constructive coaching on improvement
- **Recurring Themes**: Patterns across multiple weeks
- **Insights & Reflections**: Deeper observations
- **Focus for Next Week**: Suggested priorities
- **Commitments Tracker**: New promises made

Files are named: `YYYY-MM-DD Weekly Review.md`

## Troubleshooting

### No files found

- Check your `obsidian_vault_path` in config.json
- Verify file permissions
- Ensure files have been modified in the past 7 days

### API key errors

- Verify `ANTHROPIC_API_KEY` environment variable is set
- Check API key is valid at https://console.anthropic.com/
- Ensure API key has sufficient credits

### Cron job not running

- Check cron is running: `ps aux | grep cron`
- View cron logs: `cat weekly_review.log`
- Test cron job manually: `./run_weekly_review_cron.sh`
- Verify crontab entry: `crontab -l`

### Permission errors

Make scripts executable:
```bash
chmod +x run_weekly_review.py
chmod +x setup_automation.sh
chmod +x run_weekly_review_cron.sh
```

## Advanced Usage

### Multiple Vaults

Create separate config files and wrapper scripts for each vault:

```bash
cp config.json config-personal.json
cp config.json config-work.json
```

Create separate cron jobs pointing to each config.

### Manual Runs

Run a review anytime:

```bash
./run_weekly_review.py
```

### Custom Date Range

Modify `days_to_review` in config.json for different review periods:
- `7` - Weekly (default)
- `14` - Bi-weekly
- `30` - Monthly

### Notifications

Edit `run_weekly_review_cron.sh` to add notifications:

**macOS:**
```bash
osascript -e 'display notification "Your weekly review is ready!" with title "Weekly Review"'
```

**Linux:**
```bash
notify-send "Weekly Review" "Your weekly review is ready!"
```

## Privacy & Security

- All processing happens locally on your machine
- Only the analyzed text is sent to Claude API
- Your vault files are never uploaded or stored externally
- API keys are stored in environment variables (not in code)
- Reviews are saved directly to your vault

## Cost Estimate

Using Claude Sonnet 4.5:
- Typical weekly review: ~$0.10 - $0.50 per run
- Monthly cost: ~$0.40 - $2.00

Cost varies based on:
- Vault activity (number of modified files)
- File sizes
- Number of previous reviews to analyze

## Contributing

Suggestions and improvements welcome! This is a personal productivity tool, so feel free to fork and customize for your needs.

## License

MIT License - Feel free to use and modify as you wish.

## Acknowledgments

- Built with [Claude](https://www.anthropic.com/claude) by Anthropic
- Designed for [Obsidian](https://obsidian.md/) users
- Inspired by the Getting Things Done (GTD) methodology

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review the configuration in config.json
3. Check the log file: `cat weekly_review.log`
4. Open an issue on GitHub (if applicable)

---

**Ready to level up your weekly reflection practice? Get started above!** 🚀
