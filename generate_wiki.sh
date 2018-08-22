#!/bin/bash

###

#USAGE: gerenate_wiki.sh source_dir dest_dir

#NOTES: exclude_dir.lst and template.css should be located in the destination 

###

if [ -z $1 ]; then
    echo "Usage: ./generate source_dir dest_dir"
    echo "-----"
    echo "This tool converts md files into html files and generates an index.html which links all generated html files. The tool keeps the respects the directories inside the source dir."
    echo "NOTES: Requires pandoc installed to work and the css files must be located in the destination dir"


wiki_dir="$2"
wiki_source="$1"

cmd='find $2 -type f -name "*.md"'

for i in $(cat $1/exclude_dir.lst); do 
    cmd="$cmd -not -path \"$i*\""

done


result=$(eval "$cmd" | sort )

echo "" > index.md
rm -rf ${2}/*.html

for i in $result; do 
    clean_name=$(echo $i | sed 's#\.\./##g' | sed 's/\.md//g')
    file_name=$(echo $i | sed 's#\.\./##g' | sed 's#/#_#g')
    pandoc --css ${2}/template.css -s -S --toc -H ${2}/pandoc.css   "${i}" > "${2}/${file_name}".html;
    
    echo "+ [$clean_name](${file_name}.html)" >> index.md

done

pandoc --css ${2}/template.css -s -S --toc -H ${2}/pandoc.css   ${2}/index.md > ${2}/index.html;





