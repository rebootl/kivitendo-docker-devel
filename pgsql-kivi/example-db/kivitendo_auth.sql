--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5 (Debian 11.5-3.pgdg90+1)
-- Dumped by pg_dump version 11.5 (Debian 11.5-3.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: kivitendo_auth; Type: DATABASE; Schema: -; Owner: kivitendo
--

CREATE DATABASE kivitendo_auth WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';


ALTER DATABASE kivitendo_auth OWNER TO kivitendo;

\connect kivitendo_auth

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: kivitendo
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO kivitendo;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: clients; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.clients (
    id integer NOT NULL,
    name text NOT NULL,
    dbhost text NOT NULL,
    dbport integer DEFAULT 5432 NOT NULL,
    dbname text NOT NULL,
    dbuser text NOT NULL,
    dbpasswd text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    task_server_user_id integer
);


ALTER TABLE auth.clients OWNER TO kivitendo;

--
-- Name: clients_groups; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.clients_groups (
    client_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE auth.clients_groups OWNER TO kivitendo;

--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: auth; Owner: kivitendo
--

CREATE SEQUENCE auth.clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.clients_id_seq OWNER TO kivitendo;

--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: kivitendo
--

ALTER SEQUENCE auth.clients_id_seq OWNED BY auth.clients.id;


--
-- Name: clients_users; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.clients_users (
    client_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE auth.clients_users OWNER TO kivitendo;

--
-- Name: group_id_seq; Type: SEQUENCE; Schema: auth; Owner: kivitendo
--

CREATE SEQUENCE auth.group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.group_id_seq OWNER TO kivitendo;

--
-- Name: group; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth."group" (
    id integer DEFAULT nextval('auth.group_id_seq'::regclass) NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE auth."group" OWNER TO kivitendo;

--
-- Name: group_rights; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.group_rights (
    group_id integer NOT NULL,
    "right" text NOT NULL,
    granted boolean NOT NULL
);


ALTER TABLE auth.group_rights OWNER TO kivitendo;

--
-- Name: master_rights; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.master_rights (
    id integer NOT NULL,
    "position" integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    category boolean DEFAULT false NOT NULL
);


ALTER TABLE auth.master_rights OWNER TO kivitendo;

--
-- Name: master_rights_id_seq; Type: SEQUENCE; Schema: auth; Owner: kivitendo
--

CREATE SEQUENCE auth.master_rights_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.master_rights_id_seq OWNER TO kivitendo;

--
-- Name: master_rights_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: kivitendo
--

ALTER SEQUENCE auth.master_rights_id_seq OWNED BY auth.master_rights.id;


--
-- Name: schema_info; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.schema_info (
    tag text NOT NULL,
    login text,
    itime timestamp without time zone DEFAULT now()
);


ALTER TABLE auth.schema_info OWNER TO kivitendo;

--
-- Name: session; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.session (
    id text NOT NULL,
    ip_address inet,
    mtime timestamp without time zone,
    api_token text
);


ALTER TABLE auth.session OWNER TO kivitendo;

--
-- Name: session_content; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.session_content (
    session_id text NOT NULL,
    sess_key text NOT NULL,
    sess_value text,
    auto_restore boolean
);


ALTER TABLE auth.session_content OWNER TO kivitendo;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: auth; Owner: kivitendo
--

CREATE SEQUENCE auth.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.user_id_seq OWNER TO kivitendo;

--
-- Name: user; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth."user" (
    id integer DEFAULT nextval('auth.user_id_seq'::regclass) NOT NULL,
    login text NOT NULL,
    password text
);


ALTER TABLE auth."user" OWNER TO kivitendo;

--
-- Name: user_config; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.user_config (
    user_id integer NOT NULL,
    cfg_key text NOT NULL,
    cfg_value text
);


ALTER TABLE auth.user_config OWNER TO kivitendo;

--
-- Name: user_group; Type: TABLE; Schema: auth; Owner: kivitendo
--

CREATE TABLE auth.user_group (
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE auth.user_group OWNER TO kivitendo;

--
-- Name: clients id; Type: DEFAULT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients ALTER COLUMN id SET DEFAULT nextval('auth.clients_id_seq'::regclass);


--
-- Name: master_rights id; Type: DEFAULT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.master_rights ALTER COLUMN id SET DEFAULT nextval('auth.master_rights_id_seq'::regclass);


--
-- Data for Name: clients; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.clients (id, name, dbhost, dbport, dbname, dbuser, dbpasswd, is_default, task_server_user_id) FROM stdin;
1	mycompany2	mypgsql-test	5432	mycompany2	kivitendo	mypass123	t	\N
\.


--
-- Data for Name: clients_groups; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.clients_groups (client_id, group_id) FROM stdin;
1	1
\.


--
-- Data for Name: clients_users; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.clients_users (client_id, user_id) FROM stdin;
1	1
\.


--
-- Data for Name: group; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth."group" (id, name, description) FROM stdin;
1	Vollzugriff	Vollzugriff auf alle Funktionen
\.


--
-- Data for Name: group_rights; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.group_rights (group_id, "right", granted) FROM stdin;
1	customer_vendor_edit	t
1	customer_vendor_all_edit	t
1	part_service_assembly_edit	t
1	part_service_assembly_details	t
1	assembly_edit	t
1	shop_part_edit	t
1	project_edit	t
1	project_edit_view_invoices_permission	t
1	show_extra_record_tab_customer	t
1	show_extra_record_tab_vendor	t
1	requirement_spec_edit	t
1	sales_quotation_edit	t
1	shop_order	t
1	sales_order_edit	t
1	sales_delivery_order_edit	t
1	invoice_edit	t
1	dunning_edit	t
1	sales_letter_edit	t
1	sales_all_edit	t
1	edit_prices	t
1	show_ar_transactions	t
1	delivery_plan	t
1	delivery_value_report	t
1	sales_letter_report	t
1	import_ar	t
1	request_quotation_edit	t
1	purchase_order_edit	t
1	purchase_delivery_order_edit	t
1	vendor_invoice_edit	t
1	show_ap_transactions	t
1	import_ap	t
1	warehouse_contents	t
1	warehouse_management	t
1	general_ledger	t
1	gl_transactions	t
1	ar_transactions	t
1	ap_transactions	t
1	datev_export	t
1	cash	t
1	bank_transaction	t
1	report	t
1	advance_turnover_tax_return	t
1	batch_printing	t
1	config	t
1	admin	t
1	edit_shop_config	t
1	custom_data_export_designer	t
1	email_bcc	t
1	email_journal	t
1	email_employee_readall	t
1	productivity	t
1	display_admin_link	t
1	record_links	t
1	purchase_letter_edit	t
1	purchase_letter_report	t
1	all_drafts_edit	t
\.


--
-- Data for Name: master_rights; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.master_rights (id, "position", name, description, category) FROM stdin;
1	100	master_data	Master Data	t
2	200	customer_vendor_edit	Create customers and vendors. Edit all vendors. Edit only customers where salesman equals employee (login)	f
3	300	customer_vendor_all_edit	Create customers and vendors. Edit all vendors. Edit all customers	f
4	400	part_service_assembly_edit	Create and edit parts, services, assemblies	f
5	500	part_service_assembly_details	Show details and reports of parts, services, assemblies	f
6	600	project_edit	Create and edit projects	f
7	700	ar	AR	t
8	800	requirement_spec_edit	Create and edit requirement specs	f
9	900	sales_quotation_edit	Create and edit sales quotations	f
10	1000	sales_order_edit	Create and edit sales orders	f
11	1100	sales_delivery_order_edit	Create and edit sales delivery orders	f
12	1200	invoice_edit	Create and edit invoices and credit notes	f
13	1300	dunning_edit	Create and edit dunnings	f
14	1400	sales_letter_edit	Edit sales letters	f
15	1500	sales_all_edit	View/edit all employees sales documents	f
16	1600	edit_prices	Edit prices and discount (if not used, textfield is ONLY set readonly)	f
17	1700	show_ar_transactions	Show AR transactions as part of AR invoice report	f
18	1800	delivery_plan	Show delivery plan	f
19	1900	delivery_value_report	Show delivery value report	f
20	2000	sales_letter_report	Show sales letters report	f
21	2100	ap	AP	t
22	2200	request_quotation_edit	Create and edit RFQs	f
23	2300	purchase_order_edit	Create and edit purchase orders	f
24	2400	purchase_delivery_order_edit	Create and edit purchase delivery orders	f
25	2500	vendor_invoice_edit	Create and edit vendor invoices	f
26	2600	show_ap_transactions	Show AP transactions as part of AP invoice report	f
27	2700	warehouse	Warehouse management	t
28	2800	warehouse_contents	View warehouse content	f
29	2900	warehouse_management	Warehouse management	f
30	3000	general_ledger_cash	General ledger and cash	t
32	3200	datev_export	DATEV Export	f
33	3300	cash	Receipt, payment, reconciliation	f
34	3400	bank_transaction	Bank transactions	f
35	3500	reports	Reports	t
36	3600	report	All reports	f
37	3700	advance_turnover_tax_return	Advance turnover tax return	f
38	3800	batch_printing_category	Batch Printing	t
39	3900	batch_printing	Batch Printing	f
40	4000	configuration	Configuration	t
41	4100	config	Change kivitendo installation settings (most entries in the 'System' menu)	f
43	4300	others	Others	t
45	4500	productivity	Productivity	f
31	3100	general_ledger	AP/AR Aging & Journal	f
42	4200	admin	Client administration: configuration, editing templates, task server control, background jobs (remaining entries in the 'System' menu)	f
44	4400	email_bcc	May set the BCC field when sending emails	f
46	4600	display_admin_link	Show administration link	f
47	255000	purchase_letter_edit	Edit purchase letters	f
48	265000	purchase_letter_report	Show purchase letters report	f
49	500000	all_drafts_edit	Edit all drafts	f
50	4450	email_journal	E-Mail-Journal	f
51	4480	email_employee_readall	Read all employee e-mails	f
52	2050	import_ar	Import AR from Scanner or Email	f
54	4750	record_links	Linked Records	f
55	3130	gl_transactions	General Ledger Transaction	f
56	3150	ar_transactions	AR Transactions	f
57	3170	ap_transactions	AP Transactions	f
53	2680	import_ap	Import AP from Scanner or Email	f
58	550	assembly_edit	Always edit assembly items (user can change/delete items even if assemblies are already produced)	f
59	4275	custom_data_export_designer	Custom data export	f
60	550	shop_part_edit	Create and edit shopparts	f
61	950	shop_order	Get shoporders	f
62	4250	edit_shop_config	Create and edit webshops	f
63	610	show_extra_record_tab_customer	Show record tab in customer	f
64	611	show_extra_record_tab_vendor	Show record tab in vendor	f
65	602	project_edit_view_invoices_permission	Projects: edit the list of employees allowed to view invoices	f
\.


--
-- Data for Name: schema_info; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.schema_info (tag, login, itime) FROM stdin;
add_api_token	admin	2019-10-15 11:35:50.630594
add_batch_printing_to_full_access	admin	2019-10-15 11:35:50.646001
auth_schema_normalization_1	admin	2019-10-15 11:35:50.658486
password_hashing	admin	2019-10-15 11:35:50.741624
remove_menustyle_v4	admin	2019-10-15 11:35:50.750032
remove_menustyle_xml	admin	2019-10-15 11:35:50.759044
session_content_auto_restore	admin	2019-10-15 11:35:50.767311
release_3_0_0	admin	2019-10-15 11:35:50.775758
clients	admin	2019-10-15 11:35:50.78688
clients_webdav	admin	2019-10-15 11:35:51.003997
foreign_key_constraints_on_delete	admin	2019-10-15 11:35:51.016707
release_3_2_0	admin	2019-10-15 11:35:51.084953
add_master_rights	admin	2019-10-15 11:35:51.092599
bank_transaction_rights	admin	2019-10-15 11:35:51.207197
delivery_plan_rights	admin	2019-10-15 11:35:51.215922
delivery_process_value	admin	2019-10-15 11:35:51.225229
details_and_report_of_parts	admin	2019-10-15 11:35:51.233861
productivity_rights	admin	2019-10-15 11:35:51.242003
requirement_spec_rights	admin	2019-10-15 11:35:51.249523
rights_for_showing_ar_and_ap_transactions	admin	2019-10-15 11:35:51.25757
sales_letter_rights	admin	2019-10-15 11:35:51.265788
purchase_letter_rights	admin	2019-10-15 11:35:51.273355
release_3_3_0	admin	2019-10-15 11:35:51.287285
client_task_server	admin	2019-10-15 11:35:51.295329
remove_insecurely_hashed_passwords	admin	2019-10-15 11:35:51.305093
session_content_primary_key	admin	2019-10-15 11:35:51.313126
release_3_4_0	admin	2019-10-15 11:35:51.344823
all_drafts_edit	admin	2019-10-15 11:35:51.353184
master_rights_position_gaps	admin	2019-10-15 11:35:51.362565
mail_journal_rights	admin	2019-10-15 11:35:51.371008
other_file_sources	admin	2019-10-15 11:35:51.384859
record_links_rights	admin	2019-10-15 11:35:51.392747
split_transaction_rights	admin	2019-10-15 11:35:51.4008
other_file_sources2	admin	2019-10-15 11:35:51.410324
rename_general_ledger_rights	admin	2019-10-15 11:35:51.418365
release_3_5_0	admin	2019-10-15 11:35:51.426429
assembly_edit_right	admin	2019-10-15 11:35:51.434356
custom_data_export_rights	admin	2019-10-15 11:35:51.442402
webshop_api_rights	admin	2019-10-15 11:35:51.450624
webshop_api_rights_2	admin	2019-10-15 11:35:51.460304
release_3_5_1	admin	2019-10-15 11:35:51.468123
release_3_5_2	admin	2019-10-15 11:35:51.475602
customer_vendor_record_extra_tab_rights	admin	2019-10-15 11:35:51.484131
release_3_5_3	admin	2019-10-15 11:35:51.491881
rights_for_viewing_project_specific_invoices	admin	2019-10-15 11:35:51.499638
release_3_5_4	admin	2019-10-15 11:35:51.507643
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.session (id, ip_address, mtime, api_token) FROM stdin;
90621ff66ea34b605f122c08854778b8	192.168.10.30	2019-10-15 12:05:25.44915	9c050c54873618e5c8fd2e7cddc8cbc1
fcb609d614cd40881fa2647d5ce85cb1	192.168.10.11	2019-10-15 11:37:13.777452	721565b132424cce2c0511bbb1e26623
\.


--
-- Data for Name: session_content; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.session_content (session_id, sess_key, sess_value, auto_restore) FROM stdin;
fcb609d614cd40881fa2647d5ce85cb1	admin_password	--- admin123\n	\N
fcb609d614cd40881fa2647d5ce85cb1	session_auth_status_root	--- 0\n	\N
fcb609d614cd40881fa2647d5ce85cb1	database_superuser_password	--- mypass123\n	\N
fcb609d614cd40881fa2647d5ce85cb1	database_superuser_username	--- kivitendo\n	\N
90621ff66ea34b605f122c08854778b8	session_auth_status_root	--- 0\n	\N
90621ff66ea34b605f122c08854778b8	session_auth_status_user	--- 0\n	\N
90621ff66ea34b605f122c08854778b8	login	--- cem\n	\N
90621ff66ea34b605f122c08854778b8	client_id	--- 1\n	\N
90621ff66ea34b605f122c08854778b8	23b59b320ba2032d2df10595d79b6ecf	---\naction: add\nshow_details: ''\n	\N
90621ff66ea34b605f122c08854778b8	4c1b247c555f0175a8e4c26418f81d64	---\nAR: 1100--Forderungen aus Lieferungen und Leistungen\nAR_paid_1: 1000--Kasse\nNOTFORPURCHASE: 2\nNOTFORSALE: 1\nacc_trans_id_1: ''\naction: update\nactive_discount_source_1: ''\nactive_price_source_1: ''\nbasefactor_1: ''\nbin_1: ''\nbo_1: ''\nbusiness: ''\ncallback: is.pl?action=add&type=invoice\nclient_id: 1\nclosedto: ''\nconvert_from_ar_ids: ''\nconvert_from_do_ids: ''\nconvert_from_oe_ids: ''\nconverted_from_delivery_order_items_id_1: ''\nconverted_from_invoice_id_1: ''\nconverted_from_orderitems_id_1: ''\ncreditlimit: 0.00000\ncreditremaining: 0\ncurrency: CHF\ncursor_fokus: ''\ncusordnumber: ''\ncusordnumber_1: ''\ncustomer_discount: 0\ncustomer_id: 410\ncustomer_pricegroup_id: ''\ndatepaid_1: 15.10.2019\ndelivery_term_id: ''\ndeliverydate: ''\ndepartment_id: ''\ndescription_1: ''\ndiscount: ''\ndiscount_1: 0\ndonumber: ''\ndonumber_1: ''\ndraft_description: ''\ndraft_id: ''\nduedate: 15.10.2019\ndunning_amount: ''\ndunning_description: ''\nemailed: ''\nemployee_id: 409\nexchangerate: 1\nexpense_accno_1: ''\nfollow_up_rowcount: 1\nfollow_up_trans_id_1: ''\nfollow_up_trans_info_1: ' (Orbital)'\nfollow_up_trans_type_1: sales_invoice\nforex: 1\nformat: pdf\nformname: invoice\nfxgain_accno: 6952\nfxloss_accno: 6942\ngldate: ''\ngldate_1: ''\nglobalproject_id: ''\nid: ''\nid_1: 0\nincome_accno_1: ''\nintnotes: ''\ninvdate: 15.10.2019\ninventory_accno_1: ''\ninvnumber: ''\ninvoice_id: ''\ninvoice_id_1: ''\nis_wrong_pclass: 0\nlanguage_id: ''\nlastcost_1: '0,00'\nlastmtime: ''\nlistprice_1: ''\nlocked: ''\nlongdescription_1: ''\nmarge_absolut_1: '0,00'\nmarge_percent: ''\nmarge_percent_1: '0,00'\nmarge_price_factor_1: ''\nmarge_total: 0\nmax_dunning_level: ''\nmedia: screen\nmemo_1: ''\nnotes: ''\noldinvtotal: 0\noldtotalpaid: 0\norddate: ''\nordnumber: ''\nordnumber_1: ''\npaid_1: ''\npaidaccounts: 1\npart_type_1: ''\npartnotes_1: ''\npartnumber_1: d\npartsgroup_1: ''\npayment_id: ''\nprevious_customer_id: 410\nprice_factor_id_1: ''\nprice_new_1: 0\nprice_old_1: 0\nprinted: ''\nproject_id_1: ''\nqty_1: '0,00'\nqueued: ''\nquodate: ''\nquonumber: ''\nreqdate_1: ''\nrndgain_accno: 6953\nrndloss_accno: 6943\nrowcount: 1\nrunningnumber_1: 1\nsalesman_id: 409\nscript: is.pl\nselectAR: "<option selected>1100--Forderungen aus Lieferungen und Leistungen</option>\\r\\n<option>1140--Vorschüsse, kurzfristige Darlehen</option>\\r\\n"\nselectAR_paid: "<option>1000--Kasse</option>\\r\\n<option>1020--Postfinance oder Bank1</option>\\r\\n<option>1021--Bank2</option>\\r\\n<option>2030--Anzahlungen von Kundinnen und Kunden</option>\\r\\n<option>2100--Bankverbindlichkeiten</option>\\r\\n<option>3800--Skonti</option>\\r\\n<option>3801--Rabatte, Preisnachlässe</option>\\r\\n<option>3805--Verluste aus Forderungen</option>\\r\\n<option>3809--MWST - nur Saldosteuersatz</option>\\r\\n"\nsellprice_1: '0,00'\nserialnumber_1: ''\nsession_auth_status_root: 0\nsession_auth_status_user: 0\nshipped: ''\nshippingpoint: ''\nshiptocity: ''\nshiptocontact: ''\nshiptocountry: ''\nshiptocp_gender: m\nshiptodepartment_1: ''\nshiptodepartment_2: ''\nshiptoemail: ''\nshiptofax: ''\nshiptogln: ''\nshiptoname: ''\nshiptophone: ''\nshiptostreet: ''\nshiptozipcode: ''\nshipvia: ''\nshow_details: 0\nsource_1: ''\nstorno: ''\nstorno_id: ''\ntaxaccounts: ''\ntaxaccounts_1: ''\ntaxincluded: ''\ntaxzone_id: 4\ntitle: Rechnung erfassen\ntradediscount: ''\ntransaction_description: Support\ntransdate_1: ''\ntype: invoice\nunit_1: Stck\nunit_old_1: ''\nupdate: 1\nuseasnew: ''\nvc: customer\nwebdav: ''\nweight_1: 0\n	\N
90621ff66ea34b605f122c08854778b8	80780b48d345c293a6a3fe7fee2eea96	---\nAR: 1100--Forderungen aus Lieferungen und Leistungen\nAR_paid_1: 1000--Kasse\nNOTFORPURCHASE: 2\nNOTFORSALE: 1\nacc_trans_id_1: ''\naction: update\nactive_discount_source_1: ''\nactive_price_source_1: ''\nbasefactor_1: ''\nbin_1: ''\nbo_1: ''\nbusiness: ''\ncallback: is.pl?action=add&type=invoice\nclient_id: 1\nclosedto: ''\nconvert_from_ar_ids: ''\nconvert_from_do_ids: ''\nconvert_from_oe_ids: ''\nconverted_from_delivery_order_items_id_1: ''\nconverted_from_invoice_id_1: ''\nconverted_from_orderitems_id_1: ''\ncreditlimit: 0.00000\ncreditremaining: 0\ncurrency: CHF\ncursor_fokus: ''\ncusordnumber: ''\ncusordnumber_1: ''\ncustomer_discount: 0\ncustomer_id: 410\ncustomer_pricegroup_id: ''\ndatepaid_1: 15.10.2019\ndelivery_term_id: ''\ndeliverydate: ''\ndepartment_id: ''\ndescription_1: ''\ndiscount: ''\ndiscount_1: 0\ndonumber: ''\ndonumber_1: ''\ndraft_description: ''\ndraft_id: ''\nduedate: 15.10.2019\ndunning_amount: ''\ndunning_description: ''\nemailed: ''\nemployee_id: 409\nexchangerate: 1\nexpense_accno_1: ''\nfollow_up_rowcount: 1\nfollow_up_trans_id_1: ''\nfollow_up_trans_info_1: ' (Orbital)'\nfollow_up_trans_type_1: sales_invoice\nforex: 1\nformat: pdf\nformname: invoice\nfxgain_accno: 6952\nfxloss_accno: 6942\ngldate: ''\ngldate_1: ''\nglobalproject_id: ''\nid: ''\nid_1: 413\nincome_accno_1: ''\nintnotes: ''\ninvdate: 15.10.2019\ninventory_accno_1: ''\ninvnumber: ''\ninvoice_id: ''\ninvoice_id_1: ''\nis_wrong_pclass: 0\nlanguage_id: ''\nlastcost_1: '0,00'\nlastmtime: ''\nlistprice_1: ''\nlocked: ''\nlongdescription_1: ''\nmarge_absolut_1: '0,00'\nmarge_percent: ''\nmarge_percent_1: '0,00'\nmarge_price_factor_1: ''\nmarge_total: 0\nmax_dunning_level: ''\nmedia: screen\nmemo_1: ''\nnotes: ''\noldinvtotal: 0\noldtotalpaid: 0\norddate: ''\nordnumber: ''\nordnumber_1: ''\npaid_1: ''\npaidaccounts: 1\npart_type_1: ''\npartnotes_1: ''\npartnumber_1: d\npartsgroup_1: ''\npayment_id: ''\nprevious_customer_id: 410\nprice_factor_id_1: ''\nprice_new_1: 0\nprice_old_1: 0\nprinted: ''\nproject_id_1: ''\nqty_1: '0,00'\nqueued: ''\nquodate: ''\nquonumber: ''\nreqdate_1: ''\nrndgain_accno: 6953\nrndloss_accno: 6943\nrowcount: 1\nrunningnumber_1: 1\nsalesman_id: 409\nscript: is.pl\nselectAR: "<option selected>1100--Forderungen aus Lieferungen und Leistungen</option>\\r\\n<option>1140--Vorschüsse, kurzfristige Darlehen</option>\\r\\n"\nselectAR_paid: "<option>1000--Kasse</option>\\r\\n<option>1020--Postfinance oder Bank1</option>\\r\\n<option>1021--Bank2</option>\\r\\n<option>2030--Anzahlungen von Kundinnen und Kunden</option>\\r\\n<option>2100--Bankverbindlichkeiten</option>\\r\\n<option>3800--Skonti</option>\\r\\n<option>3801--Rabatte, Preisnachlässe</option>\\r\\n<option>3805--Verluste aus Forderungen</option>\\r\\n<option>3809--MWST - nur Saldosteuersatz</option>\\r\\n"\nsellprice_1: '0,00'\nserialnumber_1: ''\nsession_auth_status_root: 0\nsession_auth_status_user: 0\nshipped: ''\nshippingpoint: ''\nshiptocity: ''\nshiptocontact: ''\nshiptocountry: ''\nshiptocp_gender: m\nshiptodepartment_1: ''\nshiptodepartment_2: ''\nshiptoemail: ''\nshiptofax: ''\nshiptogln: ''\nshiptoname: ''\nshiptophone: ''\nshiptostreet: ''\nshiptozipcode: ''\nshipvia: ''\nshow_details: 0\nsource_1: ''\nstorno: ''\nstorno_id: ''\ntaxaccounts: ''\ntaxaccounts_1: ''\ntaxincluded: ''\ntaxzone_id: 4\ntitle: Rechnung erfassen\ntradediscount: ''\ntransaction_description: Support\ntransdate_1: ''\ntype: invoice\nunit_1: Stck\nunit_old_1: ''\nupdate: 1\nuseasnew: ''\nvc: customer\nwebdav: ''\nweight_1: 0\n	\N
90621ff66ea34b605f122c08854778b8	ca0a6eaae3a8b39ae302da6354ed0023	---\naction: edit\ncallback: is.pl?action=add&type=invoice\nedit: ''\nid: 2\nsaved_message: ''\n	\N
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth."user" (id, login, password) FROM stdin;
1	cem	{PBKDF2}dcc4a23f61e9030cb8412f8f0e4ec98947:629347e9ab79d5a68c956e2e480ebb3691ec02397df4b7621915d2a1597d259e
\.


--
-- Data for Name: user_config; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.user_config (user_id, cfg_key, cfg_value) FROM stdin;
1	favorites	\N
1	numberformat	1.000,00
1	phone_password	
1	dateformat	dd.mm.yy
1	phone_extension	
1	item_multiselect	0
1	template_format	pdf
1	hide_cvar_search_options	0
1	mandatory_departments	\N
1	taxincluded_checked	0
1	default_media	screen
1	menustyle	v3
1	stylesheet	kivitendo.css
1	countrycode	de
1	tel	
1	fax	
1	show_form_details	0
1	copies	
1	form_cvars_nr_cols	3
1	timeformat	hh:mm
1	default_printer_id	
1	signature	 
1	name	
1	focus_position	new_description
1	email	
\.


--
-- Data for Name: user_group; Type: TABLE DATA; Schema: auth; Owner: kivitendo
--

COPY auth.user_group (user_id, group_id) FROM stdin;
1	1
\.


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: kivitendo
--

SELECT pg_catalog.setval('auth.clients_id_seq', 1, true);


--
-- Name: group_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: kivitendo
--

SELECT pg_catalog.setval('auth.group_id_seq', 1, true);


--
-- Name: master_rights_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: kivitendo
--

SELECT pg_catalog.setval('auth.master_rights_id_seq', 65, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: kivitendo
--

SELECT pg_catalog.setval('auth.user_id_seq', 1, true);


--
-- Name: clients clients_dbhost_dbport_dbname_key; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients
    ADD CONSTRAINT clients_dbhost_dbport_dbname_key UNIQUE (dbhost, dbport, dbname);


--
-- Name: clients_groups clients_groups_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_groups
    ADD CONSTRAINT clients_groups_pkey PRIMARY KEY (client_id, group_id);


--
-- Name: clients clients_name_key; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients
    ADD CONSTRAINT clients_name_key UNIQUE (name);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: clients_users clients_users_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_users
    ADD CONSTRAINT clients_users_pkey PRIMARY KEY (client_id, user_id);


--
-- Name: group group_name_key; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth."group"
    ADD CONSTRAINT group_name_key UNIQUE (name);


--
-- Name: group group_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth."group"
    ADD CONSTRAINT group_pkey PRIMARY KEY (id);


--
-- Name: group_rights group_rights_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.group_rights
    ADD CONSTRAINT group_rights_pkey PRIMARY KEY (group_id, "right");


--
-- Name: master_rights master_rights_name_key; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.master_rights
    ADD CONSTRAINT master_rights_name_key UNIQUE (name);


--
-- Name: master_rights master_rights_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.master_rights
    ADD CONSTRAINT master_rights_pkey PRIMARY KEY (id);


--
-- Name: schema_info schema_info_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.schema_info
    ADD CONSTRAINT schema_info_pkey PRIMARY KEY (tag);


--
-- Name: session_content session_content_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.session_content
    ADD CONSTRAINT session_content_pkey PRIMARY KEY (session_id, sess_key);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: user_config user_config_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.user_config
    ADD CONSTRAINT user_config_pkey PRIMARY KEY (user_id, cfg_key);


--
-- Name: user_group user_group_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.user_group
    ADD CONSTRAINT user_group_pkey PRIMARY KEY (user_id, group_id);


--
-- Name: user user_login_key; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth."user"
    ADD CONSTRAINT user_login_key UNIQUE (login);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: clients_groups clients_groups_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_groups
    ADD CONSTRAINT clients_groups_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.clients(id) ON DELETE CASCADE;


--
-- Name: clients_groups clients_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_groups
    ADD CONSTRAINT clients_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES auth."group"(id) ON DELETE CASCADE;


--
-- Name: clients clients_task_server_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients
    ADD CONSTRAINT clients_task_server_user_id_fkey FOREIGN KEY (task_server_user_id) REFERENCES auth."user"(id);


--
-- Name: clients_users clients_users_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_users
    ADD CONSTRAINT clients_users_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.clients(id) ON DELETE CASCADE;


--
-- Name: clients_users clients_users_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.clients_users
    ADD CONSTRAINT clients_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth."user"(id) ON DELETE CASCADE;


--
-- Name: group_rights group_rights_group_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.group_rights
    ADD CONSTRAINT group_rights_group_id_fkey FOREIGN KEY (group_id) REFERENCES auth."group"(id) ON DELETE CASCADE;


--
-- Name: session_content session_content_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.session_content
    ADD CONSTRAINT session_content_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.session(id) ON DELETE CASCADE;


--
-- Name: user_config user_config_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.user_config
    ADD CONSTRAINT user_config_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth."user"(id) ON DELETE CASCADE;


--
-- Name: user_group user_group_group_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.user_group
    ADD CONSTRAINT user_group_group_id_fkey FOREIGN KEY (group_id) REFERENCES auth."group"(id) ON DELETE CASCADE;


--
-- Name: user_group user_group_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: kivitendo
--

ALTER TABLE ONLY auth.user_group
    ADD CONSTRAINT user_group_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth."user"(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

