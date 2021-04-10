cmake_minimum_required(VERSION 3.13.4 FATAL_ERROR)

# ----------------------------------------------- User settings --------------------------------------------------------
# ======================================================================================================================

# project
project(CMAKE_Template_Project LANGUAGES CXX VERSION 0.0.1)

# settings
set(Target "Template_Project")    # Executable name (without file extension!)
set(STANDARD 20)             # C++ Standard


# options
option(BUILD_DOC "Build documentation" ON)
option(COMPILER_WARNINGS "Enable compiler warnings" ON)
option(ENABLE_MULTITHREADING "Link the default multithreading library for the current target system" ON)
option(MAKE_32_BIT_BINARY "Compile as 32 bit application. No effect on 32 bit Systems" OFF)
option(OPENMP "enable openmp" ON)
option(OPTIMIZE_DEBUG "apply optimizations also in debug mode" ON)
option(CLANG_FORMAT "use clang-format" ON)
option(CLANG_TIDY "use clang-tidy" OFF)


# ======================================================================================================================
# ======================================================================================================================


# ----------------------------------------------- Do not change --------------------------------------------------------
# ======================================================================================================================

if(CLANG_TIDY)
    set(CMAKE_CXX_CLANG_TIDY
            clang-tidy;
            -checks=*;
            )
endif()

# add executable
add_executable(${Target})

# set source and libraries directory
add_subdirectory("src")
add_subdirectory("libs")

# force C++ Standard and disable compiler specific extensions
set_target_properties(${Target} PROPERTIES
        CXX_STANDARD ${STANDARD}
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
    )

# options that are valid for gcc and clang
function(commonopts)
    # more debugging information
    if(OPTIMIZE_DEBUG)
        SET(CMAKE_CXX_FLAGS_DEBUG "-g3 -O3")
    else()
        SET(CMAKE_CXX_FLAGS_DEBUG "-g3")
    endif()

    if(MAKE_32_BIT_BINARY)
        message("Compiling as 32 bit binary.")
        target_compile_options(${Target} PUBLIC -m32)
    endif()

    if(ENABLE_MULTITHREADING AND OPENMP)
        message("openmp enabled")
        target_compile_options(${Target} PUBLIC -fopenmp)
    endif()
endfunction()

# warnings that are valid for gcc and clang
function(commonwarn)
    # see https://gcc.gnu.org/onlinedocs/gcc-4.3.2/gcc/Warning-Options.html for more details

    target_compile_options(${Target} PUBLIC -Wnull-dereference)
    target_compile_options(${Target} PUBLIC -Wold-style-cast)
    target_compile_options(${Target} PUBLIC -Wdouble-promotion)
    target_compile_options(${Target} PUBLIC -Wformat=2)
    target_compile_options(${Target} PUBLIC -Winit-self)
    target_compile_options(${Target} PUBLIC -Wsequence-point)
    target_compile_options(${Target} PUBLIC -Wswitch-default)
    target_compile_options(${Target} PUBLIC -Wswitch-enum -Wno-error=switch-enum)
    target_compile_options(${Target} PUBLIC -Wconversion)
    target_compile_options(${Target} PUBLIC -Wcast-align)
    target_compile_options(${Target} PUBLIC -Wfloat-equal)
    target_compile_options(${Target} PUBLIC -Wundef)
    target_compile_options(${Target} PUBLIC -Wcast-qual)
endfunction()

# gcc specific warnings
function(gccwarn)
    # see https://gcc.gnu.org/onlinedocs/gcc-4.3.2/gcc/Warning-Options.html for more details

    target_compile_options(${Target} PUBLIC -Wduplicated-cond)
    target_compile_options(${Target} PUBLIC -Wduplicated-branches)
    target_compile_options(${Target} PUBLIC -Wlogical-op)
    target_compile_options(${Target} PUBLIC -Wrestrict)
    target_compile_options(${Target} PUBLIC -Wuseless-cast -Wno-error=useless-cast)
    target_compile_options(${Target} PUBLIC -Wshadow=local -Wno-error=shadow)

    target_compile_options(${Target} PUBLIC -Wno-error=switch-default)
    target_compile_options(${Target} PUBLIC -Wno-error=attributes)
endfunction()

# clang specific warnings
function(clangwarn)
    # enable all
    target_compile_options(${Target} PUBLIC -Weverything)

    # and remove "useless" ones
    target_compile_options(${Target} PUBLIC -Wno-c++98-compat)
    target_compile_options(${Target} PUBLIC -Wno-c++98-c++11-c++14-compat)
    target_compile_options(${Target} PUBLIC -Wno-c++98-compat-pedantic)
    target_compile_options(${Target} PUBLIC -Wno-error=covered-switch-default)
    target_compile_options(${Target} PUBLIC -Wno-shadow-field-in-constructor)
    target_compile_options(${Target} PUBLIC -Wno-padded)
    target_compile_options(${Target} PUBLIC -Wno-shadow-field)
    target_compile_options(${Target} PUBLIC -Wno-weak-vtables)
    target_compile_options(${Target} PUBLIC -Wno-exit-time-destructors)
    target_compile_options(${Target} PUBLIC -Wno-global-constructors)
    target_compile_options(${Target} PUBLIC -Wno-error=unreachable-code-return)
    target_compile_options(${Target} PUBLIC -Wno-error=unreachable-code)
    target_compile_options(${Target} PUBLIC -Wno-error=documentation)
    target_compile_options(${Target} PUBLIC -Wno-error=unused-exception-parameter)
    target_compile_options(${Target} PUBLIC -Wno-nested-anon-types)
    target_compile_options(${Target} PUBLIC -Wno-gnu-anonymous-struct)

endfunction()

if(COMPILER_WARNINGS)
    message("Compiler warnings enabled.")
else()
    message("Compiler warnings disabled.")
endif()

# gcc settings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    # compiler specific defines
    target_compile_definitions(${Target} PUBLIC "COMPILER_GNU")

    commonopts()

    # enable warnings
    if(COMPILER_WARNINGS)
        target_compile_options(${Target} PUBLIC -Wall -Wextra -Werror -pedantic -pedantic-errors)
        commonwarn()
        gccwarn()
    else()
        target_compile_options(${Target} PUBLIC -w)
    endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # compiler specific defines
    target_compile_definitions(${Target} PUBLIC "COMPILER_CLANG")

    commonopts()

    # enable warnings (general)
    if(COMPILER_WARNINGS)
        target_compile_options(${Target} PUBLIC -Wall -Wextra -Werror -pedantic -pedantic-errors)
        commonwarn()
        clangwarn()
    else()
        target_compile_options(${Target} PUBLIC -w)
    endif()

elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    # compiler specific defines
    target_compile_definitions(${Target} PUBLIC "COMPILER_MSVC")

    # more debugging information
    SET(CMAKE_CXX_FLAGS_DEBUG "/Zi")  
    message(AUTHOR_WARNING
            "You are using the MSVC compiler! Only gcc/clang are fully supported by this template.")
    target_compile_options(${Target} PUBLIC /Wall /WX /OpenMP)
else()
    message(AUTHOR_WARNING
            "You are using a compiler other than gcc/clang. Only gcc/clang are fully supported by this template.")
endif()

if(ENABLE_MULTITHREADING)
    # threading lib (std::thread)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
    target_link_libraries(${Target} PRIVATE Threads::Threads)
endif()

# os dependent defines
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    target_compile_definitions(${Target} PUBLIC "OS_LINUX")
    target_compile_definitions(${Target} PUBLIC "OS_POSIX")
elseif(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
    target_compile_definitions(${Target} PUBLIC "OS_FREEBSD")
    target_compile_definitions(${Target} PUBLIC "OS_POSIX")
elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
    target_compile_definitions(${Target} PUBLIC "OS_WINDOWS")
    # TODO check options
    target_compile_options(${Target} PUBLIC -D_DLL -D_MT -Xclang --dependent-lib=msvcrtd)
    # TODO disable DEBUG in release mode
    SET(CMAKE_CXX_FLAGS_DEBUG "-g3 -D_DEBUG")
elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    target_compile_definitions(${Target} PUBLIC "OS_DARWIN")
    target_compile_definitions(${Target} PUBLIC "OS_POSIX")
endif()

# architecture defines
target_compile_definitions(${Target} PUBLIC CPU_WORD_BYTES=${CMAKE_SIZEOF_VOID_P})


if(BUILD_DOC)
    # doxygen documentation (https://vicrucann.github.io/tutorials/quick-cmake-doxygen/)
    # check if Doxygen is installed
    find_package(Doxygen)
    if (DOXYGEN_FOUND)
        # set input and output files
        set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
        set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

        # request to configure the file
        configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
        message("Doxygen build started")

        # note the option ALL which allows to build the docs together with the application
        add_custom_target( doc_doxygen ALL
            COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating API documentation with Doxygen"
            VERBATIM )
    else (DOXYGEN_FOUND)
      message("Doxygen need to be installed and accessible to generate the doxygen documentation.")
    endif (DOXYGEN_FOUND)
endif()

if(CLANG_FORMAT)
    include(ClangFormat.cmake)
    target_clangformat_setup(${Target})
endif()
