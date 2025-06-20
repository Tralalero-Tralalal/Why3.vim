import re, vim

class Regex:

    def grab_data_print(s_str):
        theory = {
            'name': [],
            'id': []
        } 
        name_match = re.search("File\\s(.*?)," , s_str)
        if name_match: 
            theory['name'] = [name_match.group(0), name_match.group(1)]
        else:
            print("could not regex name")
        id_match = re.search("id:\\s(\\d+)" , s_str)
        if id_match:
            theory['id'] = [id_match.group(0), id_match.group(1)]
        else: 
            print("could not regex id")
        return theory
