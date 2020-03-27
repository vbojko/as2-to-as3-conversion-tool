# How to use the AS2 to AS3 conversion tool


1. Collect the AS2 configuration from the BIG-IP you want to migrate to AS3
    - Here is a [step by step](./get_AS2_config.md) description how to do this
1. Run the conversion tool to generate the AS3 declaration
    - Here is a [step by step](./run_conversion_tool.md) description how to do this
1. Deploy the AS3 declaration to the Lab BIG-IP
    - Testing is critical. Always deploy the declaration in a lab and make sure the declaration provides the desired output. Do not forget to run a test with Lab traffic first, before you deploy in production. Btw, here is a [step by step](./deploy_AS3_declaration.md) description how to deploly the AS3 declaration to a BIG-IP.

There is a Postman collection under [files/Postman](./files/Postman) that includes all required API calls for Step 1 and 3. Step 2 runs

## What tools are required

The conversion tool is a collection of bash scripts that use the command line JSON processor "jq". 

The required tools are:

- bash
- jq

Here is a [step by step](./install_jq.md) description how to install JQ on MACOS and Ubuntu.

