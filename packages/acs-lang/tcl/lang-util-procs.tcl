#/packages/acs-lang/tcl/lang-util-procs.tcl
ad_library {

    Utility routines for translating pages. Many of these procs deal with
    message keys embedded in strings with the #key# or the <#key text#> syntax.
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::util {

    ad_proc -public lang_sort {
        field 
        {locale {}}
    } { 
        Each locale can have a different alphabetical sort order. You can test
        this proc with the following data:
        <pre>
        insert into lang_testsort values ('lama');
        insert into lang_testsort values ('lhasa');
        insert into lang_testsort values ('llama');
        insert into lang_testsort values ('lzim');  
        </pre>
    
        @author Jeff Davis (davis@arsdigita.com)
    
        @param field       Name of Oracle column
        @param locale      Locale for sorting. 
                           If locale is unspecified just return the column name
        @return Language aware version of field for Oracle <em>ORDER BY</em> clause.
    
    } {
        # Use west european for english since I think that will fold 
        # cedilla etc into reasonable values...
        set lang(en) "XWest_european"
        set lang(de) "XGerman_din"
        set lang(fr) "XFrench" 
        set lang(es) "XSpanish" 
        
        if { [empty_string_p $locale] || ![info exists lang($locale)] } {
            return $field
        } else { 
            return "NLSSORT($field,'NLS_SORT = $lang($locale)')"
        }
    }

    ad_proc -private get_hash_indices { multilingual_string } {
        Returns a list of two element lists containing 
        the start and end indices of a #message_key# match in the multilingual string.
        This proc is used by the localize proc.
    
        @author Peter marklund (peter@collaboraid.biz)
    } {

        set regexp_pattern {(?:^|[^\\])(\#[-a-zA-Z0-9_:\.]+\#)}
        return [get_regexp_indices $multilingual_string $regexp_pattern]
    }

    ad_proc get_adp_message_regexp_pattern {} {
        The regexp expression used by proc get_adp_message_indices and elsewhere
        to extract temporary message catalog tags (<#...#>) from adp templates.
        The first sub match of the expression is the whole tag, the second sub match
        is the message key, and the third sub match is the message text in en_US locale.

        @author Peter marklund (peter@collaboraid.biz)
    } {
        return {(<#\s*?([-a-zA-Z0-9_:\.]+)\s+([^<]+)#>)}
    }

    ad_proc get_adp_message_indices { adp_file_string } {
        Given the contents of an adp file return the indices of the
        start and end chars of embedded message keys on the syntax:
    
        <#package_key.message_key Some en_US text#>    
    
        @author Peter marklund (peter@collaboraid.biz)    
    } {
        return [lang::util::get_regexp_indices $adp_file_string [get_adp_message_regexp_pattern]]
    }
        
    ad_proc -private get_regexp_indices { multilingual_string regexp_pattern } {
        Returns a list of two element lists containing 
        the start and end indices of what is captured by the first parenthesis in the
        given regexp pattern in the multilingual string. The
        regexp pattern must follow the syntax of the expression argument to the TCL regexp command.
        It must also contain exactly one capturing parenthesis for the pieces of text that indices
        are to be returned for.

        @see get_hash_indices
    
        @author Peter marklund (peter@collaboraid.biz)
    } {
    
        set multilingual_string_offset "0"
        set offset_string $multilingual_string
        set indices_list [list]

        while { [regexp -indices $regexp_pattern $offset_string full_match_idx key_match_idx] } { 
            
            set start_idx [lindex $key_match_idx 0]
            set end_idx [lindex $key_match_idx 1]

            lappend indices_list [list [expr $multilingual_string_offset + $start_idx] \
                    [expr $multilingual_string_offset + $end_idx]]
            
            set new_offset [expr $end_idx + 1]
            set multilingual_string_offset [expr $multilingual_string_offset + $new_offset]
            set offset_string [string range $offset_string $new_offset end]
        }
        
        return $indices_list
    }    

    ad_proc extract_keys_from_adps { adp_files } {
        Modify the given adp templates by replacing occurencies of
    
        <#package_key.message_key Some en_US text#>
    
        with #package_key.message_key# and create entries in the file
        $package_root/catalog/$package_key.en_US.iso-8859-1.cat for
        each of these keys.
    
        @author Peter marklund (peter@collaboraid.biz)
    } {
    
        # First open the catalog file of the package to add new message keys to
        if { [llength $adp_files] > 0 } {
            set adp_file [lindex $adp_files 0]
    
            # Open the corresponding catalog file of the package for writing
            # Create the catalog directory if it doesn't exist
            regexp {^packages/([^/]+)} $adp_file full_match package_key
            set catalog_dir "[acs_root_dir]/packages/$package_key/catalog"
            if { ![file isdirectory $catalog_dir] } {
                ns_log Notice "lang_extract_keys_from_adps: Creating new catalog directory $catalog_dir"
                file mkdir $catalog_dir
            }
            set catalog_file_path "$catalog_dir/$package_key.en_US.iso-8859-1.cat"
            ns_log Notice "lang_extract_keys_from_adps: opening catalog file $catalog_file_path for writing"
            set catalog_file_id [open "$catalog_file_path" a+]
            # The file may not end in a new line so add one
            puts $catalog_file_id "\n"
        } else {
            # No files to process so return
            return
        }

        # Use the original catalog file contents to determine if a key should
        # be added to the catalog file or not
        set original_catalog_file_contents [read $catalog_file_id]

        # Keep track of the messages added to the catalog file
        array set added_catalog_messages {}

        # Loop over and process the adp files
        foreach adp_file $adp_files {            

            # We keep track of when we've written to the catalog file to be able
            # to add a comment for each adp
            set has_written_to_catalog_file_p "0"

            set full_adp_path "[acs_root_dir]/$adp_file"
            ns_log Notice "processing adp file $full_adp_path"
    
            # Make a backup of the adp file first
            # Do not overwrite old backup files
            if { [catch "file copy $full_adp_path \"${full_adp_path}.orig\"" errmsg] } {
                ns_log Warning "The file $full_adp_path could not be backed up before message key extraction since backup file ${full_adp_path}.orig already exists"
            }
    
            # Read the contents of the adp file
            set file_contents [template::util::read_file $full_adp_path]
            set modified_file_contents $file_contents
    
            # Loop over each message tag in the adp
            # Get the indices of the first and last char of the <#...#> text snippets
            set message_key_indices [lang::util::get_adp_message_indices $file_contents]
            foreach index_pair $message_key_indices {

                set tag_start_idx [lindex $index_pair 0]
                set tag_end_idx [lindex $index_pair 1]
                set message_tag "[string range $file_contents $tag_start_idx $tag_end_idx]"
                
                # Extract the message key and the text from the message tag
                # The regexp on the message tag string should never fail as the message tag
                # was extracted with a known regexp
                if { ![regexp [lang::util::get_adp_message_regexp_pattern] $message_tag full_match message_tag message_key new_en_us_text] } {
                    ns_log Error "Internal programming error: could not extract message key and text from the message tag $message_tag in file $adp_file. This means there is a mismatch with the regexp that extracted the message key."
                    continue
                }

                # If the message key doesn't contain the package key prefix then add such a prefix
                if { ![regexp {\.} $message_key match] } {
                    set message_key "${package_key}.${message_key}"
                }

                # Make the key unique so that we can add it to the catalog file
                set message_key_to_add [get_unique_key_to_add_to_catalog_file $original_catalog_file_contents [array get added_catalog_messages] $message_key $new_en_us_text]
                if { ![empty_string_p $message_key_to_add] } {
                    if { ![string equal $message_key_to_add $message_key] } {
                        # The message key had to be changed to be made unique
                        ns_log Warning "The message key $message_key was changed to $message_key_to_add to be made unique. If the value was mistyped and should have been the same as previously then you must manually remove the entry for $message_key_to_add from the catalog file and change the key in the adp $adp_file fom $message_key_to_add to $message_key"
                    }

                    set message_key $message_key_to_add
                    ns_log Notice "adding message key $message_key to catalog file"

                    if { !$has_written_to_catalog_file_p } {
                        # Show which template the keys are for
                        puts $catalog_file_id "# $adp_file"
                    }

                    puts $catalog_file_id "_mr en_US $message_key \{${new_en_us_text}\}"                    
                    set added_catalog_messages($message_key) "$new_en_us_text"
                    set has_written_to_catalog_file_p "1"
                }  else {
                    ns_log Notice "message key $message_key already exists in catalog file with same value, not adding"
                }             

                # Insert new or update existing message key
                lang::message::register "en_US" $message_key $new_en_us_text
    
    
                # Replace the message tag with the message key
                regsub [lang::util::get_adp_message_regexp_pattern] $modified_file_contents "#${message_key}#" modified_file_contents
            }
    
            # Update the adp with the replaced message keys
            set adp_file_id [open $full_adp_path w]
            puts $adp_file_id "$modified_file_contents"
            close $adp_file_id
        }    

        # Close the catalog file
        if { [info exists catalog_file_id] } {
            close $catalog_file_id
        }
    }   

    ad_proc -private get_unique_key_to_add_to_catalog_file {
        original_catalog_file_contents
        added_catalog_messages
        message_key
        new_en_us_text
    } {
        Returns a unique message key that can be added to the given catalog file
        contents. If the message key is already in the file with the same value then
        an empty string is returned indicating that no insertion is needed. If the
        key already exists in the file with a different value then the key returned
        will have an integer appended to it to make it unique.

        @author Peter marklund (peter@collaboraid.biz)
    } {

        # Get any existing message from original catalog file
        regexp "_mr\\s+\\S+\\s+${message_key}\\s+\{(\[^\}\]+)\}" $original_catalog_file_contents match existing_en_us_text
        
        # See if we already inserted the message
        array set added_messages_array $added_catalog_messages 
        if { ![info exists existing_en_us_text] } {
            set existing_en_us_text [lindex [array get added_messages_array $message_key] 1]
        }

        if { [info exists existing_en_us_text] && ![empty_string_p $existing_en_us_text] } {

            # The key already exists in the catalog file, check if the values are the same
            if { [string equal $new_en_us_text $existing_en_us_text] } {
                # Value is the same, no need to change the catalog file
                set add_key_to_catalog_file_p "0"
            } else {
                # Value is different. Assume that the new text is correct but that the
                # key needs to be changed to be unique                    
                set unique_message_key "${message_key}_2"

                set message_key_to_add [get_unique_key_to_add_to_catalog_file $original_catalog_file_contents [array get added_messages_array] $unique_message_key $new_en_us_text]
                
                return $message_key_to_add
            }

        } else {
            # The message key is not already in the catalog file so add it
            set add_key_to_catalog_file_p "1"
        }

        if { $add_key_to_catalog_file_p } {

            return $message_key
        } else {
            # No key should be added to catalog file
            return ""
        }
    }
    
    ad_proc -public localize { 
        string_with_hashes
    } {
        Takes a string with embedded message keys on the format #message_key_name#
        and returns the same string but with the message keys (and their surrounding hash
        marks) replaced with the corresponding value in the message catalog. Message lookup
        is done with the locale of the request. If message lookup fails for a certain key
        then that key is not replaced.
    
        @author Peter marklund (peter@collaboraid.biz)
    } {
        set indices_list [get_hash_indices $string_with_hashes]
        
        set subst_string $string_with_hashes
        foreach item_idx $indices_list {
            # The replacement string starts and ends with a hash mark
            set replacement_string [string range $string_with_hashes [lindex $item_idx 0] \
                    [lindex $item_idx 1]]
            set message_key [string range $replacement_string 1 [expr [string length $replacement_string] - 2]]
            
            # Attempt a message lookup
            set message_value [_ [ad_locale request locale] $message_key "not_found"]
            
            # Do substitution if message lookup succeeded
            if { ![string equal $message_value "not_found"] } {                
                regsub $replacement_string $subst_string $message_value subst_string
            }
        }        
        
        return $subst_string
    }

    ad_proc -public charset_for_locale { 
        locale 
    } {
        Returns the MIME charset name corresponding to a locale.
    
        @author        Henry Minsky (hqm@mit.edu)
        @param locale  Name of a locale, as language_COUNTRY using ISO 639 and ISO 3166
        @return        IANA MIME character set name
    } {
        return [db_string charset_for_locale {}]
    }
    
    ad_proc -public default_locale_from_lang { 
        language
    } {
        Returns the default locale for a language
        
        @author          Henry Minsky (hqm@mit.edu)
        @param language  Name of a country, using ISO-3166 two letter code
        @return          Default locale
    } {
        return [db_string default_locale_from_lang {}]
    }

    ad_proc -public nls_language_from_language { 
        language 
    } {
        Returns the nls_language name for a language

        @author          Henry Minsky (hqm@mit.edu)
        @param language  Name of a country, using ISO-3166 two letter code
        @return          The nls_language name of the language.
    } {
        return [db_string nls_language_from_language {}]
    }


}

#####
#
# Compatibility procs
#
#####

ad_proc -deprecated -warn lang_sort {
    field 
    {locale {}}
} { 
    Each locale can have a different alphabetical sort order. You can test
    this proc with the following data:
    <pre>
    insert into lang_testsort values ('lama');
    insert into lang_testsort values ('lhasa');
    insert into lang_testsort values ('llama');
    insert into lang_testsort values ('lzim');  
    </pre>

    @author Jeff Davis (davis@arsdigita.com)

    @param field       Name of Oracle column
    @param locale      Locale for sorting. 
                       If locale is unspecified just return the column name
    @return Language aware version of field for Oracle <em>ORDER BY</em> clause.

    @see lang::util::sort
} {
    return [lang::util::sort $field $locale]
}

ad_proc -deprecated -warn ad_locale_charset_for_locale { 
    locale 
} {
    Returns the MIME charset name corresponding to a locale.

    @see           ad_locale
    @author        Henry Minsky (hqm@mit.edu)
    @param locale  Name of a locale, as language_COUNTRY using ISO 639 and ISO 3166
    @return        IANA MIME character set name
    @see           lang::util::charset_for_locale
} {
    return [lang::util::charset_for_locale $locale]
}

ad_proc -deprecated -warn ad_locale_locale_from_lang { 
    language
} {
    Returns the default locale for a language
    
    @author          Henry Minsky (hqm@mit.edu)
    @param language  Name of a country, using ISO-3166 two letter code
    @return          Default locale
    @see             lang::util::default_locale_from_lang
} {
    return [lang::util::default_locale_from_lang $language]
}

ad_proc -deprecated -warn ad_locale_language_name { 
    language 
} {
    Returns the nls_language name for a language

    @author          Henry Minsky (hqm@mit.edu)
    @param language  Name of a country, using ISO-3166 two letter code
    @return          The nls_language name of the language.
    @see             lang::util::nls_language_from_language
} {
    return [lang::util::nls_language_from_language $language]
}
