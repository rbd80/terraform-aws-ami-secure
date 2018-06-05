#!/bin/bash -eux

# Zero out the rest of the free space using dd, then delete the written file.
#sudo dd if=/dev/zero of=/EMPTY bs=1M
#sudo rm -f /EMPTY
#sudo rm -rf staging_directory/

# Clean up directories
#sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sudo sync