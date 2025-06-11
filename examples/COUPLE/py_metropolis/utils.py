import lammps
import random 
import numpy as np
import pypARTn2
import os
import sys

# Extracts the count from the file "filecounter"
def get_counter(filename: str) -> int:
# Open the file in read mode with UTF-8 encoding
 
    if os.path.exists(filename):
        file = open(filename, 'r', encoding='utf-8')
        first_line = file.readline().strip()

        # Split the line into tokens based on whitespace
        tokens = first_line.split()
        if len(tokens) < 2:
            raise ValueError("The first line must contain at least two elements.")

        # Attempt to convert the second token to an integer
        try:
            return int(tokens[1])
        except ValueError:
            raise ValueError(f"Cannot convert '{tokens[1]}' to an integer.")
    else :
        counter = 999
        return update_counter(counter,filename)
        

# Updates the counter and the corresponding file
def update_counter(counter:int, filename:str)->int:
    counter = counter + 1
    file = open(filename,'w',encoding='utf-8')
    file.write(f"counter: {counter}")
    file.close()
    return counter

# Reads the configuration file in an xyz format
def read_configuration(filename:str, num_atoms:int) :

    atom_id = np.zeros(num_atoms, dtype=int)
    pos = np.zeros((num_atoms,3),dtype=float)

    with open(filename, 'r', encoding='utf-8') as file:
         
        # Read run_id
        tokens  = file.readline().strip().split()
        if len(tokens) < 2:
            raise ValueError("The first line must contain at least two elements.")
        run_id = int(tokens[1])

        # Get energy
        tokens = file.readline().strip().split()
        if len(tokens) < 2:
            raise ValueError("The second line must contain at least two elements.")
        energy = float(tokens[1])

        # Get box
        tokens  = file.readline().strip().split()
        if len(tokens) < 4:
            raise ValueError("The third line must contain at least four elements.")
        box_type = tokens[0]
        box = np.zeros(3,dtype=float)
        box = [float(tokens[1]), float(tokens[2]), float(tokens[3])]
    
        for i in range(num_atoms) :
            tokens = file.readline().strip().split()
            if len(tokens) < 4:
                raise ValueError("Line must contain four elements.")
            atom_id[i] = int(tokens[0])
            pos[i][0] = float(tokens[1])
            pos[i][1] = float(tokens[2]) 
            pos[i][2] = float(tokens[3]) 

    return run_id, box, atom_id, pos,energy         

# Writes init configuration if it does not exist
def write_init_configuration(counter,name, pos, num_atoms,atom_id, energy,box) :
    filename =  f"{name}{counter}"

    if os.path.exists(filename) == False:
        filename = write_configuration_name(filename,counter, pos, num_atoms,atom_id, energy,box)
    else :
         print("File exists, we continue :", os.path.exists(filename))
    return filename

# Writes configurations according to the counter name
def write_configuration(counter,name, pos, num_atoms,atom_id, energy,box) :
    filename =  f"{name}{counter}"

    if os.path.exists(filename) == False:
        filename = write_configuration_name(filename,counter, pos, num_atoms,atom_id, energy,box)
    else :
         print("File exists, we must stop :", os.path.exists(filename))
         sys.exit(1)
    return filename



# Writes a configuration in the filename file
def write_configuration_name(filename,counter, pos, num_atoms,atom_id, energy,box):
    print("Writing to: ", filename)
    file = open(filename, "w")
    file.write(f"run_id:  {counter}\n" )
    file.write(f"total_energy:   {energy}\n")
    file.write(f"P {box[0]}  {box[1]}  {box[2]}\n")
    for i in range(num_atoms) :
        x = pos[i][0]
        y = pos[i][1]
        z = pos[i][2]
        file.write(f"{atom_id[i]} {x}  {y}  {z} ")

    file.close()
    return filename

# Creates the filecounter file with header
def create_event_list() :
    filename = "eventlist" 

    if os.path.exists(filename) == False:
     file = open(filename, "x")
     file.write(" Init          Sad          Fin       Status    Barrier  Displacement   Random\n")
     file.write(" **********   ************ *******  *********  ********* ************   ***********\n")
     file.close()