#!/bin/bash


###

#USAGE: gerenate_wiki.sh source_dir dest_dir

#NOTES: exclude_dir.lst and template.css should be located in the destination 

###
function generate_index {
	python - <<END

"""
Python source code - replace this with a description of the code and write the code below this text.
"""

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import pdb
import re

##### Section Class#####
#This Class should contain the information of each section of the wiki
#
#The parent_section and child_section are not the sections names.
#They are an id generated from the position in the tree (directories separated by ':'
############################
class section:
    section_name=""
    child_section=[]
    parent_section=""
    level=0
    visible=False
    filename=''    
    def __init__(self,section_name,parent_section,level,visible):
        self.section_name=section_name
        self.parent_section=parent_section
        self.visible=visible
        self.level=level
        self.child_section=[]
    
    def set_filename(self,filename):
        self.filename=filename

    def get_filename(self):
        return self.filename

    def get_level(self):
        return self.level

    def set_child_section(self,child):
        if child not in self.child_section:
            self.child_section.append(child)
    
    def get_child_section(self):
        return self.child_section

    def set_visible(self,state):
        self.visible=state

    def get_visible(self):
        return self.visible
    
    def get_parent_section(self):
        return self.parent_section
    
    def get_section_name(self):
        return self.section_name
    
    def get_md_link(self):
        doc_name=re.sub("^([0-9]*-)","",self.section_name)
        doc_name=re.sub("\.md$","",doc_name)
        link_name=re.sub("\.md$",".md.html",self.filename.replace('/','_'))
        return "["+doc_name+"]("+link_name+")"

    def get_clean_section_name(self):
        return re.sub("^([0-9]*-)","",self.section_name)
        


def set_visible_parents(section,list):
    for i in list:
        None
    while list[section].get_section_name()!="/":
        list[section].set_visible(True)
        section=list[section].get_parent_section()
        #pdb.set_trace()



pages=open("md_files.lst","r")
section_list={}
section_list["/"]=section("/",None,0,True)

for i in pages:
    
    ##Line clean up. Remove ../ and \n
    ##line will be used for the filename and to generate the sections
    line=filter(None,i.replace("../","").replace("\n",""))
    
    sections=line.split('/')
    level=1
    for j in sections:

        #creating ID
        id=':'.join(sections[:level])

        if level==1:
            #insert into list of known sections unless it is there already
            if id not in section_list:
                section_list[id]=section(j,"/",level,False)    
            #add himself to parent's list of child pages
            section_list["/"].set_child_section(j)

        elif level==len(sections): #This means it is a document and not just a section
            parent_id=':'.join(sections[:level-1])
            
            #insert into list of known sections unless it is there already
            if id not in section_list:
                section_list[id]=section(j,parent_id,level,True)
            
            #Adding the filename to the 
            section_list[id].set_filename(line)
            
            #add himself to parent's list of child pages
            section_list[parent_id].set_child_section(id)
            
            #since it is a document, set parent pages to visible
            set_visible_parents(id,section_list)
        
        else: #It is a normal section
            parent_id=':'.join(sections[:level-1])
            if id not in section_list:
                section_list[id]=section(j,parent_id,level,False)
            section_list[parent_id].set_child_section(id)
        level=level+1



def print_tree(section,list):
    if section.get_section_name()=="/":
        print "#Nokia DevOps Wiki Index"
        
    elif len(section.get_child_section())==0:
        print "\t"*(section.get_level()-1)+'1. '+section.get_md_link() 
    else:
        print "\t"*(section.get_level()-1)+'1. **'+section.get_clean_section_name()+"**"
    for i in section.get_child_section():
        print_tree(list[i],section_list)
    

print_tree(section_list["/"],section_list)
END
}

#==================================
#           MAIN                
#==================================

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

touch "${wiki_source}/exclude_dir.lst"

for i in $(cat "${wiki_source}/exclude_dir.lst"); do 
    cmd="$cmd -not -path \"$i*\""

done


result=$(eval "$cmd" | sort )
echo $result | tr '[:blank:]' '\n'  > md_files.lst

mkdir -p old/temp

IFS=$'\n'
for i in $(cat pages.lst); do mv "${i}" ./old/temp; done
tar -czf "old/$(date '+%Y%m%d_%H%M%S').tar" old/temp/*
rm -rf old/temp/*

echo "" legacy_index.md
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

    pandoc --verbose --self-contained --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css  "${md_file_name}" -o "${file_name}".html && mv "${file_name}.html" "${current_dir}" 
    echo "${current_dir}/${file_name}.html" >> "${current_dir}/pages.lst.temp"


    echo "+ [$clean_name](${file_name}.html)" >> "${current_dir}/legacy_index.md"
done


cd "${current_dir}"; pandoc --self-contained --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   legacy_index.md -o legacy_index.html;

python BuildBetterIndex.py > index.md


cd "${current_dir}"; pandoc --self-contained --css ~/.markdown/template.css -s -S --toc -H ~/.markdown/pandoc.css   index.md -o index.html;

cat pages.lst.temp > pages.lst
rm -rf pages.lst.temp
rm -rf md_files.lst


