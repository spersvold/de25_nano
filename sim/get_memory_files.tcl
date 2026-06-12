set NAMESPACE [lindex $argv 1]
set QSYS_SIMDIR [lindex $argv 2]
set memory_files [list]
source $QSYS_SIMDIR/common/vcsmx_files.tcl
set memory_files [concat $memory_files [${NAMESPACE}::get_memory_files "$QSYS_SIMDIR" "$env(QUARTUS_HOME)"]]
foreach file $memory_files { puts "$file" }
exit 0
