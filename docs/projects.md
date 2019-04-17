#Projects in AERCalc

## Overview
A 'project' in AERCalc is a .sqlite database containing products a user has imported and (perhaps) simulated, and the associated
.idf files for each row that was imported.


## Directory Structure
A project has the following directory structure:

- [project name]
    - db
        - [project name].sqlite
    - bsdf
        - [bdsf file 1]
        - [bsdf file 2]
        - ...
        
        
## Opening a Project
A user opens a new project by selecting File > Open and navigating to the directory for their project.
AERCalc then
- validates that the project has the correct directory structure and files
- loads the database and marks any rows that are missing a bsdf file
- checks the verions of the database and allows user to migrate database or cancel open.

## Saving a Project
AERCalc saves changes as the user makes them, so there is no "Save" menu option at the moment.
However, the user can create a new project from the existing data by selecting File > Save As.
The user then browses to a empty directory, gives that directory a (project) name, and then AERCalc
will create the required subdirectories and files.





        
