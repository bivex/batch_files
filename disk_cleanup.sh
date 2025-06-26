#!/bin/bash

# Disk Cleanup Script
# Automated disk space cleanup for Ubuntu servers
# Created: $(date)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/disk_cleanup.log"
TEMP_LOG="/tmp/cleanup_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$TEMP_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to show disk usage
show_disk_usage() {
    echo -e "${BLUE}Current disk usage:${NC}"
    df -h / | grep -v Filesystem
    echo ""
}

# Function to get available space in MB
get_available_space() {
    df --output=avail / | tail -1 | tr -d ' '
}

log_message "${GREEN}=== Disk Cleanup Script Started ===${NC}"
log_message "Script started at: $(date)"

# Show initial disk usage
log_message "${YELLOW}BEFORE CLEANUP:${NC}"
INITIAL_SPACE=$(get_available_space)
show_disk_usage

log_message "${BLUE}Starting cleanup operations...${NC}"

# 1. APT Package Cache Cleanup
log_message "${YELLOW}1. Cleaning APT package cache...${NC}"
apt clean 2>/dev/null
if [ $? -eq 0 ]; then
    log_message "${GREEN}✓ APT cache cleaned${NC}"
else
    log_message "${RED}✗ Failed to clean APT cache${NC}"
fi

# 2. Remove unnecessary packages
log_message "${YELLOW}2. Removing unnecessary packages...${NC}"
apt autoremove -y 2>/dev/null
if [ $? -eq 0 ]; then
    log_message "${GREEN}✓ Unnecessary packages removed${NC}"
else
    log_message "${RED}✗ Failed to remove unnecessary packages${NC}"
fi

# 3. Clean systemd journal logs (keep last 7 days)
log_message "${YELLOW}3. Cleaning systemd journal logs...${NC}"
JOURNAL_BEFORE=$(du -sh /var/log/journal 2>/dev/null | cut -f1)
journalctl --vacuum-time=7d 2>/dev/null
JOURNAL_AFTER=$(du -sh /var/log/journal 2>/dev/null | cut -f1)
log_message "${GREEN}✓ Journal logs cleaned (was: $JOURNAL_BEFORE, now: $JOURNAL_AFTER)${NC}"

# 4. Clean old log files
log_message "${YELLOW}4. Cleaning old log files...${NC}"
find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null
find /var/log -name "*.log.*" -type f -mtime +7 -delete 2>/dev/null
log_message "${GREEN}✓ Old log files cleaned${NC}"

# 5. Clean temporary directories
log_message "${YELLOW}5. Cleaning temporary directories...${NC}"
rm -rf /tmp/* 2>/dev/null
rm -rf /var/tmp/* 2>/dev/null
log_message "${GREEN}✓ Temporary directories cleaned${NC}"

# 6. Clean various cache directories
log_message "${YELLOW}6. Cleaning cache directories...${NC}"
find /var/cache -type f -delete 2>/dev/null
log_message "${GREEN}✓ Cache directories cleaned${NC}"

# 7. Clean old kernel files (be careful here)
log_message "${YELLOW}7. Checking for old kernel files...${NC}"
CURRENT_KERNEL=$(uname -r)
OLD_KERNELS=$(ls /boot/vmlinuz-* 2>/dev/null | grep -v "$CURRENT_KERNEL" | wc -l)

if [ "$OLD_KERNELS" -gt 0 ]; then
    log_message "${YELLOW}Found $OLD_KERNELS old kernel files${NC}"
    for kernel in $(ls /boot/vmlinuz-* 2>/dev/null | grep -v "$CURRENT_KERNEL"); do
        kernel_version=$(basename "$kernel" | sed 's/vmlinuz-//')
        log_message "Removing old kernel files for version: $kernel_version"
        rm -f "/boot/vmlinuz-$kernel_version" 2>/dev/null
        rm -f "/boot/initrd.img-$kernel_version" 2>/dev/null
        rm -f "/boot/System.map-$kernel_version" 2>/dev/null
        rm -f "/boot/config-$kernel_version" 2>/dev/null
    done
    log_message "${GREEN}✓ Old kernel files removed${NC}"
else
    log_message "${GREEN}✓ No old kernel files to remove${NC}"
fi

# 8. Clean MySQL binary logs (if MySQL is installed)
log_message "${YELLOW}8. Cleaning MySQL binary logs...${NC}"
if [ -d "/var/lib/mysql" ] && command -v mysql >/dev/null 2>&1; then
    # Try to purge binary logs older than 7 days
    mysql -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 7 DAY);" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✓ MySQL binary logs purged${NC}"
    else
        # If MySQL command fails, manually remove old binary logs
        find /var/lib/mysql/binlog* -mtime +7 -delete 2>/dev/null
        log_message "${GREEN}✓ Old MySQL binary logs removed manually${NC}"
    fi
else
    log_message "${YELLOW}MySQL not found or not accessible${NC}"
fi

# 9. Clean WordPress temporary files (if exists)
log_message "${YELLOW}9. Cleaning WordPress temporary files...${NC}"
if [ -d "/tmp_wordpress" ]; then
    WP_TEMP_SIZE=$(du -sh /tmp_wordpress 2>/dev/null | cut -f1)
    rm -rf /tmp_wordpress/* 2>/dev/null
    log_message "${GREEN}✓ WordPress temporary files cleaned (freed: $WP_TEMP_SIZE)${NC}"
else
    log_message "${YELLOW}No WordPress temporary directory found${NC}"
fi

# 10. Clean user cache directories
log_message "${YELLOW}10. Cleaning user cache directories...${NC}"
find /home -name ".cache" -type d -exec rm -rf {}/* \; 2>/dev/null
find /root -name ".cache" -type d -exec rm -rf {}/* \; 2>/dev/null
log_message "${GREEN}✓ User cache directories cleaned${NC}"

# 11. Clean package manager leftovers
log_message "${YELLOW}11. Cleaning package manager leftovers...${NC}"
rm -rf /var/lib/apt/lists/* 2>/dev/null
apt update -qq 2>/dev/null
log_message "${GREEN}✓ Package manager leftovers cleaned${NC}"

# Show final disk usage
log_message "${YELLOW}AFTER CLEANUP:${NC}"
FINAL_SPACE=$(get_available_space)
show_disk_usage

# Calculate space freed
SPACE_FREED=$((FINAL_SPACE - INITIAL_SPACE))
SPACE_FREED_MB=$((SPACE_FREED / 1024))

log_message "${GREEN}=== Cleanup Summary ===${NC}"
log_message "Space freed: ${GREEN}${SPACE_FREED_MB} MB${NC}"
log_message "Available space before: ${INITIAL_SPACE} KB"
log_message "Available space after: ${FINAL_SPACE} KB"
log_message "Cleanup completed at: $(date)"

# Copy temp log to main log
cat "$TEMP_LOG" >> "$LOG_FILE"
rm -f "$TEMP_LOG"

log_message "${GREEN}=== Disk Cleanup Script Completed ===${NC}"
