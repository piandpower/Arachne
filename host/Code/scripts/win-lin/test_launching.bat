@echo off

rem Run this BAT-script with two arguments specifying:
rem 1) the number of processes,
rem 2) list of comma-separated cluster node names to run simulation on.

rem Initialize variables
call Code\scripts\win-lin\params.bat

rem Go to 3rd party software directory containing plink.exe
cd %THIRDPARTYDIR%

rem Execute two commands on remote server:
rem 1) go to HPC kernel directory,
rem 2) run helper SH-script to determine whether the number of available cluster nodes is sufficient.
plink -pw %PASSWORD% %LOGIN%@%HEADNODEIP% "cd \"%REMOTESCRIPTSDIR%\"; sh test.sh %1 %2" > nul