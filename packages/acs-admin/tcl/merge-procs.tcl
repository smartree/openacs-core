ad_library {

    Definitions of procs for the merge process

    @creation-date 15 APR 2005
    @author Enrique Catalan (quio@galileo.edu)
    @cvs-id $Id$

}

namespace eval merge {
    ad_proc -public MergeUserInfo {
	-from_user_id:required
	-to_user_id:required
    } {

	ns_log Notice "Running merge::MergeUserInfo"
	db_transaction {
	    if { ![db_0or1row to_user_portrait {*SQL*}] &&  [db_0or1row from_user_portrait {*SQL*}] } {
		db_dml upd_portrait {*SQL*}
	    } 
	    
	    # get the permissions of the from_user_id
	    # and grant them to the to_user_id
	    db_foreach getfromobjs {*SQL*} {
		# revoke the permissions of from_user_id
		permission::revoke -object_id $from_oid -party_id $from_user_id -privilege $from_priv
		if { ![db_string touserhas {*SQL*} ] } {
		    # grant the permissions to to_user_id
		    permission::grant -object_id $from_oid -party_id $to_user_id -privilege $from_priv
		} 
	    }
	    
	    ns_log notice "  Merging acs_objects"
	    
	    db_dml acs_objs_upd  {*SQL*} 	
	}
	ns_log Notice "Finishing merge::MergeUserInfo"
    }
}

ad_proc -callback MergePackageUser {
    -from_user_id:required
    -to_user_id:required
} {
    Merge two accounts
} -

ad_proc -callback MergeShowUserInfo {
    -user_id:required
} {
    Merge two accounts
} -

