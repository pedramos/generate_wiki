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



pages=open("lib/md_files.lst","r")
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
        print "# TAG::::::TITLE #"
        
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
    echo "The file with the ignored dirs must be named exclude_dir.lst and placed into the dest_dir/bin."
    echo "The dirs listed in exclude_dir.lst must be relative to the dest_dir"
    echo "title.txt in the dest_dir stores the wiki title"
    exit
fi

wiki_dir="$(pwd)/$2"
wiki_source="$(pwd)/$1"

mkdir -p "${wiki_dir}/lib"

cp *.css "${wiki_dir}/lib" 2>/dev/null

cd "${wiki_dir}"

cmd="find ${wiki_source} -type f -name \"*.md\""

touch "${wiki_dir}/lib/exclude_dir.lst"

for i in $(cat "${wiki_dir}/lib/exclude_dir.lst"); do 
    cmd="$cmd -not -path \"${wiki_source}/$i*\""
done


result=$(eval "$cmd" | sort )
echo $result | tr '[:blank:]' '\n' | sed "s#${wiki_source}/##g"  > lib/md_files.lst

mkdir -p old/temp

touch lib/pages.lst

IFS=$'\n'
for i in $(cat lib/pages.lst); do mv "${i}" ./old/temp; done
tar -czf "old/$(date '+%Y%m%d_%H%M%S').tar" old/temp/* 2>/dev/null
rm -rf old/temp/* 2>/dev/null

echo "" > lib/legacy_index.md
echo "" > lib/pages.lst.temp

wiki_name=$(echo wiki_dir | sed "s#.*/##g")

#wiki_dir=$(pwd)

for i in $result; do

    
    clean_name=$(echo $i | sed 's#\.\./##g' | sed 's/\.md//g')
    file_name=$(echo $i | sed "s#${wiki_source}/##g" | sed 's#\.\./##g' |  sed 's#/#_#g')
    work_dir=$(dirname "${i}")
    md_file_name=$(basename -- "${i}")


    cd "${work_dir}"
    
    echo "STARTING: ${work_dir}/${md_file_name}"
    pandoc --verbose --self-contained --css "${wiki_dir}/lib/template.css" -s -S --toc -H "${wiki_dir}/lib/pandoc.css"  "${md_file_name}" -o "${file_name}".html && mv "${file_name}.html" "${wiki_dir}"  
    if [ "$(echo $?)" != "0" ]; then
        echo "ERROR: Processing file ${md_file_name} file with the error above"
    else
        echo "OK: ${md_file_name}"
        echo "${wiki_dir}/${file_name}.html" >> "${wiki_dir}/lib/pages.lst.temp"
    fi


    echo "+ [$clean_name](${file_name}.html)" >> "${wiki_dir}/lib/legacy_index.md"
done


cd "${wiki_dir}"; pandoc --self-contained --css "${wiki_dir}/lib/template.css" -s -S --toc -H "${wiki_dir}/lib/pandoc.css"   lib/legacy_index.md -o legacy_index.html;

generate_index > lib/index.md

touch lib/title.txt

title=$(cat lib/title.txt)

sed -i "s/# TAG::::::TITLE #/# ${title}/g" lib/index.md 

#cd "${wiki_dir}"; pandoc --self-contained --css "${wiki_dir}/template.css" -s -S --toc -H "${wiki_dir}/pandoc.css"   index.md -o index.html;


cd "${wiki_dir}"; pandoc --self-contained --css "${wiki_dir}/lib/template.css" -s -S  -H "${wiki_dir}/lib/pandoc.css"   lib/index.md -o index.html;

cat lib/pages.lst.temp > lib/pages.lst
rm -rf lib/pages.lst.temp
rm -rf lib/md_files.lst


