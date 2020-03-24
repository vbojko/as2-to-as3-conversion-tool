# This script parses all ob jects in the as2 variables array and stores them in a csv.
# The goal is to use the csv to supprot easier pattern finding for as3 templates
usecase="report_3"
while getopts d:u: option
do
    case "${option}"
    in
        d) location=${OPTARG};;
        u) usecase=${OTPARG};;
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

    # Now I tell the script in which folder my input files are
    filelocation="$location/"
    #Adding the for loop for every file on the filelocation folder
    # This section writes a controll file which proves that all variable field names are in the same order
    echo "" > $filelocation/variables_$usecase.csv
    echo "" > $filelocation/variablesheaders_$usecase.csv
    #start creation of variableheaders.csv file
    firstrun="new"
    for filecontent in $filelocation*.json
    do
        file=$(<$filecontent)
        varlength=$( echo $file | jq '.variables' | jq length )
        i=0
        headerlist=$( echo $file | jq -r '.name')
        valuelist=$( echo $file | jq -r '.name')
        while [ $i -lt $varlength ]
        do 
            headerlist="$headerlist,$( echo $file | jq -r ".variables[$i].name" ) "
            valuelist="$valuelist,$( echo $file | jq -r ".variables[$i].value") "
           
        i=$(( $i + 1 ))
        done
        echo $headerlist >> $filelocation\variablesheaders_$usecase.csv
        if [[ $firstrun == "new" ]]; then
            echo $headerlist >> $filelocation\variables_$usecase.csv
            echo $valuelist >> $filelocation\variables_$usecase.csv
            firstrun="old"
        else 
            echo $valuelist >> $filelocation\variables_$usecase.csv
        fi
    done
fi