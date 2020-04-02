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
    if [ -d "$location/as3/AS2_new" ] 
    then
        echo "Directory $location/as3/AS2_new exists." 
    else
        mkdir ./$location/as3/AS2_new
    fi
    
    # Now I tell the script in which folder my input files are
    filelocation="$location"
    # Adding the for loop for every file on the filelocation folder
    # echo "filelocation: $filelocation"
    
    for file in $filelocation/*.json
    do
        echo ""
        echo "variable reformating: File currently worked on: $file"
        appname=$( jq -r  ".name" $file )
        #replacing dots and dashes with underscores for appname
        appname=${appname//./_}
        appname=${appname//-/_}
        kind=$( jq ".kind" $file )
        partition=$( jq ".partition" $file )    
        subpath=$( jq ".subPath" $file )
        description=$( jq ".description" $file )
        deviceGroup=$( jq ".deviceGroup" $file )
        strictUpdates=$( jq ".strictUpdates" $file )
        trafficGroup=$( jq ".trafficGroup" $file )
        templateVersion="\"template\": \"/Common/appsvcs_integration_v2.0.004\""
        
        jsonSchema="{ \"kind\": $kind, \
         \"name\": \"$appname\", \
         \"partition\": $partition, \
         \"generation\": 1, \
         \"description\": $description, \
         \"strictUpdates\": $strictUpdates, \
         $templateVersion, \
         \"trafficGroup\": $trafficGroup "

        #echo "$jsonSchema } " 

        # Table array
        tablejson="\"tables\": ["
        tablecount=$( jq ".tables" $file | jq length)
        tablesnumber=0
        while [ $tablesnumber -lt $tablecount ]
        do
            tablesname=$( jq -r ".tables[$tablesnumber].name" $file )
            if [[ $tablesname == "monitor__Monitors" ]]; then
                #echo "mon"
                newrow=$( jq ".tables[$tablesnumber].rows[0].row" $file | jq '. + [ "" ]' )
                #oldrow=$( jq ".tables[$tablesnumber].rows[0].row" $file )
                tablescolumnnames=$( jq ".tables[$tablesnumber].columnNames" $file )
                #echo $oldrow
                echo $tablescolumnnames
                tablejson=" $tablejson { \"name\": \"$tablesname\", \
                \"columnNames\":$tablescolumnnames, \"rows\": [ { \"row\": $newrow } ]  } "
            else
                #echo "else"
                tablesvar=$( jq ".tables[$tablesnumber]" $file )
                tablejson=" $tablejson, $tablesvar  "
            fi

            tablesnumber=$(( $tablesnumber + 1 ))
        done

        tablejson="$tablejson ]"
        echo $tablejson
        jsonSchema="$jsonSchema, $tablejson "
        # Variable array
        variablecount=$( jq ".variables" $file | jq length)
        variablenumber=0
        varjson="\"variables\": [ "
        varjsonstart=0
        while [ $variablenumber -lt $variablecount ]
        do
            variablevalue=$( jq ".variables[$variablenumber].value" $file )
            if [[ ! $variablevalue == "null" ]]; then
                variable_extend=$(jq ."variables[$variablenumber]" $file)
                if [[ "$varjsonstart" == "0" ]]; then
                    varjson="$varjson $variable_extend"
                    varjsonstart=$(( $varjsonstart + 1 ))
                else
                    varjson="$varjson, $variable_extend"
                fi
            fi
            variablenumber=$(( $variablenumber + 1 ))
        done
        varjson="$varjson ]"
        jsonSchema="$jsonSchema, $varjson }"
        echo $jsonSchema | jq . > $location/as3/AS2_new/as2_new_$appname.json
        varjsonstart="0"
    
    done
fi