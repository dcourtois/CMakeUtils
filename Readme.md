Introduction
------------

Collection of "useful" (at least to me) CMake scripts.

Content
-------

### Qt.cmake

This one was created after an awefull lot of time spent on trying to figure out how the
hell are we supposed to link against a statically built version of Qt on Windows.

It also helps me with handling my various development machines by providing helpers to locate
Qt library. Basic usage:

```cmake
# this will import the needed targets, and patch them if necessary
# (which it is on Windows when using a static Qt lib)
set (QT_ROOT "path/to/your/Qt/library/folder/lib/cmake")
set (QT_COMPONENTS Widgets)
include (CMakeUtils/Qt.cmake)

#...

set (CMAKE_AUTOMOC ON)
set (CMAKE_AUTORCC ON)

#...

target_link_libraries (MyAwesomeQtTool PRIVATE Qt::Widgets)
```

For more information, check the beginning of the script. But basically even on Windows with a
static Qt library, this should work out of the box.

### Utils.cmake

Various helpers for ease of development. For each function, check the comment preceding in
the CMake script for more information.

- target_set_app_icon : Set an icon to the executable file. Windows only.
