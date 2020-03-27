# AS2 to AS3 offline conversion tool

## Introduction

this tool helps to convert BIG-IP AS2 confgs into AS3 declarations.
It is an offline tool, so you do not need a BIG-IP for the conversion itself. BUT, before deploying the AS3 declaration in production it is highly recommended to perform following tests:

- Take the output AS3 declarations and load it in a lab environment to test successfull deployment. A lab can be a BIG-IP Virtual Edition (VE) or physical device, including Viprion and vCMP instances. It is mandatory that the Lab infrastructure has the same sw version and module provisioning as the originating isntance.
- Test in a lab environment if the application works as expected after the declaration. Run traffic through it.

### Performance of AS3 config

This conversion tool does not give performance guarantees. It just converts the AS2 config declaration to AS3 config declaration. You can perform performance tests, but this is out of scope of this tool.

## Documentation

Documentation is in the "documentation" folder of this repository. Click [here](./documentation/readme.md)

## Where to find the tool

The tool is located in the "files/conversion_tool" folder of this repo

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).  

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects. Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.  

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein. You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.
