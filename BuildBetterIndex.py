#!/usr/bin/python2 -O

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


#for i in section_list.values():
#    print i.get_level()
#    print "section name"+i.get_section_name()
#    print "childs:"
#    print i.get_child_section()
#    #print j
#    print "============="
#    None


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
