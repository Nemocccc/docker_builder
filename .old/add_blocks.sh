SCRIPT_DIR=$1

echo "${SCRIPT_DIR}" 

read -p "add tag to your block: " tag
while true;
do
	if grep -q "{${tag}" ${SCRIPT_DIR}/blocks.txt;
	then
		echo "the blocks.txt have contains a block tagged $tag."
		read -p "enter again:" tag
	else
		echo "tag is availible"
		break
	fi
done

echo "" >> ${SCRIPT_DIR}/blocks.txt
echo "{$tag" >> ${SCRIPT_DIR}/blocks.txt

while true;
do
	echo "enter commands and stop by crtl + D (need to indent by yourself):"
	commands=$(cat)
	echo "-------------------------------------------------"
	echo "$commands"
	echo "-------------------------------------------------"
	read -p "save it to blocks.txt?(y|N): " save
	if [[ save == 'y' ]];
	then
		echo "$commands" >> ${SCRIPT_DIR}/blocks.txt
		break
	else
		head -n -2 ${SCRIPT_DIR}/blocks.txt > temp_file && mv temp_file ${SCRIPT_DIR}/blocks.txt
		exit 0
	fi
done

echo "}$tag" >> ${SCRIPT_DIR}/blocks.txt
echo "" >> ${SCRIPT_DIR}/blocks.txt
