# How to get the AS2 config from BIG-IP
Following API endpoint to the BIG-IP AS2 API returns the complete AS2 configuration

```HTTP
GET https://{{bigip_mgmt}}/mgmt/tm/sys/application/service/
```

There are multiple options.

## Option1

There is a [Postman collection](../files/Postman/) in the "files/Postman/" folder of this repo. Use it to get all necesary API calls 

## Option 2

Do not use Postman, use curl.

This is a two step process:

1. Get the authentication token

    ```curl
    curl --location --request POST 'https://<mgmtIP or Hostname>/mgmt/shared/authn/login' --header 'Content-Type: application/json' --data-raw '{"username": admin,"password": adminpassword,"loginProvidername":"tmos"}
    ```

    The reponse is a JSON document. Parse the response for the value of 

    ```JSON
    {"token":{"token":"thisiswhatyouwant"}}
    ```

1. Get the AS2 config

    Here is an example CURL request to collect the AS2 config:

    ```curl
    curl --location --request GET 'https://{{bigip_mgmt}}/mgmt/tm/sys/application/service/' --header 'Content-Type: application/json' --header 'X-F5-Auth-Token: {{token}}' --data-raw ''
    ```

* replace {{bigip_mgmt}} with the BIG-IP management IP or hostname
* replace {{token}} with the token value you got in step 1

The response is a JSON document with the content of the entire AS2 configuration.

## Option 3

Yeah, you can come up with something. Two is enough from my side.

### Links

[back to readme](readme.md)
<br>[how to install jq](install_jq.md)
<br>[how to use the conversion tool](run_conversion_tool.md)
<br>[how to deploy the AS3 declaration](deploy_AS3_declaration.md)