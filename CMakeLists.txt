cmake_minimum_required(VERSION 3.27)

project(fBoggle VERSION 0.1
  DESCRIPTION "A Fortran2008 implementation of the word game Boggle - word searcher"
        LANGUAGES Fortran)
enable_language(Fortran)

# Currently setting the Fortran compiler to use -std=gnu, change this if you
# want a specific standard
set(FVERSION "-std=f2008")

set(GENERIC_COMPILE_FLAGS "-O2 ${FVERSION}")
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)
if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  set (BOGGLE_RELEASE_FLAGS "${GENERIC_COMPILE_FLAGS} -Wall -Wextra")
  set (BOGGLE_DEBUG_FLAGS "-g -O0 -Wall -Wextra -fcheck=all -fbacktrace -pedantic")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*" OR Fortran_COMPILER_NAME MATCHES "ifx.*")
  set (BOGGLE_RELEASE_FLAGS "${GENERIC_COMPILE_FLAGS}")
  set (BOGGLE_RELEASE_FLAGS "-g -O0 -backtrace -check all")
endif()
#set(CMAKE_Fortran_FLAGS "${GENERIC_COMPILE_FLAGS} ${CMAKE_Fortran_FLAGS} ${FVERSION}")

# Source code
add_subdirectory(src)
find_package(OpenMP REQUIRED)
target_link_libraries(fboggle PRIVATE OpenMP::OpenMP_Fortran)
install(TARGETS fboggle    DESTINATION "build")
target_compile_options(fboggle PRIVATE 
  "$<$<CONFIG:Debug>:${BOGGLE_DEBUG_FLAGS}>"
  "$<$<CONFIG:Release>:${BOGGLE_RELEASE_FLAGS}>"
)
