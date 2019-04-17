# AERCalc Project 
## Overview
A "Project" is a folder containing two things: 
 - a `db` subdirectory with a `.sqlite` file containing product information for use in AERCalc.
 - a `bsdf` subdirectory with bsdf files for each product in the .sqlite database

## Project Structure
### `db` Subdirectory and `.sqlite` Database
The .sqlite database in the `db` subdirectory may have any name, but must have a `.sqlite` extension. It must also
have a valid set of tables and indices expected by AERCalc, including the database version.
 
The database may be an earlier AERCalc database version, in which case the user will be prompted 
to migrate the db when the project is oepened.

### `bsdf` Subdirectory
The `bsdf` subdirectory should have a .bsdf file for each row in the products table in the project's database. 
The bsdf files should have the correct name to match the name of the window, following the rules
defined in AERCalc (e.g. colons are turned into double underscores). The user should not have to modify the names
of the bsdf files, they are created at import time and named accordingly so that they match with the 
imported product row.

## Switching Projects
A user can open a different project by selecting File > Open from the program menu and  then
browsing to a project directory.

## Creating Projects
A user can create a new project by selecting File > Save As from the program  menu and then
browsing to an **empty** directory. The user should give the directory a userful name -- AERCalc will
give that same name to the .sqlite file in the db subdirectory.


## Valdating Projects on Open
When the user selects a new project to open, AERCalc:
- Validates the database exists and is indeed an AERCalc db 
- If the db is an older version, asks the user if they want to migrate it
- Before migrating, stores a backup copy of the db in the same `db` subdirectory
- Once the sqlite db is opened and attached, AERCalc loads the product information in the 
products database and refreshes internal collections and the user interface.
- For any bsdf that doesn't exist, AERCalc :
    - sets a flag that indicates the bsdf file is missing for this product
    - removes any calculated values, forcing a re-simulation of the product
    - displays a warning dialog if any rows were invalidate in this way
    - makes sure that each affected row now has a warning marker in the bsdf column
    

    


