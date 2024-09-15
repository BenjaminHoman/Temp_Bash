#!/bin/bash
# usage: sudo bash setup_app.sh "app_name"

# Globals
LOG_FILE='.setup_app.log'
APP_NAME='app' #default name

# Region Logging <------------------------------------------------------------------------------------------------------

#usage - log "type" "msg"
function log {
    OUTPUT_RED='\033[0;31m'
    OUTPUT_YELLOW='\033[0;33m'
    OUTPUT_BLUE='\033[0;36m'
    OUTPUT_END='\033[0m'

    if [ "$1" == "ERROR" ]; then
        printf "${OUTPUT_RED}[$1]${OUTPUT_END} - $2\n"
    elif [ "$1" == "WARN" ]; then
        printf "${OUTPUT_YELLOW}[$1]${OUTPUT_END} - $2\n"
    elif [ "$1" == "INFO" ]; then
        printf "${OUTPUT_BLUE}[$1]${OUTPUT_END} - $2\n"
    else
        echo "[$1] - $2"
    fi

    datetime=$(date +'%Y-%m-%d %H:%M:%S')
    echo "$datetime [$1] - $2" >> "$LOG_FILE"
}

# usage - log_info "msg"
function log_info {
    log "INFO" "$1"
}

# usage - log_error "msg"
function log_error {
    log "ERROR" "$1"
}

# usage - log_warn "msg"
function log_warn {
    log "WARN" "$1"
}

# usage - log_debug "msg"
function log_debug {
    log "DEBUG" "$1"
}

# End Region Logging <--------------------------------------------------------------------------------------------------

# Region Users & Groups <-----------------------------------------------------------------------------------------------

function setup_user_and_group {
    log_info "Begin setup users & groups"

    APP_GROUP="${APP_NAME}_group"
    APP_USER="${APP_NAME}_user"

    log_info "Create Group: $APP_GROUP if not exists"
    if getent group "$APP_GROUP" > /dev/null 2>&1; then
        log_warn "Group: $APP_GROUP already exists. Will not create"
    else
        groupadd "$APP_GROUP"
    fi

    log_info "Create User: $APP_USER if not exists"
    if getent passwd "$APP_USER" > /dev/null 2>&1; then
        log_warn "User: $APP_USER already exists. Will not create"
    else
        useradd -s /bin/bash -g "$APP_GROUP" "$APP_USER"
    fi

    log_info "Finished setup users & groups"
}

function delete_user_and_group {
    log_info "Begin delete users & groups"

    APP_GROUP="${APP_NAME}_group"
    APP_USER="${APP_NAME}_user"

    log_info "Deleting User: $APP_USER"
    if getent passwd "$APP_USER" > /dev/null 2>&1; then
        userdel "$APP_USER"
    else
        log_warn "User: $APP_USER does not exists. Will not delete."
    fi

    log_info "Deleting Group: $APP_GROUP"
    if getent group "$APP_GROUP" > /dev/null 2>&1; then
        groupdel "$APP_GROUP"
    else
        log_warn "Group: $APP_GROUP does not exists. Will not delete."
    fi

    log_info "Finished delete users & groups"
}

# End Region Users & Groups <-------------------------------------------------------------------------------------------

# Region Template App <-------------------------------------------------------------------------------------------------

function setup_folder {
    log_info "Begin setup folder for $APP_NAME"

    APP_FOLDER="/${APP_NAME}"
    APP_GROUP="${APP_NAME}_group"
    APP_USER="${APP_NAME}_user"

    log_info "Building app folder at: $APP_FOLDER"
    rm -r -f "$APP_FOLDER"
    mkdir "$APP_FOLDER"
    mkdir "$APP_FOLDER/logs"
    mkdir "$APP_FOLDER/build"
    mkdir "$APP_FOLDER/src"

    log_info "Template out app.py"
    cat > "$APP_FOLDER/app.py" <<EOL
import time
while True:
    with open("$APP_FOLDER/logs/app.log", "a") as f:
        f.write("Hello from app\n")
        time.sleep(5)
EOL

    chown -R "$APP_USER":"$APP_GROUP" "$APP_FOLDER"

    log_info "Finished setup folder for $APP_NAME"
}

function template_systemd_service {
    log_info "Begin templating out systemd service file"

    APP_GROUP="${APP_NAME}_group"
    APP_USER="${APP_NAME}_user"

    cat > "/etc/systemd/system/${APP_NAME}.service" <<EOL
[UNIT]
Description=A demo app setup via automation
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=2
User=$APP_USER
Group=$APP_GROUP
ExecStart=/usr/bin/python3 /${APP_NAME}/app.py

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl start "${APP_NAME}.service"

    log_info "Finished templating out systemd service file"
}

# End Region Template App <---------------------------------------------------------------------------------------------

function main {
    log_info "Testing info"
    log_error "Testing error"
    log_warn "Testing warn"
}

# Parse script args
if [ "$#" -eq 1 ]; then
    APP_NAME="$1"
    log_info "Setting up app using: $APP_NAME \n"
else
    log_error "Script needs to be called in the following way...\n\tsudo bash setup_app.sh 'app_name' "
    exit 1
fi

main