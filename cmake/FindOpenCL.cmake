# - Try to find OpenCL
# This module tries to find an OpenCL implementation on your system. It supports
# AMD / ATI, Apple and NVIDIA implementations, but should work, too.
#
# Once done this will define
#  OPENCL_FOUND        - system has OpenCL
#  OPENCL_INCLUDE_DIRS  - the OpenCL include directory
#  OPENCL_LIBRARIES    - link these to use OpenCL
#
# WIN32 should work, but is untested

FIND_PACKAGE( PackageHandleStandardArgs )

SET (OPENCL_VERSION_STRING "0.1.0")
SET (OPENCL_VERSION_MAJOR 0)
SET (OPENCL_VERSION_MINOR 1)
SET (OPENCL_VERSION_PATCH 0)

SET(OPENCL_ROOT_DIR
  "${OPENCL_ROOT_DIR}"
  CACHE
  PATH
  "Path to search for opencl")

IF (APPLE)

  FIND_LIBRARY(OPENCL_LIBRARIES OpenCL DOC "OpenCL lib for OSX")
  FIND_PATH(OPENCL_INCLUDE_DIRS OpenCL/cl.h DOC "Include for OpenCL on OSX")
  FIND_PATH(_OPENCL_CPP_INCLUDE_DIRS OpenCL/cl.hpp DOC "Include for OpenCL CPP bindings on OSX")

ELSE (APPLE)

  IF (WIN32)

    FIND_PATH(OPENCL_INCLUDE_DIRS CL/cl.h )
    FIND_PATH(_OPENCL_CPP_INCLUDE_DIRS CL/cl.hpp )

    IF( ${OPENCL_INCLUDE_DIRS} STREQUAL "OPENCL_INCLUDE_DIRS-NOTFOUND" )
     SET( SEARCH_PATH ${OPENCL_ROOT_DIR}/inc ${OPENCL_ROOT_DIR}/common/inc ${PATH} "C:/ProgramData/NVIDIA Corporation/NVIDIA GPU Computing SDK/OpenCL/common/inc" "$ENV{ATISTREAMSDKROOT}/include" "C:/Program Files (x86)/AMD APP/include")
     FIND_PATH(OPENCL_INCLUDE_DIRS CL/cl.h PATHS ${SEARCH_PATH} )
     FIND_PATH(_OPENCL_CPP_INCLUDE_DIRS CL/cl.hpp PATHS ${SEARCH_PATH} )
    ENDIF( ${OPENCL_INCLUDE_DIRS} STREQUAL "OPENCL_INCLUDE_DIRS-NOTFOUND" )

    SET(_OPENCL_BASE ${OPENCL_INCLUDE_DIRS}/..)

    IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
     SET(OPENCL_LIB_DIR ${_OPENCL_BASE}/lib/x64 ${_OPENCL_BASE}/lib/x86_64)
    ELSE(CMAKE_SIZEOF_VOID_P EQUAL 8)
     SET(OPENCL_LIB_DIR ${_OPENCL_BASE}/lib/Win32 ${_OPENCL_BASE}/lib/x86)
    ENDIF(CMAKE_SIZEOF_VOID_P EQUAL 8)

    FIND_LIBRARY(OPENCL_LIBRARIES OpenCL.lib PATHS ${OPENCL_LIB_DIR})

    GET_FILENAME_COMPONENT(_OPENCL_INC_CAND_PRE ${OPENCL_LIBRARIES} PATH)
    SET(_OPENCL_INC_CAND ${_OPENCL_INC_CAND_PRE}/../../include)

    # On Win32 search relative to the library
    FIND_PATH(OPENCL_INCLUDE_DIRS CL/cl.h PATHS "${_OPENCL_INC_CAND}")
    FIND_PATH(_OPENCL_CPP_INCLUDE_DIRS CL/cl.hpp PATHS "${_OPENCL_INC_CAND}")

  ELSE (WIN32)

    # Unix style platforms
    FIND_LIBRARY(OPENCL_LIBRARIES OpenCL
      PATHS ${OPENCL_ROOT_DIR}/lib ${OPENCL_ROOT_DIR}/common/lib
      ENV LD_LIBRARY_PATH
      )

    GET_FILENAME_COMPONENT(OPENCL_LIB_DIR ${OPENCL_LIBRARIES} PATH)
    GET_FILENAME_COMPONENT(_OPENCL_INC_CAND ${OPENCL_LIB_DIR}/../../include ABSOLUTE)

    SET(_OPENCL_INC_CAND
        ${_OPENCL_INC_CAND}
        ${OPENCL_ROOT_DIR}/include
        ${OPENCL_ROOT_DIR}/inc
        ${OPENCL_ROOT_DIR}/common/inc
       )

    # The AMD SDK currently does not place its headers
    # in /usr/include, therefore also search relative
    # to the library
    FIND_PATH(OPENCL_INCLUDE_DIRS CL/cl.h PATHS ${_OPENCL_INC_CAND} /usr/local/cuda/include/)
    FIND_PATH(_OPENCL_CPP_INCLUDE_DIRS CL/cl.hpp PATHS ${_OPENCL_INC_CAND})

  ENDIF (WIN32)

ENDIF (APPLE)

FIND_PACKAGE_HANDLE_STANDARD_ARGS( OpenCL DEFAULT_MSG OPENCL_LIBRARIES OPENCL_INCLUDE_DIRS )

IF( _OPENCL_CPP_INCLUDE_DIRS )
  SET( OPENCL_HAS_CPP_BINDINGS TRUE )
  LIST( APPEND OPENCL_INCLUDE_DIRS ${_OPENCL_CPP_INCLUDE_DIRS} )
  # This is often the same, so clean up
  LIST( REMOVE_DUPLICATES OPENCL_INCLUDE_DIRS )
ENDIF( _OPENCL_CPP_INCLUDE_DIRS )

MARK_AS_ADVANCED(
  OPENCL_INCLUDE_DIRS
  )

if(OPENCL_FOUND)
  try_run(RUN_RESULT_VAR COMPILE_RESULT_VAR
         ${CMAKE_BINARY_DIR} 
         ${CMAKE_CURRENT_LIST_DIR}/has_opencl_gpu.cxx
         CMAKE_FLAGS 
             -DINCLUDE_DIRECTORIES:STRING=${OPENCL_INCLUDE_DIRS}
             -DLINK_LIBRARIES:STRING=${OPENCL_LIBRARIES}
         COMPILE_OUTPUT_VARIABLE COMPILE_OUTPUT_VAR
         RUN_OUTPUT_VARIABLE RUN_OUTPUT_VAR)
    # COMPILE_RESULT_VAR is TRUE when compile succeeds
    # RUN_RESULT_VAR is zero when a GPU is found
    if(COMPILE_RESULT_VAR AND NOT RUN_RESULT_VAR)
       set(OPENCL_HAVE_GPU TRUE CACHE BOOL "Whether OpenCL-capable GPU is present")
    else()
       set(OPENCL_HAVE_GPU FALSE CACHE BOOL "Whether OpenCL-capable GPU is present")
    endif()
    mark_as_advanced(OPENCL_HAVE_GPU)
endif(OPENCL_FOUND)
