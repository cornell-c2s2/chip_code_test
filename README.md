# chip_code_test
This is a repository for running multi-file C/C++ programs in OpenLANE. This is meant to be run within a [Caravel User Project](https://github.com/efabless/caravel_user_project) structure

## Setup
 - Navigate to your test directory within your Caravel User Project and clone the repository
 ```bash
  % cd <CARAVEL_DIR>/verilog/dv
  % git clone git@github.com:cornellcustomsiliconsystems/chip_code_test.git
 ```
  - Navigate into the directory, and rename it using `rename` and the references in files to your desired name
    - You will need to re-enter the directory to see the change on your terminal prompt
    
```bash
 % cd chip_code_test
 % ./rename <new_name>
 % cd ..
 % cd <new_name>
 ```
 
 ## Using the test directory
 
 Your C/C++ code should go in `<new_name>.c`; this should be the code that has `main`. In addition, any source files you wish to use (along with their header files) should go in `src`
  - The directory includes `utils.h`, which contains several helper functions for testing and printing with the current test harness setup
  
## Building

The test harness is meant to integrate seamlessly with OpenLane. Simply follow their documentation for running tests. For example:
```bash
 % cd <CARAVEL_DIR>
 % make verify-<new_name>-rtl
```
 
