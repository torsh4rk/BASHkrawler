#!/bin/bash

# Global arguments
DOMAIN=$1
PATTERN=$2
USER_AGENT=$(shuf -n1 user_agents/user-agents.txt) # Choosing the random user-agent from a wordlist

# Regular used colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
NC='\033[0m'              # No Color


# display banner
displayBanner() {
    echo -e """${Yellow}
  ____    _    ____  _   _ _                       _           
 | __ )  / \  / ___|| | | | | ___ __ __ ___      _| | ___ _ __ 
 |  _ \ / _ \ \___ \| |_| | |/ / '__/ _  \ \ /\ / / |/ _ \ '__|
 | |_) / ___ \ ___) |  _  |   <| | | (_| |\ V  V /| |  __/ |   
 |____/_/   \_\____/|_| |_|_|\_\_|  \__,_| \_/\_/ |_|\___|_|   

Bash Web Crawler to find URLs by parsing the HTML source code and the found javascript links at homepage of a required specific website domain


Coded by: @torsh4rk

\n${Yellow}# Settings \n\n## Domain (target): $DOMAIN\n## Random User-Agent: $USER_AGENT\n
"""                                                               


}


# HTML parsing at target domain - Look the source code at target domain and extract all URLs by using (or without using) a pattern word as optional argument.
# Checking if argument PATTERN is empty or not empty.
findURLs(){

    for URLs in $(curl -k -s -L -H "User-Agent: $USER_AGENT" "https://$DOMAIN" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*"* | sort -u); 
    do
        if [[ -z "$PATTERN" ]]; then
            URL=$(echo "$URLs")
        elif [[ ! -z "$PATTERN" ]]; then
            URL=$(echo "$URLs" | grep "$PATTERN")
        fi
        STATUS_CODE=$(curl -k -s -L -H "$USER_AGENT" "$URL" --write-out %{http_code} --output /dev/null)
        if [[ -n "$URL" ]] && [[ "$STATUS_CODE" -ne 404 ]]; then
            FOUND_URLs="$URL"
            echo -e "${Green} $FOUND_URLs"
        fi
    done
}


# JS link finder - find js directories or js file links at target domain and make parsing the all them.
# Make parsing to find other URLs within js links and extract this URLs by using (or without using) a pattern word as optional argument
# Checking if argument PATTERN is empty or not empty.
jsLinkParser(){

    for URLs in $(curl -k -s -L -H "User-Agent: $USER_AGENT" "https://$DOMAIN" | grep -Eo "(http|https)://([a-zA-Z0-9./?=&,{};_-]+)*"* | sort -u); 
    do
        jsLink=$(echo "$URLs" | grep ".js")
        if [[ -n "$jsLink" ]]; then
            jsParser=$(curl -k -s -L -H "User-Agent: $USER_AGENT" "$jsLink" | grep -Eo "(http|https)://([a-zA-Z0-9./?=&,{};_-]+)*"* | sort -u);
            if [[ -n "$jsParser" ]] && [[ -z "$PATTERN" ]]; then
                echo -e "\n${Green}[*] Found JS Link: $jsLink\n\n${NC}JS Parsing:\n\n$jsParser" 
            elif [[ -n "$jsParser" ]] && [[ ! -z "$PATTERN" ]]; then
                echo -e "\n ${Green}[*] Found JS Link: $jsLink\n\n ${NC}JS Parsing:\n\n$jsParser" | grep "$PATTERN"
            fi
        fi
    done
}


# Menu 
# Display options
# Checking if argument PATTERN is empty or not empty and calling the functions findURLs or/and jsLinkParser
Menu(){

    echo -e "${Yellow}How do you wish to make the web crawling on target domain $DOMAIN ?\n"
    echo -e "[ 1 ] parsing the HTML source code of homepage"
    echo -e "[ 2 ] By parsing the found Javascript links at homepage"
    echo -e "[ 3 ] Make a full web crawling (Run the option 1 and 2)"
    echo -e "[ 4 ] Exit"
    echo -e "\n"
    while true; do read -p "Chosen option: " chosen_option && [[ -n $chosen_option ]] && [[ $chosen_option =~ ^[1-9]{1}$] && [$chosen_option -ge 1 || $chosen_option -le 4 ]] && break || echo -e "${Red}Invalid chosen option. Try again!" && continue; done
    echo -e "\n"
    case $chosen_option in
        "1")
            [[ -n "$PATTERN" ]] && echo -e "\n\n${Yellow}[*] Finding URLs by parsing the HTML source code of homepage from $DOMAIN and matching the word \"$PATTERN\" \n\n" && findURLs $PATTERN || echo -e "\n\n${Yellow}[*] Finding URLs by parsing the HTML source code of homepage from $DOMAIN \n\n" && findURLs
            ;;
        "2")
            [[ -n "$PATTERN" ]] && echo -e "\n\n${Yellow}[*] Finding URLs by parsing the found JS links at homepage from $DOMAIN matching the word \"$PATTERN\" \n\n" && jsLinkParser $PATTERN || echo -e "\n\n${Yellow}[*] Finding URLs by parsing the found JS links at homepage from $DOMAIN \n\n" && jsLinkParser
            ;;
        "3")
            [[ -n "$PATTERN" ]] && echo -e "\n\n${Yellow}[*] Finding URLs by parsing the HTML source code of homepage from $DOMAIN and matching the word \"$PATTERN\" \n\n" && findURLs $PATTERN || echo -e "\n\n${Yellow}[*] Finding URLs by parsing the HTML source code of homepage from $DOMAIN \n\n" && findURLs
            [[ -n "$PATTERN" ]] && echo -e "\n\n${Yellow}[*] Finding URLs by parsing the found JS links at homepage from $DOMAIN matching the word \"$PATTERN\" \n\n" && jsLinkParser $PATTERN || echo -e "\n\n${Yellow}[*] Finding URLs by parsing the found JS links at homepage from $DOMAIN \n\n" && jsLinkParser
            ;;
        "4")
            echo -e "${Red}\n\n Bye! \nExiting... \n\n"
            exit 0
            ;;
    esac

}


# Function to check KeyboardInterrupt - signal 2 (SIGINT)
# initialise trap to call trap_ctrlc function when signal 2 (SIGINT) is received
trap_ctrlc (){
	
	echo -e "\n${Red}Ctrl-C caught. \n\nExitng...\n"
	exit 2
}
trap "trap_ctrlc" 2 


# Main block
# Checking if DOMAIN argument is empty or not
# Calling the funtions displayBanner and Menu
if [[ ! -z "$DOMAIN" ]]; 
then
    displayBanner
    Menu
    echo -e "\n\n${Yellow}Finished! \n\n"
else
    displayBanner
    echo -e "\n${Red}Domain is required! \n"
    echo -e "\n${Yellow}Usage: ./bashkrawler.sh + domain + pattern (optional) \n"
    echo -e "\n${Yellow} Example 1: ./bashkrawler.sh www.example.com => Make web crawling and find all URLs at target domain (Without matching a pattern word)"
    echo -e "\n${Yellow} Example 2: ./bashkrawler.sh www.example.com \"example\" => Make web crawling at a target domain and find all URLs with the word \"example\" (Via matching a pattern word)"
fi