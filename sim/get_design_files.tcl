set NAMESPACE [lindex $argv 1]
set QSYS_SIMDIR [lindex $argv 2]
set files [dict create]
source $QSYS_SIMDIR/common/vcsmx_files.tcl
set files [concat $files [${NAMESPACE}::get_design_files "" "" "" "$QSYS_SIMDIR" "$env(QUARTUS_HOME)"]]
set design_files $files
foreach file $design_files {
    # remove unwanted elements from the file list
    set replacements {"vlogan" {} "+v2k" {} "-sverilog" {} "-work" {}}
    set file_r [string map $replacements $file]
    if { [llength $file_r] > 2 } {
        puts [lindex $file_r 0]
        puts [lindex $file_r 1]
    } else {
        puts [lindex $file_r 0]
    }
}
exit 0
