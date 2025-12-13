cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(rnoh_vlc_media_player_generated_dir "${CMAKE_CURRENT_SOURCE_DIR}/generated")
file(GLOB_RECURSE rnoh_vlc_generated_SRC "${rnoh_vlc_media_player_generated_dir}/**/*.cpp")
file(GLOB_RECURSE rnoh_vlc_SRC CONFIGURE_DEPENDS *.cpp)
add_library(rnoh_vlc SHARED ${rnoh_vlc_generated_SRC} ${rnoh_vlc_SRC})
target_include_directories(rnoh_vlc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${rnoh_vlc_media_player_generated_dir})
target_link_libraries(rnoh_vlc PUBLIC rnoh)