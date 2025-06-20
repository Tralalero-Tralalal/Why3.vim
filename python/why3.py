import re, vim

class UnavailableCommand(Exception):
    pass

class RegexFailure(Exception):
    pass

class FailedToGetData(Exception):
    pass

def grab_data_print(s_str):
    theory = {
        'name': "",
        'id': "" 
    } 
    name_match = re.search("File\\s(.*?)," , s_str)
    if name_match: 
        theory['name'] = name_match.group(1)
    else:
        raise RegexFailure("Failed to regex name")
    id_match = re.search("id:\\s(\\d+)" , s_str)
    if id_match:
        theory['id'] = id_match.group(1)
    else: 
        raise RegexFailure("Failed to regex id")
    return theory

def grab_data(s_str):
    regex_type = vim.eval("s:regex_type") 
    if regex_type == "p":
        try:
            return grab_data_print(s_str)
        except RegexFailure as e:
            raise FailedToGetData(f"Error regexing data for print: {e}") from e
        except:
            raise FailedToGetData("Anomalous error in getting data from print")
    elif regex_type == "start":
        return {'start': 'server'}
    else:
        raise UnavailableCommand("Command is not available")

def On_Ev(s_str):
    try:
        new_data = grab_data(s_str)
        print(new_data)
    except UnavailableCommand as e:
        print(f"COMMAND ERROR: {e}")
    except FailedToGetData as e:
        print(f"REQ ERROR: {e}")
    except:
        print("Anomalous error")
    
