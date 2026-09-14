with open('install.sh', 'r') as f:
    lines = f.readlines()

head_block = lines[0:44]
tail_block = lines[66:76]
close_block = ["    exit 0\n", "fi\n\n"]
ip_check_block = lines[44:66]
rest_of_script = lines[76:]

new_lines = head_block + tail_block + close_block + ip_check_block + rest_of_script

with open('install.sh', 'w') as f:
    f.writelines(new_lines)

print("Fixed install.sh")
