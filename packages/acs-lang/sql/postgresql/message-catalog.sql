--
-- packages/acs-lang/sql/postgresql/message-catalog.sql
--
-- @author Jeff Davis (davis@xarg.net)
-- @author Christian Hvid
-- @creation-date 2000-09-10
-- @cvs-id $Id$
--

begin;

create table lang_user_timezone (
    user_id            integer
                       constraint lang_user_timezone_user_id_fk
                       references users (user_id) on delete cascade,
    timezone           varchar(30)
);

create table lang_message_keys ( 
    message_key        varchar(200)
                       constraint lang_message_keys_message_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_message_keys_fk
                       references apm_package_types(package_key)
                       constraint lang_message_keys_package_key_nn
                       not null,
    constraint lang_message_keys_pk
    primary key (message_key, package_key)
);

create table lang_messages (    
    message_key        varchar(200)
                       constraint lang_messages_message_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_messages_package_key_nn
                       not null,
    locale             varchar(30) 
                       constraint lang_messages_locale_fk
                       references ad_locales(locale)
                       constraint lang_messages_locale_nn
                       not null,
    message            text,
    constraint lang_messages_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade,
    constraint lang_messages_pk 
    primary key (message_key, package_key, locale)
);

create table lang_messages_audit (    
    message_key        varchar(200)
                       constraint lang_messages_audit_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_messages_audit_p_key_nn
                       not null,
    locale             varchar(30) 
                       constraint lang_messages_audit_l_fk
                       references ad_locales(locale)
                       constraint lang_messages_audit_l_nn
                       not null,
    message            text,
    overwrite_date     date default now() not null,
    overwrite_user     integer
                       constraint lang_messages_audit_ou_fk
                       references users (user_id),
    constraint lang_messages_audit_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade
);


-- ****************************************************************************
-- * The lang_translate_columns table holds the columns that require translation.
-- * It is needed to generate the user interface for translating the web site.
-- * Note that we register on_what_column itself for translation.
-- ****************************************************************************

create table lang_translate_columns (   
        column_id               integer primary key,
        -- cant do references on user_tables cause oracle sucks
        on_which_table          varchar(50),
        on_what_column          varchar(50),
        --
        -- whether all entries in a column must be translated for the 
        -- site to function.
        --
        -- probably ultimately need something more sophisticated than 
        -- simply required_p
        --
        required_p              boolean,
        --
        -- flag for whether to use the lang_translations table for content
        -- or add a row in the on_which_table table with the translated content.
        --
        short_p                 boolean,
        constraint  ltc_u unique (on_which_table, on_what_column)
);


-- ****************************************************************************
-- * The lang_translation_registry table identifies a row as requiring translation
-- * to a given language. This should identify the parent table not the broken-apart
-- * child table.
-- ****************************************************************************

create table lang_translation_registry (
	on_which_table		varchar(50),
	on_what_id		integer not null,
        locale                  varchar(30) constraint ltr_locale_ref
                                references ad_locales(locale),
        --
        -- should have dependency info here
        --
        constraint lang_translation_registry_pk primary key(on_what_id, on_which_table, locale)
);

end;


