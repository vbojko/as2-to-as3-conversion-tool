#!/bin/bash
# This script parses a AS2 declaration and outputs pool, pool member and monitor as AS3 declaration
# for the output it creates a subfolder AS3 in the folder where the AS2 declarations are.
# every AS3 declaration is named: as3_<appname>.json
# usage: scriptname.sh -d <folder where as2 declarations are stored>

while getopts d: option
do
    case "${option}"
    in
        d) location=${OPTARG};;
    esac
done

# check if conf directory exist, if not create it

if [ -d "$location" ] ; then
    echo "Directory $location exists." 
else
    mkdir ./$location
fi
if [ -d "$location/as3" ] ; then
    echo "Directory $location/as3 exists." 
else
    mkdir ./$location/as3
fi
if [ -d "$location/as3/pools" ] ; then
    echo "Directory $location/as3/pools exists." 
else
    mkdir ./$location/as3/pools
fi

# Now I need to decide which is my input file
filelocation="./$location/"

# Run the following logic for every file on the filelocation directory

    for file in $filelocation*.json
    do
        echo "poolcreation: File currently worked on is:  $file"
        # find out if this is a monitor or pool member config object
        unset var_monitorNameOrder var_monitorOptionsOrder var_monitorTypeOrder
        unset var_monitorName var_monitorOptions var_monitorType
        unset  monitorpointer var_monitorBlob
        unset var_PriorityGroupOrder var_IPAddressOrder var_PortOrder var_ConnectionLimitOrder var_RatioOrder var_StateOrder
        unset var_IPAddress var_Port var_ConnectionLimit var_PriorityGroup var_Ratio var_State
        unset poolmembercount poolmemberpointer elementOrder columnNameLength var_PoolMemberBlob
        unset poolBlob
        unset tableslength tablescounter appname var_tablesname poolcount poolelementOrder columnNameLength elementName 
        unset var_AdvOptionsOrder var_LbMethodOrder var_LbMethod poolnumber var_AdvOptions

        tableslength=$( jq '.tables' $file | jq length )
        tablescounter=0
        appname=$( jq -r  ".name" $file )
        # replace dots in appname with underscore
        appname=${appname//./_}
        poolBlob="{ \"serverpool\": { \"class\": \"Pool\" "
        var_LbMethod=" \"loadBalancingMode\": \"round-robin\" "
        while [ $tablescounter -lt $tableslength ]
        do           
            var_tablesname=$( jq -r  ".tables[$tablescounter].name" $file )
            if [[ "$var_tablesname" == "pool__Pools" ]]; then
                poolelementOrder=0
                columnNameLength=$(jq -r ".tables[$tablescounter].columnNames" $file | jq length ) 
                while [ $poolelementOrder -lt $columnNameLength ]
                do 
                    elementName=$(jq -r ".tables[$tablescounter].columnNames[$poolelementOrder]" $file)
                    if [[ "$elementName" == "AdvOptions" ]]; then
                        var_AdvOptionsOrder=$poolelementOrder
                    elif [[ "$elementName" == "LbMethod" ]]; then
                        var_LbMethodOrder=$poolelementOrder
                    fi
                    poolelementOrder=$(( $poolelementOrder + 1 )) 
                done
                # Check if LB Method is set. If so, create AS3 declaration
                poolnumber=0
                poolcount=$( jq -r ".tables[$tablescounter].rows" $file | jq length )
                while [ $poolnumber -lt $poolcount ]
                do
                    if [[ ! -z "$var_LbMethodOrder" ]]; then
                        var_LbMethod=" \"loadBalancingMode\": \"$(jq -r ".tables[$tablescounter].rows[$poolnumber].row[$var_LbMethodOrder]" $file)\" "
                        #echo "LBmethod overwrite for $appname = $var_LbMethod"
                    fi
                    # Check if advanced Options are set. IF found, then create corresponding AS3 parameters,
                    if [[ ! -z "$var_AdvOptionsOrder" ]]; then
                        #cho "AdvOpOrder = $var_AdvOptionsOrder on $appname "
                        var_AdvOptions=$(jq -r ".tables[$tablescounter].rows[$poolnumber].row[$var_AdvOptionsOrder]" $file)                        
                        if  [[ "$var_AdvOptions" == "" ]]; then                      
                            unset var_AdvOptions
                        elif  [[ "$var_AdvOptions" == "none" ]]; then
                            unset var_AdvOptions
                        elif  [[ ! "$var_AdvOptions" == "none" ]]; then
                            if [[ "$var_AdvOptions" == *"slow-ramp-time"* ]]; then
                                var_AdvOptions=${var_AdvOptions#*=}
                                var_AdvOptions="\"slowRampTime\": $var_AdvOptions  "
                            fi
                        
                        fi
                    fi
                    poolnumber=$(( $poolnumber + 1 ))   
                done
            fi  
                
                
                
                # Here we write tshe prefix format for the pool declaration
                # Here we examine the pool parameter
            if [[ "$var_tablesname" == "pool__Members" ]]; then
                # echo "Pool members found: $var_tablesname"
                #Instructions:
                # Write a script that will add the value of AS2 keys to following vars:
                    # var_AdvOptions="" <-- skip this, AS2 specific, there is no AS3 equivalent
                # var_Index="" <-- skip this, AS2 specific, there is no AS3 equivalent
                # The variable headers are set in the columnNames Element. The order of the Elements is important, becasue they refer to the order of the values in the following rows.
                # It turns out that the order might differ between declarations to the order of the columnNames keys is not always the same. 
                # In order to address this we will run through the columnNames Element and tell the script what the order of each Key is.
                # Then we will run though the rows[].row[] elements and get teh calue for each Element.
                # Step 1: read the order of the variables in the declaration in the columnNames element. We use elementOrder variable for the ordering
                # After the sorting we will sort the variables in following order"
                # 1. IP Address
                # 2. Port
                # 3. Connection Limit
                # 4. Priority Group
                # 5. Ratio
                # 6. State
                elementOrder=0
                columnNameLength=$(jq -r ".tables[$tablescounter].columnNames" $file | jq length ) 
                while [ $elementOrder -lt $columnNameLength ]
                do 
                    elementName=$(jq -r ".tables[$tablescounter].columnNames[$elementOrder]" $file)
                    if [[ "$elementName" == "IPAddress" ]]; then
                        var_IPAddressOrder=$elementOrder
                    elif [[ "$elementName" == "Port" ]]; then
                        var_PortOrder=$elementOrder
                    elif [[ "$elementName" == "ConnectionLimit" ]]; then
                        var_ConnectionLimitOrder=$elementOrder
                    elif [[ "$elementName" == "PriorityGroup" ]]; then
                        var_PriorityGroupOrder=$elementOrder
                    elif [[ "$elementName" == "Ratio" ]]; then
                        var_RatioOrder=$elementOrder
                    elif [[ "$elementName" == "State" ]]; then
                        var_StateOrder=$elementOrder
                    fi
                    elementOrder=$(( $elementOrder + 1 ))
                done
                # Now since we have the order, we can create the new data structure for AS3 pool members.
                #  The pool members  information is stored in tables[$tablescounter].rows[] array. The order of the elements is corresponding to the order in the collumnName element
                # We have to create a pool member blob for every entry in the tables[$tablescounter].rows[] array.
                poolmembercount=$(jq -r ".tables[$tablescounter].rows" $file | jq length ) 
                poolmemberpointer=0
               while [ $poolmemberpointer -lt $poolmembercount ]
               do 
                  # Somtimes AS2 does not declare all fields for the pool member config. We check if every field is declared and if not we declare default values.
                    if [[ ! -z "$var_IPAddressOrder" ]]; then
                        var_IPAddress=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_IPAddressOrder]" $file)
                    else
                        var_IPAddress=255.255.255.254
                    fi
                    if [[ ! -z "$var_PortOrder" ]]; then
                        var_Port=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_PortOrder]" $file)
                    else 
                        var_Port=0
                    fi
                    if [[ ! -z "$var_ConnectionLimitOrder" ]]; then
                        var_ConnectionLimit=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_ConnectionLimitOrder]" $file)
                    else
                        var_ConnectionLimit=0
                    fi
                    if [[ ! -z "$var_PriorityGroupOrder" ]]; then
                        var_PriorityGroup=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_PriorityGroupOrder]" $file)
                    else
                        var_PriorityGroup=0
                    fi
                    if [[ ! -z "$var_RatioOrder" ]]; then
                        var_Ratio=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_RatioOrder]" $file)
                    else 
                        var_Ratio=1
                    fi
                    if [[ ! -z "$var_StateOrder" ]]; then
                        var_State=$(jq -r ".tables[$tablescounter].rows[$poolmemberpointer].row[$var_StateOrder]" $file)
                    else 
                        vat_State="enable"
                    fi
                    if [[ $var_State == "enabled" ]]; then
                        var_State="enable"
                    elif [[ $var_State == "disabled" ]]; then
                        var_State="disable"
                    else
                        var_State="enable"
                    fi 

                    # Now we write the poolmember blob. We have to check it it was written before and then append it to the prior one with a leading comma.
                    if [[ -z "$var_PoolMemberBlob" ]]; then
                        var_PoolMemberBlob=" { \"serverAddresses\":[ \"$var_IPAddress\" ], \"servicePort\":$var_Port, \"connectionLimit\":$var_ConnectionLimit, \"priorityGroup\":$var_PriorityGroup, \"ratio\":$var_Ratio, \"adminState\":\"$var_State\", \"shareNodes\": true  } "
                    else
                        var_PoolMemberBlob="$var_PoolMemberBlob, { \"serverAddresses\":[ \"$var_IPAddress\" ], \"servicePort\":$var_Port, \"connectionLimit\":$var_ConnectionLimit, \"priorityGroup\":$var_PriorityGroup, \"ratio\":$var_Ratio, \"adminState\":\"$var_State\", \"shareNodes\": true  } "
                    fi
                    poolmemberpointer=$(( $poolmemberpointer + 1 ))
                done
                var_PoolMemberBlob=" \"members\": [ $var_PoolMemberBlob ] "
                #echo "\"members\": [ $var_PoolMemberBlob ] "
                # echo $var_PoolMemberBlob
                # IT is mandaroty to unset the variables. Otherwise the script will use values from previous declarations on next config declarations
            fi
            if [[ "$var_tablesname" == "monitor__Monitors" ]]; then
                # echo "Column Headers for monitor__Monitors for $appname  "
                # jq -r ".tables[$tablescounter].columnNames" $file
                # jq -r ".tables[$tablescounter].rows[].row" $file
                    if [[ "$var_tablesname" == "monitor__Monitors" ]]; then
                        # echo "Pool members found: $var_tablesname"
                        #Instructions:
                        # Write a script that will add the value of AS2 keys to following vars:
                        # var_AdvOptions="" <-- skip this, AS2 specific, there is no AS3 equivalent
                        # var_Index="" <-- skip this, AS2 specific, there is no AS3 equivalent
                        # The variable headers are set in the columnNames Element. The order of the Elements is important, becasue they refer to the order of the values in the following rows.
                        # It turns out that the order might differ between declarations to the order of the columnNames keys is not always the same. 
                        elementOrder=0
                        columnNameLength=$(jq -r ".tables[$tablescounter].columnNames" $file | jq length ) 
                        while [ $elementOrder -lt $columnNameLength ]
                        do 
                            elementName=$(jq -r ".tables[$tablescounter].columnNames[$elementOrder]" $file)
                            if [[ "$elementName" == "Name" ]]; then
                                var_monitorNameOrder=$elementOrder
                            elif [[ "$elementName" == "Options" ]]; then
                                var_monitorOptionsOrder=$elementOrder
                            elif [[ "$elementName" == "Type" ]]; then
                                var_monitorTypeOrder=$elementOrder
                            fi
                        elementOrder=$(( $elementOrder + 1 ))
                        done
                        # Now since we have the order, we can create the new data structure for AS3 pool members.
                        # The pool members  information is stored in tables[$tablescounter].rows[] array. The order of the elements is corresponding to the order in the collumnName element
                        # We have to create a pool member blob for every entry in the tables[$tablescounter].rows[] array.
                        monitorcount=$(jq -r ".tables[$tablescounter].rows" $file | jq length ) 
                        monitorpointer=0
                        while [ $monitorpointer -lt $monitorcount ]
                        do 
                            # Somtimes AS2 does not declare all fields for the pool member config. We check if every field is declared and if not we declare default values.
                            if [[ ! -z "$var_monitorNameOrder" ]]; then
                                var_monitorName=$(jq -r ".tables[$tablescounter].rows[$monitorpointer].row[$var_monitorNameOrder]" $file)
                            else
                                var_monitorName=""
                            fi
                            if [[ ! -z "$var_monitorOptionsOrder" ]]; then
                                var_monitorOptions=$(jq -r ".tables[$tablescounter].rows[$monitorpointer].row[$var_monitorOptionsOrder]" $file)
                            else 
                                var_monitorOptions=""
                            fi
                            if [[ ! -z "$var_monitorTypeOrder" ]]; then
                                var_monitorType=$(jq -r ".tables[$tablescounter].rows[$monitorpointer].row[$var_monitorTypeOrder]" $file)
                            else
                                var_monitorType=""
                            fi

                            # Now we write the var_monitorBlob blob. We have to check it it was written before and then append it to the prior one with a leading comma.
                            if [[ -z "$var_monitorBlob" ]]; then
                                if [[ $var_monitorName == "/Common/http" ]]; then
                                    var_monitorBlob="\"http\""
                                elif [[ $var_monitorName == "/Common/https" ]]; then
                                    var_monitorBlob="\"https\""
                                elif [[ $var_monitorName == "/Common/tcp" ]]; then
                                    var_monitorBlob="\"tcp\""
                                else
                                    var_monitorBlob=" { \"bigip\": \"$var_monitorName\" }"
                                fi
                            else
                              echo " multiple monitors detected. not supportet by script"
                            fi
                            monitorpointer=$(( $monitorpointer + 1 ))
                        done
                        var_monitorBlob=" \"monitors\": [ $var_monitorBlob ] "

                    fi
            fi

            tablescounter=$(( $tablescounter + 1 ))            
        done
        # now write output file
        if [[ -z "$var_AdvOptions"  ]]; then
    
             echo "$poolBlob , $var_LbMethod , $var_PoolMemberBlob , $var_monitorBlob} } " | jq . > $location/as3/pools/as3_pools_$appname.json
        else
            echo "$poolBlob , $var_LbMethod , $var_AdvOptions , $var_PoolMemberBlob , $var_monitorBlob} } " | jq . > $location/as3/pools/as3_pools_$appname.json
        fi
    done