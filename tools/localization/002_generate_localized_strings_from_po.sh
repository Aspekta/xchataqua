#!/bin/bash
BASESED='002.sed'
BASELOCALE='en'

for locale in `ls -d po/*.strings`; do
	locale=`basename $locale .strings`
	echo -n $locale
	if [ $BASELOCALE = $locale ]; then
		continue
	fi
	if [ $DEBUG ]; then
		echo "generate $BASESED.$locale..."
	fi
	echo "#!/bin/sed" > $BASESED.$locale
	if [ -e strings/$locale/xib.strings ]; then
		sed -f $BASESED strings/$locale/xib.strings >> $BASESED.$locale
	fi
	sed -f $BASESED po/$locale.strings >> $BASESED.$locale
	if [ ! -e "lproj/$locale" ]; then
		mkdir lproj/$locale
	fi
	for strings in `ls lproj/$BASELOCALE/*.xib.strings`; do
		newstrings=lproj/$locale/`basename $strings`
		if [ $newstrings -nt $strings ]; then
			if [ $newstrings -nt strings/$locale/xib.strings ]; then
				if [ $newstrings -nt po/$locale.strings ]; then
					continue
				fi
			fi
		fi
		cmd="sed -f $BASESED.$locale $strings"
		if [ $DEBUG ]; then
			echo $cmd
		fi
	 	$cmd > $newstrings &
		echo -n .
	done
	echo ""
	wait $!
done
sleep 1
if [ $DEBUG ]; then
	echo "to remove temporary files, 'rm $BASESED.*'"
else
	rm $BASESED.*
fi
#eof
