if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    cmake_minimum_required(VERSION 3.13)
    project(hlredis LANGUAGES C CXX)

    include(GNUInstallDirs)
    include(FindPkgConfig)
    include(FetchContent)

    set(HASHLINK_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." CACHE PATH "Path to the HashLink repository root")

    set(WITH_VM OFF CACHE BOOL "" FORCE)
    set(WITH_FMT OFF CACHE BOOL "" FORCE)
    set(WITH_OPENAL OFF CACHE BOOL "" FORCE)
    set(WITH_SDL OFF CACHE BOOL "" FORCE)
    set(WITH_SQLITE OFF CACHE BOOL "" FORCE)
    set(WITH_SSL OFF CACHE BOOL "" FORCE)
    set(WITH_UI OFF CACHE BOOL "" FORCE)
    set(WITH_UV OFF CACHE BOOL "" FORCE)
    set(WITH_VIDEO OFF CACHE BOOL "" FORCE)
    set(WITH_HEAPS OFF CACHE BOOL "" FORCE)
    set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
    set(DOWNLOAD_DEPENDENCIES ON CACHE BOOL "" FORCE)

    add_subdirectory("${HASHLINK_DIR}" hashlink-build EXCLUDE_FROM_ALL)

    if(BUILD_SHARED_LIBS)
        set(HDLL_SUFFIX .hdll)
    else()
        set(HDLL_SUFFIX .hdll${CMAKE_STATIC_LIBRARY_SUFFIX})
    endif()

    function(set_as_hdll target)
        set_target_properties(${target}.hdll
            PROPERTIES
            PREFIX ""
            OUTPUT_NAME ${target}
            SUFFIX ${HDLL_SUFFIX}
        )
        if(NOT MSVC AND NOT APPLE)
            target_link_options(${target}.hdll PRIVATE "-Wl,--no-undefined")
        endif()
    endfunction()

    set(HDLL_DESTINATION ${CMAKE_BINARY_DIR}/bin)
else()
    include(FindPkgConfig)
    if(DOWNLOAD_DEPENDENCIES)
        include(FetchContent)
    endif()
endif()

add_library(redis.hdll
    redis.c
)

set_as_hdll(redis)

set(HIREDIS_TARGET "")

if(DOWNLOAD_DEPENDENCIES)
    FetchContent_Declare(hiredis-project
        URL https://github.com/redis/hiredis/archive/refs/tags/v1.2.0.tar.gz
        URL_HASH SHA256=82ad632d31ee05da13b537c124f819eb88e18851d9cb0c30ae0552084811588c
        EXCLUDE_FROM_ALL
    )
    set(DISABLE_TESTS ON CACHE INTERNAL "")
    set(ENABLE_SSL OFF CACHE INTERNAL "")
    FetchContent_MakeAvailable(hiredis-project)

    if(TARGET hiredis::hiredis)
        set(HIREDIS_TARGET hiredis::hiredis)
    elseif(TARGET hiredis)
        set(HIREDIS_TARGET hiredis)
    elseif(TARGET libhiredis)
        set(HIREDIS_TARGET libhiredis)
    endif()
endif()

if(NOT HIREDIS_TARGET AND PkgConfig_FOUND)
    pkg_check_modules(HIREDIS IMPORTED_TARGET hiredis)
endif()

if(NOT HIREDIS_TARGET AND TARGET PkgConfig::HIREDIS)
    set(HIREDIS_TARGET PkgConfig::HIREDIS)
endif()

if(HIREDIS_TARGET)
    target_link_libraries(redis.hdll
        libhl
        ${HIREDIS_TARGET}
    )
else()
    find_path(HIREDIS_INCLUDE_DIR hiredis/hiredis.h)
    find_library(HIREDIS_LIBRARY NAMES hiredis)

    if(NOT HIREDIS_INCLUDE_DIR OR NOT HIREDIS_LIBRARY)
        message(FATAL_ERROR "hiredis was not found. Install hiredis development files or make it visible to CMake.")
    endif()

    target_include_directories(redis.hdll
        PRIVATE
        ${HIREDIS_INCLUDE_DIR}
    )
    target_link_libraries(redis.hdll
        libhl
        ${HIREDIS_LIBRARY}
    )
endif()

if(WIN32)
    target_link_libraries(redis.hdll
        ws2_32
    )

    if(TARGET hiredis::hiredis OR TARGET hiredis OR TARGET libhiredis)
        add_custom_command(TARGET redis.hdll POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:${HIREDIS_TARGET}>
                $<TARGET_FILE_DIR:redis.hdll>
        )
    endif()
endif()

install(
    TARGETS
        redis.hdll
    DESTINATION ${HDLL_DESTINATION}
)
