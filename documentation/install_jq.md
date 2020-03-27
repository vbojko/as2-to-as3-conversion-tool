# How to install "jq" 
## Instruction to install "jq" on MACOS
Here is the external link I used to install "jq" on MACOS: http://macappstore.org/jq/

To make it easier fopr the reader, I copied the instruction below:

1. Press <Command+Space> and type **Terminal** and press _enter/return_ key.

1. Run in Terminal app:

    ```
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
    ```

    and press _enter/return_ key.If the screen prompts you to enter a password, please enter your Mac's user password to continue. When you type the password, it won't be displayed on screen, but the system would accept it. So just type your password and press ENTER/RETURN key. Then wait for the command to finish.

1. Run:

    ```
    brew install jq
    ```

    Done! You can now use jq.

## Now, what happens if your MAC does not know what brew is

Well, in this case you have to install "homebrew". Here is the best external Link for Homebrew: <https://brew.sh/>

For your convenience, here are the steps to install homebrew:

1. Press <Command+Space> and type **Terminal** and press _enter/return_ key.

2. Paste in Terminal app:

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    ```

    and press _enter/return_ key.

    The script explains what it will do and then pauses before it does it. Read about other [installation options](https://docs.brew.sh/Installation).

## Instruction to install "jq" on Ubuntu 18.0.4

Here the external link for the installation: <https://zoomadmin.com/HowToInstall/UbuntuPackage/jq>

For your convenience, find the instructions below:

Step 1 - Run update command to update package repositories and get latest package information.

```bash
sudo apt-get update -y
```

Step 2: - Run the install command with -y flag to quickly install the packages and dependencies.

```bash
sudo apt-get install -y jq
```
### Links

[back to readme](readme.md)
<br>[how to get the AS2 config](get_AS2_config.md)
<br>[how to use the conversion tool](run_conversion_tool.md)
<br>[how to deploy the AS3 declaration](deploy_AS3_declaration.md)