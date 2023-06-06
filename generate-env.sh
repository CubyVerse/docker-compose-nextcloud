# Was created with the assistance of ChatGPT.
#!/usr/bin/env bash

# only run on linux
if [ "$(uname)" != "Linux" ]; then
  echo "The script only runs on Linux."
  exit 1
fi

# ask the user if .env already exists
if [ -f .env ]; then
  read -p "Environment already defined. Do you want to overwrite it? (y/[n]) " CHOICE
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
    read -p "input choice [1]: " CHOICE
    case "${CHOICE}" in
        1)
            USERNAME="administrator"
            break
            ;;
        2)
            read -p "Please provide a valid username (special-characters: -_): " USERNAME
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
    read -p "input choice [1]: " CHOICE
    case "${CHOICE}" in
        1)
            PASSWORD=$(tr -dc '[:alnum:]' < /dev/urandom | fold -w ${1:-64} | head -n 1)
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
    read -p "Enter the amount of RAM you want to allocate to PHP (e.g. 512M or 1G): " RAM

    # Extract the numeric value and unit from the input
    NUM=$(echo $RAM | grep -oE '[0-9]+')
    UNIT=$(echo $RAM | grep -oE '[[:alpha:]]{2}$')

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
    read -p "Enter the amount of RAM you want to allocate to PHP (e.g. 512M or 1G): " UPLOAD

    # Extract the numeric value and unit from the input
    NUM=$(echo $UPLOAD | grep -oE '[0-9]+')
    UNIT=$(echo $UPLOAD | grep -oE '[[:alpha:]]{2}$')

    # Check if unit is valid
    if [[ $UNIT == "M" || $UNIT == "G" ]]; then
        echo "PHP upload limit set to ${UPLOAD}."
        break
    else
        echo "Invalid unit. Please enter a valid UPLOAD limit in G or M."
    fi
done

sed -i -e "s:^PHP_MEMORY_LIMIT=:PHP_MEMORY_LIMIT=${RAM}:g" .env
sed -i -e "s:^PHP_UPLOAD_LIMIT=:PHP_UPLOAD_LIMIT=${UPLOAD}:g" .env

## Docker-Container (MariaDB)
PASSWORD=""
PASSWORD=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-64} | head -n 1)
sed -i -e "s:^MARIADB_PASSWORD_ROOT=:MARIADB_PASSWORD_ROOT=${PASSWORD}:g" .env

PASSWORD=""
PASSWORD=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-64} | head -n 1)
sed -i -e "s:^MARIADB_PASSWORD_USER=:MARIADB_PASSWORD_USER=${PASSWORD}:g" .env
