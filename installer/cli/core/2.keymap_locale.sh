#!/bin/bash

keymapc() {
	title="Set the Keyboard Layout"
	while true; do
		KEYMAP=$(dbox --nocancel --default-item "us" --menu "Select a keymap that corresponds to your keyboard layout. Choose 'other' if your keymap is not listed. If you are unsure, the default is 'us' (United States/QWERTY).\n\nKeymap:" 0 0 0 \
			"br-abnt2" "Brazilian Portuguese" \
			"cf" "Canadian-French" \
			"colemak" "Colemak (US)" \
			"dvorak" "Dvorak (US)" \
			"fr-latin1" "French" \
			"de-latin1" "German" \
			"gr" "Greek" \
			"it" "Italian" \
			"hu" "Hungarian" \
			"jp" "Japanese" \
			"pl" "Polish" \
			"pt-latin9" "Portuguese" \
			"ru4" "Russian" \
			"es" "Spanish" \
			"la-latin1" "Spanish Latinoamerican" \
			"sv-latin1" "Swedish" \
			"us" "United States" \
			"uk" "United Kingdom" \
			"other" "View all available keymaps")
		[ "$KEYMAP" = "other" ] || break

		keymaps=()
		for map in $(localectl list-keymaps); do
			keymaps+=("$map" "")
		done

		KEYMAP=$(dbox --cancel-label "Back" --menu "Select a keymap that corresponds to your keyboard layout. The default is 'us' (United States/QWERTY)." 0 0 0 "${keymaps[@]}") && break
	done

	localectl set-keymap "$KEYMAP"
	loadkeys "$KEYMAP"
	KEY_STAT="*"
}

localec() {
	title="Set the System Locale"
	menu_title() { say "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. $* If you are unsure, the default is 'en_US\.UTF-8'\.\\n\\nLocale:"; }

	while true; do
		LOCALE=$(dbox --nocancel --default-item "en_US.UTF-8" --menu "$(menu_title "Choose 'other' if your language and/or region is not listed.") " 0 0 0 \
			"en_AU.UTF-8" "English (Australia)" \
			"en_CA.UTF-8" "English (Canada)" \
			"en_US.UTF-8" "English (United States)" \
			"en_GB.UTF-8" "English (Great Britain)" \
			"fr_FR.UTF-8" "French (France)" \
			"de_DE.UTF-8" "German (Germany)" \
			"it_IT.UTF-8" "Italian (Italy)" \
			"ja_JP.UTF-8" "Japanese (Japan)" \
			"pt_BR.UTF-8" "Portuguese (Brazil)" \
			"pt_PT.UTF-8" "Portuguese (Portugal)" \
			"ru_RU.UTF-8" "Russian (Russia)" \
			"es_MX.UTF-8" "Spanish (Mexico)" \
			"es_ES.UTF-8" "Spanish (Spain)" \
			"sv_SE.UTF-8" "Swedish (Sweden)" \
			"vi_VN.UTF-8" "Vietnamese (Vietnam)" \
			"zh_CN.UTF-8" "Chinese (Simplified)" \
			"other" "View all available locales")
		[ "$LOCALE" = "other" ] || break

		locales=()
		while read -r line; do
			locales+=("$line" "")
		done < <(grep -E "^#?[a-z].*UTF-8" /etc/locale.gen | sed -e 's/#//' -e 's/\s.*$//')

		LOCALE=$(dbox --cancel-label "Back" --menu "$(menu_title)" 0 0 0 "${locales[@]}") && break

	done
	LOC_STAT="*"
}

localtz() {
	utc_enabled=true
	title="Set the Time Zone"
	menu_title() { say "Select your time zone.\n$*\nTime zone:"; }

	regions=()
	for region in $(find "$ZONEINFO_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -E -v '/$|posix|right' | sort); do
		regions+=("$region" "")
	done
	regions+=("other" "")

	while true; do
		ZONE=$(dbox --nocancel --menu "$(menu_title "If your region is not listed, select 'other'.\n")" 0 0 0 "${regions[@]}")

		if [ "$ZONE" = "other" ]; then
			for other_region in $(find "$ZONEINFO_PATH" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | grep -E -v '/$|iso3166.tab|leapseconds|posixrules|tzdata.zi|zone.tab|zone1970.tab' | sort); do
				other_regions+=("$other_region" "")
			done

			ZONE=$(dbox --cancel-label "Back" --menu "$(menu_title "")" 0 0 0 "${other_regions[@]}") && break
		fi

		zone_regions=()
		for zone_region in $(find "$ZONEINFO_PATH"/"${ZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
			zone_regions+=("$zone_region" "")
		done

		SUBZONE=$(dbox --cancel-label "Back" --menu "$(menu_title "")" 0 0 0 "${zone_regions[@]}") || continue

		if [ ! -d "$ZONEINFO_PATH"/"${ZONE}/${SUBZONE}" ]; then
			ZONE="${ZONE}/${SUBZONE}"
			break
		fi

		subzone_regions=()
		for subzone_region in $(find "$ZONEINFO_PATH"/"${ZONE}/${SUBZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
			subzone_regions+=("$subzone_region" "")
		done

		SUBZONE_SUBREGION=$(dbox --cancel-label "Back" --menu "$(menu_title "")" 0 0 0 "${subzone_regions[@]}") &&
			ZONE="${ZONE}/${SUBZONE}/${SUBZONE_SUBREGION}" &&
			break
	done
	title="Set the Hardware Clock"
	dbox --nocancel --yesno "Would you like to set the hardware clock from the system clock using UTC time?\nIf you select no, local time will be used instead.\n\nIf you are unsure, UTC time is the default." 0 0 || utc_enabled=false

	TZC_STAT="*"
}
