
#
# Collection of utilities
#


#
# Add an icon to an application. WIndows only.
#
# TARGET : Name of the application target
# ICON   : Path of to the .ico file
#
function (target_set_app_icon TARGET ICON)

	if (WIN32)

		# disable the banner when invoking the rc tool
		set (CMAKE_RC_FLAGS "/nologo" PARENT_SCOPE)

		# the rc filename
		set (RC_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Icon.rc")

		# write the rc file
		file (WRITE
			${RC_FILENAME}
			"IDI_ICON1 ICON DISCARDABLE \"${ICON}\"\n"
		)

		# add the file to the target
		target_sources (${TARGET}
			PRIVATE
			${RC_FILENAME}
		)

	endif ()

endfunction ()
