#
# Copyright (C) 2024 Nikolas Koesling <nikolas@koesling.info>.
# This program is free software. You can redistribute it and/or modify it under the terms of the MIT License.
#

# Determine whether this is a standalone project or included by other projects
set(STANDALONE_PROJECT OFF)
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(STANDALONE_PROJECT ON)
endif ()

# warnings as errors
if (WERROR AND COMPILER_WARNINGS AND STANDALONE_PROJECT)
    set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
endif ()

# clang tidy
if (CLANG_TIDY AND COMPILER_WARNINGS)
    if (${CLANG_TIDY_NO_ERRORS}) 
        set (CLANG_TIDY_CONFIG_FILE ${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy-noerrors)
    else ()
        set (CLANG_TIDY_CONFIG_FILE ${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy)
    endif ()

    set(CMAKE_CXX_CLANG_TIDY
            clang-tidy
            -config-file=${CLANG_TIDY_CONFIG_FILE})
    message(STATUS "clang-tidy enabled: ${CLANG_TIDY_CONFIG_FILE}")
endif ()

# add executable
add_executable(${Target})
if (INSTALL_TARGET)
    install(TARGETS ${Target})
endif ()


# set source and libraries directory
add_subdirectory("src")
add_subdirectory("libs")

include(cmake_files/warnings.cmake)
include(cmake_files/define.cmake)
include(cmake_files/compileropts.cmake)

# force C++ Standard and disable/enable compiler specific extensions
set_target_properties(${Target} PROPERTIES
        CXX_STANDARD ${STANDARD}
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS ${COMPILER_EXTENSIONS}
)

# compiler definitions and options
set_definitions(${Target})
if (ENABLE_MULTITHREADING AND OPENMP)
    set_options(${Target} ON)
else ()
    set_options(${Target} OFF)
endif ()

if (COMPILER_WARNINGS)
    enable_warnings(${Target})
    message(STATUS "Compiler warnings enabled.")
else ()
    disable_warnings(${Target})
    message(STATUS "Compiler warnings disabled.")
endif ()

if (ENABLE_MULTITHREADING)
    # required by threading lib (std::thread)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
    target_link_libraries(${Target} PRIVATE Threads::Threads)
endif ()

# lto
if (LTO_ENABLED)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported OUTPUT error)
    if ( ipo_supported )
        message(STATUS "IPO / LTO enabled")
        set_property(TARGET ${Target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
    else ()
        message(STATUS "IPO / LTO not supported: <${error}>")
    endif ()
endif ()

# ----------------------------------------------- doxygen documentation ------------------------------------------------
# ======================================================================================================================
if (BUILD_DOC AND STANDALONE_PROJECT)
    # doxygen documentation (https://vicrucann.github.io/tutorials/quick-cmake-doxygen/)
    # check if Doxygen is installed
    find_package(Doxygen)
    if (DOXYGEN_FOUND)
        # set input and output files
        set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
        set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

        if (EXISTS ${DOXYGEN_IN})
            # request to configure the file
            configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
            message(STATUS "Doxygen configured")

            # note the option ALL which allows to build the docs together with the application
            add_custom_target(doc_doxygen_${Target}
                    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMENT "Generating API documentation with Doxygen"
                    VERBATIM)
            message(STATUS "Added target doc_doxygen_${Target}")

            if (TARGET doc_doxygen)
                add_dependencies(doc_doxygen doc_doxygen_${Target})
            else ()
                add_custom_target(doc_doxygen DEPENDS doc_doxygen_${Target})
            endif ()
        else ()
            message(WARNING "doxygen documentation requested, but file ${DOXYGEN_IN} does not exist.")
        endif ()
    else (DOXYGEN_FOUND)
        message(WARNING "Doxygen must be installed and accessible to generate the doxygen documentation.")
    endif (DOXYGEN_FOUND)
endif ()

# add clang format target
if (CLANG_FORMAT AND STANDALONE_PROJECT)
    set(CLANG_FORMAT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format)

    if (EXISTS ${CLANG_FORMAT_FILE})
        include(cmake_files/ClangFormat.cmake)
        target_clangformat_setup(${Target})

        if (FORCE_CLANG_FORMAT)
            add_dependencies(${Target} ${Target}_clangformat)
        endif ()

        message(STATUS "Added clang format target(s)")
    else ()
        message(WARNING "Clang format enabled, but file ${CLANG_FORMAT_FILE}  does not exist")
    endif ()
endif ()

# add test targets
if (ENABLE_TEST)
    enable_testing()
    add_subdirectory("test")
endif ()

# generate version_info.{c,h}pp
add_custom_command(
    OUTPUT
        ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/version_info_cpp  # file does not exist --> command is always executed

    BYPRODUCTS
        ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/version_info.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/version_info.hpp

    COMMAND
        bash ${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_version_info_cpp.sh ${PROJECT_NAME}

    WORKING_DIRECTORY
        ${CMAKE_CURRENT_SOURCE_DIR}
)

execute_process(
    COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_version_info_cpp.sh" ${PROJECT_NAME}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(${Target}_generated_version_info
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/version_info_cpp
)

add_dependencies(${Target} ${Target}_generated_version_info)
