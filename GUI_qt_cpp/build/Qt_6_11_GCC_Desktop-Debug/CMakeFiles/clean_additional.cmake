# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/getinfo_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/getinfo_autogen.dir/ParseCache.txt"
  "getinfo_autogen"
  )
endif()
