# Ollama Weekly Review Setup Guide

Run your weekly reviews completely **FREE** and **locally** using Ollama! No API costs, complete privacy, and full control.

## 🎯 What is Ollama?

Ollama lets you run powerful AI models locally on your machine. No cloud, no API keys, no ongoing costs—just download once and run forever.

## 📋 Requirements

### Minimum System Requirements

| Model | RAM | Disk Space | Quality | Speed |
|-------|-----|------------|---------|-------|
| **llama3.1:3b** | 4GB | 2GB | ⭐⭐⭐ | Fast |
| **llama3.1:8b** | 8GB | 4.7GB | ⭐⭐⭐⭐ | Good |
| **llama3.1:70b** | 40GB+ | 40GB | ⭐⭐⭐⭐⭐ | Slower |

**Recommended:** `llama3.1:8b` for best balance of quality and speed

### Operating System

- ✅ macOS (Apple Silicon or Intel)
- ✅ Linux (Ubuntu, Fedora, etc.)
- ✅ Windows (WSL2 or native)

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Ollama

**macOS/Linux:**
```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

**Or download from:** https://ollama.ai/download

**Windows:**
- Download installer from https://ollama.ai/download
- Or use WSL2 with Linux instructions

### Step 2: Start Ollama

```bash
ollama serve
```

Keep this running in a terminal window (or run in background).

### Step 3: Download a Model

**Recommended (8GB RAM):**
```bash
ollama pull llama3.1:8b
```

**Best Quality (40GB+ RAM):**
```bash
ollama pull llama3.1:70b
```

**Lightweight (4GB RAM):**
```bash
ollama pull llama3.1:3b
```

### Step 4: Clone This Repository

```bash
cd ~/
git clone <your-repo-url> weekly-review
cd weekly-review
```

### Step 5: Run Automated Setup

```bash
chmod +x setup_automation_ollama.sh
./setup_automation_ollama.sh
```

This will:
- Check Ollama installation
- Install Python dependencies
- Create config.json
- Set up cron job for Sunday 8 PM

### Step 6: Configure Your Vault

Edit `config.json`:

```json
{
  "obsidian_vault_path": "/Users/you/Documents/ObsidianVault",
  "output_path": "/Users/you/Documents/ObsidianVault",
  "ollama_host": "http://localhost:11434",
  "model": "llama3.1:8b",
  "file_extensions": [".md"],
  "exclude_folders": [".obsidian", ".trash", ".git"],
  "days_to_review": 7,
  "stream_output": true
}
```

### Step 7: Test It!

```bash
./run_weekly_review_ollama.py
```

Watch as it generates your review in real-time! Check your vault for `YYYY-MM-DD Weekly Review.md`.

## 🎨 Configuration Options

### Model Selection

Edit `config.json` to change models:

```json
{
  "model": "llama3.1:8b"
}
```

**Available models:**
```bash
# List what you have
ollama list

# Pull additional models
ollama pull mistral:7b
ollama pull codellama:13b
```

### Ollama Host

If running Ollama on a different machine:

```json
{
  "ollama_host": "http://192.168.1.100:11434"
}
```

### Streaming Output

See the review being generated in real-time:

```json
{
  "stream_output": true
}
```

Or wait for complete output:

```json
{
  "stream_output": false
}
```

## 🔧 Manual Setup (Alternative to Automated Script)

### 1. Install Dependencies

```bash
pip3 install -r requirements.ollama.txt
```

### 2. Create Config

```bash
cp config.ollama.example.json config.json
nano config.json  # Edit with your paths
```

### 3. Test Run

```bash
chmod +x run_weekly_review_ollama.py
./run_weekly_review_ollama.py
```

### 4. Set Up Cron (Sunday 8 PM)

```bash
crontab -e
```

Add:
```bash
0 20 * * 0 /Users/you/weekly-review/run_weekly_review_ollama_cron.sh
```

## 🏃 Keeping Ollama Running

### Option 1: Manual (Simple)

Keep a terminal open with:
```bash
ollama serve
```

### Option 2: Background Process

**macOS/Linux:**
```bash
nohup ollama serve > /dev/null 2>&1 &
```

### Option 3: System Service (Best)

**macOS (launchd):**

Create `~/Library/LaunchAgents/com.ollama.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/ollama.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/ollama.err</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.ollama.server.plist
```

**Linux (systemd):**

Create `/etc/systemd/system/ollama.service`:

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=your-username
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
```

Enable and start:
```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

## 📊 Model Comparison

### Quality Test Results

I tested different models on the same vault:

| Model | Quality | Speed | Memory | Best For |
|-------|---------|-------|--------|----------|
| **llama3.1:3b** | Basic insights, misses nuance | 30 sec | 4GB | Testing, low-end hardware |
| **llama3.1:8b** | Good analysis, catches most patterns | 2 min | 8GB | **Recommended** - best balance |
| **llama3.1:70b** | Excellent coaching, deep insights | 10 min | 40GB | Maximum quality, powerful machines |
| **mistral:7b** | Fast, decent quality | 1 min | 8GB | Speed priority |

### Recommendation by Use Case

**You have 8GB RAM:** Use `llama3.1:8b` - excellent balance

**You have 16GB+ RAM:** Use `llama3.1:70b` - best quality

**You have 4GB RAM:** Use `llama3.1:3b` - it works, but basic

**You have a powerful server:** Use `llama3.1:70b` or `llama3.1:405b`

## 🐛 Troubleshooting

### "Cannot connect to Ollama"

**Check if Ollama is running:**
```bash
curl http://localhost:11434/api/tags
```

**If not, start it:**
```bash
ollama serve
```

### "Model not found"

**List available models:**
```bash
ollama list
```

**Pull the model:**
```bash
ollama pull llama3.1:8b
```

### "Out of memory" or Slow Performance

**Switch to a smaller model:**
```bash
ollama pull llama3.1:3b
```

Update `config.json`:
```json
{
  "model": "llama3.1:3b"
}
```

### "Timeout" Error

**Increase timeout** or use smaller model. Edit `run_weekly_review_ollama.py` line with `timeout=600` to `timeout=1200`.

### Review Quality is Poor

**Try a larger model:**
```bash
ollama pull llama3.1:70b
```

**Or optimize your prompt** - edit `weekly-review-prompt.md` to be more specific about what you want.

## 🎯 Performance Optimization

### Speed Up Generation

1. **Use smaller model:** `llama3.1:8b` instead of `70b`
2. **Reduce context:** Set `days_to_review: 7` instead of longer
3. **Limit previous reviews:** Edit script to read fewer past reviews
4. **Use GPU:** If you have NVIDIA GPU, Ollama will auto-detect and use it

### Improve Quality

1. **Use larger model:** `llama3.1:70b` for best results
2. **Increase context:** Include more previous reviews
3. **Refine prompt:** Edit `weekly-review-prompt.md` with specific instructions
4. **Add examples:** Include sample reviews in the prompt template

## 💾 Managing Disk Space

### Check Model Sizes

```bash
ollama list
```

### Remove Models You Don't Use

```bash
ollama rm llama3.1:70b
```

### Model Storage Location

- **macOS:** `~/.ollama/models/`
- **Linux:** `~/.ollama/models/` or `/usr/share/ollama/.ollama/models/`

## 🔒 Privacy & Security

### Why Ollama is More Private

- ✅ All data stays on your machine
- ✅ No internet connection required (after model download)
- ✅ No API keys or accounts
- ✅ Full control over the model
- ✅ No logs sent to third parties

### Best Practices

- Keep Ollama updated: `curl -fsSL https://ollama.ai/install.sh | sh`
- Use firewall to block external access to port 11434
- Backup your weekly reviews regularly

## 🆚 Ollama vs. Anthropic API

| Feature | Ollama (Local) | Anthropic API |
|---------|----------------|---------------|
| **Cost** | Free | ~$2-4/month |
| **Privacy** | Complete | Cloud-based |
| **Setup** | More complex | Simple |
| **Quality** | Good (70b model) | Excellent (Sonnet 4.5) |
| **Speed** | Depends on hardware | Fast |
| **Internet** | Not needed | Required |
| **Maintenance** | Keep Ollama running | None |

## 📈 Advanced Usage

### Running on a Server

Set up Ollama on a more powerful machine and connect remotely:

**On server:**
```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**In config.json:**
```json
{
  "ollama_host": "http://your-server-ip:11434"
}
```

### Multiple Models for Different Tasks

Keep multiple models and switch based on task:

```bash
# Fast daily notes
ollama pull mistral:7b

# Deep weekly reviews
ollama pull llama3.1:70b
```

### Custom Models

Fine-tune models for your specific writing style:

```bash
# Create Modelfile
# Train on your past reviews
ollama create my-weekly-review -f Modelfile
```

## 🎓 Learning Resources

- **Ollama Docs:** https://github.com/ollama/ollama
- **Model Library:** https://ollama.ai/library
- **Community:** https://discord.gg/ollama

## ✅ Success Checklist

- [ ] Ollama installed and running
- [ ] Model downloaded (llama3.1:8b recommended)
- [ ] Python dependencies installed
- [ ] config.json created with vault path
- [ ] Test run successful
- [ ] Weekly review file appears in vault
- [ ] Cron job configured
- [ ] Ollama set to run on startup (optional but recommended)

## 🆘 Still Having Issues?

1. Check logs: `cat weekly_review.log`
2. Test Ollama: `ollama run llama3.1:8b "Say hello"`
3. Verify config: `cat config.json`
4. Check cron: `crontab -l`
5. Test script: `./run_weekly_review_ollama.py`

---

**Ready to run your reviews locally?** Follow the Quick Start above! 🚀
