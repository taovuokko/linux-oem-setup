add_library(oem_setup_helper_lib STATIC
    HelperOps.cpp
)

target_include_directories(oem_setup_helper_lib
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(oem_setup_helper_lib
    PUBLIC
        Qt6::Core
        oem_setup_common
)

add_executable(oem-setup-helper
    main.cpp
)

target_link_libraries(oem-setup-helper
    PRIVATE
        oem_setup_helper_lib
)

install(TARGETS oem-setup-helper
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/oem-setup
)
