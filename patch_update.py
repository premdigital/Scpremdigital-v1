import re

with open('install.sh', 'r') as f:
    content = f.read()

# find the update block
update_block_match = re.search(r'(if \[\[ "\$1" == "--update-menu" \]\]; then.*?fi\n)', content, re.DOTALL)
if update_block_match:
    update_block = update_block_match.group(1)
    # remove the block from its current location
    content = content.replace(update_block, '')
    
    # find where to insert it (after #!/bin/bash)
    insert_pos = content.find('# ==========================================\n# CEK LISENSI IP (GITHUB)')
    
    if insert_pos != -1:
        content = content[:insert_pos] + update_block + '\n' + content[insert_pos:]
        
        with open('install.sh', 'w') as f:
            f.write(content)
        print("Successfully moved update-menu block.")
    else:
        print("Could not find insertion point.")
else:
    print("Could not find update-menu block.")
