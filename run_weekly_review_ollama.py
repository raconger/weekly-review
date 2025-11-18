#!/usr/bin/env python3
"""
Weekly Review Generator for Obsidian Vault (Ollama Version)
Analyzes vault activity and generates comprehensive weekly reviews using local Ollama models
"""

import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
import json
import requests

# Configuration
CONFIG_FILE = "config.json"
DEFAULT_CONFIG = {
    "obsidian_vault_path": "",  # Path to your Obsidian vault
    "output_path": "",  # Where to save weekly reviews (usually same as vault path)
    "ollama_host": "http://localhost:11434",  # Ollama API endpoint
    "model": "llama3.1:70b",  # Ollama model to use
    "file_extensions": [".md"],  # File types to analyze
    "exclude_folders": [".obsidian", ".trash", ".git"],  # Folders to ignore
    "days_to_review": 7,  # Number of days to look back
    "stream_output": True  # Show progress while generating
}


def load_config():
    """Load configuration from config.json or create default"""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            # Merge with defaults to handle missing keys
            return {**DEFAULT_CONFIG, **config}
    else:
        print(f"⚠️  Config file not found. Creating {CONFIG_FILE} with defaults.")
        print("Please edit config.json and set your obsidian_vault_path and output_path.")
        with open(CONFIG_FILE, 'w') as f:
            json.dump(DEFAULT_CONFIG, f, indent=2)
        return DEFAULT_CONFIG


def check_ollama_available(host):
    """Check if Ollama is running and accessible"""
    try:
        response = requests.get(f"{host}/api/tags", timeout=5)
        if response.status_code == 200:
            return True, response.json().get('models', [])
        return False, []
    except requests.exceptions.RequestException as e:
        return False, []


def check_model_available(host, model_name):
    """Check if specific model is available in Ollama"""
    try:
        response = requests.get(f"{host}/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get('models', [])
            available_models = [m['name'] for m in models]
            return model_name in available_models, available_models
        return False, []
    except requests.exceptions.RequestException:
        return False, []


def get_date_range(days_back=7):
    """Calculate the date range for the review"""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days_back)
    report_date = end_date

    return {
        'start_date': start_date,
        'end_date': end_date,
        'report_date': report_date,
        'start_date_str': start_date.strftime('%Y-%m-%d'),
        'end_date_str': end_date.strftime('%Y-%m-%d'),
        'report_date_str': report_date.strftime('%Y-%m-%d'),
        'generation_timestamp': end_date.strftime('%Y-%m-%d %H:%M:%S')
    }


def find_modified_files(vault_path, start_date, end_date, extensions, exclude_folders):
    """Find all files modified within the date range"""
    vault_path = Path(vault_path)
    modified_files = []

    if not vault_path.exists():
        print(f"❌ Vault path does not exist: {vault_path}")
        return []

    start_timestamp = start_date.timestamp()
    end_timestamp = end_date.timestamp()

    for file_path in vault_path.rglob('*'):
        # Skip directories
        if file_path.is_dir():
            continue

        # Skip excluded folders
        if any(excluded in file_path.parts for excluded in exclude_folders):
            continue

        # Check file extension
        if file_path.suffix not in extensions:
            continue

        # Check modification time
        mtime = file_path.stat().st_mtime
        if start_timestamp <= mtime <= end_timestamp:
            modified_files.append(file_path)

    return sorted(modified_files, key=lambda x: x.stat().st_mtime, reverse=True)


def read_file_content(file_path, vault_path):
    """Read file content with error handling"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        relative_path = file_path.relative_to(vault_path)
        return {
            'path': str(relative_path),
            'content': content,
            'modified': datetime.fromtimestamp(file_path.stat().st_mtime).strftime('%Y-%m-%d %H:%M')
        }
    except Exception as e:
        print(f"⚠️  Error reading {file_path}: {e}")
        return None


def find_previous_reviews(vault_path):
    """Find previous weekly review files"""
    vault_path = Path(vault_path)
    review_files = []

    for file_path in vault_path.rglob('*Weekly Review.md'):
        # Skip excluded folders
        if any(excluded in file_path.parts for excluded in [".obsidian", ".trash", ".git"]):
            continue
        review_files.append(file_path)

    return sorted(review_files, reverse=True)


def read_previous_reviews(review_files, limit=4):
    """Read the most recent previous reviews"""
    reviews = []
    for file_path in review_files[:limit]:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            reviews.append({
                'filename': file_path.name,
                'content': content
            })
        except Exception as e:
            print(f"⚠️  Error reading previous review {file_path}: {e}")
    return reviews


def load_prompt_template():
    """Load the prompt template"""
    template_path = Path(__file__).parent / "weekly-review-prompt.md"
    if not template_path.exists():
        print(f"❌ Prompt template not found: {template_path}")
        sys.exit(1)

    with open(template_path, 'r', encoding='utf-8') as f:
        return f.read()


def build_full_prompt(template, dates, vault_files, previous_reviews):
    """Build the complete prompt with all context"""

    # Replace template variables in the prompt
    prompt = template.replace('{{START_DATE}}', dates['start_date_str'])
    prompt = prompt.replace('{{END_DATE}}', dates['end_date_str'])
    prompt = prompt.replace('{{REPORT_DATE}}', dates['report_date_str'])
    prompt = prompt.replace('{{GENERATION_TIMESTAMP}}', dates['generation_timestamp'])

    # Build context section
    context = f"\n\n## VAULT ACTIVITY CONTEXT\n\n"
    context += f"### Files Modified This Week ({len(vault_files)} files)\n\n"

    for file_info in vault_files:
        context += f"#### {file_info['path']}\n"
        context += f"*Last modified: {file_info['modified']}*\n\n"
        context += f"```markdown\n{file_info['content']}\n```\n\n"

    if previous_reviews:
        context += f"\n### Previous Weekly Reviews ({len(previous_reviews)} recent reviews)\n\n"
        for review in previous_reviews:
            context += f"#### {review['filename']}\n\n"
            context += f"```markdown\n{review['content']}\n```\n\n"

    full_prompt = prompt + context

    return full_prompt


def call_ollama(prompt, host, model, stream=True):
    """Call Ollama API to generate the review"""
    try:
        print(f"🤖 Calling Ollama with model '{model}'...")

        # Check if model is available
        model_available, available_models = check_model_available(host, model)
        if not model_available:
            print(f"❌ Model '{model}' not found in Ollama")
            if available_models:
                print(f"📋 Available models: {', '.join(available_models)}")
                print(f"\nTo download '{model}', run:")
                print(f"   ollama pull {model}")
            else:
                print("No models found. Install a model with: ollama pull llama3.1:70b")
            sys.exit(1)

        url = f"{host}/api/generate"
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": stream
        }

        if stream:
            print("📝 Generating review (this may take a few minutes)...\n")
            response = requests.post(url, json=payload, stream=True, timeout=600)
            response.raise_for_status()

            full_response = ""
            for line in response.iter_lines():
                if line:
                    try:
                        json_response = json.loads(line)
                        if 'response' in json_response:
                            chunk = json_response['response']
                            full_response += chunk
                            print(chunk, end='', flush=True)
                        if json_response.get('done', False):
                            break
                    except json.JSONDecodeError:
                        continue

            print("\n")  # New line after streaming
            return full_response.strip()
        else:
            response = requests.post(url, json=payload, timeout=600)
            response.raise_for_status()
            result = response.json()
            return result.get('response', '').strip()

    except requests.exceptions.Timeout:
        print(f"❌ Request timed out. The model might be too large or your prompt too long.")
        print(f"💡 Try a smaller model like 'llama3.1:8b' or reduce vault activity.")
        sys.exit(1)
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to Ollama at {host}")
        print(f"💡 Make sure Ollama is running: ollama serve")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error calling Ollama: {e}")
        sys.exit(1)


def save_review(content, output_path, report_date_str):
    """Save the generated review to a file"""
    output_path = Path(output_path)
    output_path.mkdir(parents=True, exist_ok=True)

    filename = f"{report_date_str} Weekly Review.md"
    file_path = output_path / filename

    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Weekly review saved to: {file_path}")
        return file_path
    except Exception as e:
        print(f"❌ Error saving review: {e}")
        sys.exit(1)


def main():
    """Main execution function"""
    print("=" * 60)
    print("📝 OBSIDIAN WEEKLY REVIEW GENERATOR (OLLAMA)")
    print("=" * 60)
    print()

    # Load configuration
    config = load_config()

    # Validate configuration
    if not config['obsidian_vault_path']:
        print("❌ Please set 'obsidian_vault_path' in config.json")
        sys.exit(1)

    if not config['output_path']:
        print("ℹ️  No output_path set, using vault path")
        config['output_path'] = config['obsidian_vault_path']

    # Check if Ollama is running
    print("🔍 Checking Ollama status...")
    ollama_available, models = check_ollama_available(config['ollama_host'])

    if not ollama_available:
        print(f"❌ Cannot connect to Ollama at {config['ollama_host']}")
        print()
        print("Please make sure Ollama is installed and running:")
        print("  1. Install: https://ollama.ai/download")
        print("  2. Start: ollama serve")
        print("  3. Pull a model: ollama pull llama3.1:70b")
        print()
        sys.exit(1)

    print(f"✅ Ollama is running at {config['ollama_host']}")
    print(f"📦 {len(models)} model(s) available")
    print()

    # Calculate dates
    dates = get_date_range(config['days_to_review'])
    print(f"📅 Review period: {dates['start_date_str']} to {dates['end_date_str']}")
    print()

    # Find modified files
    print("🔍 Scanning vault for activity...")
    modified_files = find_modified_files(
        config['obsidian_vault_path'],
        dates['start_date'],
        dates['end_date'],
        config['file_extensions'],
        config['exclude_folders']
    )
    print(f"   Found {len(modified_files)} modified files")
    print()

    # Read file contents
    print("📖 Reading file contents...")
    vault_files = []
    for file_path in modified_files:
        file_info = read_file_content(file_path, Path(config['obsidian_vault_path']))
        if file_info:
            vault_files.append(file_info)
    print(f"   Loaded {len(vault_files)} files")
    print()

    # Find and read previous reviews
    print("🔙 Looking for previous weekly reviews...")
    review_files = find_previous_reviews(config['obsidian_vault_path'])
    previous_reviews = read_previous_reviews(review_files, limit=4)
    print(f"   Found {len(previous_reviews)} recent reviews")
    print()

    # Load prompt template
    print("📋 Loading prompt template...")
    template = load_prompt_template()
    print()

    # Build full prompt
    print("🔨 Building analysis prompt...")
    full_prompt = build_full_prompt(template, dates, vault_files, previous_reviews)
    print(f"   Prompt size: {len(full_prompt)} characters")
    print()

    # Call Ollama
    review_content = call_ollama(
        full_prompt,
        config['ollama_host'],
        config['model'],
        config.get('stream_output', True)
    )

    if not review_content:
        print("❌ No content generated. Please check your Ollama setup.")
        sys.exit(1)

    print()

    # Save review
    output_file = save_review(
        review_content,
        config['output_path'],
        dates['report_date_str']
    )
    print()

    print("=" * 60)
    print("✨ Weekly review complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
