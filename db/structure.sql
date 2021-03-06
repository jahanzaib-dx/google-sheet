--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_features; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE account_features (
    id integer NOT NULL,
    show_tenantrex_cashflow boolean DEFAULT false,
    show_tenantrex_output boolean DEFAULT false,
    account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_type character varying(255) DEFAULT 'cushman'::character varying
);


--
-- Name: account_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_features_id_seq OWNED BY account_features.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id integer NOT NULL,
    fullname character varying(255),
    role character varying(255),
    user_id integer,
    firm_id integer,
    office_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    market_id integer,
    accepted_terms_of_service boolean DEFAULT false
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE activity_logs (
    id integer NOT NULL,
    comp_id integer,
    status character varying(255),
    receiver_id integer,
    initiator_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    comptype character varying(255),
    child_comp integer,
    master_id integer
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_logs_id_seq OWNED BY activity_logs.id;


--
-- Name: archive_migration_tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archive_migration_tenant_records (
    id integer NOT NULL,
    image_url character varying(255),
    confidential integer,
    website character varying(255),
    tenant_improvement_modifier numeric(20,0),
    insurance numeric(20,0),
    maintenance numeric(20,0),
    utilities numeric(20,0),
    taxes numeric(20,0),
    lease_commencement date,
    lease_expiration date
);


--
-- Name: archive_migration_tenant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archive_migration_tenant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archive_migration_tenant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archive_migration_tenant_records_id_seq OWNED BY archive_migration_tenant_records.id;


--
-- Name: attached_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE attached_files (
    id integer NOT NULL,
    message_id integer NOT NULL,
    file_name character varying(255)
);


--
-- Name: attached_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attached_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attached_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attached_files_id_seq OWNED BY attached_files.id;


--
-- Name: back_end_custom_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE back_end_custom_records (
    id integer NOT NULL,
    custom_record_id integer,
    file character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: back_end_custom_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE back_end_custom_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: back_end_custom_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE back_end_custom_records_id_seq OWNED BY back_end_custom_records.id;


--
-- Name: back_end_lease_comps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE back_end_lease_comps (
    id integer NOT NULL,
    user_id integer,
    file character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: back_end_lease_comps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE back_end_lease_comps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: back_end_lease_comps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE back_end_lease_comps_id_seq OWNED BY back_end_lease_comps.id;


--
-- Name: back_end_sale_comps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE back_end_sale_comps (
    id integer NOT NULL,
    user_id integer,
    file character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: back_end_sale_comps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE back_end_sale_comps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: back_end_sale_comps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE back_end_sale_comps_id_seq OWNED BY back_end_sale_comps.id;


--
-- Name: comp_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comp_requests (
    id integer NOT NULL,
    comp_id integer,
    initiator_id integer,
    receiver_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    comp_type character varying
);


--
-- Name: comp_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comp_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comp_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comp_requests_id_seq OWNED BY comp_requests.id;


--
-- Name: comp_unlock_fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comp_unlock_fields (
    id integer NOT NULL,
    shared_comp_id integer,
    field_name character varying
);


--
-- Name: comp_unlock_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comp_unlock_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comp_unlock_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comp_unlock_fields_id_seq OWNED BY comp_unlock_fields.id;


--
-- Name: connection_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE connection_requests (
    id integer NOT NULL,
    user_id integer,
    agent_id integer,
    message character varying,
    request_code character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: connection_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE connection_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connection_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE connection_requests_id_seq OWNED BY connection_requests.id;


--
-- Name: connections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE connections (
    id integer NOT NULL,
    user_id bigint,
    created_at timestamp without time zone,
    group_id integer,
    agent_id integer,
    connection_established boolean
);


--
-- Name: connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE connections_id_seq OWNED BY connections.id;


--
-- Name: custom_record_properties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_record_properties (
    id integer NOT NULL,
    key character varying,
    value character varying,
    custom_record_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    row_id integer,
    visible boolean DEFAULT true
);


--
-- Name: custom_record_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_record_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_record_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_record_properties_id_seq OWNED BY custom_record_properties.id;


--
-- Name: custom_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_records (
    id integer NOT NULL,
    is_existing_data_set boolean DEFAULT false,
    is_geo_coded boolean DEFAULT true,
    name character varying,
    address1 character varying,
    city character varying,
    state character varying,
    latitude numeric(30,9),
    longitude numeric(30,9),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    zipcode character varying,
    zipcode_plus character varying,
    user_id integer,
    country character varying
);


--
-- Name: custom_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_records_id_seq OWNED BY custom_records.id;


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE expenses (
    id integer NOT NULL,
    name character varying(255),
    display_order integer DEFAULT 0
);


--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE expenses_id_seq OWNED BY expenses.id;


--
-- Name: firms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE firms (
    id integer NOT NULL,
    name character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: firms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE firms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: firms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE firms_id_seq OWNED BY firms.id;


--
-- Name: flaged_comps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flaged_comps (
    id integer NOT NULL,
    comp_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    comp_type character varying
);


--
-- Name: flaged_comps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flaged_comps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flaged_comps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flaged_comps_id_seq OWNED BY flaged_comps.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    user_id integer,
    title character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: import_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_logs (
    id integer NOT NULL,
    tenant_record_import_id integer,
    tenant_record_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


--
-- Name: import_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_logs_id_seq OWNED BY import_logs.id;


--
-- Name: import_mappings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_mappings (
    id integer NOT NULL,
    import_template_id integer,
    spreadsheet_column character varying(255),
    record_column character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_value character varying(255)
);


--
-- Name: import_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_mappings_id_seq OWNED BY import_mappings.id;


--
-- Name: import_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_records (
    id integer NOT NULL,
    tenant_record_import_id integer,
    record_valid boolean DEFAULT false,
    geocode_valid boolean DEFAULT false,
    imported boolean DEFAULT false,
    record_warnings text,
    data hstore,
    record_errors hstore
);


--
-- Name: import_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_records_id_seq OWNED BY import_records.id;


--
-- Name: import_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_templates (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    reusable boolean DEFAULT true,
    user_id integer,
    type character varying(30)
);


--
-- Name: import_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_templates_id_seq OWNED BY import_templates.id;


--
-- Name: industries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE industries (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: industries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE industries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: industries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE industries_id_seq OWNED BY industries.id;


--
-- Name: industry_sic_codes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE industry_sic_codes (
    id integer NOT NULL,
    value character varying(255),
    description character varying(255),
    division character varying(255),
    major_group character varying(255),
    industry_group character varying(255),
    division_desc character varying(255),
    major_group_desc character varying(255),
    industry_group_desc character varying(255)
);


--
-- Name: industry_sic_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE industry_sic_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: industry_sic_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE industry_sic_codes_id_seq OWNED BY industry_sic_codes.id;


--
-- Name: learn_more_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE learn_more_requests (
    id integer NOT NULL,
    fullname character varying(255),
    brokerage_firm character varying(255),
    email character varying(255),
    market_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: learn_more_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE learn_more_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learn_more_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE learn_more_requests_id_seq OWNED BY learn_more_requests.id;


--
-- Name: lease_structure_expenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lease_structure_expenses (
    id integer NOT NULL,
    lease_structure_id integer,
    calculation_type character varying(255),
    default_cost numeric,
    increase_percent numeric,
    start_date date,
    name character varying(255),
    delay_start_date date
);


--
-- Name: lease_structure_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lease_structure_expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lease_structure_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lease_structure_expenses_id_seq OWNED BY lease_structure_expenses.id;


--
-- Name: lease_structures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lease_structures (
    id integer NOT NULL,
    name character varying(255),
    description text,
    account_id integer,
    discount_rate numeric(4,2),
    office_id integer,
    interest_rate numeric(4,2) DEFAULT 0.0
);


--
-- Name: lease_structures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lease_structures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lease_structures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lease_structures_id_seq OWNED BY lease_structures.id;


--
-- Name: lookup_address_zipcodes_tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_address_zipcodes_tenant_records (
    tenant_record_id integer,
    lookup_address_zipcode_id integer
);


--
-- Name: lookup_companies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_companies (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: lookup_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lookup_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookup_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lookup_companies_id_seq OWNED BY lookup_companies.id;


--
-- Name: lookup_companies_tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_companies_tenant_records (
    tenant_record_id integer,
    lookup_company_id integer
);


--
-- Name: lookup_property_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_property_names (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: lookup_property_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lookup_property_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookup_property_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lookup_property_names_id_seq OWNED BY lookup_property_names.id;


--
-- Name: lookup_property_names_tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_property_names_tenant_records (
    tenant_record_id integer,
    lookup_property_name_id integer
);


--
-- Name: lookup_submarkets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_submarkets (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: lookup_submarkets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lookup_submarkets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookup_submarkets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lookup_submarkets_id_seq OWNED BY lookup_submarkets.id;


--
-- Name: lookup_submarkets_tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lookup_submarkets_tenant_records (
    tenant_record_id integer,
    lookup_submarket_id integer
);


--
-- Name: maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE maps (
    id integer NOT NULL,
    account_id integer,
    office_id integer,
    name character varying(255),
    mode character varying(255),
    latitude text,
    longitude text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE maps_id_seq OWNED BY maps.id;


--
-- Name: market_expenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE market_expenses (
    id integer NOT NULL,
    taxes numeric(20,2),
    insurance numeric(20,2),
    utilities numeric(20,2),
    cam numeric(20,2),
    janitorial numeric(20,2),
    administrative numeric(20,2),
    payroll_and_benefits numeric(20,2),
    management_fee numeric(20,2),
    grounds_landscape numeric(20,2),
    security numeric(20,2),
    other_tax numeric(20,2),
    total_opex numeric(20,2),
    opex_market_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: market_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE market_expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: market_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE market_expenses_id_seq OWNED BY market_expenses.id;


--
-- Name: markets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE markets (
    id integer NOT NULL,
    name character varying(255),
    is_preferred boolean DEFAULT false,
    description character varying(255)
);


--
-- Name: markets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE markets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: markets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE markets_id_seq OWNED BY markets.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    group_id integer,
    member_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    receiver_id integer NOT NULL,
    message text,
    file character varying(255),
    status boolean DEFAULT false,
    created_at timestamp without time zone
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: notify_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notify_emails (
    id integer NOT NULL,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notify_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notify_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notify_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notify_emails_id_seq OWNED BY notify_emails.id;


--
-- Name: offices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE offices (
    id integer NOT NULL,
    firm_id integer,
    name character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    latitude numeric(30,9),
    longitude numeric(30,9),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode integer,
    zipcode_plus integer,
    logo_image_file_name character varying(255),
    logo_image_content_type character varying(255),
    logo_image_file_size integer,
    logo_image_updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    registration_code character varying(255)
);


--
-- Name: offices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE offices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE offices_id_seq OWNED BY offices.id;


--
-- Name: opex_markets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE opex_markets (
    id integer NOT NULL,
    name character varying,
    code character varying,
    description character varying,
    property_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: opex_markets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE opex_markets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opex_markets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE opex_markets_id_seq OWNED BY opex_markets.id;


--
-- Name: property_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE property_types (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: property_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE property_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: property_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE property_types_id_seq OWNED BY property_types.id;


--
-- Name: report_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE report_templates (
    id integer NOT NULL,
    template_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: report_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_templates_id_seq OWNED BY report_templates.id;


--
-- Name: sale_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sale_records (
    id integer NOT NULL,
    is_sales_record boolean DEFAULT false,
    land_size_identifier character varying,
    view_type character varying,
    address1 character varying,
    city character varying,
    state character varying,
    land_size numeric(20,2),
    price numeric(20,2),
    cap_rate numeric(20,2),
    latitude numeric(30,9),
    longitude numeric(30,9),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    zipcode character varying,
    zipcode_plus character varying,
    class_type character varying,
    property_type character varying,
    build_date date,
    sold_date date,
    user_id integer,
    custom hstore,
    property_name character varying,
    submarket character varying,
    main_image_file_name character varying,
    parent_id integer,
    master_id integer,
    country character varying,
    is_geo_coded boolean DEFAULT true
);


--
-- Name: sale_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sale_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sale_records_id_seq OWNED BY sale_records.id;


--
-- Name: schedule_accesses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schedule_accesses (
    id integer NOT NULL,
    start_date_time timestamp without time zone,
    end_date_time timestamp without time zone,
    status boolean,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schedule_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schedule_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schedule_accesses_id_seq OWNED BY schedule_accesses.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shared_comps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE shared_comps (
    id integer NOT NULL,
    comp_id integer,
    agent_id integer,
    comp_type character varying,
    comp_status character varying,
    ownership boolean DEFAULT false
);


--
-- Name: shared_comps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shared_comps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_comps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shared_comps_id_seq OWNED BY shared_comps.id;


--
-- Name: stepped_rents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stepped_rents (
    id integer NOT NULL,
    tenant_record_id integer,
    "order" integer,
    months integer,
    cost_per_month numeric(20,2),
    deleted_at timestamp without time zone
);


--
-- Name: stepped_rents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stepped_rents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stepped_rents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stepped_rents_id_seq OWNED BY stepped_rents.id;


--
-- Name: tenant_record_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_record_categories (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tenant_record_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_record_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_record_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_record_categories_id_seq OWNED BY tenant_record_categories.id;


--
-- Name: tenant_record_category_fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_record_category_fields (
    id integer NOT NULL,
    label_name character varying(255),
    tenant_record_field character varying(255),
    tenant_record_category_id integer,
    "order" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tenant_record_category_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_record_category_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_record_category_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_record_category_fields_id_seq OWNED BY tenant_record_category_fields.id;


--
-- Name: tenant_record_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_record_images (
    id integer NOT NULL,
    tenant_record_id integer,
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tenant_record_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_record_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_record_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_record_images_id_seq OWNED BY tenant_record_images.id;


--
-- Name: tenant_record_import_operating_expense_mappings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_record_import_operating_expense_mappings (
    id integer NOT NULL,
    tenant_record_import_id integer,
    column_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tenant_record_import_operating_expense_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_record_import_operating_expense_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_record_import_operating_expense_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_record_import_operating_expense_mappings_id_seq OWNED BY tenant_record_import_operating_expense_mappings.id;


--
-- Name: tenant_record_imports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_record_imports (
    id integer NOT NULL,
    import_template_id integer,
    complete boolean DEFAULT false,
    import_valid boolean DEFAULT false,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    geocode_valid boolean,
    status text,
    total_record_count integer DEFAULT 0,
    num_imported_records integer DEFAULT 0,
    lease_structure_id integer,
    total_traversed_count integer DEFAULT 0,
    user_id integer
);


--
-- Name: tenant_record_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_record_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_record_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_record_imports_id_seq OWNED BY tenant_record_imports.id;


--
-- Name: tenant_records_new; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_records_new (
    id integer NOT NULL,
    office_id integer,
    comments text,
    industry_sic_code_id integer,
    company character varying(255),
    address1 character varying(255),
    suite character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    zipcode_plus integer,
    view_type character varying(255) DEFAULT 'public'::character varying,
    comp_type character varying(255) DEFAULT 'internal'::character varying,
    contact character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    location_type character varying(255),
    lease_commencement_date date,
    lease_term_months integer,
    lease_type character varying(255),
    property_type character varying(255),
    class_type character varying(255),
    version integer DEFAULT 1,
    mongoid character varying(255),
    latitude numeric(30,9),
    longitude numeric(30,9),
    size integer,
    net_effective_per_sf numeric(20,9) DEFAULT 0.0,
    landlord_concessions_per_sf numeric(20,9) DEFAULT 0.0,
    landlord_margins numeric(20,9) DEFAULT 0.0,
    base_rent numeric(20,9),
    escalation numeric(4,2),
    tenant_improvement numeric(20,9) DEFAULT 0.0,
    tenant_ti_cost numeric(20,9) DEFAULT 0.0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    data hstore,
    team_id integer,
    main_image_file_name character varying(255),
    main_image_content_type character varying(255),
    main_image_file_size integer,
    main_image_updated_at timestamp without time zone,
    avg_base_rent_per_annum_by_sf numeric,
    landlord_effective_rent numeric(20,9) DEFAULT 0.0,
    submarket character varying(255),
    property_name character varying(255),
    free_rent_total integer DEFAULT 0,
    free_rent character varying(255) DEFAULT '0'::character varying,
    industry_type character varying(255),
    cushman_net_effective_per_sf numeric(20,2) DEFAULT 0.0,
    is_stepped_rent boolean DEFAULT false,
    company_logo_file_name character varying(255),
    company_logo_content_type character varying(255),
    company_logo_file_size integer,
    company_logo_updated_at timestamp without time zone,
    user_id integer,
    cap_rate double precision,
    sale_price double precision,
    build_date date,
    sold_date date,
    record_type character varying
);


--
-- Name: tenant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tenant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tenant_records_id_seq OWNED BY tenant_records_new.id;


--
-- Name: tenant_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tenant_records (
    id integer DEFAULT nextval('tenant_records_id_seq'::regclass) NOT NULL,
    office_id integer,
    comments text,
    industry_sic_code_id integer,
    company character varying(255),
    address1 character varying(255),
    suite character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    zipcode_plus integer,
    view_type character varying(255) DEFAULT 'public'::character varying,
    comp_type character varying(255) DEFAULT 'internal'::character varying,
    contact character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    location_type character varying(255),
    lease_commencement_date date,
    lease_term_months integer,
    lease_type character varying(255),
    property_type character varying(255),
    class_type character varying(255),
    version integer DEFAULT 1,
    mongoid character varying(255),
    latitude numeric(30,9),
    longitude numeric(30,9),
    size integer,
    net_effective_per_sf numeric(20,9) DEFAULT 0,
    landlord_concessions_per_sf numeric(20,9) DEFAULT 0,
    landlord_margins numeric(20,9) DEFAULT 0,
    base_rent numeric(20,9),
    escalation numeric(4,2),
    tenant_improvement numeric(20,9) DEFAULT 0,
    tenant_ti_cost numeric(20,9) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    data hstore,
    team_id integer,
    main_image_file_name character varying(255),
    main_image_content_type character varying(255),
    main_image_file_size integer,
    main_image_updated_at timestamp without time zone,
    avg_base_rent_per_annum_by_sf numeric,
    landlord_effective_rent numeric(20,9) DEFAULT 0,
    submarket character varying(255),
    property_name character varying(255),
    free_rent_total integer DEFAULT 0,
    free_rent character varying(255) DEFAULT '0'::character varying,
    industry_type character varying(255),
    cushman_net_effective_per_sf numeric(20,2) DEFAULT 0,
    is_stepped_rent boolean DEFAULT false,
    company_logo_file_name character varying(255),
    company_logo_content_type character varying(255),
    company_logo_file_size integer,
    company_logo_updated_at timestamp without time zone,
    user_id integer,
    has_additional_tenant_cost boolean DEFAULT false,
    has_additional_ll_allowance boolean DEFAULT false,
    additional_ll_allowance numeric(20,2) DEFAULT 0,
    additional_tenant_cost numeric(20,2) DEFAULT 0,
    gross_free_rent boolean DEFAULT false,
    comp_view_type character varying,
    deal_type character varying,
    comp_data_type character varying,
    base_rent_type character varying,
    rent_escalation_type character varying,
    free_rent_type character varying,
    is_tenant_improvement boolean DEFAULT false,
    fixed_escalation numeric(20,2) DEFAULT 0.0,
    custom_data hstore,
    parent_id integer,
    master_id integer,
    country character varying,
    is_geo_coded boolean DEFAULT true
);


--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_settings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    sms boolean,
    email boolean,
    outofnetwork boolean,
    rating integer
);


--
-- Name: user_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_settings_id_seq OWNED BY user_settings.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username character varying(255),
    mobile character varying(255),
    email_code character varying(255),
    sms_code character varying(255),
    linkedin character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying(255),
    provider character varying(255),
    uid character varying(255),
    mobile_active boolean,
    first_name character varying(100),
    last_name character varying(100),
    title character varying(30),
    firm_name character varying(100),
    address character varying(255),
    city character varying(50),
    state character varying(50),
    website character varying(150),
    zip character varying(6),
    avatar character varying(255),
    linkedin_photo character varying,
    parent_id integer,
    total_export_permissions integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: visitors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visitors (
    id integer NOT NULL,
    page character varying(100),
    email character varying,
    ip character varying(15),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: visitors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visitors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visitors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visitors_id_seq OWNED BY visitors.id;


--
-- Name: white_glove_service_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE white_glove_service_requests (
    id integer NOT NULL,
    user_id integer,
    file_path character varying,
    import_template_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying
);


--
-- Name: white_glove_service_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE white_glove_service_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: white_glove_service_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE white_glove_service_requests_id_seq OWNED BY white_glove_service_requests.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_features ALTER COLUMN id SET DEFAULT nextval('account_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_logs ALTER COLUMN id SET DEFAULT nextval('activity_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY archive_migration_tenant_records ALTER COLUMN id SET DEFAULT nextval('archive_migration_tenant_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attached_files ALTER COLUMN id SET DEFAULT nextval('attached_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY back_end_custom_records ALTER COLUMN id SET DEFAULT nextval('back_end_custom_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY back_end_lease_comps ALTER COLUMN id SET DEFAULT nextval('back_end_lease_comps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY back_end_sale_comps ALTER COLUMN id SET DEFAULT nextval('back_end_sale_comps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comp_requests ALTER COLUMN id SET DEFAULT nextval('comp_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comp_unlock_fields ALTER COLUMN id SET DEFAULT nextval('comp_unlock_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY connection_requests ALTER COLUMN id SET DEFAULT nextval('connection_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY connections ALTER COLUMN id SET DEFAULT nextval('connections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_record_properties ALTER COLUMN id SET DEFAULT nextval('custom_record_properties_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_records ALTER COLUMN id SET DEFAULT nextval('custom_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY expenses ALTER COLUMN id SET DEFAULT nextval('expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY firms ALTER COLUMN id SET DEFAULT nextval('firms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flaged_comps ALTER COLUMN id SET DEFAULT nextval('flaged_comps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_logs ALTER COLUMN id SET DEFAULT nextval('import_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_mappings ALTER COLUMN id SET DEFAULT nextval('import_mappings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_records ALTER COLUMN id SET DEFAULT nextval('import_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_templates ALTER COLUMN id SET DEFAULT nextval('import_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY industries ALTER COLUMN id SET DEFAULT nextval('industries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY industry_sic_codes ALTER COLUMN id SET DEFAULT nextval('industry_sic_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY learn_more_requests ALTER COLUMN id SET DEFAULT nextval('learn_more_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lease_structure_expenses ALTER COLUMN id SET DEFAULT nextval('lease_structure_expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lease_structures ALTER COLUMN id SET DEFAULT nextval('lease_structures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lookup_companies ALTER COLUMN id SET DEFAULT nextval('lookup_companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lookup_property_names ALTER COLUMN id SET DEFAULT nextval('lookup_property_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lookup_submarkets ALTER COLUMN id SET DEFAULT nextval('lookup_submarkets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY maps ALTER COLUMN id SET DEFAULT nextval('maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY market_expenses ALTER COLUMN id SET DEFAULT nextval('market_expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY markets ALTER COLUMN id SET DEFAULT nextval('markets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notify_emails ALTER COLUMN id SET DEFAULT nextval('notify_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY offices ALTER COLUMN id SET DEFAULT nextval('offices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY opex_markets ALTER COLUMN id SET DEFAULT nextval('opex_markets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY property_types ALTER COLUMN id SET DEFAULT nextval('property_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_templates ALTER COLUMN id SET DEFAULT nextval('report_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_records ALTER COLUMN id SET DEFAULT nextval('sale_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule_accesses ALTER COLUMN id SET DEFAULT nextval('schedule_accesses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shared_comps ALTER COLUMN id SET DEFAULT nextval('shared_comps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stepped_rents ALTER COLUMN id SET DEFAULT nextval('stepped_rents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_categories ALTER COLUMN id SET DEFAULT nextval('tenant_record_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_category_fields ALTER COLUMN id SET DEFAULT nextval('tenant_record_category_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_images ALTER COLUMN id SET DEFAULT nextval('tenant_record_images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_import_operating_expense_mappings ALTER COLUMN id SET DEFAULT nextval('tenant_record_import_operating_expense_mappings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_imports ALTER COLUMN id SET DEFAULT nextval('tenant_record_imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_records_new ALTER COLUMN id SET DEFAULT nextval('tenant_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_settings ALTER COLUMN id SET DEFAULT nextval('user_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visitors ALTER COLUMN id SET DEFAULT nextval('visitors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY white_glove_service_requests ALTER COLUMN id SET DEFAULT nextval('white_glove_service_requests_id_seq'::regclass);


--
-- Name: account_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY account_features
    ADD CONSTRAINT account_features_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: archive_migration_tenant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archive_migration_tenant_records
    ADD CONSTRAINT archive_migration_tenant_records_pkey PRIMARY KEY (id);


--
-- Name: attached_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attached_files
    ADD CONSTRAINT attached_files_pkey PRIMARY KEY (id);


--
-- Name: back_end_custom_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY back_end_custom_records
    ADD CONSTRAINT back_end_custom_records_pkey PRIMARY KEY (id);


--
-- Name: back_end_lease_comps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY back_end_lease_comps
    ADD CONSTRAINT back_end_lease_comps_pkey PRIMARY KEY (id);


--
-- Name: back_end_sale_comps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY back_end_sale_comps
    ADD CONSTRAINT back_end_sale_comps_pkey PRIMARY KEY (id);


--
-- Name: comp_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comp_requests
    ADD CONSTRAINT comp_requests_pkey PRIMARY KEY (id);


--
-- Name: comp_unlock_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comp_unlock_fields
    ADD CONSTRAINT comp_unlock_fields_pkey PRIMARY KEY (id);


--
-- Name: connection_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY connection_requests
    ADD CONSTRAINT connection_requests_pkey PRIMARY KEY (id);


--
-- Name: connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: custom_record_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_record_properties
    ADD CONSTRAINT custom_record_properties_pkey PRIMARY KEY (id);


--
-- Name: custom_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_records
    ADD CONSTRAINT custom_records_pkey PRIMARY KEY (id);


--
-- Name: expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: firms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY firms
    ADD CONSTRAINT firms_pkey PRIMARY KEY (id);


--
-- Name: flaged_comps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flaged_comps
    ADD CONSTRAINT flaged_comps_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: import_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id);


--
-- Name: import_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_mappings
    ADD CONSTRAINT import_mappings_pkey PRIMARY KEY (id);


--
-- Name: import_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_records
    ADD CONSTRAINT import_records_pkey PRIMARY KEY (id);


--
-- Name: import_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_templates
    ADD CONSTRAINT import_templates_pkey PRIMARY KEY (id);


--
-- Name: industries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY industries
    ADD CONSTRAINT industries_pkey PRIMARY KEY (id);


--
-- Name: industry_sic_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY industry_sic_codes
    ADD CONSTRAINT industry_sic_codes_pkey PRIMARY KEY (id);


--
-- Name: learn_more_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY learn_more_requests
    ADD CONSTRAINT learn_more_requests_pkey PRIMARY KEY (id);


--
-- Name: lease_structure_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lease_structure_expenses
    ADD CONSTRAINT lease_structure_expenses_pkey PRIMARY KEY (id);


--
-- Name: lease_structures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lease_structures
    ADD CONSTRAINT lease_structures_pkey PRIMARY KEY (id);


--
-- Name: lookup_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lookup_companies
    ADD CONSTRAINT lookup_companies_pkey PRIMARY KEY (id);


--
-- Name: lookup_property_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lookup_property_names
    ADD CONSTRAINT lookup_property_names_pkey PRIMARY KEY (id);


--
-- Name: lookup_submarkets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lookup_submarkets
    ADD CONSTRAINT lookup_submarkets_pkey PRIMARY KEY (id);


--
-- Name: maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY maps
    ADD CONSTRAINT maps_pkey PRIMARY KEY (id);


--
-- Name: market_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY market_expenses
    ADD CONSTRAINT market_expenses_pkey PRIMARY KEY (id);


--
-- Name: markets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY markets
    ADD CONSTRAINT markets_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notify_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notify_emails
    ADD CONSTRAINT notify_emails_pkey PRIMARY KEY (id);


--
-- Name: offices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: opex_markets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY opex_markets
    ADD CONSTRAINT opex_markets_pkey PRIMARY KEY (id);


--
-- Name: property_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY property_types
    ADD CONSTRAINT property_types_pkey PRIMARY KEY (id);


--
-- Name: report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report_templates
    ADD CONSTRAINT report_templates_pkey PRIMARY KEY (id);


--
-- Name: sale_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sale_records
    ADD CONSTRAINT sale_records_pkey PRIMARY KEY (id);


--
-- Name: schedule_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule_accesses
    ADD CONSTRAINT schedule_accesses_pkey PRIMARY KEY (id);


--
-- Name: shared_comps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY shared_comps
    ADD CONSTRAINT shared_comps_pkey PRIMARY KEY (id);


--
-- Name: stepped_rents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stepped_rents
    ADD CONSTRAINT stepped_rents_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_record_categories
    ADD CONSTRAINT tenant_record_categories_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_category_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_record_category_fields
    ADD CONSTRAINT tenant_record_category_fields_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_record_images
    ADD CONSTRAINT tenant_record_images_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_import_operating_expense_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_record_import_operating_expense_mappings
    ADD CONSTRAINT tenant_record_import_operating_expense_mappings_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_record_imports
    ADD CONSTRAINT tenant_record_imports_pkey PRIMARY KEY (id);


--
-- Name: tenant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tenant_records
    ADD CONSTRAINT tenant_records_pkey PRIMARY KEY (id);


--
-- Name: user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visitors
    ADD CONSTRAINT visitors_pkey PRIMARY KEY (id);


--
-- Name: white_glove_service_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY white_glove_service_requests
    ADD CONSTRAINT white_glove_service_requests_pkey PRIMARY KEY (id);


--
-- Name: index_accounts_on_firm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_firm_id ON accounts USING btree (firm_id);


--
-- Name: index_accounts_on_office_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_office_id ON accounts USING btree (office_id);


--
-- Name: index_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accounts_on_user_id ON accounts USING btree (user_id);


--
-- Name: index_comp_requests_on_comp_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comp_requests_on_comp_id ON comp_requests USING btree (comp_id);


--
-- Name: index_comp_requests_on_initiator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comp_requests_on_initiator_id ON comp_requests USING btree (initiator_id);


--
-- Name: index_comp_requests_on_receiver_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comp_requests_on_receiver_id ON comp_requests USING btree (receiver_id);


--
-- Name: index_connection_requests_on_agent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_connection_requests_on_agent_id ON connection_requests USING btree (agent_id);


--
-- Name: index_connection_requests_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_connection_requests_on_user_id ON connection_requests USING btree (user_id);


--
-- Name: index_custom_records_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_custom_records_on_user_id ON custom_records USING btree (user_id);


--
-- Name: index_groups_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_groups_on_user_id ON groups USING btree (user_id);


--
-- Name: index_import_logs_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_logs_on_user_id ON import_logs USING btree (user_id);


--
-- Name: index_import_templates_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_import_templates_on_user_id ON import_templates USING btree (user_id);


--
-- Name: index_lease_structure_expenses_on_lease_structure_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lease_structure_expenses_on_lease_structure_id ON lease_structure_expenses USING btree (lease_structure_id);


--
-- Name: index_lease_structures_on_name_and_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_lease_structures_on_name_and_account_id ON lease_structures USING btree (name, account_id);


--
-- Name: index_lookup_companies_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lookup_companies_on_name ON lookup_companies USING btree (name);


--
-- Name: index_lookup_property_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lookup_property_names_on_name ON lookup_property_names USING btree (name);


--
-- Name: index_lookup_submarkets_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_lookup_submarkets_on_name ON lookup_submarkets USING btree (name);


--
-- Name: index_maps_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_maps_on_account_id ON maps USING btree (account_id);


--
-- Name: index_maps_on_office_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_maps_on_office_id ON maps USING btree (office_id);


--
-- Name: index_memberships_on_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_group_id ON memberships USING btree (group_id);


--
-- Name: index_memberships_on_member_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_member_id ON memberships USING btree (member_id);


--
-- Name: index_offices_on_firm_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_offices_on_firm_id ON offices USING btree (firm_id);


--
-- Name: index_sale_records_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sale_records_on_user_id ON sale_records USING btree (user_id);


--
-- Name: index_schedule_accesses_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_schedule_accesses_on_user_id ON schedule_accesses USING btree (user_id);


--
-- Name: index_stepped_rents_on_deleted_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stepped_rents_on_deleted_at ON stepped_rents USING btree (deleted_at);


--
-- Name: index_tenant_record_imports_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tenant_record_imports_on_user_id ON tenant_record_imports USING btree (user_id);


--
-- Name: index_tenant_records_on_industry_sic_code_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tenant_records_on_industry_sic_code_id ON tenant_records_new USING btree (industry_sic_code_id);


--
-- Name: index_tenant_records_on_office_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tenant_records_on_office_id ON tenant_records_new USING btree (office_id);


--
-- Name: index_tenant_records_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tenant_records_on_user_id ON tenant_records_new USING btree (user_id);


--
-- Name: index_tr_import_oe_mappings_on_tr_import_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tr_import_oe_mappings_on_tr_import_id ON tenant_record_import_operating_expense_mappings USING btree (tenant_record_import_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_white_glove_service_requests_on_import_template_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_white_glove_service_requests_on_import_template_id ON white_glove_service_requests USING btree (import_template_id);


--
-- Name: index_white_glove_service_requests_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_white_glove_service_requests_on_user_id ON white_glove_service_requests USING btree (user_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_rails_09a2e1e0ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_imports
    ADD CONSTRAINT fk_rails_09a2e1e0ba FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_0a70287dd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY white_glove_service_requests
    ADD CONSTRAINT fk_rails_0a70287dd0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1b137019c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_records
    ADD CONSTRAINT fk_rails_1b137019c3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1d5f22eb3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schedule_accesses
    ADD CONSTRAINT fk_rails_1d5f22eb3b FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_5c1d3c1c63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_rails_5c1d3c1c63 FOREIGN KEY (member_id) REFERENCES users(id);


--
-- Name: fk_rails_738e304f14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tenant_record_import_operating_expense_mappings
    ADD CONSTRAINT fk_rails_738e304f14 FOREIGN KEY (tenant_record_import_id) REFERENCES tenant_record_imports(id);


--
-- Name: fk_rails_7bd6558db5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT fk_rails_7bd6558db5 FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: fk_rails_8dad33a7fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_records
    ADD CONSTRAINT fk_rails_8dad33a7fe FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_a9f8511872; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY white_glove_service_requests
    ADD CONSTRAINT fk_rails_a9f8511872 FOREIGN KEY (import_template_id) REFERENCES import_templates(id);


--
-- Name: fk_rails_c4f44ffbb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_c4f44ffbb0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_dcc950a319; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_logs
    ADD CONSTRAINT fk_rails_dcc950a319 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_deefbaa61b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_templates
    ADD CONSTRAINT fk_rails_deefbaa61b FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20160719080631');

INSERT INTO schema_migrations (version) VALUES ('20160719115708');

INSERT INTO schema_migrations (version) VALUES ('20160719115709');

INSERT INTO schema_migrations (version) VALUES ('20160720104305');

INSERT INTO schema_migrations (version) VALUES ('20160728073310');

INSERT INTO schema_migrations (version) VALUES ('20160818062546');

INSERT INTO schema_migrations (version) VALUES ('20160818092344');

INSERT INTO schema_migrations (version) VALUES ('20160818093208');

INSERT INTO schema_migrations (version) VALUES ('20160822062727');

INSERT INTO schema_migrations (version) VALUES ('20160823123054');

INSERT INTO schema_migrations (version) VALUES ('20160823123701');

INSERT INTO schema_migrations (version) VALUES ('20160823123711');

INSERT INTO schema_migrations (version) VALUES ('20160829103633');

INSERT INTO schema_migrations (version) VALUES ('20160830191914');

INSERT INTO schema_migrations (version) VALUES ('20160831101828');

INSERT INTO schema_migrations (version) VALUES ('20160904190912');

INSERT INTO schema_migrations (version) VALUES ('20160904193254');

INSERT INTO schema_migrations (version) VALUES ('20160916104235');

INSERT INTO schema_migrations (version) VALUES ('20160917080951');

INSERT INTO schema_migrations (version) VALUES ('20160923063603');

INSERT INTO schema_migrations (version) VALUES ('20160928092409');

INSERT INTO schema_migrations (version) VALUES ('20160929112401');

INSERT INTO schema_migrations (version) VALUES ('20161004054508');

INSERT INTO schema_migrations (version) VALUES ('20161004060626');

INSERT INTO schema_migrations (version) VALUES ('20161005103317');

INSERT INTO schema_migrations (version) VALUES ('20161005104536');

INSERT INTO schema_migrations (version) VALUES ('20161006120927');

INSERT INTO schema_migrations (version) VALUES ('20161006120950');

INSERT INTO schema_migrations (version) VALUES ('20161006121027');

INSERT INTO schema_migrations (version) VALUES ('20161006121858');

INSERT INTO schema_migrations (version) VALUES ('20161006121933');

INSERT INTO schema_migrations (version) VALUES ('20161006121954');

INSERT INTO schema_migrations (version) VALUES ('20161006122054');

INSERT INTO schema_migrations (version) VALUES ('20161006125912');

INSERT INTO schema_migrations (version) VALUES ('20161006125931');

INSERT INTO schema_migrations (version) VALUES ('20161006125951');

INSERT INTO schema_migrations (version) VALUES ('20161006130016');

INSERT INTO schema_migrations (version) VALUES ('20161006130054');

INSERT INTO schema_migrations (version) VALUES ('20161006130146');

INSERT INTO schema_migrations (version) VALUES ('20161006130211');

INSERT INTO schema_migrations (version) VALUES ('20161006182940');

INSERT INTO schema_migrations (version) VALUES ('20161007065215');

INSERT INTO schema_migrations (version) VALUES ('20161007085810');

INSERT INTO schema_migrations (version) VALUES ('20161007090254');

INSERT INTO schema_migrations (version) VALUES ('20161007090307');

INSERT INTO schema_migrations (version) VALUES ('20161007090328');

INSERT INTO schema_migrations (version) VALUES ('20161007090506');

INSERT INTO schema_migrations (version) VALUES ('20161007090527');

INSERT INTO schema_migrations (version) VALUES ('20161007090546');

INSERT INTO schema_migrations (version) VALUES ('20161007090607');

INSERT INTO schema_migrations (version) VALUES ('20161007090622');

INSERT INTO schema_migrations (version) VALUES ('20161007090708');

INSERT INTO schema_migrations (version) VALUES ('20161007090830');

INSERT INTO schema_migrations (version) VALUES ('20161010044456');

INSERT INTO schema_migrations (version) VALUES ('20161010045021');

INSERT INTO schema_migrations (version) VALUES ('20161010052306');

INSERT INTO schema_migrations (version) VALUES ('20161010052331');

INSERT INTO schema_migrations (version) VALUES ('20161019053445');

INSERT INTO schema_migrations (version) VALUES ('20161019053658');

INSERT INTO schema_migrations (version) VALUES ('20161019064841');

INSERT INTO schema_migrations (version) VALUES ('20161027071106');

INSERT INTO schema_migrations (version) VALUES ('20161027110604');

INSERT INTO schema_migrations (version) VALUES ('20161027111025');

INSERT INTO schema_migrations (version) VALUES ('20161027121442');

INSERT INTO schema_migrations (version) VALUES ('20161102133336');

INSERT INTO schema_migrations (version) VALUES ('20161103094724');

INSERT INTO schema_migrations (version) VALUES ('20161107070850');

INSERT INTO schema_migrations (version) VALUES ('20161107073627');

INSERT INTO schema_migrations (version) VALUES ('20161108093149');

INSERT INTO schema_migrations (version) VALUES ('20161108102156');

INSERT INTO schema_migrations (version) VALUES ('20161110114014');

INSERT INTO schema_migrations (version) VALUES ('20161110114027');

INSERT INTO schema_migrations (version) VALUES ('20161110115341');

INSERT INTO schema_migrations (version) VALUES ('20161116233418');

INSERT INTO schema_migrations (version) VALUES ('20161116233517');

INSERT INTO schema_migrations (version) VALUES ('20161116233527');

INSERT INTO schema_migrations (version) VALUES ('20161116233707');

INSERT INTO schema_migrations (version) VALUES ('20161116233730');

INSERT INTO schema_migrations (version) VALUES ('20161116235323');

INSERT INTO schema_migrations (version) VALUES ('20161116235350');

INSERT INTO schema_migrations (version) VALUES ('20161117125255');

INSERT INTO schema_migrations (version) VALUES ('20161124103445');

INSERT INTO schema_migrations (version) VALUES ('20161127194026');

INSERT INTO schema_migrations (version) VALUES ('20161129214838');

INSERT INTO schema_migrations (version) VALUES ('20161130051234');

INSERT INTO schema_migrations (version) VALUES ('20161206201225');

INSERT INTO schema_migrations (version) VALUES ('20161213055642');

INSERT INTO schema_migrations (version) VALUES ('20170106110541');

INSERT INTO schema_migrations (version) VALUES ('20170116072603');

INSERT INTO schema_migrations (version) VALUES ('20170116073700');

INSERT INTO schema_migrations (version) VALUES ('20170123094330');

INSERT INTO schema_migrations (version) VALUES ('20170125053157');

INSERT INTO schema_migrations (version) VALUES ('20170125053226');

INSERT INTO schema_migrations (version) VALUES ('20170125055641');

INSERT INTO schema_migrations (version) VALUES ('20170125055701');

INSERT INTO schema_migrations (version) VALUES ('20170125070916');

INSERT INTO schema_migrations (version) VALUES ('20170207072720');

INSERT INTO schema_migrations (version) VALUES ('20170213074138');

INSERT INTO schema_migrations (version) VALUES ('20170213074202');

INSERT INTO schema_migrations (version) VALUES ('20170213091644');

INSERT INTO schema_migrations (version) VALUES ('20170217062133');

INSERT INTO schema_migrations (version) VALUES ('20170217062144');

INSERT INTO schema_migrations (version) VALUES ('20170222100731');

INSERT INTO schema_migrations (version) VALUES ('20170223094339');

INSERT INTO schema_migrations (version) VALUES ('20170310130827');

INSERT INTO schema_migrations (version) VALUES ('20170312172034');

INSERT INTO schema_migrations (version) VALUES ('20170314103732');

