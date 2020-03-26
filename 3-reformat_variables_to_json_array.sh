#!/bin/bash
# This script parses all objects in the as2 variables array finds similarities between configs.
# AS2 declarations with similar configs are moved in the same folder.
# The folders are created in the $location folder
# The goal is to use the csv to supprot easier pattern finding for as3 templates

while getopts d: option
do
    case "${option}"
    in
        d) location=${OPTARG};;
    esac
done
# The script will only run of both variables $location and $Origin have values
# if statement below checks if variables are present
if [[ -z $location ]]; then 
    echo " insufficient input variables"
else
    # check if conf directory exist, if not create it
    if [ -d "$location" ] 
    then
        echo "Directory $location exists." 
    else
        mkdir ./$location
    fi
    if [ -d "$location/as3" ] 
    then
        echo "Directory $location/as3 exists." 
    else
        mkdir ./$location/as3
    fi
    if [ -d "$location/as3/variables" ] 
    then
        echo "Directory $location/as3/variables exists." 
    else
        mkdir ./$location/as3/variables
    fi
    
    # Now I tell the script in which folder my input files are
    filelocation="$location"
    #Adding the for loop for every file on the filelocation folder
    #echo "filelocation: $filelocation"
    
    for file in $filelocation/*.json
    do
        appname=$( jq -r  ".name" $file )
        #replacong dots with underscores for appname
        appname=${appname//./_}
        echo ""
        echo "variable reformating: File currently worked on: $file"
        variablecount=$( jq ".variables" $file | jq length)
        variablenumber=0
        varjson="{"
        while [ $variablenumber -lt $variablecount ]
        do
            variablename=$( jq ".variables[$variablenumber].name" $file)
            variablevalue=$( jq ".variables[$variablenumber].value" $file)
            if [[ "$varjson" == "{" ]]; then
                varjson="$varjson $variablename:$variablevalue "
            else    
                varjson="$varjson, $variablename:$variablevalue"
            fi    
            variablenumber=$(( $variablenumber + 1 ))
        done
        varjson="$varjson }"
        echo $varjson | jq . > $location/as3/variables/as3_variables_$appname.json
    
    done
fi