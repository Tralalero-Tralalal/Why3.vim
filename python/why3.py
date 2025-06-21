import re, vim
from dataclasses import dataclass, field
from typing import List, Optional

class UnavailableCommand(Exception):
    pass

class RegexFailure(Exception):
    pass

class FailedToGetData(Exception):
    pass

@dataclass
class Goal:
    Name: str
    id: int
    parent: str
    Status: List[str] 

@dataclass
class Theory:
    id: int
    name: str
    Goals: List[Goal] = field(default_factory=list) 

@dataclass
class File:
    id: int
    name: str
    Theories: List[Theory] = field(default_factory=list) 

@dataclass
class Session:
    sess_name: str
    Files: List[File] = field(default_factory=list) 

# regex for selected node. gets everything between ** **, not greedy
# \*\*(.*?)\*\*   \gs global singeline
#
# regex for goals. gets everything between {}, greedy
# \{[^}]*\}       \gs global singeline
#
# regex for first word
# ^(\S+)
#
# regex for file name
# File\s(.*),
#
# regex for file ID
# id\s\d+
#
# regex for Theory name
# Theory\s+(.*),
#
# regex for Theory ID
# \vid:\s\d+
#
# SUB REGEXES
#
# Get goal name from Goal
# Goal=(.*),
#
# Get ID of Goal
# id = (\d+)
#
# Get parent name of Goal
# parent=(.*);
#
# Get data about goal. It'll be a list of 2, the provenness is in the first
# element, while unknown data is in the 2nd
# \[.*?\]
#
# root  File hello.why, id 1;
#     [ Theory HelloProof, id: 2;
#       [{ Goal=G1, id = 3; parent=HelloProof; [] [] };
#       { Goal=G2, id = 4; parent=HelloProof; [] [] };
#       { Goal=G3, id = 5; parent=HelloProof; [] [] };
#       { Goal=G4, id = 6; parent=HelloProof; [] [] }]];

def grab_theories(s_str):
    names_match = re.findall(r"Theory\s(.*),", s_str)
    ids_match = re.findall(r"id:\s(\d+)", s_str)
    theories = []
    for name, id in zip(names_match, ids_match):
        theories.append(Theory(id, name, []).__dict__)
    return theories

def grab_goals(s_str):
    goals_str = re.findall("{[^}]*}", s_str)
    goals = []
    for goal in goals_str:
        match_name = re.search("Goal=(.*),", goal)
        match_id = re.search(r"id = (\d+)", goal)
        match_parent = re.search(r"parent=(.*);", goal)
        if match_name:
            name = match_name.group(1)
        if match_id:
            id = match_id.group(1)
        if match_parent:
            parent = match_parent.group(1)
        goals.append(Goal(name, id, parent, []).__dict__)
    return goals

def grab_files(s_str):
    names_match = re.findall(r"File\s(.*?)," , s_str)
    # Check if names_match is empty, raise an error if it is
    if not names_match:
        raise RegexFailure("Failed to regex names, Check to see whether the regex is valid or the output changed")
    ids_match = re.findall(r"id\s(\d+)" , s_str)
    # Check if ids_match is empty, raise an error if it is
    if not ids_match:
        raise RegexFailure("Failed to regex ids, Check to see whether the regex is valid or the output changed")
    # Check if the length is equal
    if length(names_match) == length(ids_match):
        raise RegexFailure("Unequality in regex of id and names")
    files = []
    for name_match, id_match in zip(names_match, ids_match):
        files.append(File(id_match, name_match, []).__dict__)
    return files

def grab_data(s_str):
    regex_type = vim.eval("s:regex_type") 
    match regex_type:
        case "p": 
            try:
                return grab_theories(s_str)
            except RegexFailure as e:
                raise FailedToGetData(f"Error regexing data for print: {e}") from e
            except Exception as e:
                raise FailedToGetData(f"Anomalous error in getting file data: {type(e).__name__}: {e}")
        case "g":
            return grab_goals(s_str)
        case "start": 
            return {'start': 'server'}
        case "quit":
            return {'quit': 'server'}
        case _:
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
    
