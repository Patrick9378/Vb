#!/bin/zsh
_base="$(grep "^ " $1)"
if [ "$(echo "$_base" | grep -F "B_IF 19/5" )" = "" ]; then
    exit 1
fi
get_offset () {
    echo "$1" | grep -bo "$2" | cut -d ":" -f 1 | head -n 1
}
echo "$_base" | grep -Fno Datum
block_boundaries="$(grep  "^ " 2019-11-25.txt | sed 's/^ //' | grep -n Datum | cut -d ":" -f 1)"
lines="$(echo $block_boundaries | wc -l)"
i=1
until [ $i -gt $lines ]; do
    
    #echo "$_base"
    descriptor="$(echo $_base | sed $(echo "$block_boundaries" | sed ${i}\!d)\!d)"
    datum="$(get_offset "$descriptor" "Datum")"
    tag="$(get_offset "$descriptor" "Tag")"
    stunde="$(get_offset "$descriptor" "Pos")"
    lehrer="$(get_offset "$descriptor" "[^V]Lehrer")"
    fach="$(get_offset "$descriptor" "Fach")"
    raum="$(get_offset "$descriptor" "Raum")"
    mitteilung="$(get_offset "$descriptor" "Mitteilung")"
    lower=$(($(echo $block_boundaries | sed ${i}\!d)+1))
    let i++
    echo "$lines $i"
    if [ $i -gt $lines ]; then
        upper=$(echo $_base | wc -l)
    else
        upper=$(($(echo $block_boundaries | sed ${i}\!d)-1))
    fi
    echo "$lower $upper"
done
