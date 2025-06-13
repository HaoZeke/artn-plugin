# README py_metropolis

This python script runs a ARTn search following a metropolis schedule based either on the  energy difference between the final and the initial structures (that is how the standard ARTn works) or on the barriers. 

All parameters are defined in the main script `art_metropolis.py`. 

In addition to the standard parameters that can be found in the manuel. A few additional parameters can be set:

```
TEMPERATURE = 0.3        # Temperature is  in eV
NUMBER_EVENTS = 20       # Maximum number of succesfull event
ACCEPT_CHECK= "fin-ini"  # Can be either "fin-ini" -energy asymmetry- or "sad-ini"
REVERSIBLE   = True      # If True, check whether the event is reversible with MAX_DELR_INI
MAX_DELR_INI = 0.1       # Maximum displacement when returning to initial minimum

# files
filecounter = "filecounter"  # Counter for numbering files and events
refconfig = "refconfig"      # reference configuration from which events are started
file_format = 'lammps'       # Input/Output style : either 'lammps' or 'xyz'
```


Questions: Normand Mousseau  - normand.mousseau@Umontreal.ca