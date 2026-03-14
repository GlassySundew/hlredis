if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message(FATAL_ERROR
        "libs/hlredis must be built from the HashLink repository root.\n"
        "Run CMake from the hashlink directory, for example:\n"
        "  cmake -S /path/to/hashlink -B /path/to/hashlink/build-win "
        "-G \"Visual Studio 17 2022\" -A x64 -DWITH_HLREDIS=ON -DDOWNLOAD_DEPENDENCIES=ON"
    )
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
endif()

install(
    TARGETS
        redis.hdll
    DESTINATION ${HDLL_DESTINATION}
)
