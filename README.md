# 🚨 PagerDuty On-Call Time Calculator 🕒

A simple Ruby script that calculates and summarizes the time each team member spends on-call using the PagerDuty API.

## 📋 Features

- Calculate total on-call hours per user
- Filter by date range, users, or escalation policies
- List all available escalation policies
- Support for pagination and time zones
- Simple and readable command line output

## 🛠️ Installation

```bash
# Clone the repository
git clone git@github.com:QuirkQ/pagerduty-oncall-summarizer.git
cd pagerduty-oncall-summarizer

# Install dependencies
bundle install
```

## 🔑 Setup

You'll need a PagerDuty API token to use this script. You can either:

1. Set it as an environment variable:
   ```bash
   export PAGERDUTY_API_TOKEN=your_token_here
   ```

2. Or provide it directly as a command-line argument (see Usage below)

To create a PagerDuty API token:
1. Log in to your PagerDuty account
2. Go to My Profile → User Settings → Create API User Token
3. Give it a description and save the token in a secure place

## 🚀 How to Use

### Basic Usage

```bash
# Get on-call hours summary for all users in the last 30 days
./script.rb --since "$(date -d '30 days ago' '+%Y-%m-%d')" --until "$(date '+%Y-%m-%d')"

# Using with explicit token
./script.rb --token YOUR_PAGERDUTY_TOKEN --since 2025-06-01 --until 2025-06-30
```

### List All Escalation Policies

```bash
./script.rb --list-policies
```

### Filter by User or Policy

```bash
# Filter for a specific user
./script.rb --since 2025-06-01 --until 2025-06-30 --user PXXXXX

# Filter for a specific escalation policy
./script.rb --since 2025-06-01 --until 2025-06-30 --policy PXXXXX

# You can specify multiple users or policies
./script.rb --user PXXXXX --user PYYYYYY
```

### Other Options

```bash
# Use a specific timezone
./script.rb --since 2025-06-01 --until 2025-06-30 --tz "America/New_York"

# Only get the primary on-calls (earliest flag)
./script.rb --since 2025-06-01 --until 2025-06-30 --earliest
```

## 📝 Command Line Options

```
--token TOKEN           PagerDuty API token
--since DATE            Start date YYYY-MM-DD
--until DATE            End date YYYY-MM-DD
--user ID               Filter by user (can be used multiple times)
--policy ID             Filter by policy (can be used multiple times)
--earliest              Show only the primary on-call person
--tz ZONE               Time zone (e.g. Europe/Amsterdam)
--list-policies         List all escalation policy IDs and names
-h, --help              Show help message
```

## 📊 Example Output

When listing policies:
```
Escalation Policy IDs and Names:
P1ABCDE — Primary On-Call Rotation
P2FGHIJ — Secondary Engineering Support
P3KLMNO — Platform Team Alerts
```

When showing on-call summary:
```
On-Call Time Summary
------------------------------------------------------------
User                                       Hours
------------------------------------------------------------
Jane Smith (PABCDE12345)                  168.00
John Doe (PFGHIJ67890)                     72.50
Alex Johnson (PKLMNO12345)                 48.25
```

## 🤔 Contributing

Found a bug? Have a feature request? PRs welcome! Just try not to break the script while you're on-call. That would be... ironic.

## 📜 License

MIT License - Feel free to use, modify, and distribute as needed!
