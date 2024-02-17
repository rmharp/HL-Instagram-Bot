# Instagram Automation Project

## Overview
This project is designed to automate the process of following users on Instagram based on a list of Instagram page URLs obtained from the Heellife UNC website. It uses R and RSelenium to navigate web pages, extract Instagram handles, and automate the login and following process on Instagram.

## Installation
Before running the script, ensure that you have R installed on your system. Then, install the required R packages by running the script. The script checks for the existence of each package before attempting to install it, ensuring that all dependencies are satisfied.

## Setup
1. Clone or download this repository to your local machine.
2. Open the R script in an R environment (e.g., RStudio).

## .env File Configuration
Fill in a `.env` file in the root directory of the project and add your Heellife credentials, Instagram credentials, and any other environment variables you need. Example:
```
env_content <- "HL_USERNAME=yourHeellifeUsername\nHL_PASSWORD=yourHeellifePassword\nIG_USERNAME=yourInstagramUsername\nIG_PASSWORD=yourInstagramPassword"
```
**Note:** Do not share or commit this file as it contains sensitive information.

## Running the Script
To run the script, simply execute it in your R environment. The script will perform the following actions:
- Log in to Heellife UNC and Instagram.
- Scrape Instagram handles from Heellife UNC.
- Navigate to each Instagram page and follow users up to the specified follow limit.

## Limitations
- The script is designed to respect Instagram's rate limiting by incorporating delays between actions. Adjust the `followLimit` and sleep intervals as necessary to comply with Instagram's terms of service.

## Contributions
Contributions are welcome! Please feel free to submit a pull request or open an issue if you have suggestions for improvements.

## License
This project is open-sourced under the MIT License. See the LICENSE file for details.
