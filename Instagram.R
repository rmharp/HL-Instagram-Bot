#' ---
#' title: "Instagram"
#' output: html_document
#' date: "`r Sys.Date()`"
#' ---
#' 
## --------------------------------------------------------------------------------------------------------------------
if(!require(dplyr)) {install.packages("dplyr"); library(dplyr)}
if(!require(tidyverse)) {install.packages("tidyverse"); library(tidyverse)}
if(!require(rvest)) {install.packages("rvest"); library(rvest)}
if(!require(RSelenium)) {install.packages("RSelenium"); library(RSelenium)}
if(!require(wdman)) {install.packages("wdman"); library(wdman)}
if(!require(netstat)) {install.packages("netstat"); library(netstat)}
if(!require(xml2)) {install.packages("xml2"); library(xml2)}
if(!require(webdriver)) {install.packages("webdriver"); library(webdriver)}
if(!require(purrr)) {install.packages("purrr"); library(purrr)}
if (!require(here)) {install.packages("here"); library(here)}
if (!require(dotenv)) {install.packages("dotenv"); library(dotenv)}

setwd(here())
# Define .env content
env_content <- ""
# Write to .env file in the current working directory
if (nchar(env_content) > 0) {
  cat(env_content, file = ".env", append = TRUE, sep = "\n")
}
dotenv::load_dot_env(".env")
# Read the contents of the .env file
print(readLines(".env"))

#' 
## --------------------------------------------------------------------------------------------------------------------
# Enter your ONYEN and password
HLusername <- Sys.getenv("HL_USERNAME")
HLpassword <- Sys.getenv("HL_PASSWORD")

# Change to TRUE if instagram URLs haven't yet been webscraped
heellife = FALSE

# Enter your Instagram username and password
IGusername <- Sys.getenv("IG_USERNAME")
IGpassword <- Sys.getenv("IG_PASSWORD")
followLimit <- 100


# Start the Selenium server with a specified port (e.g., 4567)
rD <- rsDriver(browser = "firefox", chromever = NULL, port = netstat::free_port())
remDr <- rD$client

if (heellife == TRUE) {
  # Obtain org instagrams from Heellife
  remDr$navigate("https://heellife.unc.edu/account/login?returnUrl=/organizations")
  login <- remDr$findElement(using = 'id', value = 'username')
  login$sendKeysToElement(list(HLusername))
  next_button <- remDr$findElement(using = "css", "button")
  next_button$highlightElement()
  next_button$clickElement()
  Sys.sleep(1.5)
  pass <- remDr$findElement(using = 'id', value = 'password')
  pass$sendKeysToElement(list(HLpassword))
  signin_button <- remDr$findElement(using = "id", value = "submitBtn")
  signin_button$highlightElement()
  signin_button$clickElement()
  Sys.sleep(5)
  div_element <- remDr$findElement(using = 'css selector', value = 'div[style="color: rgb(73, 73, 73); margin: 15px 0px 0px; font-style: italic; text-align: left;"]')
  div_text <- div_element$getElementText()
  extracted_numbers <- regmatches(div_text, gregexpr("\\d+", div_text))
  num_results <- as.numeric(extracted_numbers[[1]][length(extracted_numbers[[1]])])
  instagrams <- vector("list", length(num_results))
  num_presses <- ceiling((num_results-10)/10)
  for (k in 1:num_presses) {
    remDr$executeScript("window.scrollTo(0, document.body.scrollHeight);")
    load_more <- remDr$findElement(using = "css", "button")
    load_more$highlightElement()
    load_more$clickElement()
    Sys.sleep(0.1)
  }
  raw <- remDr$getPageSource()
  html <- xml2::read_html(raw[[1]])
  links <- html %>% html_nodes("a") %>% html_attr("href")
  links <- links[-1]
  pages <- vector("list", length(links))
  for (i in seq_along(links)) {
    remDr$navigate(paste0("https://heellife.unc.edu", links[i]))
    Sys.sleep(1)
    page_raw <- remDr$getPageSource()
    html_raw <- xml2::read_html(page_raw[[1]])
    pages[[i]] <- html_raw
  }
  org_info <- data_frame()
  instagram <- vector("list", length(pages))
  for (i in seq_along(pages)) {
    organization <- html_text(html_nodes(pages[[i]], xpath = "//h1[contains(@style, 'padding: 13px 0px 0px 85px;')]"), trim = TRUE)
    instagram_node <- html_nodes(pages[[i]], xpath = '//a[@aria-label="Visit our instagram"]')
    if (!is_empty(instagram_node)) {
      instagram <- html_attr(instagram_node, 'href')
    } else {
      instagram <- NA
    }
    new_org <- data_frame(
      Organization = organization,
      Instagram = instagram
    )
    org_info <- rbind(org_info, new_org)
  }
  #Save to csv
  write.csv(org_info, "org_info.csv", row.names = FALSE)
}

org_info <- read.csv("org_info.csv")
instagrams <- org_info$Instagram
# Navigate to a website and login
remDr$navigate("https://www.instagram.com/")
Sys.sleep(1)
login <- remDr$findElement(using = 'name', value = 'username')
login$sendKeysToElement(list(IGusername))
Sys.sleep(1)
pass <- remDr$findElement(using = 'name', value = 'password')
pass$sendKeysToElement(list(IGpassword))
signin_button <- remDr$findElement(using = "css", value = "button[type='submit']")
signin_button$highlightElement()
signin_button$clickElement()
Sys.sleep(5)

# #Navigate to search
# search_button <- remDr$findElement(using = "css", value = "[aria-label='Search']")
# search_button$highlightElement()
# search_button$clickElement()
# search_input <- remDr$findElement(using = "css", value = "input[aria-label='Search input']")
# search_input$highlightElement()
# search_input$clickElement()
# search_input$sendKeysToElement(list(instagrams))

followedCount <- 0
for (i in seq_along(instagrams)) {
   if (!is.na(instagrams[i]) && followedCount < followLimit) {
    remDr$navigate(instagrams[i])
    match <- regexpr("(?<=https://www\\.instagram\\.com/)[^/]+", instagrams[i], perl = TRUE)
    extracted_string <- regmatches(instagrams[i], match)[[1]]
    xpath_expression <- paste0("//a[contains(@href, '/", extracted_string, "/')]")
    Sys.sleep(5)
    number_element <- remDr$findElement(using = "xpath", value = xpath_expression)
    followersText <- number_element$getElementText()[[1]]
    followersNumber <- as.numeric(gsub("[^0-9]", "", followersText))
    remDr$navigate(paste0(instagrams[i], "followers/"))
    Sys.sleep(5)
    for (j in 1:followersNumber) {
      if (followedCount >= followLimit) {
        break # Stop if follow limit is reached
      }
      if (j %% 8 == 0) {
        remDr$executeScript("window.scrollTo(0, document.body.scrollHeight);")
      }
      tryCatch({
        follow_button <- remDr$findElement(using = "xpath", value = "//div[contains(@class, '_aano')]//button[.//div[. = 'Follow']]")
        follow_button$highlightElement()
        follow_button$clickElement()
        # Wait for 1 second after clicking
        followedCount <- followedCount + 1
        Sys.sleep(5)
      }, error = function(e){
        message("Error clicking follow button: ", e$message)
        remDr$executeScript("window.scrollTo(0, document.body.scrollHeight);")
        Sys.sleep(0.1)
      })
    }
   }
  if (followedCount >= followLimit) {
    break
  }
}

# Close the browser when done
remDr$close()
rD$server$stop()

