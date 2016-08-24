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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: marketrex_depopulate_office_from_agreement(integer, integer); Type: FUNCTION; Schema: public; Owner: marketrex
--

CREATE FUNCTION marketrex_depopulate_office_from_agreement(pagreementid integer, pofficeid integer, OUT counttenantrecords integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
 BEGIN

    create temp table tDepopulateOfficeFromAgreement(
        tenant_record_id int not null primary key
    );

    insert into tDepopulateOfficeFromAgreement(tenant_record_id)
    select tenant_records.id from tenant_records
      join agreements_tenant_records on tenant_records.id = agreements_tenant_records.tenant_record_id
      join agreements                on agreements.id = agreements_tenant_records.agreement_id
      join agreements_offices        on agreements_offices.agreement_id = agreements.id
    where agreements.office_default = true
      and agreements_offices.office_id = pOfficeId;

    delete from agreements_tenant_records
      where agreement_id = pAgreementId
        and tenant_record_id IN ( SELECT tenant_record_id FROM tDepopulateOfficeFromAgreement);

    drop table if exists tDepopulateOfficeFromAgreement;

    select count(tenant_record_id) into countTenantRecords from agreements_tenant_records where agreement_id = pAgreementId;

END ;
$$;


ALTER FUNCTION public.marketrex_depopulate_office_from_agreement(pagreementid integer, pofficeid integer, OUT counttenantrecords integer) OWNER TO marketrex;

--
-- Name: marketrex_populate_office_into_agreement(integer, integer); Type: FUNCTION; Schema: public; Owner: marketrex
--

CREATE FUNCTION marketrex_populate_office_into_agreement(pagreementid integer, pofficeid integer, OUT counttenantrecords integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
 BEGIN

    insert into agreements_tenant_records(agreement_id, tenant_record_id)
    select pAgreementId, tenant_records.id from tenant_records
      join agreements_tenant_records on tenant_records.id = agreements_tenant_records.tenant_record_id
      join agreements                on agreements.id = agreements_tenant_records.agreement_id
      join agreements_offices        on agreements_offices.agreement_id = agreements.id
    where agreements.office_default = true
      and agreements_offices.office_id = pOfficeId
      and tenant_records.comp_type = 'internal'
      and tenant_records.view_type NOT IN ('private');

    select count(tenant_record_id) into countTenantRecords from agreements_tenant_records where agreement_id = pAgreementId;

END ;
$$;


ALTER FUNCTION public.marketrex_populate_office_into_agreement(pagreementid integer, pofficeid integer, OUT counttenantrecords integer) OWNER TO marketrex;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_features; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE account_features (
    id integer NOT NULL,
    show_marketrex_cashflow boolean DEFAULT false,
    show_marketrex_output boolean DEFAULT false,
    account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_type character varying(255) DEFAULT 'cushman'::character varying
);


ALTER TABLE public.account_features OWNER TO marketrex;

--
-- Name: account_features_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE account_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_features_id_seq OWNER TO marketrex;

--
-- Name: account_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE account_features_id_seq OWNED BY account_features.id;


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO marketrex;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE accounts (
    id integer DEFAULT nextval('accounts_id_seq'::regclass) NOT NULL,
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


ALTER TABLE public.accounts OWNER TO marketrex;

--
-- Name: accounts_teams; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE accounts_teams (
    id integer NOT NULL,
    account_id integer,
    team_id integer
);


ALTER TABLE public.accounts_teams OWNER TO marketrex;

--
-- Name: accounts_teams_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE accounts_teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_teams_id_seq OWNER TO marketrex;

--
-- Name: accounts_teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE accounts_teams_id_seq OWNED BY accounts_teams.id;


--
-- Name: agreements_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE agreements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agreements_id_seq OWNER TO marketrex;

--
-- Name: agreements; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE agreements (
    id integer DEFAULT nextval('agreements_id_seq'::regclass) NOT NULL,
    name character varying(255),
    description text,
    office_default boolean DEFAULT false,
    agreement_start_date timestamp without time zone,
    agreement_end_date timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.agreements OWNER TO marketrex;

--
-- Name: agreements_offices; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE agreements_offices (
    agreement_id integer,
    office_id integer
);


ALTER TABLE public.agreements_offices OWNER TO marketrex;

--
-- Name: agreements_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE agreements_tenant_records (
    agreement_id integer,
    tenant_record_id integer
);


ALTER TABLE public.agreements_tenant_records OWNER TO marketrex;

--
-- Name: archive_migration_tenant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE archive_migration_tenant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.archive_migration_tenant_records_id_seq OWNER TO marketrex;

--
-- Name: archive_migration_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE archive_migration_tenant_records (
    id integer DEFAULT nextval('archive_migration_tenant_records_id_seq'::regclass) NOT NULL,
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


ALTER TABLE public.archive_migration_tenant_records OWNER TO marketrex;

--
-- Name: custom_report_header_custom_fields; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_report_header_custom_fields (
    id integer NOT NULL,
    custom_report_header_id integer,
    custom_field_name character varying(255),
    "order" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.custom_report_header_custom_fields OWNER TO marketrex;

--
-- Name: custom_report_header_custom_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_report_header_custom_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_report_header_custom_fields_id_seq OWNER TO marketrex;

--
-- Name: custom_report_header_custom_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_report_header_custom_fields_id_seq OWNED BY custom_report_header_custom_fields.id;


--
-- Name: custom_report_header_fields; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_report_header_fields (
    id integer NOT NULL,
    custom_report_header_id integer,
    tenant_record_sub_category_id integer,
    "order" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.custom_report_header_fields OWNER TO marketrex;

--
-- Name: custom_report_header_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_report_header_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_report_header_fields_id_seq OWNER TO marketrex;

--
-- Name: custom_report_header_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_report_header_fields_id_seq OWNED BY custom_report_header_fields.id;


--
-- Name: custom_report_headers; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_report_headers (
    id integer NOT NULL,
    bg_color character varying(255),
    tenant_record_category_id integer,
    custom_report_id integer,
    "order" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    header_name character varying(255)
);


ALTER TABLE public.custom_report_headers OWNER TO marketrex;

--
-- Name: custom_report_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_report_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_report_headers_id_seq OWNER TO marketrex;

--
-- Name: custom_report_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_report_headers_id_seq OWNED BY custom_report_headers.id;


--
-- Name: custom_report_summary_column_names; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_report_summary_column_names (
    id integer NOT NULL,
    label_name character varying(255),
    custom_report_id integer,
    custom_report_summary_field_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "order" integer
);


ALTER TABLE public.custom_report_summary_column_names OWNER TO marketrex;

--
-- Name: custom_report_summary_column_names_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_report_summary_column_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_report_summary_column_names_id_seq OWNER TO marketrex;

--
-- Name: custom_report_summary_column_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_report_summary_column_names_id_seq OWNED BY custom_report_summary_column_names.id;


--
-- Name: custom_report_summary_fields; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_report_summary_fields (
    id integer NOT NULL,
    field_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    label_name character varying(255)
);


ALTER TABLE public.custom_report_summary_fields OWNER TO marketrex;

--
-- Name: custom_report_summary_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_report_summary_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_report_summary_fields_id_seq OWNER TO marketrex;

--
-- Name: custom_report_summary_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_report_summary_fields_id_seq OWNED BY custom_report_summary_fields.id;


--
-- Name: custom_reports; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE custom_reports (
    id integer NOT NULL,
    name character varying(255),
    bg_color character varying(255),
    template_type character varying(255),
    report_template_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "default" boolean DEFAULT false
);


ALTER TABLE public.custom_reports OWNER TO marketrex;

--
-- Name: custom_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE custom_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_reports_id_seq OWNER TO marketrex;

--
-- Name: custom_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE custom_reports_id_seq OWNED BY custom_reports.id;


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE expenses (
    id integer NOT NULL,
    name character varying(255),
    display_order integer DEFAULT 0
);


ALTER TABLE public.expenses OWNER TO marketrex;

--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.expenses_id_seq OWNER TO marketrex;

--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE expenses_id_seq OWNED BY expenses.id;


--
-- Name: firms_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE firms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.firms_id_seq OWNER TO marketrex;

--
-- Name: firms; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE firms (
    id integer DEFAULT nextval('firms_id_seq'::regclass) NOT NULL,
    name character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.firms OWNER TO marketrex;

--
-- Name: import_logs; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE import_logs (
    id integer NOT NULL,
    tenant_record_import_id integer,
    office_id integer,
    tenant_record_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.import_logs OWNER TO marketrex;

--
-- Name: import_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE import_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_logs_id_seq OWNER TO marketrex;

--
-- Name: import_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE import_logs_id_seq OWNED BY import_logs.id;


--
-- Name: import_mappings; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
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


ALTER TABLE public.import_mappings OWNER TO marketrex;

--
-- Name: import_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE import_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_mappings_id_seq OWNER TO marketrex;

--
-- Name: import_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE import_mappings_id_seq OWNED BY import_mappings.id;


--
-- Name: import_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
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


ALTER TABLE public.import_records OWNER TO marketrex;

--
-- Name: import_records_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE import_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_records_id_seq OWNER TO marketrex;

--
-- Name: import_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE import_records_id_seq OWNED BY import_records.id;


--
-- Name: import_templates; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE import_templates (
    id integer NOT NULL,
    office_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    reusable boolean DEFAULT true
);


ALTER TABLE public.import_templates OWNER TO marketrex;

--
-- Name: import_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE import_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_templates_id_seq OWNER TO marketrex;

--
-- Name: import_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE import_templates_id_seq OWNED BY import_templates.id;


--
-- Name: industry_sic_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE industry_sic_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.industry_sic_codes_id_seq OWNER TO marketrex;

--
-- Name: industry_sic_codes; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE industry_sic_codes (
    id integer DEFAULT nextval('industry_sic_codes_id_seq'::regclass) NOT NULL,
    value character varying(255),
    description character varying(255),
    division character varying(255),
    major_group character varying(255),
    industry_group character varying(255),
    division_desc character varying(255),
    major_group_desc character varying(255),
    industry_group_desc character varying(255)
);


ALTER TABLE public.industry_sic_codes OWNER TO marketrex;

--
-- Name: learn_more_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE learn_more_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.learn_more_requests_id_seq OWNER TO marketrex;

--
-- Name: learn_more_requests; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE learn_more_requests (
    id integer DEFAULT nextval('learn_more_requests_id_seq'::regclass) NOT NULL,
    fullname character varying(255),
    brokerage_firm character varying(255),
    email character varying(255),
    market_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.learn_more_requests OWNER TO marketrex;

--
-- Name: lease_structure_expenses; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lease_structure_expenses (
    id integer NOT NULL,
    lease_structure_id integer,
    calculation_type character varying(255),
    default_cost numeric,
    increase_percent numeric,
    start_date date,
    name character varying(255)
);


ALTER TABLE public.lease_structure_expenses OWNER TO marketrex;

--
-- Name: lease_structure_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lease_structure_expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lease_structure_expenses_id_seq OWNER TO marketrex;

--
-- Name: lease_structure_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lease_structure_expenses_id_seq OWNED BY lease_structure_expenses.id;


--
-- Name: lease_structures; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lease_structures (
    id integer NOT NULL,
    name character varying(255),
    description text,
    account_id integer,
    discount_rate numeric(4,2),
    office_id integer,
    interest_rate numeric(4,2) DEFAULT 0
);


ALTER TABLE public.lease_structures OWNER TO marketrex;

--
-- Name: lease_structures_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lease_structures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lease_structures_id_seq OWNER TO marketrex;

--
-- Name: lease_structures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lease_structures_id_seq OWNED BY lease_structures.id;


--
-- Name: lookup_address_zipcodes; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_address_zipcodes (
    id integer NOT NULL,
    name character varying(255),
    city character varying(255),
    state character varying(255),
    location geometry(Point,3785)
);


ALTER TABLE public.lookup_address_zipcodes OWNER TO marketrex;

--
-- Name: lookup_address_zipcodes_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lookup_address_zipcodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lookup_address_zipcodes_id_seq OWNER TO marketrex;

--
-- Name: lookup_address_zipcodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lookup_address_zipcodes_id_seq OWNED BY lookup_address_zipcodes.id;


--
-- Name: lookup_address_zipcodes_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_address_zipcodes_tenant_records (
    tenant_record_id integer,
    lookup_address_zipcode_id integer
);


ALTER TABLE public.lookup_address_zipcodes_tenant_records OWNER TO marketrex;

--
-- Name: lookup_companies; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_companies (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.lookup_companies OWNER TO marketrex;

--
-- Name: lookup_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lookup_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lookup_companies_id_seq OWNER TO marketrex;

--
-- Name: lookup_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lookup_companies_id_seq OWNED BY lookup_companies.id;


--
-- Name: lookup_companies_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_companies_tenant_records (
    tenant_record_id integer,
    lookup_company_id integer
);


ALTER TABLE public.lookup_companies_tenant_records OWNER TO marketrex;

--
-- Name: lookup_property_names; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_property_names (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.lookup_property_names OWNER TO marketrex;

--
-- Name: lookup_property_names_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lookup_property_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lookup_property_names_id_seq OWNER TO marketrex;

--
-- Name: lookup_property_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lookup_property_names_id_seq OWNED BY lookup_property_names.id;


--
-- Name: lookup_property_names_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_property_names_tenant_records (
    tenant_record_id integer,
    lookup_property_name_id integer
);


ALTER TABLE public.lookup_property_names_tenant_records OWNER TO marketrex;

--
-- Name: lookup_submarkets; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_submarkets (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.lookup_submarkets OWNER TO marketrex;

--
-- Name: lookup_submarkets_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE lookup_submarkets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lookup_submarkets_id_seq OWNER TO marketrex;

--
-- Name: lookup_submarkets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE lookup_submarkets_id_seq OWNED BY lookup_submarkets.id;


--
-- Name: lookup_submarkets_tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE lookup_submarkets_tenant_records (
    tenant_record_id integer,
    lookup_submarket_id integer
);


ALTER TABLE public.lookup_submarkets_tenant_records OWNER TO marketrex;

--
-- Name: maps_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.maps_id_seq OWNER TO marketrex;

--
-- Name: maps; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE maps (
    id integer DEFAULT nextval('maps_id_seq'::regclass) NOT NULL,
    account_id integer,
    office_id integer,
    name character varying(255),
    mode character varying(255),
    latitude text,
    longitude text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.maps OWNER TO marketrex;

--
-- Name: markets_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE markets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.markets_id_seq OWNER TO marketrex;

--
-- Name: markets; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE markets (
    id integer DEFAULT nextval('markets_id_seq'::regclass) NOT NULL,
    name character varying(255),
    is_preferred boolean DEFAULT false,
    description character varying(255)
);


ALTER TABLE public.markets OWNER TO marketrex;

--
-- Name: offices_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE offices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.offices_id_seq OWNER TO marketrex;

--
-- Name: offices; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE offices (
    id integer DEFAULT nextval('offices_id_seq'::regclass) NOT NULL,
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


ALTER TABLE public.offices OWNER TO marketrex;

--
-- Name: ownerships; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE ownerships (
    id integer NOT NULL,
    account_id integer,
    tenant_record_id integer
);


ALTER TABLE public.ownerships OWNER TO marketrex;

--
-- Name: ownerships_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE ownerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ownerships_id_seq OWNER TO marketrex;

--
-- Name: ownerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE ownerships_id_seq OWNED BY ownerships.id;


--
-- Name: report_templates; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE report_templates (
    id integer NOT NULL,
    template_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.report_templates OWNER TO marketrex;

--
-- Name: report_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE report_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_templates_id_seq OWNER TO marketrex;

--
-- Name: report_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE report_templates_id_seq OWNED BY report_templates.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO marketrex;

--
-- Name: stepped_rents; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE stepped_rents (
    id integer NOT NULL,
    tenant_record_id integer,
    "order" integer,
    months integer,
    cost_per_month numeric(20,2),
    deleted_at timestamp without time zone
);


ALTER TABLE public.stepped_rents OWNER TO marketrex;

--
-- Name: stepped_rents_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE stepped_rents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stepped_rents_id_seq OWNER TO marketrex;

--
-- Name: stepped_rents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE stepped_rents_id_seq OWNED BY stepped_rents.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE teams (
    id integer NOT NULL,
    office_id integer,
    name character varying(255),
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    multi_user boolean DEFAULT true
);


ALTER TABLE public.teams OWNER TO marketrex;

--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teams_id_seq OWNER TO marketrex;

--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: tenant_record_categories; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE tenant_record_categories (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.tenant_record_categories OWNER TO marketrex;

--
-- Name: tenant_record_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE tenant_record_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenant_record_categories_id_seq OWNER TO marketrex;

--
-- Name: tenant_record_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE tenant_record_categories_id_seq OWNED BY tenant_record_categories.id;


--
-- Name: tenant_record_category_fields; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
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


ALTER TABLE public.tenant_record_category_fields OWNER TO marketrex;

--
-- Name: tenant_record_category_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE tenant_record_category_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenant_record_category_fields_id_seq OWNER TO marketrex;

--
-- Name: tenant_record_category_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE tenant_record_category_fields_id_seq OWNED BY tenant_record_category_fields.id;


--
-- Name: tenant_record_images; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
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


ALTER TABLE public.tenant_record_images OWNER TO marketrex;

--
-- Name: tenant_record_images_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE tenant_record_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenant_record_images_id_seq OWNER TO marketrex;

--
-- Name: tenant_record_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE tenant_record_images_id_seq OWNED BY tenant_record_images.id;


--
-- Name: tenant_record_imports; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE tenant_record_imports (
    id integer NOT NULL,
    office_id integer,
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
    team_id integer,
    total_traversed_count integer DEFAULT 0
);


ALTER TABLE public.tenant_record_imports OWNER TO marketrex;

--
-- Name: tenant_record_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE tenant_record_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenant_record_imports_id_seq OWNER TO marketrex;

--
-- Name: tenant_record_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: marketrex
--

ALTER SEQUENCE tenant_record_imports_id_seq OWNED BY tenant_record_imports.id;


--
-- Name: tenant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE tenant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenant_records_id_seq OWNER TO marketrex;

--
-- Name: tenant_records; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
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
    company_logo_updated_at timestamp without time zone
);


ALTER TABLE public.tenant_records OWNER TO marketrex;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: marketrex
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO marketrex;

--
-- Name: users; Type: TABLE; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE TABLE users (
    id integer DEFAULT nextval('users_id_seq'::regclass) NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying(255),
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO marketrex;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY account_features ALTER COLUMN id SET DEFAULT nextval('account_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY accounts_teams ALTER COLUMN id SET DEFAULT nextval('accounts_teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_report_header_custom_fields ALTER COLUMN id SET DEFAULT nextval('custom_report_header_custom_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_report_header_fields ALTER COLUMN id SET DEFAULT nextval('custom_report_header_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_report_headers ALTER COLUMN id SET DEFAULT nextval('custom_report_headers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_report_summary_column_names ALTER COLUMN id SET DEFAULT nextval('custom_report_summary_column_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_report_summary_fields ALTER COLUMN id SET DEFAULT nextval('custom_report_summary_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY custom_reports ALTER COLUMN id SET DEFAULT nextval('custom_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY expenses ALTER COLUMN id SET DEFAULT nextval('expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY import_logs ALTER COLUMN id SET DEFAULT nextval('import_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY import_mappings ALTER COLUMN id SET DEFAULT nextval('import_mappings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY import_records ALTER COLUMN id SET DEFAULT nextval('import_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY import_templates ALTER COLUMN id SET DEFAULT nextval('import_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lease_structure_expenses ALTER COLUMN id SET DEFAULT nextval('lease_structure_expenses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lease_structures ALTER COLUMN id SET DEFAULT nextval('lease_structures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lookup_address_zipcodes ALTER COLUMN id SET DEFAULT nextval('lookup_address_zipcodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lookup_companies ALTER COLUMN id SET DEFAULT nextval('lookup_companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lookup_property_names ALTER COLUMN id SET DEFAULT nextval('lookup_property_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY lookup_submarkets ALTER COLUMN id SET DEFAULT nextval('lookup_submarkets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY ownerships ALTER COLUMN id SET DEFAULT nextval('ownerships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY report_templates ALTER COLUMN id SET DEFAULT nextval('report_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY stepped_rents ALTER COLUMN id SET DEFAULT nextval('stepped_rents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY tenant_record_categories ALTER COLUMN id SET DEFAULT nextval('tenant_record_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY tenant_record_category_fields ALTER COLUMN id SET DEFAULT nextval('tenant_record_category_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY tenant_record_images ALTER COLUMN id SET DEFAULT nextval('tenant_record_images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: marketrex
--

ALTER TABLE ONLY tenant_record_imports ALTER COLUMN id SET DEFAULT nextval('tenant_record_imports_id_seq'::regclass);



--
-- Name: account_features_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY account_features
    ADD CONSTRAINT account_features_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: accounts_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY accounts_teams
    ADD CONSTRAINT accounts_teams_pkey PRIMARY KEY (id);


--
-- Name: agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY agreements
    ADD CONSTRAINT agreements_pkey PRIMARY KEY (id);


--
-- Name: archive_migration_tenant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY archive_migration_tenant_records
    ADD CONSTRAINT archive_migration_tenant_records_pkey PRIMARY KEY (id);


--
-- Name: custom_report_header_custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_report_header_custom_fields
    ADD CONSTRAINT custom_report_header_custom_fields_pkey PRIMARY KEY (id);


--
-- Name: custom_report_header_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_report_header_fields
    ADD CONSTRAINT custom_report_header_fields_pkey PRIMARY KEY (id);


--
-- Name: custom_report_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_report_headers
    ADD CONSTRAINT custom_report_headers_pkey PRIMARY KEY (id);


--
-- Name: custom_report_summary_column_names_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_report_summary_column_names
    ADD CONSTRAINT custom_report_summary_column_names_pkey PRIMARY KEY (id);


--
-- Name: custom_report_summary_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_report_summary_fields
    ADD CONSTRAINT custom_report_summary_fields_pkey PRIMARY KEY (id);


--
-- Name: custom_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY custom_reports
    ADD CONSTRAINT custom_reports_pkey PRIMARY KEY (id);


--
-- Name: expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: firms_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY firms
    ADD CONSTRAINT firms_pkey PRIMARY KEY (id);


--
-- Name: import_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id);


--
-- Name: import_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY import_mappings
    ADD CONSTRAINT import_mappings_pkey PRIMARY KEY (id);


--
-- Name: import_records_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY import_records
    ADD CONSTRAINT import_records_pkey PRIMARY KEY (id);


--
-- Name: import_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY import_templates
    ADD CONSTRAINT import_templates_pkey PRIMARY KEY (id);


--
-- Name: industry_sic_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY industry_sic_codes
    ADD CONSTRAINT industry_sic_codes_pkey PRIMARY KEY (id);


--
-- Name: learn_more_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY learn_more_requests
    ADD CONSTRAINT learn_more_requests_pkey PRIMARY KEY (id);


--
-- Name: lease_structure_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lease_structure_expenses
    ADD CONSTRAINT lease_structure_expenses_pkey PRIMARY KEY (id);


--
-- Name: lease_structures_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lease_structures
    ADD CONSTRAINT lease_structures_pkey PRIMARY KEY (id);


--
-- Name: lookup_address_zipcodes_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lookup_address_zipcodes
    ADD CONSTRAINT lookup_address_zipcodes_pkey PRIMARY KEY (id);


--
-- Name: lookup_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lookup_companies
    ADD CONSTRAINT lookup_companies_pkey PRIMARY KEY (id);


--
-- Name: lookup_property_names_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lookup_property_names
    ADD CONSTRAINT lookup_property_names_pkey PRIMARY KEY (id);


--
-- Name: lookup_submarkets_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY lookup_submarkets
    ADD CONSTRAINT lookup_submarkets_pkey PRIMARY KEY (id);


--
-- Name: maps_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY maps
    ADD CONSTRAINT maps_pkey PRIMARY KEY (id);


--
-- Name: markets_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY markets
    ADD CONSTRAINT markets_pkey PRIMARY KEY (id);


--
-- Name: offices_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: ownerships_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY ownerships
    ADD CONSTRAINT ownerships_pkey PRIMARY KEY (id);


--
-- Name: report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY report_templates
    ADD CONSTRAINT report_templates_pkey PRIMARY KEY (id);


--
-- Name: stepped_rents_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY stepped_rents
    ADD CONSTRAINT stepped_rents_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY tenant_record_categories
    ADD CONSTRAINT tenant_record_categories_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_category_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY tenant_record_category_fields
    ADD CONSTRAINT tenant_record_category_fields_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_images_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY tenant_record_images
    ADD CONSTRAINT tenant_record_images_pkey PRIMARY KEY (id);


--
-- Name: tenant_record_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY tenant_record_imports
    ADD CONSTRAINT tenant_record_imports_pkey PRIMARY KEY (id);


--
-- Name: tenant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY tenant_records
    ADD CONSTRAINT tenant_records_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: marketrex; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_accounts_on_firm_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_accounts_on_firm_id ON accounts USING btree (firm_id);


--
-- Name: index_accounts_on_office_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_accounts_on_office_id ON accounts USING btree (office_id);


--
-- Name: index_accounts_on_user_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_accounts_on_user_id ON accounts USING btree (user_id);


--
-- Name: index_agreement_tenant_record; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_agreement_tenant_record ON agreements_tenant_records USING btree (agreement_id, tenant_record_id);


--
-- Name: index_agreements_offices_on_agreement_id_and_office_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_agreements_offices_on_agreement_id_and_office_id ON agreements_offices USING btree (agreement_id, office_id);


--
-- Name: index_agreements_offices_on_office_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_agreements_offices_on_office_id ON agreements_offices USING btree (office_id);


--
-- Name: index_agreements_tenant_records_on_tenant_record_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_agreements_tenant_records_on_tenant_record_id ON agreements_tenant_records USING btree (tenant_record_id);


--
-- Name: index_import_templates_on_name_and_office_id_and_reusable; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_import_templates_on_name_and_office_id_and_reusable ON import_templates USING btree (name, office_id, reusable);


--
-- Name: index_lease_structure_expenses_on_lease_structure_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lease_structure_expenses_on_lease_structure_id ON lease_structure_expenses USING btree (lease_structure_id);


--
-- Name: index_lease_structures_on_name_and_account_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_lease_structures_on_name_and_account_id ON lease_structures USING btree (name, account_id);


--
-- Name: index_lookup_address_zipcodes_on_location; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lookup_address_zipcodes_on_location ON lookup_address_zipcodes USING gist (location);


--
-- Name: index_lookup_address_zipcodes_on_name; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lookup_address_zipcodes_on_name ON lookup_address_zipcodes USING btree (name);


--
-- Name: index_lookup_companies_on_name; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lookup_companies_on_name ON lookup_companies USING btree (name);


--
-- Name: index_lookup_property_names_on_name; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lookup_property_names_on_name ON lookup_property_names USING btree (name);


--
-- Name: index_lookup_submarkets_on_name; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_lookup_submarkets_on_name ON lookup_submarkets USING btree (name);


--
-- Name: index_maps_on_account_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_maps_on_account_id ON maps USING btree (account_id);


--
-- Name: index_maps_on_office_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_maps_on_office_id ON maps USING btree (office_id);


--
-- Name: index_offices_on_firm_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_offices_on_firm_id ON offices USING btree (firm_id);


--
-- Name: index_stepped_rents_on_deleted_at; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_stepped_rents_on_deleted_at ON stepped_rents USING btree (deleted_at);


--
-- Name: index_tenant_records_on_address1; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_tenant_records_on_address1 ON tenant_records USING btree (lower((address1)::text) varchar_pattern_ops);


--
-- Name: index_tenant_records_on_industry_sic_code_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_tenant_records_on_industry_sic_code_id ON tenant_records USING btree (industry_sic_code_id);


--
-- Name: index_tenant_records_on_office_id; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE INDEX index_tenant_records_on_office_id ON tenant_records USING btree (office_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: marketrex; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

