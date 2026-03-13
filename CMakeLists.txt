add_library(redis.hdll
    redis.c
)

set_as_hdll(redis)

if(PkgConfig_FOUND)
    pkg_check_modules(HIREDIS IMPORTED_TARGET hiredis)
endif()

if(TARGET PkgConfig::HIREDIS)
    target_link_libraries(redis.hdll
        libhl
        PkgConfig::HIREDIS
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

install(
    TARGETS
        redis.hdll
    DESTINATION ${HDLL_DESTINATION}
)
