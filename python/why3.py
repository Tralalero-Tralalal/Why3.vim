import re, vim
from dataclasses import dataclass, field
from typing import List, Optional

class UnavailableCommand(Exception):
    pass

class RegexFailure(Exception):
    pass

class FailedToGetData(Exception):
    pass

class NoNodeAvailable(Exception):
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

def grab_selected_goal(s_str):
    # Get selected goal, greedy
    selected_goal_str = re.search(r"\*\*(.*?)\*\*", s_str)
    if not selected_goal_str:
        raise NoNodeAvailable("There is no goal selected")

    # get specific parts of the goal 
    match_name = re.search(r"Goal=(.*),", selected_goal_str.group(0))
    if match_name:
        name = match_name.group(1)
        match_id = re.search(r"id = (\d+)", selected_goal_str.group(0))
        if match_id:
            id = match_id.group(1)
            match_parent = re.search(r"parent=(.*);", selected_goal_str.group(0))
            if match_parent:
                parent = match_parent.group(1)
                return Goal(name, id, parent, []).__dict__
            else:
                raise RegexFailure("Failed to regex parent in selected goal")
        else:
            raise RegexFailure("Failed to regex id in selected  goal")
    else:
        raise RegexFailure("Failed to regex name in selected goal")

def grab_goals(s_str, n=None):
    goals_str = re.findall(r"{[^}]*}", s_str)
    if n is not None:
        num_of_nodes = n + len(goals_str)
        return num_of_nodes
    else:
        goals = []
        for goal in goals_str:
            match_name = re.search(r"Goal=(.*),", goal)
            if match_name:
                name = match_name.group(1)
                match_id = re.search(r"id = (\d+)", goal)
                if match_id:
                    id = match_id.group(1)
                    match_parent = re.search(r"parent=(.*);", goal)
                    if match_parent:
                        parent = match_parent.group(1)
                        goals.append(Goal(name, id, parent, []).__dict__)
                    else:
                        raise RegexFailure("Failed to regex parent in goal")
                else:
                    raise RegexFailure("Failed to regex id in goal")
            else:
                raise RegexFailure("Failed to regex name in goal")
        return goals

def grab_theories(s_str, n=None):
    theories_str = re.findall(r"(Theory\s.*?)(?= Theory|$)", s_str, re.DOTALL)
    if n is not None:
        num_of_nodes = n + len(theories_str)
        return grab_goals(s_str, num_of_nodes)
    else:

        theories = []
        for theory in theories_str:
            name_match = re.search(r"Theory\s+(.*),", theory)
            if name_match:
                name = name_match.group(1)
                id_match = re.search(r"id:\s(\d+)", theory)
                if id_match:
                    id = id_match.group(1)
                    goals = grab_goals(theory)
                    theories.append(Theory(id, name, goals).__dict__)
                else:
                    raise RegexFailure("Failed to regex id in theory")
            else:
                raise RegexFailure("Failed to regex name in theory")
        return theories

def grab_files(s_str, n=None):
    names_match = re.findall(r"File\s(.*?)," , s_str)
    if n is not None:
        num_of_nodes = len(names_match)
        return grab_theories(s_str, num_of_nodes)

    else:# Check if names_match is empty, raise an error if it is
        if not names_match:
            raise RegexFailure("Failed to regex name in file, Check to see whether the regex is valid or the output changed")
        ids_match = re.findall(r"id\s(\d+)" , s_str)
        # Check if ids_match is empty, raise an error if it is
        if not ids_match:
            raise RegexFailure("Failed to regex id in file, Check to see whether the regex is valid or the output changed")
        # Check if the length is equal
        if len(names_match) != len(ids_match):
            raise RegexFailure("Unequality in regex of id and names")
        files = []
        for name_match, id_match in zip(names_match, ids_match):
            files.append(File(id_match, name_match, grab_theories(s_str)).__dict__)
        return files

def grab_session(s_str):
    sess_match = re.search(r"^(\S+)", s_str)
    if sess_match:
        sess = sess_match.group(0)
        try:
            files = grab_files(s_str)
            return Session(sess, files)
        except Exception as e:
            raise FailedToGetData(f"Failed to grab data in session: {e}")
    else:
        raise RegexFailure("Failed to grab session")

#def sel_node_num = 0
#def next_node():
#    sel_node_num++;
#    return "On node: " node_num

def grab_data(s_str):
    regex_type = vim.eval("s:regex_type") 
    match regex_type:
        case "p": 
            try:
                return grab_session(s_str)
            except RegexFailure as e:
                raise FailedToGetData(f"Error regexing data for print: {e}") from e
            except Exception as e:
                raise e
        case "ng":
            try:
               return grab_selected_goal(s_str) 
            except Exception as e:
                raise e
        case "start": 
            return {'start': "session" }
        case "quit":
            return {'quit': 'server'}
        case "initialize":
            num_of_nodes = grab_files(s_str, 0)
            s = "initialized with x nodes: ", num_of_nodes
            return { 'server': s }
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
    except Exception as e:
        print(f"Anomalous error: {e}")
    
