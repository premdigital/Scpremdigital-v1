with open('install.sh', 'r') as f:
    lines = f.readlines()

shebang = lines[0:2] # #!/bin/bash
ip_block = lines[2:23] # # ====== CEK LISENSI IP ... fi
update_block = lines[23:215] # if [[ "$1" == "--update-menu" ]]; then ... fi
rest_of_script = lines[215:]

new_lines = shebang + update_block + ip_block + rest_of_script

with open('install.sh', 'w') as f:
    f.writelines(new_lines)

print("Swapped blocks successfully")
