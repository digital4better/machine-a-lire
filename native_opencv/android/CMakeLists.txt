cmake_minimum_required(VERSION 3.4.1)  # for example

set(OPENCV_INCLUDE_DIR "$ENV{OPENCV_ANDROID_SDK_HOME}/sdk/native/jni/include/")
set(OPENCV_LIB_DIR "$ENV{OPENCV_ANDROID_SDK_HOME}/sdk/native/libs/${ANDROID_ABI}")

include_directories(${OPENCV_INCLUDE_DIR})

add_library(opencv SHARED IMPORTED)
set_target_properties(opencv PROPERTIES IMPORTED_LOCATION ${OPENCV_LIB_DIR}/libopencv_java4.so)

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

find_library(log-lib log)
target_link_libraries(native_opencv opencv ${log-lib})
