FetchContent_Declare(
    stb_image
    GIT_REPOSITORY  https://github.com/nothings/stb.git
    GIT_TAG         master
    GIT_SHALLOW     TRUE
    GIT_PROGRESS    TRUE
)

FetchContent_MakeAvailable(stb_image)
message("Fetching stb_image")

add_library(stb_image INTERFACE ${stb_image_SOURCE_DIR}/stb_image.h)
target_include_directories(stb_image INTERFACE ${stb_image_SOURCE_DIR})
