# AS2 related tools

This folder contains the last version of the app services iApp. <br>
There is a tool that allows users to take and AS2 declaration from an existing big=ip and clean out unused parameters. <br>
For example, it will create a neW AS2 declaration without variables that have no value. <br>
another thing is, that it cleans key-value pairs that may cause problems when they are deployed and it fixes a strange behaviour around the monitor definition rows <br>

This tool can be used together with the AS2-to-AS3 conversion tool.
Run

```bash
./as2-as3-conversion.sh -o <as2declaration.json> -d <destinationfolder> 
```

first. After the script you will find all individual AS2 declaration files in the destination folder. These AS2 declarations are the original declarations from BIG-IP. <br>
Now, use these declarations as input for this tool.


Usage:

```bash
./as2-to-as2-converter.sh -d <destinationfolder>
```

The tool will create a subfolder under

```bash
<destinationfolder>/as3/AS2_new
```

With all sanitized AS2 declarations have a prefix of <code>as2_new_appname.json