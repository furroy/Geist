# Script to embed Ghost GUI resource files into C++ code
# This generates a header file with embedded file contents

# Ensure output dir is set
if(NOT OUTPUT_DIR OR OUTPUT_DIR STREQUAL "")
    message(FATAL_ERROR "OUTPUT_DIR is not set. Run this script via CMake configure.")
endif()

message(STATUS "embed_resources: OUTPUT_DIR = ${OUTPUT_DIR}")
message(STATUS "embed_resources: SOURCE_DIR = ${SOURCE_DIR}")

set(OUTPUT_FILE "${OUTPUT_DIR}/GhostEmbeddedResources.h")
set(RESOURCE_DIR "${SOURCE_DIR}/tools/ghost/data/Ghost")
set(CONFIG_FILE "${SOURCE_DIR}/tools/ghost/data/ghost.cfg")
set(IMAGE_FILE "${SOURCE_DIR}/tools/ghost/data/Images/image.png")
set(GUIELEMENTS_FILE "${SOURCE_DIR}/tools/ghost/data/Images/GUI/guielements.png")
set(FONT_FILE "${SOURCE_DIR}/tools/ghost/data/Fonts/babyblocks.ttf")

# Get list of all .ghost files
file(GLOB GHOST_FILES "${RESOURCE_DIR}/*.ghost")

# Start generating the header file
file(WRITE ${OUTPUT_FILE} "// Auto-generated file - do not edit manually\n")
file(APPEND ${OUTPUT_FILE} "#ifndef GHOST_EMBEDDED_RESOURCES_H\n")
file(APPEND ${OUTPUT_FILE} "#define GHOST_EMBEDDED_RESOURCES_H\n\n")
file(APPEND ${OUTPUT_FILE} "#include <string>\n")
file(APPEND ${OUTPUT_FILE} "#include <map>\n")
file(APPEND ${OUTPUT_FILE} "#include <vector>\n\n")
file(APPEND ${OUTPUT_FILE} "namespace GhostEmbeddedResources {\n\n")

# Embed ghost.cfg file first
if(EXISTS ${CONFIG_FILE})
    file(READ ${CONFIG_FILE} FILE_CONTENT)

    # Escape special characters for C++ string literal
    string(REPLACE "\\" "\\\\" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "\"" "\\\"" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "\n" "\\n\"\n    \"" FILE_CONTENT "${FILE_CONTENT}")

    # Write as string literal
    file(APPEND ${OUTPUT_FILE} "const char* ghost_cfg = \n    \"${FILE_CONTENT}\";\n\n")
endif()

# For each .ghost file, embed it as a string literal
foreach(GHOST_FILE ${GHOST_FILES})
    get_filename_component(FILENAME ${GHOST_FILE} NAME_WE)

    # Read file content
    file(READ ${GHOST_FILE} FILE_CONTENT)

    # Escape special characters for C++ string literal
    string(REPLACE "\\" "\\\\" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "\"" "\\\"" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "\n" "\\n\"\n    \"" FILE_CONTENT "${FILE_CONTENT}")

    # Write as string literal
    file(APPEND ${OUTPUT_FILE} "const char* ${FILENAME}_ghost = \n    \"${FILE_CONTENT}\";\n\n")
endforeach()

# Embed binary files (PNG, TTF) as byte arrays
# Helper function to convert binary file to hex array
macro(EMBED_BINARY_FILE FILE_PATH VAR_NAME)
    if(EXISTS ${FILE_PATH})
        file(READ ${FILE_PATH} FILE_CONTENT_HEX HEX)
        string(LENGTH "${FILE_CONTENT_HEX}" HEX_LENGTH)
        math(EXPR BYTE_COUNT "${HEX_LENGTH} / 2")

        file(APPEND ${OUTPUT_FILE} "const unsigned char ${VAR_NAME}_data[] = {\n    ")

        set(BYTE_INDEX 0)
        string(REGEX MATCHALL ".." HEX_BYTES "${FILE_CONTENT_HEX}")
        foreach(HEX_BYTE ${HEX_BYTES})
            file(APPEND ${OUTPUT_FILE} "0x${HEX_BYTE},")
            math(EXPR BYTE_INDEX "${BYTE_INDEX} + 1")
            math(EXPR MOD_RESULT "${BYTE_INDEX} % 16")
            if(MOD_RESULT EQUAL 0)
                file(APPEND ${OUTPUT_FILE} "\n    ")
            endif()
        endforeach()

        file(APPEND ${OUTPUT_FILE} "\n};\n")
        file(APPEND ${OUTPUT_FILE} "const unsigned int ${VAR_NAME}_size = ${BYTE_COUNT};\n\n")
    endif()
endmacro()

# Embed image.png
EMBED_BINARY_FILE(${IMAGE_FILE} "image_png")

# Embed guielements.png
EMBED_BINARY_FILE(${GUIELEMENTS_FILE} "guielements_png")

# Embed babyblocks.ttf
EMBED_BINARY_FILE(${FONT_FILE} "babyblocks_ttf")

# Create a map for text resources (ghost.cfg and .ghost files)
file(APPEND ${OUTPUT_FILE} "const std::map<std::string, const char*> ResourceMap = {\n")
# Add ghost.cfg to the map
if(EXISTS ${CONFIG_FILE})
    file(APPEND ${OUTPUT_FILE} "    {\"ghost.cfg\", ghost_cfg},\n")
endif()
# Add all .ghost files to the map
foreach(GHOST_FILE ${GHOST_FILES})
    get_filename_component(FILENAME ${GHOST_FILE} NAME)
    get_filename_component(FILENAME_WE ${GHOST_FILE} NAME_WE)
    file(APPEND ${OUTPUT_FILE} "    {\"${FILENAME}\", ${FILENAME_WE}_ghost},\n")
endforeach()
file(APPEND ${OUTPUT_FILE} "};\n\n")

# Create a struct for binary resources
file(APPEND ${OUTPUT_FILE} "struct BinaryResource {\n")
file(APPEND ${OUTPUT_FILE} "    const unsigned char* data;\n")
file(APPEND ${OUTPUT_FILE} "    unsigned int size;\n")
file(APPEND ${OUTPUT_FILE} "};\n\n")

# Create a map for binary resources
file(APPEND ${OUTPUT_FILE} "const std::map<std::string, BinaryResource> BinaryResourceMap = {\n")
if(EXISTS ${IMAGE_FILE})
    file(APPEND ${OUTPUT_FILE} "    {\"Images/image.png\", {image_png_data, image_png_size}},\n")
endif()
if(EXISTS ${GUIELEMENTS_FILE})
    file(APPEND ${OUTPUT_FILE} "    {\"GUI/guielements.png\", {guielements_png_data, guielements_png_size}},\n")
endif()
if(EXISTS ${FONT_FILE})
    file(APPEND ${OUTPUT_FILE} "    {\"Fonts/babyblocks.ttf\", {babyblocks_ttf_data, babyblocks_ttf_size}},\n")
endif()
file(APPEND ${OUTPUT_FILE} "};\n\n")

# Helper function to get text resource
file(APPEND ${OUTPUT_FILE} "inline const char* GetResource(const std::string& name) {\n")
file(APPEND ${OUTPUT_FILE} "    auto it = ResourceMap.find(name);\n")
file(APPEND ${OUTPUT_FILE} "    return (it != ResourceMap.end()) ? it->second : nullptr;\n")
file(APPEND ${OUTPUT_FILE} "}\n\n")

# Helper function to get binary resource
file(APPEND ${OUTPUT_FILE} "inline BinaryResource GetBinaryResource(const std::string& name) {\n")
file(APPEND ${OUTPUT_FILE} "    auto it = BinaryResourceMap.find(name);\n")
file(APPEND ${OUTPUT_FILE} "    return (it != BinaryResourceMap.end()) ? it->second : BinaryResource{nullptr, 0};\n")
file(APPEND ${OUTPUT_FILE} "}\n\n")

file(APPEND ${OUTPUT_FILE} "} // namespace GhostEmbeddedResources\n\n")
file(APPEND ${OUTPUT_FILE} "#endif // GHOST_EMBEDDED_RESOURCES_H\n")

message(STATUS "Generated embedded resources header: ${OUTPUT_FILE}")
