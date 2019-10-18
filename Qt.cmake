
#
# This is a helper script that I use to ease creation of CMake based project using
# Qt. It especially takes care of patching Qt's exported targets when you're using
# a statically built version of Qt (check Google for "Qt static link windows") to
# see what I mean :)
#
# Basically this script is used like so:
#
# ```
# set (QT_ROOT "path/to/your/Qt/library/folder/lib/cmake")
# set (QT_COMPONENTS Widgets)
# include ("./CMakeUtils/Qt.cmake")
# ```
#
# You just have to make `QT_ROOT` point at the folder where the CMake exported targets
# are located. Usually located in `lib/cmake` in your Qt root folder.
#
# Here is more detailed explanation of the variables available to configure the script:
#
# QT_ROOT       : Can be either the folder where the CMake exported targets are located,
#                 or a list of such folders. This is passed to `find_package` as `HINTS`.
# QT_SUFFIX     : When used, it's passed to `find_package` as `PATH_SUFFIXES`. It can be
#                 either a single string or a list.
# QT_VERSION    : Optional version number. If omitted, uses `5`.
# QT_COMPONENTS : The components you want to load.
#
# A more complete example, if you're working on a multiplatform project:
#
# ```
# # The paths on your various platforms or build machines:
# set (QT_ROOT
#     "C:/Qt/5.13.1"
#     "D:/Qt/5.13.1"
#     "/usr/localQt/5.13.1"
# )
#
# # The suffixes (those are kinda standard when installing Qt from the online installer)
# set (QT_SUFFIX
#     "msvc2017_64/lib/cmake"
#     "gcc_64/lib/cmake"
#     "clang_64/lib/cmake"
# )
# set (QT_COMPONENTS Widgets)
# include ("./CMakeUtils/Qt.cmake")
# ```
#

#
# Find Qt.
#
find_path (QT_DIR Qt5
	HINTS
		${QT_ROOT}
	PATH_SUFFIXES
		${QT_SUFFIX}
)

#
# Log / Error
#
if (NOT QT_DIR)
	message (FATAL_ERROR "Couldn't find Qt. Use QT_DIR variable to point to a valid Qt install.")
else ()
	message (STATUS "Found Qt in '${QT_DIR}'")
endif ()

#
# Find our Qt components
#
if (NOT QT_VERSION)
	set (QT_VERSION 5)
endif ()
set (CMAKE_PREFIX_PATH ${QT_DIR})
find_package (Qt5 ${QT_VERSION} COMPONENTS ${QT_COMPONENTS} REQUIRED)

#
# Check if Qt is a shared or static library
#
get_target_property (QT_CORE_TARGET_TYPE Qt5::Core TYPE)
if (QT_CORE_TARGET_TYPE STREQUAL STATIC_LIBRARY)
	set (QT_STATIC ON)
	message (STATUS "Using a static Qt library, patching exported targets...")
else ()
	set (QT_STATIC OFF)
endif ()

#
# When using static build, exported Qt targets miss a awefull lot of dependencies (on Windows
# at least, didn't check the other platforms) so to avoid bothering, patch Qt5::Widgets
#
if (QT_STATIC)

	#
	# Set a few paths
	#
	set (QT_LIB_DIR "${QT_DIR}/..")
	set (QT_PLUGIN_DIR "${QT_DIR}/../../plugins")

	#
	# Qt5::QWindowsIntegrationPlugin
	# note that this target somehow is already there even if we didn't search for it in the
	# find_package command. And since it's mandatory to run the most basic Widgets application
	# on Windows ...
	#
	if (TARGET Qt5::QWindowsIntegrationPlugin)

		# find additional components needed by the windows platform plugin
		find_package (Qt5 5
			COMPONENTS
				EventDispatcherSupport
				FontDatabaseSupport
				ThemeSupport
				WindowsUIAutomationSupport
			REQUIRED
		)

		# configure direct dependencies of the plugin
		target_link_libraries(Qt5::QWindowsIntegrationPlugin
			INTERFACE
				# Qt targets
				Qt5::EventDispatcherSupport
				Qt5::FontDatabaseSupport
				Qt5::ThemeSupport
				Qt5::WindowsUIAutomationSupport

				# Windows libs
				Dwmapi.lib
				Imm32.lib
				Wtsapi32.lib

				# The following is needed if you want to use the Windows vista style plugin.
				# If you provide your own style or CSS, you can comment out the following libs.
				${QT_PLUGIN_DIR}/styles/qwindowsvistastyle.lib
				UxTheme.lib
		)

	endif ()

	#
	# Qt5::FontDatabaseSupport
	#
	if (TARGET Qt5::FontDatabaseSupport)

		target_link_libraries(Qt5::FontDatabaseSupport
			INTERFACE
				# Qt libs
				${QT_LIB_DIR}/qtfreetype.lib
		)

	endif ()

	#
	# Qt5::Gui
	#
	if (TARGET Qt5::Gui)

		target_link_libraries(Qt5::Gui
			INTERFACE
				# Qt targets
				Qt5::QWindowsIntegrationPlugin

				# Qt libs
				${QT_LIB_DIR}/qtharfbuzz.lib
				${QT_LIB_DIR}/qtlibpng.lib
		)

	endif ()

	#
	# Qt5::Core
	#
	if (TARGET Qt5::Core)

		target_link_libraries(Qt5::Core
			INTERFACE
				# Qt libs
				${QT_LIB_DIR}/qtpcre2.lib

				# Windows libs
				Netapi32.lib
				Ws2_32.lib
				UserEnv.lib
				Version.lib
				Winmm.lib
		)

		target_compile_definitions (Qt5::Core
			INTERFACE
				# Remove debug stuff from Qt
				$<$<CONFIG:Release>:QT_NO_DEBUG>
				$<$<CONFIG:Release>:QT_NO_DEBUG_OUTPUT>
				$<$<CONFIG:Release>:QT_NO_INFO_OUTPUT>
				$<$<CONFIG:Release>:QT_NO_WARNING_OUTPUT>

				# Since Qt was built in release, we need to match it on Windows
				_ITERATOR_DEBUG_LEVEL=0
		)

	endif ()

endif ()
