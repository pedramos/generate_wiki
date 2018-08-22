#!/bin/bash

###

#USAGE: gerenate_wiki.sh source_dir dest_dir

#NOTES: exclude_dir.lst and template.css should be located in the destination 

###

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
    pandoc --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   "${i}" > "${2}/${file_name}".html;
    
    echo "+ [$clean_name](${file_name}.html)" >> index.md

done

pandoc --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   ${2}/index.md > ${2}/index.html;





