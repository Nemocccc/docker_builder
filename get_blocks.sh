SCRIPT_DIR=$1

read -p "enter tag of target blocks: " tag
if grep -q "{${tag}" ${SCRIPT_DIR}/blocks.txt;
then
	echo "" >> Dockerfile
	awk '
BEGIN { in_block = 0 }
/{tag/ {
    in_block = 1
    next
}
/}tag/ {
    in_block = 0
    next
}
in_block == 1
' ${SCRIPT_DIR}/blocks.txt > Dockerfile
	echo "" >> Dockerfile
else
	echo "missed $tag in blocks.txt"
fi
