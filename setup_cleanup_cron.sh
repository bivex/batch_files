#!/bin/bash

# Setup automatic disk cleanup cron job

echo "Setting up automatic disk cleanup..."

# Create cron job to run disk cleanup weekly (every Sunday at 2 AM)
CRON_JOB="0 2 * * 0 /root/disk_cleanup.sh > /dev/null 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "disk_cleanup.sh"; then
    echo "Disk cleanup cron job already exists."
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Disk cleanup cron job added successfully!"
    echo "The script will run every Sunday at 2:00 AM"
fi

echo ""
echo "Current cron jobs:"
crontab -l 2>/dev/null || echo "No cron jobs found"

echo ""
echo "To manually run the cleanup script, use:"
echo "  /root/disk_cleanup.sh"
echo ""
echo "To view cleanup logs, use:"
echo "  tail -f /var/log/disk_cleanup.log"
