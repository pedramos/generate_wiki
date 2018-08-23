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
    exit
fi

wiki_dir="$2"
wiki_source="$1"

cd "${wiki_dir}"

cmd="find ${1} -type f -name \"*.md\""

for i in $(cat "${wiki_source}/exclude_dir.lst"); do 
    cmd="$cmd -not -path \"$i*\""

done


result=$(eval "$cmd" | sort )

mkdir old
mkdir old/temp
IFS=$'\n'
for i in $(cat pages.lst); do mv "${i}" ./old/temp; done
tar -czvf "old/$(date '+%Y%m%d_%H%M%S').tar" old/temp/*


echo "" > index.md
echo "" > pages.lst.temp




current_dir=$(pwd)

for i in $result; do 
    clean_name=$(echo $i | sed 's#\.\./##g' | sed 's/\.md//g')
    file_name=$(echo $i | sed 's#\.\./##g' | sed 's#/#_#g')
    work_dir="${current_dir}/$(dirname $i)"
    md_file_name=$(basename -- "${i}")


    #echo cd "${work_dir}" \&\& pandoc --verbose  --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   "${md_file_name}" -o "${current_dir}/${file_name}".html
    cd "${work_dir}"
    
    for j in $(egrep  "\!\[.*\]" "${md_file_name}" | awk -F'[\(\)]' '{print $2}' 2>/dev/null ); do
        image_dir="${current_dir}/$(dirname "${j}")"
        mkdir -p "${image_dir}"
        cp "${j}" "${image_dir}/"
        echo "${image_dir}" >> "${current_dir}/pages.lst.temp"
    done

    pandoc --verbose  --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css  "${md_file_name}" -o "${file_name}".html && mv "${file_name}.html" "${current_dir}" 
    echo "${current_dir}/${file_name}.html" >> "${current_dir}/pages.lst.temp"


    echo "+ [$clean_name](${file_name}.html)" >> "${current_dir}/index.md"
done


cd "${current_dir}"; pandoc --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   index.md -o index.html;


cat pages.lst.temp > pages.lst
rm -rf pages.lst.temp


