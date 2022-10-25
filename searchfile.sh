read -p "Enter folder path: " folder
if [ -e "$folder" ]
then
	cd $folder
	read -p "Enter file name: " fname
	if [ -e "$fname" ]
	then
		read -p "Enter specific word: " w
		c=$(grep -o "$w" "./$fname" | wc -l)
		echo -ne '\n'"$w appears in $c times in $folder/$fname"'\n'
	else
		echo "File does not exist"
	fi
else
	echo "Folder does not exist"
fi
