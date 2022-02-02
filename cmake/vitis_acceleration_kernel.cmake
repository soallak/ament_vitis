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
# base macros and functions to create acceleration kernels

#
# Build acceleration kernels main macro
#
# .. note:: call sub-macros or sub-functions to build, link and/or
# package, as appropriate.
#
# .. note:: kernels will be generated with their corresponding ".xclbin"
# format. A signature of the build type will be appended at the end except
# for the "hardware" build type which includes no signature.
# E.g. "vadd.xclbin.hw_emu" or "vadd.xclbin".
#
# :param NAME: Name of the kernel to compile and link
# :type target: string
#
# :param FILE: CMAKE_SOURCE_DIR relative path to source code of the kernel
# :type target: string
#
# :param CONFIG: CMAKE_SOURCE_DIR relative path to configuration file
# for the kernel e.g. src/zcu102.cfg.
# :type target: string
#
# :param CLOCK: Frequency in Hz at which the kernel should be compiled by
# Vitis HLS.
# See https://www.xilinx.com/html_docs/xilinx2020_2/vitis_doc/vitiscommandcompiler.html#mcj1568640526180__section_bh5_dg4_bjb
# for more details.
# :type target: string
#
# :param TYPE: type of kernel to generate, could be "sw_emu",
# "hw_emu" or "hardware" (or several of them)
# :type target: string
#
# :param INCLUDE: one or muliple relative path directories whereto search for
# header files. This option is passed to the OpenCL preprocessor. Directories
# are relative to CMAKE_SOURCE_DIR.
# :type target: string
#
# :param LINK: Invoke the v++ linker to generate the corresponding artifacts.
# :type target: bool
#
# :param PACKAGE: Invoke the -p (package) flag of v++ to generate
# the corresponding artifacts for emulation.
# :type target: bool
#
macro(vitis_acceleration_kernel)
    set(options PACKAGE LINK)
    set(oneValueArgs NAME FILE CONFIG CLOCK)
    set(multiValueArgs TYPE INCLUDE)

    cmake_parse_arguments(VITIS_KERNEL "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )


    # if (CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64" AND DEFINED CMAKE_SYSROOT})
    if (DEFINED CMAKE_SYSROOT)
      # debug()
      foreach(type ${VITIS_KERNEL_TYPE})
        # Check that the build type is valid
        if (${type} STREQUAL "sw_emu")
          set(BUILT_TYPE "sw_emu")
        elseif (${type} STREQUAL "hw_emu")
          set(BUILT_TYPE "hw_emu")
        elseif (${type} STREQUAL "hw")
          set(BUILT_TYPE "hw")
        else()
          message(
            FATAL_ERROR "'" ${type} "' is not a recognized build target \
            for acceleration kernels. Consider 'sw_emu', 'hw_emu' or 'hardware'."
          )
        endif()

        # Consider the different link/package options
        if (${VITIS_KERNEL_LINK} AND ${VITIS_KERNEL_PACKAGE})
          vitis_acceleration_kernel_aux(
            NAME ${VITIS_KERNEL_NAME}
            FILE ${VITIS_KERNEL_FILE}
            TYPE ${BUILT_TYPE}
            CLOCK ${VITIS_KERNEL_CLOCK}
            CONFIG ${VITIS_KERNEL_CONFIG}
            INCLUDE ${VITIS_KERNEL_INCLUDE}
            LINK
            PACKAGE
          )
        elseif(${VITIS_KERNEL_LINK})
          vitis_acceleration_kernel_aux(
            NAME ${VITIS_KERNEL_NAME}
            FILE ${VITIS_KERNEL_FILE}
            TYPE ${BUILT_TYPE}
            CLOCK ${VITIS_KERNEL_CLOCK}
            CONFIG ${VITIS_KERNEL_CONFIG}
            INCLUDE ${VITIS_KERNEL_INCLUDE}
            LINK
          )
        elseif(${VITIS_KERNEL_PACKAGE})
          vitis_acceleration_kernel_aux(
            NAME ${VITIS_KERNEL_NAME}
            FILE ${VITIS_KERNEL_FILE}
            TYPE ${BUILT_TYPE}
            CLOCK ${VITIS_KERNEL_CLOCK}
            CONFIG ${VITIS_KERNEL_CONFIG}
            INCLUDE ${VITIS_KERNEL_INCLUDE}
            PACKAGE
          )
        else()
          vitis_acceleration_kernel_aux(
            NAME ${VITIS_KERNEL_NAME}
            FILE ${VITIS_KERNEL_FILE}
            TYPE ${BUILT_TYPE}
            CLOCK ${VITIS_KERNEL_CLOCK}
            CONFIG ${VITIS_KERNEL_CONFIG}
            INCLUDE ${VITIS_KERNEL_INCLUDE}
          )
        endif()
      endforeach()
    endif()  # cross compilation, DEFINED CMAKE_SYSROOT

endmacro()  # vitis_acceleration_kernel



#
# Build, link (and package) acceleration kernels for the different targets.
# Auxiliary macro.
#
# :param VITIS_KERNEL_AUX_FILE: CMAKE_SOURCE_DIR relative path to source code of
# the kernel
# :type target: string
#
# :param VITIS_KERNEL_AUX_CONFIG: CMAKE_SOURCE_DIR relative path to configuration
# file for the kernel e.g. src/zcu102.cfg.
# :type target: string
#
# :param VITIS_KERNEL_AUX_CLOCK: Frequency in Hz at which the kernel should be
# compiled by Vitis HLS.
# See https://www.xilinx.com/html_docs/xilinx2020_2/vitis_doc/vitiscommandcompiler.html#mcj1568640526180__section_bh5_dg4_bjb
# :type target: string
#
# :param VITIS_KERNEL_AUX_INCLUDE: one or muliple relative path directories whereto
# search for header files. This option is passed to the OpenCL preprocessor.
# Directories are relative to CMAKE_SOURCE_DIR.
# :type target: string
#
# :param VITIS_KERNEL_AUX_LINK: Invoke v++ linker in the
# the corresponding artifacts.
# :type target: bool
#
# :param VITIS_KERNEL_AUX_PACKAGE: Invoke the -p (package) flag of v++ to generate
# the corresponding artifacts.
# :type target: bool
#
#
macro(vitis_acceleration_kernel_aux)
  # arguments
  set(options PACKAGE LINK)
  set(oneValueArgs NAME FILE CONFIG TYPE CLOCK)
  set(multiValueArgs INCLUDE)
  cmake_parse_arguments(VITIS_KERNEL_AUX "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

  # variables for the compilation process
  set(ENV{PLATFORM_REPO_PATHS} ${PLATFORM_REPO_PATHS})
  set(ENV{XILINX_VIVADO} ${XILINX_VIVADO})
  set(ENV{XILINX_VITIS} ${XILINX_VITIS})
  set(ENV{XILINX_HLS} ${XILINX_HLS})
  # set(ENV{PATH} "$ENV{PATH}:${XILINX_HLS}/bin")

  set(CMD "PLATFORM_REPO_PATHS=${PLATFORM_REPO_PATHS} ${VPP_PATH} -c -t ${VITIS_KERNEL_AUX_TYPE} --config " ${CMAKE_SOURCE_DIR} "/"
    ${VITIS_KERNEL_AUX_CONFIG} " -k " ${VITIS_KERNEL_AUX_NAME} " "
  )
  set(INCLUDE_DIRS "")
  foreach(include_item ${VITIS_KERNEL_AUX_INCLUDE})
    if(IS_ABSOLUTE ${include_item})
      list(APPEND INCLUDE_DIRS "-I${include_item} ")
    else()
      list(APPEND INCLUDE_DIRS "-I${CMAKE_SOURCE_DIR}/${include_item} ")
    endif()
  endforeach()

  list(APPEND CMD ${INCLUDE_DIRS})
  list(APPEND CMD " " ${CMAKE_SOURCE_DIR} "/" ${VITIS_KERNEL_AUX_FILE})
  list(APPEND CMD " -o " ${CMAKE_BINARY_DIR} "/" ${VITIS_KERNEL_AUX_NAME} ".xo")

  # debug()

  if(${NOKERNELS})
    message(STATUS "No kernels built")
  else()
    # CMake configure time

    # Build
    ## pass clock flag if available
    if ("${VITIS_KERNEL_AUX_CLOCK}" STREQUAL "")
      execute_process(
        COMMAND
          ${VPP_PATH} -c -t ${VITIS_KERNEL_AUX_TYPE}
            --config "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_CONFIG}"
            -k ${VITIS_KERNEL_AUX_NAME}
            ${INCLUDE_DIRS}
            "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_FILE}"
            -o "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.xo"
        RESULT_VARIABLE
            CMD_ERROR
        OUTPUT_VARIABLE OUTPUT_VAR
        ERROR_VARIABLE ERROR_VAR
        COMMAND_ECHO STDOUT
      )
    else()
      execute_process(
        COMMAND
        ${VPP_PATH} -c --hls.clock ${VITIS_KERNEL_AUX_CLOCK}:${VITIS_KERNEL_AUX_NAME} -t ${VITIS_KERNEL_AUX_TYPE}
            --config "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_CONFIG}"
            -k ${VITIS_KERNEL_AUX_NAME}
            ${INCLUDE_DIRS}
            "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_FILE}"
            -o "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.xo"
        RESULT_VARIABLE
            CMD_ERROR
        OUTPUT_VARIABLE OUTPUT_VAR
        ERROR_VARIABLE ERROR_VAR
        COMMAND_ECHO STDOUT
      )
    endif()
    if(NOT (${CMD_ERROR} EQUAL 0))
      message(ERROR ${OUTPUT_VAR})
      message(FATAL_ERROR "Vitis compiliation failed")
    else()
      message(${OUTPUT_VAR})
    endif()

    # adjust final binary name if not "hw" (only "hw" build target is without suffix)
    set(BINARY_NAME "${VITIS_KERNEL_AUX_NAME}.xclbin")
    if (NOT ${VITIS_KERNEL_AUX_TYPE} STREQUAL "hw")
      set(BINARY_NAME "${VITIS_KERNEL_AUX_NAME}.xclbin.${VITIS_KERNEL_AUX_TYPE}")
    endif()

    # Link
    if (${VITIS_KERNEL_AUX_LINK})
      # message("linking")  # debug
      execute_process(
        COMMAND
          ${VPP_PATH} -l -t ${VITIS_KERNEL_AUX_TYPE}
            --config "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_CONFIG}"
            "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.xo"
            -o "${CMAKE_BINARY_DIR}/${BINARY_NAME}"
      )

      if (NOT ${VITIS_KERNEL_AUX_TYPE} STREQUAL "hw")
        # get a temporary symlink pointing the binary name to allow/permit the
        # v++ packaging process
        # NOTE: v++ is sensitive to the artifact names.
        # See ERROR: [v++ 60-2262] Unsupported input file type specified for
        # --package option.
        message("ln -s ${BINARY_NAME} ${VITIS_KERNEL_AUX_NAME}.xclbin")
        execute_process(
          COMMAND
            ln -s ${BINARY_NAME} ${VITIS_KERNEL_AUX_NAME}.xclbin
        )
      endif()

      # package
      #   only makes sense if linked already
      if (${VITIS_KERNEL_AUX_PACKAGE})
        # message("packaging")  # debug
        execute_process(
          COMMAND
            ${VPP_PATH} -p -t ${VITIS_KERNEL_AUX_TYPE}
              --config "${CMAKE_SOURCE_DIR}/${VITIS_KERNEL_AUX_CONFIG}"
              "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.xclbin"
              --package.out_dir package
              --package.no_image
        )
      endif()  # package

      #
      # dfx-mgr artifacts
      #
      # NOTE: dfx-mgr implementation in 2020.2.2 requires
      # besides the xilinx binary kernel (.xclbin), to
      # provide also two additional files:
      #   - .bit.bin raw bitstream
      #   - .dtbo device tree blob overlay
      #
      # extract the raw bitstream
      run("xclbinutil --dump-section BITSTREAM:RAW:${VITIS_KERNEL_AUX_NAME}.bit.bin \
          --input ${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.xclbin --force")

      # install
      if (EXISTS ${CMAKE_BINARY_DIR}/${BINARY_NAME})
        # install acceleration kernel, and ROS 2 related artifacts
        install(
          FILES
            "${CMAKE_BINARY_DIR}/${BINARY_NAME}"
            "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.bit.bin"
          DESTINATION
            lib/${PROJECT_NAME}
        )

        # install dtbo if it available
        set(DEFAULT_DTBO ${FIRMWARE_DEVICE_TREE}/kernel_default.dtbo)
        if ( EXISTS  ${DEFAULT_DTBO})
          # copy to build directory and then install
          # we could use install rename directly, alternatively 
          run("cp ${DEFAULT_DTBO} ${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.dtbo")
          install(
            FILES
              "${CMAKE_BINARY_DIR}/${VITIS_KERNEL_AUX_NAME}.dtbo"
            DESTINATION
              lib/${PROJECT_NAME}
          )
        else()
          message(WARNING "Default DTBO ${DEFAULT_DTBO} not found")
        endif()

        # package installation
        if (${VITIS_KERNEL_AUX_PACKAGE})
          install(
            DIRECTORY
              "${CMAKE_BINARY_DIR}/package"
            DESTINATION
              lib/${PROJECT_NAME}
          )

          # if hw_emu, symlink to "sim" folder
          if (${VITIS_KERNEL_AUX_TYPE} STREQUAL "hw_emu")
            # # create emulation dir if it doesn't exist, then symlink which
            # # this leads to various simlinks (as many as kernels) in a
            # # compounded way. Not ideal. See below for an alternative that checks
            #
            # execute_process(
            #   COMMAND
            #     mkdir ${FIRMWARE_DATA}/../emulation
            # )
            # execute_process(
            #   COMMAND
            #     ln -s ${CMAKE_BINARY_DIR}/package/sim ${FIRMWARE_DATA}/../emulation/sim
            # )

            set(EMULATIONSIMDIR "test -e ${FIRMWARE_DATA}/../emulation/sim || ")
            run("${EMULATIONSIMDIR} ln -s ${CMAKE_BINARY_DIR}/package/sim ${FIRMWARE_DATA}/../emulation/sim")
          endif()  # hw_emu

          # if hw, symlink to BOOT.BIN
          # NOTE: removes and creates a new symlink for each kernel, only the last
          #       symlinked kernel will remain in firmware/ dir.
          #
          if (${VITIS_KERNEL_AUX_TYPE} STREQUAL "hw")
            # if symlink exists, delete
            run("[ -L ${FIRMWARE_DATA}/../BOOT.BIN ] && unlink ${FIRMWARE_DATA}/../BOOT.BIN")
            # set(EMULATIONSIMDIR "test -e ${FIRMWARE_DATA}/../BOOT.BIN || ")
            # set(EMULATIONSIMDIR "[ -L ${FIRMWARE_DATA}/../BOOT.BIN ] && [ -e ${FIRMWARE_DATA}/../BOOT.BIN ]  && ")

            # create the new symlink
            run("ln -s ${CMAKE_BINARY_DIR}/package/BOOT.BIN ${FIRMWARE_DATA}/../BOOT.BIN")
          endif()  # hw_emu
        endif()  # package installation

        # if sw_emu, deploy "data" from firmware
        if (${VITIS_KERNEL_AUX_TYPE} STREQUAL "sw_emu")
          install(
            DIRECTORY
              "${FIRMWARE_DATA}"
            DESTINATION
              lib/${PROJECT_NAME}
          )
        endif()  # sw_emu
      endif()  # install

      # cleanup symlink for packaging
      if (NOT ${VITIS_KERNEL_AUX_TYPE} STREQUAL "hw")
        # # Check before unlinking, see below
        # execute_process(
        #   COMMAND
        #     unlink ${VITIS_KERNEL_AUX_NAME}.xclbin
        # )
        set(KERNELTOUNLINK "test -e ${VITIS_KERNEL_AUX_NAME}.xclbin && ")
        run("${KERNELTOUNLINK} unlink ${VITIS_KERNEL_AUX_NAME}.xclbin")
      endif()
    endif()  # link
  endif()  # NOKERNELS
endmacro()  # vitis_acceleration_kernel_swemu

#
# Print relevant variables for debugging purposes
#
macro(debug)
  message("CMAKE_SYSROOT: " ${CMAKE_SYSROOT})
  message("CMAKE_SYSTEM_PROCESSOR: " ${CMAKE_SYSTEM_PROCESSOR})

  message("CMAKE_SOURCE_DIR: " ${CMAKE_SOURCE_DIR})
  message("CMAKE_BINARY_DIR: " ${CMAKE_BINARY_DIR})
  message("CMAKE_INSTALL_PREFIX: " ${CMAKE_INSTALL_PREFIX})

  message("NAME: " ${VITIS_KERNEL_NAME})
  message("FILE: " ${VITIS_KERNEL_FILE})
  message("CONFIG: " ${VITIS_KERNEL_CONFIG})
  foreach(type ${VITIS_KERNEL_TYPE})
    message("TYPE: " ${type})
  endforeach()
  foreach(include_item ${VITIS_KERNEL_INCLUDE})
    message("INCLUDE: " ${include_item})
  endforeach()
  if (${VITIS_KERNEL_PACKAGE})
    message("PACKAGE: " ${VITIS_KERNEL_PACKAGE})
  endif()
  message("CMD: " ${CMD})
  message("INCLUDE_DIRS: " ${INCLUDE_DIRS})
endmacro()  # debug

#
#  A simple macro to facilitate runing processes with bash
#
macro(run CMD)
  execute_process(COMMAND bash -c ${CMD})
endmacro()
