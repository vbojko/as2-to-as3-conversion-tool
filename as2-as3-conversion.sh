##!/bin/bash
# This script takes an AS2 declaration with multiple services and transforms them into AS3 declarations

# check if conf directory exist, if not create it
while getopts o:d: option
do
    case "${option}"
    in
    o) ORIGIN=${OPTARG};;
    d) location=${OPTARG};;
    esac
done
# The script will only run of both variables $location and $ORIGIN have values
# if statement below checks if variables are present
if [[ -z $location ]] && [[ -z $ORIGIN ]]; then 
    echo " insufficient input variables"
else
    # Here the logic applies
    # The first step is to check if the destination directory exists and if not, create it.
    echo "start extracting applications from input file "
    ./1-extract_as2_config_with_parameters.sh -o $ORIGIN -d $location &&
    echo "done extracting, start creating pool definitions"
    ./2-AS3_declaration_Pool.sh  -d $location &
    echo "start reformating variables from AS2 declaration"
    ./3-reformat_variables_to_json_array.sh -d $location &&
    echo "done vars, ready for declaration"
    ./4-AS3_declaration.sh -d $location
    echo "done, have fun"
    
fi
