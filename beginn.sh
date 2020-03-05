#!/bin/zsh
if [ -z "$XDG_CONFIG_HOME" ]; then
	XDG_CONFIG_HOME="$HOME/.config"
fi
confdir="$XDG_CONFIG_HOME"/Vertretungsplan24bot
config="$confdir"/config
if [ ! -d "$confdir" ]; then
	mkdir -p "$confdir"
fi
if [ ! -s "$config" ]; then
	cat << EOF
Config file doesn't exist, please create it with the following structure:

$config:
Classdescription
HTTP User
HTTP Password
Telegram Chat
Telegram Token

EOF
	exit 1
fi
class="$(sed '1!d' "$config")"
user="$(sed '2!d' "$config")"
password="$(sed '3!d' "$config")"
chat="$(sed '4!d' "$config")"
token="$(sed '5!d' "$config")"
_base="$(grep "^ " $1)"
if [ "$(echo "$_base" | grep -F "$class" )" = "" ]; then
	exit 1
fi
get_offset () {
	echo "$1" | grep -bo "$2" | cut -d ":" -f 1 | head -n 1
}
#echo "$_base" | grep -Fno Datum #DEBUG
block_boundaries="$(echo "$_base" | grep -n Datum | cut -d ":" -f 1)"
lines="$(echo $block_boundaries | wc -l)"
i=1
until [ $i -gt $lines ]; do
    
	#echo "$_base" #DEBUG
	#echo "Schleife" #DEBUG
	descriptor="$(echo $_base | sed $(echo "$block_boundaries" | sed ${i}\!d)\!d)"
	off_datum="$(get_offset "$descriptor" "Datum")"
	off_tag="$(get_offset "$descriptor" "Tag")"
	off_stunde="$(get_offset "$descriptor" "Pos")"
	off_lehrer="$(get_offset "$descriptor" "[^V]Lehrer")"
	off_fach="$(get_offset "$descriptor" "Fach")"
	off_raum="$(get_offset "$descriptor" "Raum")"
	off_klasse="$(get_offset "$descriptor" "Klasse")"
	off_mitteilung="$(get_offset "$descriptor" "Mitteilung")"
	off_vlehrer="$(get_offset "$descriptor" "VLehrer")"
	lower=$(($(echo $block_boundaries | sed ${i}\!d)+1))
	let i++
	#echo "$lines $i" #DEBUG
	if [ $i -gt $lines ]; then
		upper=$(echo $_base | wc -l)
	else
		upper=$(($(echo $block_boundaries | sed ${i}\!d)-1))
	fi
	#echo "lower: $lower upper: $upper" #DEBUG
	datum="$(echo "$_base" | sed ${lower}\!d | grep -Eo "([0-9]{2}\.){2}[0-9]{4}")"
	#echo "$datum" #DEBUG
	if [ "$(echo "$_base" | sed -n "${lower},${upper}p" | grep -F "$class")" != "" ]; then
		#echo "Hier sind wir" #DEBUG
		tag="$(echo "$_base" | sed ${lower}\!d | head -c "$off_stunde" | tail -c +"$off_tag" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
		echo "Datum: $datum"
		echo "Tag: $tag"
		while [ $lower -le $upper ]; do
			stunde="$(echo "$_base" | sed ${lower}\!d | head -c "$off_lehrer" | tail -c +"$off_stunde" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
			if [ "$(echo $stunde | grep "[2468]")" = "" ]; then
				lehrer="$(echo "$_base" | sed ${lower}\!d | head -c "$off_fach" | tail -c +"$off_lehrer" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
				fach="$(echo "$_base" | sed ${lower}\!d | head -c "$off_raum" | tail -c +"$off_fach" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
				raum="$(echo "$_base" | sed ${lower}\!d | head -c "$off_klasse" | tail -c +"$off_raum" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
				mitteilung="$(echo "$_base" | sed ${lower}\!d | head -c "$off_vlehrer" | tail -c +"$off_mitteilung" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g')"
				if [ "$stunde" != "" ]; then
					echo "Stunde: $stunde"
				fi
				if [ -n "$lehrer" ]; then
					echo "Lehrer: $lehrer"
				fi
				if [ -n "$fach" ]; then
					echo "Fach: $fach"
				fi
				if [ -n "$raum" ]; then
					echo "Raum: $raum"
				fi
				if [ -n "$mitteilung" ]; then
					echo "Mitteilung: $mitteilung"
				fi
			fi
			let lower++
		done
	fi
done
