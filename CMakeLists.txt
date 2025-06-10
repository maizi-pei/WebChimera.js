cmake_minimum_required(VERSION 3.1)

project(WebChimera.js)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Windows 特定配置
if(MSVC)
    # 设置静态运行时库链接
    foreach(flag_var
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
        if(${flag_var} MATCHES "/MD")
           string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
        endif()
    endforeach()
    
    # Windows VLC 路径设置 (如果需要，可以在这里添加 Windows VLC 路径)
    # 例如：set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/deps/vlc-${VLC_VERSION}")
    
# macOS 特定配置
elseif(APPLE)
    # 设置 VLC 库路径
    set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/deps/VLC.app/Contents/MacOS/lib")
    
    # 添加 VLC include 路径 - 优先使用项目内的 VLC
    include_directories("${CMAKE_CURRENT_SOURCE_DIR}/deps/VLC.app/Contents/MacOS/include")
    
    # 如果存在系统 VLC 安装，也包含它作为备选
    if(EXISTS "/Applications/VLC.app/Contents/MacOS/include")
        include_directories("/Applications/VLC.app/Contents/MacOS/include")
    endif()
    
# Linux 特定配置
elseif(UNIX)
    # Linux 通常通过包管理器安装 VLC，使用 pkg-config 查找
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(VLC QUIET libvlc)
        if(VLC_FOUND)
            include_directories(${VLC_INCLUDE_DIRS})
            link_directories(${VLC_LIBRARY_DIRS})
        endif()
    endif()
endif()

file(GLOB SOURCE_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    src/[^.]*.cpp
    src/[^.]*.h
    README.md
    package.json
    )

include_directories(${CMAKE_JS_INC} deps)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/deps/libvlc_wrapper)

add_library(${PROJECT_NAME} SHARED ${SOURCE_FILES} ${CMAKE_JS_SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".node")
target_link_libraries(${PROJECT_NAME} ${CMAKE_JS_LIB} libvlc_wrapper)
target_compile_definitions(${PROJECT_NAME}
    PUBLIC
    V8_31BIT_SMIS_ON_64BIT_ARCH
    V8_COMPRESS_POINTERS
    V8_REVERSE_JSARGS
    )

#get_cmake_property(_variableNames VARIABLES)
#foreach(_variableName ${_variableNames})
#    message(STATUS "${_variableName}=${${_variableName}}")
#endforeach()
