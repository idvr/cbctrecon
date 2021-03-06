CMAKE_MINIMUM_REQUIRED (VERSION 3.8) # Yes, less won't do.

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)


SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

OPTION(USE_CUDA "Toggle CUDA on or off" ON) # OFF by default for multiple reasons
OPTION(USE_OPENCL "Toggle OpenCL (deprecated features) on or off" OFF) # OFF by default for multiple reasons
OPTION(USE_OPENMP "Toggle OpenMP on or off" ON)
OPTION(USE_CLFFT "Toggle CLFFT (in development) on or off" OFF) # OFF by default because it doesn't yet work
OPTION(USE_GPMC "Toggle gPMC on or off" OFF) # OFF by default because you can't expect developers to have access to gPMC binaries AND use VS2013 Debug when Release is much faster for everything else.
OPTION(USE_LOWPASS_FFT "Gauss FFT as low-pass filter for scatter smoothing" ON)
OPTION(BUILD_SHARED_LIBS "Build shared libs in ITK, Plastimatch and RTK (for redistribution)" ON)

OPTION(CbctRecon_SUPERBUILD "Use SUPERBUILD system" ON) # I have not tried setting it "OFF", tbh
OPTION(BUILD_TESTING "Build testing in ITK, RTK and Plastimatch" ON) # ON by default, because you should test your code
IF(USE_CUDA)
  message (STATUS "Compiling with CUDA option")
ENDIF(USE_CUDA)
IF(USE_OPENCL)
  message (STATUS "Compiling with deprecated OPENCL option")
ENDIF(USE_OPENCL)
IF(USE_GPMC)
  message (STATUS "Compiling with GPMC option")
ENDIF(USE_GPMC)
IF(USE_LOWPASS_FFT)
  message (STATUS "Compiling with Gauss FFT as low-pass filter for scatter smoothing option")
  ADD_DEFINITIONS(-DLOWPASS_FFT=TRUE)
ENDIF(USE_LOWPASS_FFT)
########################START SUPERBUILD STUFF ################################
include(ExternalProject)
include(ExternalProjectDependency)
include(ExternalProjectGenerateProjectDescription)

project(CbctRecon)

SET(CMAKE_CXX_STANDARD 14 CACHE STRING "C++ standard specification")


FIND_PACKAGE(Git REQUIRED) # We superbuild now.

FIND_PACKAGE(OpenCL REQUIRED)
IF(USE_CUDA)
  FIND_PACKAGE(CUDA_wrap)
  GET_FILENAME_COMPONENT(CUDA_TOOLKIT_ROOT_DIR "${CUDA_TOOLKIT_INCLUDE}/.." ABSOLUTE)
  FIND_PACKAGE(CUDA REQUIRED)
ENDIF(USE_CUDA)
FIND_PACKAGE(FFTW)
# set(TBB_ROOT "" CACHE PATH "Root dir of intel TBB, (one level up from lib)")
# FIND_PACKAGE(TBB) ## The world is not ready for this yet
IF(USE_OPENMP)
  FIND_PACKAGE(OpenMP)
ENDIF(USE_OPENMP)
IF(USE_CLFFT)
  FIND_PACKAGE(clFFT)
ENDIF(USE_CLFFT)

FIND_PACKAGE(Qt5 COMPONENTS Core Gui OpenGL PrintSupport Widgets REQUIRED)

SET(CbctRecon_APPLICATIONS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Applications)

#-----------------------------------------------------------------------------
# Main application
#-----------------------------------------------------------------------------
if(NOT DEFINED CbctRecon_MAIN_PROJECT)
  set(CbctRecon_MAIN_PROJECT CbctReconApp CACHE INTERNAL "Main project name")
endif()
mark_as_superbuild(CbctRecon_MAIN_PROJECT:STRING)
if(NOT DEFINED ${CbctRecon_MAIN_PROJECT}_APPLICATION_NAME)
  set(${CbctRecon_MAIN_PROJECT}_APPLICATION_NAME CbctRecon CACHE INTERNAL "Main application name")
else()
  if(NOT DEFINED CbctReconApp_APPLICATION_NAME)
    set(CbctReconApp_APPLICATION_NAME CbctRecon)
  endif()
endif()

set(CbctRecon_MAIN_PROJECT_APPLICATION_NAME ${${CbctRecon_MAIN_PROJECT}_APPLICATION_NAME})
set(CbctReconAppName ${CbctRecon_MAIN_PROJECT_APPLICATION_NAME})

#-----------------------------------------------------------------------------
set(${CbctReconAppName}_VERSION_MAJOR "1") # bump at major change -> does NOT mean release version
set(${CbctReconAppName}_VERSION_MINOR "2") # bump at functionality change
set(${CbctReconAppName}_VERSION_PATCH "1") # bump at minor change
project(${CbctReconAppName} VERSION "${${CbctReconAppName}_VERSION_MAJOR}.${${CbctReconAppName}_VERSION_MINOR}.${${CbctReconAppName}_VERSION_PATCH}")
#-----------------------------------------------------------------------------

SET(CbctRecon_INSTALL_BIN_DIR "${CMAKE_BINARY_DIR}/install-all/bin/")
SET(CbctRecon_INSTALL_LIB_DIR "${CMAKE_BINARY_DIR}/install-all/lib/")
#-----------------------------------------------------------------------------
# Superbuild script
#-----------------------------------------------------------------------------
if(CbctRecon_SUPERBUILD)
  include("${CMAKE_CURRENT_SOURCE_DIR}/SuperBuild.cmake")
  return()
endif()

foreach(dep QT ${DEPENDENCIES})
  if(CbctRecon_USE_SYSTEM_${dep})
    message(STATUS "Using system ${dep}")
  endif()
endforeach()

set(EXTERNAL_PROJECT_OPTIONAL_ARGS)
if(WIN32)
  list(APPEND EXTERNAL_PROJECT_OPTIONAL_ARGS -DCbctRecon_SKIP_ROOT_DIR_MAX_LENGTH_CHECK:BOOL=ON)
endif()

#-----------------------------------------------------------------------------
# Superbuild Option - Enabled by default
#-----------------------------------------------------------------------------
option(CbctRecon_SUPERBUILD "Build ${PROJECT_NAME} and the projects it depends on." ON)
mark_as_advanced(CbctRecon_SUPERBUILD)
set(CbctRecon_BINARY_INNER_SUBDIR CbctRecon-build)
#-----------------------------------------------------------------------------
# Sanity checks
#-----------------------------------------------------------------------------
if(WIN32)
  set(${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH 40)
  if(NOT ${PROJECT_NAME}_SUPERBUILD)
    string(LENGTH ${CbctRecon_BINARY_INNER_SUBDIR} _inner_subdir_length)
    math(EXPR ${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH "${${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH} + ${_inner_subdir_length}")
  endif()
  include(PreventDirWithTooManyChars)
endif()
include(PreventInSourceBuilds)
include(PreventInBuildInstalls)
include(PreventDirWithSpaces)
mark_as_superbuild(${PROJECT_NAME}_SKIP_DIR_WITH_SPACES_CHECK:BOOL)
#-----------------------------------------------------------------------------
# Set a default build type if none was specified
#-----------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
  mark_as_advanced(CMAKE_BUILD_TYPE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()
if(NOT CMAKE_CONFIGURATION_TYPES)
  mark_as_superbuild(VARS CMAKE_BUILD_TYPE ALL_PROJECTS)
endif()

#-----------------------------------------------------------------------------
# Clear CbctReconTargets.cmake
#-----------------------------------------------------------------------------
file(WRITE "${CbctRecon_BINARY_DIR}/CbctReconTargets.cmake" "")

##########################END SUPERBUILD STUFF ################################

Add_Subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/Applications")
