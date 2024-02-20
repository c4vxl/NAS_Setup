# NAS Setup Script
This script enables users to set up a Network Attached Storage (NAS) system on their Linux machine effortlessly. The script utilizes the Samba library for sharing the files and folders.

## Features

- Creates a NAS group for shared access
- Adds user accounts with Samba password configuration
- Configures shared folders with customizable options
- Generates Samba configuration files for easy NAS setup

## Prerequisites

- This script is designed for Linux machines.
- Ensure you have administrative privileges to execute the script.

## Usage
##### Options
- __`--group=GROUP`__: Set the NAS group name (default: NAS_user)
- __`--acc=USER:PASSWORD`__: Add a user account with the specified username and password
- __`--path=PATH`:__ Set the path to the shared folder (required)
- __`--name=NAS_NAME`:__ Set the name of the NAS (required)
- __`--public=PUBLIC`:__ Set whether the folder should be public (yes/no) (required)
- __`--writable=WRITABLE`:__ Set whether the folder should be writable (yes/no) (required)
- __`--readable=READABLE`:__ Set whether the folder should be readable (yes/no) (required)
- __`--help`__: Display help message

<br>

##### Example

```bash
./nas_setup.sh --path=/your/shared/folder --name=YourNAS --public=no --writable=yes --readable=yes
```

<br>
<br>
<br>

## License

This project is licensed under the [MIT License](LICENSE).

---

## Developer
This Project was Developed by [c4vxl](https://c4vxl.de)