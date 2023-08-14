# Docker Compose (Nextcloud)

The repository includes a Docker Compose setup for Nextcloud with Redis, Nginx, PHP and MariaDB.

## Prerequisites
Before you begin, ensure you have the following prerequisites:

- Install Git: `sudo apt update && sudo apt install git`
- Install Docker Compose: https://docs.docker.com/engine/install/

## Installation
1. Clone this repository using the following command: `git clone https://github.com/JDLLeu/docker-compose-nextcloud`
2. Change into the project directory: `cd docker-compose-nextcloud`

## Usage
1. Perform a Git pull to ensure you have the latest updates: `git pull`
2. Run the generation script and follow the prompts: `./generate-env.sh`
3. Customize settings if needed by editing the `.env` file.
4. Run Docker Compose to build and start the application containers in the background: `docker compose up -d --build`
5. Access the application in your web browser.

## Configuration
You can customize the project configuration by modifying the `.env` file. This file contains various environment variables that control the behavior of the application.


## Contributing

We welcome contributions from the community. To contribute, follow these steps:

1. Fork the repository.
2. Create a new branch.
3. Make your enhancements or fixes.
4. Submit a pull request.

If you find it helpful, don't forget to star the repository. Thank you for using our project and happy coding!
