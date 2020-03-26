##!/bin/bash
# This script parses an AS2 config file that includes all AS2 configs and creates individual AS2 configs in a specified folder
# usage example: <scriptname> -o <AS2confiffile>.json -d <destinationfoldername>

# check if conf directory exist, if not create it
while getopts o:d: option
do
    case "${option}"
    in
    o) ORIGIN=${OPTARG};;
    d) location=${OPTARG};;
    esac
done
# The script will only run of both variables $location and $Origin have values
# if statement below checks if variables are present
if [[ -z $location ]] && [[ -z $Origin ]]; then 
    echo " insufficient input variables"
else
    # Here the logic applies
    # The first step is to check if the destination directory exists and if not, create it.
    if [ -d "./$location" ] ; then
        echo "Directory ./conf_$location exists." 
    else
        mkdir ./$location
    fi

    leng=$(jq '.items |length' $ORIGIN )
    echo "number of available applications is: $leng"
    echo "start extracting"
    i=0
    while [ $i -lt $leng ]
    do
        # parse the content of the AS2 element and store it to a filename of the application in each array element
        templateid=$(jq -r ".items[$i].template" $ORIGIN)
        echo "extracting App $i"
        # extract the file only for applications that were created with the app services iApp.
        if [[ $templateid == "/Common/appsvcs_integration_v2.0.003" ]]; then
            outputfilename=$(jq -r ".items[$i].name" $ORIGIN)
            outputfilename=${outputfilename//./_}
            jq -r ".items[$i]" $ORIGIN > ./$location/$outputfilename.json
            i=$(( $i + 1 ))
        else 
            filename=$(jq -r ".items[$i].name" $ORIGIN)
            echo "app $filename not extracted, because it was not created by AppServices template"
            i=$(( $i + 1 ))
        fi
    done
fi
