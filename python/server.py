import sys
import subprocess
import os

print(f"Python's current working directory: {os.getcwd()}")

def run_why3():
    command = ["./why3.opt"]
    subprocess.run(command, True)
    print("hello world")

run_why3()
