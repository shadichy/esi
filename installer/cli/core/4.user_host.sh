#!/bin/bash

usrname() {
	title="User Configurations"
	local reserved_usrname_note="\n\nThe username must start with a lower-case letter, which can be followed by any combination of numbers, more lower-case letters, or the dash symbol, must be no more than 32 characters long, and must not be match with any reserved system usernames (See: https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames)."

	while true; do
		FULL_NAME=$(dbox --nocancel --inputbox "The installer will create a user account for you. This is the main user account that you will login to and use for non-administrative activities.\n\nPlease enter the real name for this user. This information will be used for any program that uses the user's real name such as email. Entering your full name here is recommended; however, it may be left blank.\n\nFull name for the new user:" 0 0)

		while true; do
			USER_NAME=$(dbox --cancel-label "Back" --inputbox "Please enter a username for the new account. $reserved_usrname_note\n\nUsername for your account:" 0 0 "user") || continue
			if ! say "$USER_NAME" | grep -Eoq "^[a-z][a-z0-9-]*$" && [ "${#USER_NAME}" -lt 33 ]; then
				errbox "You entered an invalid username. $reserved_usrname_note"
				continue
			fi

			if grep -Fxq "$USER_NAME" <<<"${reserved_usernames[*]}"; then
				errbox "The username you entered ($USER_NAME) is reserved for use by the system. Please select a different one."
				continue
			fi

			usrpswd_match=false
			while ! "$usrpswd_match"; do
				input=$(dbox --clear --nocancel --insecure --passwordbox "Note: the default password of '$USER_NAME' is 'extos'\n\nCreate a new password for '$USER_NAME':" 0 0 "extos")

				if [ "$input" == extos ]; then
					confirm_input=extos
				else
					confirm_input=$(dbox --clear --insecure --passwordbox "Re-enter password to verify:" 0 0)
				fi

				if [ ! "$input" ]; then
					errbox "You are not allowed to have an empty password."
				elif [ "$input" != "$confirm_input" ]; then
					errbox "The two passwords you entered did not match."
				else
					user_passwd="$input"
					usrpswd_match=true
				fi
			done
			break
		done

		if dbox --clear --nocancel --yesno "Do you want to set a password for 'root' (root is the Super User, the Administaion of the system, who grants permissions for you to do system jobs)?"; then
			supswd_match=false
			while ! "$supswd_match"; do
				input=$(dbox --clear --nocancel --insecure --passwordbox "Note: the default is 'root'\n\nEnter root password:" 0 0 "root")

				if [ "$input" == root ]; then
					confirm_input=root
				else
					confirm_input=$(dbox --clear --insecure --passwordbox "Re-enter password to verify:" 0 0)
				fi

				if [ -z "$input" ]; then
					errbox "You are not allowed to have an empty password."
				elif [ "$input" != "$confirm_input" ]; then
					errbox "The two passwords you entered did not match."
				else
					root_passwd="$input"
					supswd_match=true
				fi
			done
		fi

		HOST_NAME=$(dbox --nocancel --inputbox "Please enter the hostname for this system.\n\nThe hostname is a single word that identifies your system to the network.\n\nHostname:" 0 0 "ExtOS")
		if say "$HOST_NAME" | grep -Eoq "^[a-zA-Z0-9-]{1,63}$" && [ "${HOST_NAME:0:1}" != "-" ] && [ "${HOST_NAME: -1}" != "-" ]; then
			USR_STAT="*"
			break
		else
			errbox "You entered an invalid hostname.\n\nA valid hostname may contain only the numbers 0-9, upper and lowercase letters (A-Z and a-z), and the minus sign. It must be at most 63 characters long, and may not begin or end with a minus sign."
		fi
	done
}
