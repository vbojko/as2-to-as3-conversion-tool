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
        var_clientSSLProfile=$( jq ".vs__ProfileClientSSL" ./$filelocation/as3/variables/as3_variables_$appname.json)
        var_clientSSLcert=$( jq ".vs__ProfileClientSSLCert" ./$filelocation/as3/variables/as3_variables_$appname.json)
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
        # Begin Servicemain header Section
        if [[ "$var_httpProfile" == "null" ]]; then  # This is used for TCP virtual servers without an HTTP profile attached
            echo "tcp - no http profile"
            var_ServicemainTemplate="\"template\":\"tcp\""
            var_ServicemainClass="\"class\":\"Service_TCP\""
        elif [[ ! "$var_serverSSL" == "null" ]]; then # Sets https template and Service_HTTP class
            echo "backend serverssl" 
            var_ServicemainTemplate="\"template\":\"https\""
            var_ServicemainClass="\"class\":\"Service_HTTPS\""
        elif [[ ! "$var_clientSSLcert" == "null" ]]; then # Sets https template and Service_HTTP class
            echo "frontend clientssl" 
            var_ServicemainTemplate="\"template\":\"https\""
            var_ServicemainClass="\"class\":\"Service_HTTPS\"" 
        elif [[ ! "$var_clientSSLProfile" == "null" ]]; then # Sets https template and Service_HTTP class
            echo "frontend clientssl profile reference" 
            var_ServicemainTemplate="\"template\":\"https\""
            var_ServicemainClass="\"class\":\"Service_HTTPS\""
        elif [[ ! "$var_httpProfile" == "null"  ]]; then  # sets http template and Service_HTTP class
            echo "http profile detected"
            var_ServicemainTemplate="\"template\":\"http\""
            var_ServicemainClass="\"class\":\"Service_HTTP\""
        fi 
        var_ServicemainVIP="\"virtualAddresses\": [ $var_VIPIP ]"
        var_ServicemainVirtualPort="\"virtualPort\":$var_VIPPort"
        var_ServicemainPool="\"pool\":\"serverpool\""
        # First servicemain definition
        var_Servicemain="\"serviceMain\": { $var_ServicemainClass, $var_ServicemainVIP, $var_ServicemainVirtualPort, $var_ServicemainPool" 
        # Append Backend encryption profile if server SSL profile is defined
        if [[ ! "$var_serverSSL" == "null" ]]; then
            # We expect to have frontend SSL configured if backend SSL is defined.
            # per default we define a new frontend SSL profile with key and cert. Definition of key and cert is in the servicemain body. 
            var_ServicemainClientSSL="\"serverTLS\":\"AS3clientSslprofile\""
            # In case the AS2 definition has no key and cert but references to an existing SSL profile on BIG-IP 
            # we do not need the SSL profile definition in the Servicemain body. Instead we point to the existing profile
            if [[ ! $var_clientSSLProfile == "null" ]]; then
                var_ServicemainClientSSL="\"serverTLS\":{\"bigip\":$var_clientSSLProfile}"
            fi
            var_ServicemainServerSSL="\"clientTLS\": {\"bigip\": $var_serverSSL }"
            var_Servicemain="$var_Servicemain, $var_ServicemainClientSSL, $var_ServicemainServerSSL"
        elif [[ ! "$var_clientSSLcert" == "null" ]]; then
            echo "client ssl profile reference"
            # If ServerSSL profile is not defined we check if clientSSL profile is defined.
            # If so, then per defualt we create a new client SSL rpofile if cert and key is defined. 
            var_ServicemainClientSSL="\"serverTLS\":\"AS3clientSslprofile\""
            # In case the AS2 definition has no key and cert but references to an existing SSL profile on BIG-IP 
            # we do not need the SSL profile definition in the Servicemain body. Instead we point to the existing profile
            var_ServicemainClientSSL="\"serverTLS\":{\"bigip\":$var_clientSSLProfile}"
        elif [[ ! $var_clientSSLProfile == "null" ]]; then
            var_ServicemainClientSSL="\"serverTLS\":{\"bigip\":$var_clientSSLProfile}"
            var_Servicemain="$var_Servicemain, $var_ServicemainClientSSL"
        fi
        # Append SNAT Automap
        if [[ "$var_snat" == "automap" ]]; then
                var_ServicemainSnat="\"snat\":\"auto\""
                var_Servicemain="$var_Servicemain, $var_ServicemainSnat  }  "
        fi
        # Append default persistency profile
        if [[ "$var_defaultPersistency" == *"cookie"* ]]; then
            var_ServicemainPersistence="\"persistenceMethods\": [\"cookie\"]  "
            var_Servicemain="$var_Servicemain, $var_ServicemainPersistence"
        fi
        # Append fallback persistency profile
        if [[ "$var_fallbackPersistency" == *"source_addr"* ]]; then
            var_ServicemainFallbackPersistence="\"fallbackPersistenceMethod\":\"source-address\""
            var_Servicemain="$var_Servicemain, $var_ServicemainFallbackPersistence"
        fi
        # Append OneConnect profile
        if [[ ! "$var_Oneconnect" == "null" ]]; then
            echo "oneconnect"
            var_Servicemain="$var_Servicemain, \"profileMultiplex\": { \"bigip\": $var_Oneconnect} "
        fi
        # Append iRules
        if [[ ! "$var_iRules" == "null" ]]; then
            echo "iRule detected"
            var_Servicemain="$var_Servicemain, \"iRules\": [{ \"bigip\": $var_iRules} ]"
        fi
        # Closing Servicemain header
        var_Servicemain="$var_Servicemain}"
        # End Servicemain header
        
        # begin Servicemain body
        # per default var_Servicemainbody has the pool definition
        var_Servicemainbody="$var_pool"
        # Append Client SSL profile in case ServerSSL profile is configured. We assume we use client and serverSSL together
        if [[ ! "$var_serverSSL" == "null" ]]; then
            # Do this only, if a ssl key and cert is provided. 
            # Do not define clientssl profile if in AS2 declaration a reference to an existing client SSL profile exists
            if [[ "$var_clientSSLProfile" == "null" ]]; then
            var_AS3clientsslprof="\"AS3ClientSslProfile\": {\
            \"class\":\"TLS_Server\", \
            \"ciphers\":$var_clientSSLCipher, \
            \"certificates\":[\
                {\"certificate\":\"serversslcert\"}]}, \
                \"serversslcert\":{\"class\":\"Certificate\", \
                    \"certificate\":{\"bigip\":$var_clientSSLcert}, \
                    \"chainCA\":{\"bigip\":$var_clientSSLChain}, \
                    \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
            var_Servicemainbody="$var_Servicemainbody, $var_AS3clientsslprof "
            fi
        elif [[ ! "$var_clientSSLcert" == "null" ]]; then
            var_AS3clientsslprof="\"AS3ClientSslProfile\": {\
            \"class\":\"TLS_Server\", \
            \"ciphers\":$var_clientSSLCipher, \
            \"certificates\":[\
                {\"certificate\":\"serversslcert\"}]}, \
                \"serversslcert\":{\"class\":\"Certificate\", \
                    \"certificate\":{\"bigip\":$var_clientSSLcert}, \
                    \"chainCA\":{\"bigip\":$var_clientSSLChain}, \
                    \"privateKey\":{\"bigip\":$var_clientSSLkey}}  "
            var_Servicemainbody="$var_Servicemainbody, $var_AS3clientsslprof "
        fi
        # End Servicemain body
        # End Template logic
        #echo " { $var_as3Header $var_as3Declaration, $var_AppDeclaration, $var_ServicemainTemplate, $var_Servicemain, $var_Servicemainbody  }}} " > $filelocation/as3/declaration/as3final_test_$appname.json
        echo " { $var_as3Header $var_as3Declaration, $var_AppDeclaration, $var_ServicemainTemplate, $var_Servicemain, $var_Servicemainbody }}} " | jq . > $filelocation/as3/declaration/as3final_$appname.json
    
      
    
    done
fi


