find_package(Qt6 REQUIRED COMPONENTS Test)

add_executable(ValidationTest ValidationTest.cpp)
target_link_libraries(ValidationTest PRIVATE Qt6::Test oem_setup_common)
add_test(NAME ValidationTest COMMAND ValidationTest)

add_executable(HelperTest HelperTest.cpp)
target_link_libraries(HelperTest PRIVATE Qt6::Test oem_setup_helper_lib)
add_test(NAME HelperTest COMMAND HelperTest)
