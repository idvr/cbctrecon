CMAKE_MINIMUM_REQUIRED (VERSION 3.8)

PROJECT(gPMC)

SET(GPMC_VERSION_MAJOR "2")
SET(GPMC_VERSION_MINOR "0")
SET(GPMC_VERSION_PATCH "0")

SET(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

FIND_PACKAGE(OpenCL REQUIRED)
FIND_PACKAGE(Gengetopt)
FIND_PACKAGE(OpenMP)

IF(OPENMP_FOUND)
  message (STATUS "Compiling with OPENMP option")
  ADD_DEFINITIONS(-DUSE_OPENMP=TRUE)
ENDIF(OPENMP_FOUND)

SET(ITK_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/../ITKv4" CACHE PATH "ITK source directory")
SET(ITK_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/ITKv120-build" CACHE PATH "ITK build directory")

INCLUDE(ExternalProject)
INCLUDE(cmake/External_ITKv120.cmake)
INCLUDE_DIRECTORIES(${ITK_BUILD_DIR})
INCLUDE_DIRECTORIES(${ITK_BUILD_DIR}/Modules/Core/Common)
FIND_PACKAGE(ITK REQUIRED)
message(STATUS "ITK_DIR = ${ITK_DIR}")
INCLUDE(${ITK_USE_FILE})

SET(GPMC_LIB_DIR "${PROJECT_SOURCE_DIR}/bin")
SET(GPMC_LIBRARIES
  "${GPMC_LIB_DIR}/goPMC.lib"
  "${GPMC_LIB_DIR}/dcmtk.lib"
  "${GPMC_LIB_DIR}/libDicomRT.lib"
)

WRAP_GGO(gPMC_GGO_C gPMC.ggo gPMC3Doutputdose_section.ggo gPMCVersion.ggo.in)

ADD_EXECUTABLE(gPMC gPMC.cpp ${gPMC_GGO_C})
INCLUDE_DIRECTORIES("${PROJECT_SOURCE_DIR}/include")

MESSAGE(STATUS "CMake of gPMC was found :: ${PROJECT_SOURCE_DIR}")
add_dependencies(gPMC ITKv120)
TARGET_LINK_LIBRARIES(gPMC
  ${GPMC_LIBRARIES}
  ${ITK_LIBRARIES}
  OpenCL::OpenCL
)

SET(GPMC_SRC_DIR ${PROJECT_SOURCE_DIR})

INSTALL( TARGETS gPMC DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/../bin )

SET(GPMC_DLLS
  "${GPMC_LIB_DIR}/goPMC.dll"
  "${GPMC_LIB_DIR}/dcmtk.dll"
  "${GPMC_LIB_DIR}/libDicomRT.dll"
)
INSTALL( FILES ${GPMC_DLLS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/../bin )

FILE( GLOB LUT_FILES "${PROJECT_SOURCE_DIR}/input/*.bin" )
INSTALL( FILES ${LUT_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/../lut )
