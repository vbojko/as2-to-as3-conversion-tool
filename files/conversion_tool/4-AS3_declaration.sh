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

    if [ -d "$location/as3/declaration" ] 
    then
        echo "Directory $location/as3/declaration exists." 
    else
        mkdir ./$location/as3/declaration
    fi


    # AS3 header variables
    var_headerClass="\"class\":\"AS3\""
    var_action="\"action\": \"deploy\""
    var_persist="\"persist\": true"
    var_declaration="\"declaration\": { "
    # Declaration header variables
    var_declarationClass="\"class\": \"ADC\""
    var_schemaVersion="\"schemaVersion\": \"3.18.0\""
    var_declarationLabel="\"label\": \"example\""
    var_TenantClass="\"class\": \"Tenant\" "
    # Service header variables
    var_serviceClass="\"class\": \"Application\""

    filelocation="$location"
    #Adding the for loop for every file on the filelocation folder
     for file in $filelocation/*.json
    do
        unset var_Servicemain
        echo "Declaration creation: working on file: $file"
        appname=$( jq -r  ".name" $file )
        # replace dots in appname with underscores, becasue there are some issues with dots in names
        appname=${appname//./_}
        appname=${appname//-/_}
        var_declarationId="\"id\":\"declaration_for_$appname\""
        var_declarationRemark="\"remark\":\"remark for_$appname\""
        # read all relevat AS2 variables in BASH variables for reuse
        var_clientSSLcert=$( jq ".vs__ProfileClientSSL" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_clientSSLkey=$( jq ".vs__ProfileClientSSLKey" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_clientSSLChain=$( jq ".vs__ProfileClientSSLChain" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_clientSSLCipher=$( jq ".vs__ProfileClientSSLCipherString" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_serverSSL=$( jq ".vs__ProfileServerSSL" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_httpProfile=$( jq ".vs__ProfileHTTP" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_VIPIP=$( jq  ".pool__addr" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_VIPPort=$( jq -r ".pool__port" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_IpProtocol=$( jq ".vs__IpProtocol" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_TcpProfile=$( jq ".vs__ProfileClientProtocol" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_Oneconnect=$( jq ".vs__ProfileOneConnect" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_defaultPersistency=$( jq ".vs__ProfileDefaultPersist" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_fallbackPersistency=$( jq ".vs__ProfileFallbackPersist" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_snat=$( jq -r ".vs__SNATConfig" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_iRules=$( jq ".vs__Irules" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_pool="\"serverpool\": $( jq ".serverpool" ./$filelocation/as3/pools/as3_pools_$appname.json)"

        # Creating the AS3 header:
        var_as3Header=" $var_headerClass, $var_action, $var_persist, $var_declaration  "
        # Creating the AS3 declaration header
        var_as3Declaration=" $var_declarationClass, $var_schemaVersion, $var_declarationId, $var_declarationLabel, $var_declarationRemark, \"$appname\": { \"class\": \"Tenant\" "
        
        var_AppDeclaration="\"$appname\": { \"class\":\"Application\"  "
        # Creating the AS3 Service header
        # the service template decides if AS3 will use a HTTP, HTTP or generic template.
        # To find out we have to check if an http profile is set in the AS2 declaration
        # In this use case SNAT automap was always used.
        if [[ "$var_snat" == "automap" ]]; then
                var_ServicemainSnat="\"snat\":\"auto\""
        fi
        # Template logic - put here
        echo $var_clientSSLcert
        if [[ "$var_httpProfile" == "null" ]]; then  # This is used for non HTTP but TCP traffic
            echo "tcp"
            var_ServicemainTemplate="\"template\":\"tcp\""
            var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
            var_ServicemainClass="\"class\":\"Service_TCP\""
            var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
            var_ServicemainPool="\"pool\":\"serverpool\""
            var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat  }  "
                if [[ ! "$var_serverSSL" == "null" ]]; then  # This section is used when the BIG-IP reencrypts the TLS session to the backend server
                        echo "serverssl without HTTP profile"
                        var_ServicemainTemplate="\"template\":\"https\""
                        var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
                        var_ServicemainClass="\"class\":\"Service_HTTPS\""
                        var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
                        var_ServicemainPool="\"pool\":\"serverpool\""
                        var_ServicemainServerSSL="\"serverTLS\":\"ServerSslprofile\""
                        var_ServicemainClientSSL="\"clientTLS\":\"ClientSslProfile\""
                        # Create preliminary Servicemain declaration. have to add SSL specific information
                        var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat, $var_ServicemainServerSSL, $var_ServicemainClientSSL"
                        if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                            var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                            var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
                        fi
                        if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                        var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                        var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
                        fi
                        #closing ServiceMain variable
                        var_Servicemain="$var_Servicemain}"
                        # creating clientSSL profile
                        var_serverSSLProfile="\"ServerSslprofile\": {\"class\":\"TLS_Server\", \"ciphers\":$var_clientSSLCipher, \"certificates\":[{\"certificate\":\"serversslcert\"}]}, \"serversslcert\":{\"class\":\"Certificate\", \"certificate\":{\"bigip\":$var_clientSSLcert}, \"chainCA\":{\"bigip\":$var_clientSSLChain}, \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
                        # Modify to incorporate certificate CS's $var_clientSSLChain
                        var_clientSSLProfile="\"ClientSslProfile\": {\"class\":\"TLS_Client\", \"validateCertificate\": false }"
                        #closing declaration
                        var_Servicemain="$var_Servicemain, $var_serverSSLProfile, $var_clientSSLProfile"
                elif [[ ! "$var_clientSSLcert" == "null" ]]; then  # this is used if no server ssl profile is configured, but only client ssl
                        echo "clientssl without HTTP profile"
                        var_ServicemainTemplate="\"template\":\"https\""
                        var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
                        var_ServicemainClass="\"class\":\"Service_HTTPS\""
                        var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
                        var_ServicemainPool="\"pool\":\"serverpool\""
                        var_ServicemainServerSSL="\"serverTLS\":\"ServerSslprofile\""
                        # Create preliminary Servicemain declaration. have to add SSL specific information
                        var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat, $var_ServicemainServerSSL"
                        if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                            var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                            var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
                        fi
                        if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                            var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                            var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
                        fi
                        #closing ServiceMain variable
                        var_Servicemain="$var_Servicemain}"
                        # creating clientSSL profile
                        var_serverSSLProfile="\"ServerSslprofile\": {\"class\":\"TLS_Server\", \"ciphers\":$var_clientSSLCipher, \"certificates\":[{\"certificate\":\"serversslcert\"}]}, \"serversslcert\":{\"class\":\"Certificate\", \"certificate\":{\"bigip\":$var_clientSSLcert}, \"chainCA\":{\"bigip\":$var_clientSSLChain}, \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
                        # Modify to incorporate certificate CS's $var_clientSSLChain
                        #closing declaration
                        var_Servicemain="$var_Servicemain, $var_serverSSLProfile"
                fi
        elif [[ ! "$var_serverSSL" == "null" ]]; then  # This section is used when the BIG-IP reencrypts the TLS session to the backend server
            echo "serverssl"
            var_ServicemainTemplate="\"template\":\"https\""
            var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
            var_ServicemainClass="\"class\":\"Service_HTTPS\""
            var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
            var_ServicemainPool="\"pool\":\"serverpool\""
            var_ServicemainServerSSL="\"serverTLS\":\"ServerSslprofile\""
            var_ServicemainClientSSL="\"clientTLS\":\"ClientSslProfile\""
            # Create preliminary Servicemain declaration. have to add SSL specific information
            var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat, $var_ServicemainServerSSL, $var_ServicemainClientSSL"
            if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
            fi
            if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
            fi
            #closing ServiceMain variable
            var_Servicemain="$var_Servicemain}"
            # creating clientSSL profile
            var_serverSSLProfile="\"ServerSslprofile\": {\"class\":\"TLS_Server\", \"ciphers\":$var_clientSSLCipher, \"certificates\":[{\"certificate\":\"serversslcert\"}]}, \"serversslcert\":{\"class\":\"Certificate\", \"certificate\":{\"bigip\":$var_clientSSLcert}, \"chainCA\":{\"bigip\":$var_clientSSLChain}, \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
            # Modify to incorporate certificate CS's $var_clientSSLChain
            var_clientSSLProfile="\"ClientSslProfile\": {\"class\":\"TLS_Client\", \"validateCertificate\": false }"
            #closing declaration
            var_Servicemain="$var_Servicemain, $var_serverSSLProfile, $var_clientSSLProfile"
        elif [[ ! "$var_clientSSLcert" == "null" ]]; then  # this is used if no server ssl profile is configured, but only client ssl
            echo "clientssl"
            var_ServicemainTemplate="\"template\":\"https\""
            var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
            var_ServicemainClass="\"class\":\"Service_HTTPS\""
            var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
            var_ServicemainPool="\"pool\":\"serverpool\""
            var_ServicemainServerSSL="\"serverTLS\":\"ServerSslprofile\""
            # Create preliminary Servicemain declaration. have to add SSL specific information
            var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat, $var_ServicemainServerSSL"
            if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
            fi
            if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
            fi
            #closing ServiceMain variable
            var_Servicemain="$var_Servicemain}"
            # creating clientSSL profile
            var_serverSSLProfile="\"ServerSslprofile\": {\"class\":\"TLS_Server\", \"ciphers\":$var_clientSSLCipher, \"certificates\":[{\"certificate\":\"serversslcert\"}]}, \"serversslcert\":{\"class\":\"Certificate\", \"certificate\":{\"bigip\":$var_clientSSLcert}, \"chainCA\":{\"bigip\":$var_clientSSLChain}, \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
            # Modify to incorporate certificate CS's $var_clientSSLChain
            #closing declaration
            var_Servicemain="$var_Servicemain, $var_serverSSLProfile"

         elif [[ ! "$var_httpProfile" == "null"  ]]; then  # this is used if only HTTP Services are configured
            echo "http only"
            var_ServicemainTemplate="\"template\":\"http\""
            var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
            var_ServicemainClass="\"class\":\"Service_HTTP\""
            var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
            var_ServicemainPool="\"pool\":\"serverpool\""
            # Create preliminary Servicemain declaration. have to add SSL specific information
            var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat"
            if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
            fi
            if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
            fi
            #closing ServiceMain variable
            var_Servicemain="$var_Servicemain}"        
            
        
        elif [[ ! "$var_httpProfile" == "null"  ]]; then  # this is used if only HTTP Services are configured
            echo "http only"
            var_ServicemainTemplate="\"template\":\"http\""
            var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
            var_ServicemainClass="\"class\":\"Service_HTTP\""
            var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
            var_ServicemainPool="\"pool\":\"serverpool\""
            # Create preliminary Servicemain declaration. have to add SSL specific information
            var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool, $var_ServicemainSnat"
            if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
                var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
                var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
            fi
            if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
                var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
                var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
            fi
            #closing ServiceMain variable
            var_Servicemain="$var_Servicemain}"        
            # In some usecases admin added an http profile manually. 
        fi
        # End Template logic

        #echo " { $var_as3Header $var_as3Declaration, $var_AppDeclaration, $var_ServicemainTemplate, $var_Servicemain,  $var_pool }}}} " > $filelocation/as3/declaration/as3final_test_$appname.json
        echo " { $var_as3Header $var_as3Declaration, $var_AppDeclaration, $var_ServicemainTemplate, $var_Servicemain,  $var_pool }}}} " | jq . > $filelocation/as3/declaration/as3final_$appname.json
    
      
    
    done
fi


