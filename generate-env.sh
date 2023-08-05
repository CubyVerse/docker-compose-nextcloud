#!/usr/bin/env bash
# Was created with the assistance of ChatGPT.

# only run on linux
if [ "$(uname)" != "Linux" ] && [ "$(uname)" != "Darwin" ]; then
    echo "The script only runs on Linux."
    exit 1
fi

# Function for secure password input
read_password() {
    # The 'read' command does not echo the input on the screen using the -s flag.
    # The password will be stored in the variable "$1".
    read -r -s -p "Enter the password for the SMTP server: " "$1"
    echo
}

# Function to validate an email address
is_valid_email() {
    # Checking if the input matches the pattern of an email address.
    if [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0 # Valid email address
    else
        return 1 # Invalid email address
    fi
}

# Function to validate the port number
validate_port() {
    # Checking if the input is a whole number and in the range of 1 to 65535.
    if [[ "$1" =~ ^[0-9]+$ ]] && (($1 >= 1 && $1 <= 65535)); then
        return 0 # Valid port number
    else
        return 1 # Invalid port number
    fi
}

is_valid_domain() {
    if [[ "$1" =~ ^([A-Za-z0-9-]{1,63}\.)+[A-Za-z]{2,6}$ ]]; then
        return 0 # Valid email address
    else
        return 1 # Invalid email address
    fi
}

# ask the user if .env already exists
if [ -f .env ]; then
    read -rp "Environment already defined. Do you want to overwrite it? (y/[n]) " CHOICE
    if [ "$CHOICE" != "y" ]; then
        exit 1
    fi
fi

cp .env.example .env

## Docker-Container (Software)
# admin-user username
USERNAME=""
while true; do
    echo "Choice: Which username do you want to use?"
    echo "  1 - username (administrator)"
    echo "  2 - input your own username"
    read -rp "input choice [1]: " CHOICE
    case "${CHOICE}" in
    1 | "")
        USERNAME="administrator"
        break
        ;;
    2)
        read -rp "Please provide a valid username (special-characters: -_): " USERNAME
        if [[ "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "Username for the admin-user: $USERNAME"
            break
        else
            echo "Invalid username. Please try again."
        fi
        ;;
    *)
        echo "No valid answer. Please try again."
        ;;
    esac
done
sed -i -e "s:^NEXTCLOUD_ADMIN_USER=:NEXTCLOUD_ADMIN_USER=${USERNAME}:g" .env

# admin-user password
PASSWORD=""
while true; do
    echo "Choice: Which password do you want to use?"
    echo "  1 - random password"
    echo "  2 - input your own password"
    read -rp "input choice [1]: " CHOICE
    case "${CHOICE}" in
    1 | "")
        PASSWORD=$(LC_CTYPE=C tr -dc '[:alnum:]' </dev/urandom | fold -w "${1:-64}" | head -n 1)
        echo "Password for the user ($USERNAME): ${PASSWORD}"
        break
        ;;
    2)
        echo -n "Enter a password (at least 16 characters, with at least 3 lowercase letters, 3 uppercase letters, and 3 special characters): "
        IFS= read -r PASSWORD

        LEN=${#PASSWORD}
        LOWER=$(echo "$PASSWORD" | grep -o '[a-z]' | wc -l)
        UPPER=$(echo "$PASSWORD" | grep -o '[A-Z]' | wc -l)
        SPECIAL=$(echo "$PASSWORD" | grep -o '[^a-zA-Z0-9]' | wc -l)

        if [ "$LEN" -lt 16 ]; then
            echo "The password is shorter than 16 characters."
        elif [ "$LOWER" -lt 3 ]; then
            echo "The does not contain at least 3 lowercase letters."
        elif [ "$UPPER" -lt 3 ]; then
            echo "The does not contain at least 3 uppercase letters."
        elif [ "$SPECIAL" -lt 3 ]; then
            echo "The does not contain at least 3 special characters."
        else
            echo "Password for the user ($USERNAME): ${PASSWORD}"
            break
        fi
        ;;
    *)
        echo "No valid answer. Please try again."
        ;;
    esac
done
sed -i -e "s:^NEXTCLOUD_ADMIN_PASSWORD=:NEXTCLOUD_ADMIN_PASSWORD=${PASSWORD}:g" .env

# Loop until valid RAM allocation is entered
RAM=""
while true; do
    # Ask user for RAM allocation in GB or MB
    read -rp "Enter the amount of RAM you want to allocate to PHP (e.g. 512M or 1G): " RAM

    # Extract the numeric value and unit from the input
    NUM=$(echo "$RAM" | grep -oE '[0-9]+')
    UNIT=$(echo "$RAM" | grep -oE '[[:alpha:]]{1}$')

    # Check if unit is valid
    if [[ $UNIT == "M" || $UNIT == "G" ]]; then
        echo "PHP memory limit set to ${RAM}."
        break
    else
        echo "Invalid unit. Please enter a valid RAM allocation in G or M."
    fi
done
sed -i -e "s:^PHP_MEMORY_LIMIT=:PHP_MEMORY_LIMIT=${RAM}:g" .env

# Loop until valid UPLOAD allocation is entered
UPLOAD=""
while true; do
    # Ask user for UPLOAD allocation in GB or MB
    read -rp "Enter the amount of the UPLOAD Limit you want to allocate to PHP (e.g. 512M or 1G): " UPLOAD

    # Extract the numeric value and unit from the input
    NUM=$(echo "$UPLOAD" | grep -oE '[0-9]+')
    UNIT=$(echo "$UPLOAD" | grep -oE '[[:alpha:]]{1}$')

    # Check if unit is valid
    if [[ $UNIT == "M" || $UNIT == "G" ]]; then
        UPLOAD="$NUM$UNIT"
        echo "PHP upload limit set to ${UPLOAD}."
        break
    else
        echo "Invalid unit. Please enter a valid UPLOAD limit in G or M."
    fi
done

sed -i -e "s:^PHP_UPLOAD_LIMIT=:PHP_UPLOAD_LIMIT=${UPLOAD}:g" .env

## Docker-Container (MariaDB)
PASSWORD=""
PASSWORD=$(LC_CTYPE=C tr -dc '[:alnum:]' </dev/urandom | fold -w "${1:-64}" | head -n 1)
sed -i -e "s:^MARIADB_PASSWORD_ROOT=:MARIADB_PASSWORD_ROOT=${PASSWORD}:g" .env

PASSWORD=""
PASSWORD=$(LC_CTYPE=C tr -dc '[:alnum:]' </dev/urandom | fold -w "${1:-64}" | head -n 1)
sed -i -e "s:^MARIADB_PASSWORD_USER=:MARIADB_PASSWORD_USER=${PASSWORD}:g" .env

# SMTP
read -rp "Do you want to configure sending emails? ([y]/n):" SMTP
if [ "$SMTP" != "n" ]; then
    # Enter username and email address
    read -rp "Enter your username: " SMTP_NAME
    # Validating the input email address
    while true; do
        read -rp "Enter your email address: " SMTP_NAME
        if is_valid_email "$SMTP_NAME"; then break; fi
        echo "Invalid email address. Please try again."
    done

    # Enter password
    read_password SMTP_PASSWORD

    # Enter mail server and port
    read -rp "Enter the SMTP server (e.g., smtp.example.com): " SMTP_HOST

    echo "Select a connection method:"
    echo "1. Unencrypted connection"
    echo "2. STARTTLS (TLS encryption on a separate port)"
    echo "3. SSL/TLS encryption"
    read -rp "Enter the number of the desired connection method (default is 2): " encryption_option
    # Setting default option if input is empty
    if [ -z "$encryption_option" ]; then
        encryption_option=2
    fi
    while [[ ! "$encryption_option" =~ ^[1-3]$ ]]; do
        echo "Invalid selection. Please try again."
        read -rp "Enter the number of the desired connection method (default is 2): " encryption_option
    done
    case "${encryption_option}" in
    1)
        default_port="25"
        ;;
    2)
        default_port="587"
        SMTP_SECURE=tls
        ;;
    3)
        default_port="465"
        SMTP_SECURE=ssl
        ;;
    esac
    read -rp "Enter the port number of the SMTP server (default is $default_port): " SMTP_PORT
    # Setting default port if input is empty
    if [ -z "$SMTP_PORT" ]; then
        SMTP_PORT=$default_port
    fi
    # Validating the port number
    while ! validate_port "$SMTP_PORT"; do
        echo "Invalid port number. Please try again."
        read -rp "Enter the port number of the SMTP server (default is $default_port): " SMTP_PORT
    done

    echo "Now for the sender of system mails and notifications."
    read -rp "Please enter the username of the sender address (default: nextcloud): " MAIL_FROM_ADDRESS
    if [ -z "$MAIL_FROM_ADDRESS" ]; then
        MAIL_FROM_ADDRESS="nextcloud"
    fi
    while true; do
        read -rp "Please enter the domain of the sender address (default: example.com): " MAIL_DOMAIN
        if is_valid_domain "$MAIL_DOMAIN"; then
            break
        fi
        echo "Invalid domain name. please try again."
    done

    cat - <<EOF >>.env

# SMTP
SMTP_HOST="$SMTP_HOST"
SMTP_SECURE="$SMTP_SECURE"
SMTP_PORT="$SMTP_PORT"
SMTP_NAME="$SMTP_NAME"
SMTP_PASSWORD="$SMTP_PASSWORD"
MAIL_DOMAIN="$MAIL_DOMAIN"
MAIL_FROM_ADDRESS="$MAIL_FROM_ADDRESS"
EOF

fi
