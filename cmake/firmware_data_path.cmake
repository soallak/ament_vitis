#    ____  ____
#   /   /\/   /
#  /___/  \  /   Copyright (c) 2021, Xilinx®.
#  \   \   \/    Author: Víctor Mayoral Vilches <victorma@xilinx.com>
#   \   \
#   /   /
#  /___/   /\
#  \   \  /  \
#   \___\/\___\
#
# defines the path to the platform "data" folder (product of packaging with v++)
# NOTE: "target" in the path below is expected to by a symlink to one of the available
#  firmware options
set(FIRMWARE ${CMAKE_INSTALL_PREFIX}/../acceleration/firmware/select/)
      # <ws>/acceleration/firmware/select/data
set(FIRMWARE_DATA ${FIRMWARE}/data)
set(FIRMWARE_DEVICE_TREE ${FIRMWARE}/device_tree)
