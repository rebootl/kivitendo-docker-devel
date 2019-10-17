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
-- Name: mycompany2; Type: DATABASE; Schema: -; Owner: kivitendo
--

CREATE DATABASE mycompany2 WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';


ALTER DATABASE mycompany2 OWNER TO kivitendo;

\connect mycompany2

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
-- Name: tax; Type: SCHEMA; Schema: -; Owner: kivitendo
--

CREATE SCHEMA tax;


ALTER SCHEMA tax OWNER TO kivitendo;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: custom_data_export_query_parameter_default_value_type_enum; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.custom_data_export_query_parameter_default_value_type_enum AS ENUM (
    'none',
    'current_user_login',
    'sql_query',
    'fixed_value'
);


ALTER TYPE public.custom_data_export_query_parameter_default_value_type_enum OWNER TO kivitendo;

--
-- Name: custom_data_export_query_parameter_type_enum; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.custom_data_export_query_parameter_type_enum AS ENUM (
    'text',
    'number',
    'date',
    'timestamp'
);


ALTER TYPE public.custom_data_export_query_parameter_type_enum OWNER TO kivitendo;

--
-- Name: datev_export_format_enum; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.datev_export_format_enum AS ENUM (
    'cp1252',
    'cp1252-translit',
    'utf-8'
);


ALTER TYPE public.datev_export_format_enum OWNER TO kivitendo;

--
-- Name: dunning_creator; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.dunning_creator AS ENUM (
    'current_employee',
    'invoice_employee'
);


ALTER TYPE public.dunning_creator OWNER TO kivitendo;

--
-- Name: invoice_mail_settings; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.invoice_mail_settings AS ENUM (
    'cp',
    'invoice_mail',
    'invoice_mail_cc_cp'
);


ALTER TYPE public.invoice_mail_settings OWNER TO kivitendo;

--
-- Name: part_type_enum; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.part_type_enum AS ENUM (
    'part',
    'service',
    'assembly',
    'assortment'
);


ALTER TYPE public.part_type_enum OWNER TO kivitendo;

--
-- Name: record_template_type; Type: TYPE; Schema: public; Owner: kivitendo
--

CREATE TYPE public.record_template_type AS ENUM (
    'ar_transaction',
    'ap_transaction',
    'gl_transaction'
);


ALTER TYPE public.record_template_type OWNER TO kivitendo;

--
-- Name: add_parts_price_history_entry(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.add_parts_price_history_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF      (TG_OP = 'UPDATE')
        AND ((OLD.lastcost  IS NULL AND NEW.lastcost  IS NULL) OR (OLD.lastcost  = NEW.lastcost))
        AND ((OLD.listprice IS NULL AND NEW.listprice IS NULL) OR (OLD.listprice = NEW.listprice))
        AND ((OLD.sellprice IS NULL AND NEW.sellprice IS NULL) OR (OLD.sellprice = NEW.sellprice)) THEN
      RETURN NEW;
    END IF;

    INSERT INTO parts_price_history (part_id, lastcost, listprice, sellprice, valid_from)
    VALUES (NEW.id, NEW.lastcost, NEW.listprice, NEW.sellprice, now());

    RETURN NEW;
  END;
$$;


ALTER FUNCTION public.add_parts_price_history_entry() OWNER TO kivitendo;

--
-- Name: chart_category_to_sgn(character); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.chart_category_to_sgn(character) RETURNS integer
    LANGUAGE sql
    AS $_$SELECT  1 WHERE $1 IN ('I', 'L', 'Q')
      UNION 
    SELECT -1 WHERE $1 IN ('E', 'A')$_$;


ALTER FUNCTION public.chart_category_to_sgn(character) OWNER TO kivitendo;

--
-- Name: check_bin_belongs_to_wh(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.check_bin_belongs_to_wh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
        IF NEW.bin_id IS NULL AND NEW.warehouse_id IS NULL THEN
          RETURN NEW;
        END IF;
        IF NEW.bin_id IN (SELECT id FROM bin WHERE warehouse_id = NEW.warehouse_id) THEN
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'bin (id=%) does not belong to warehouse (id=%).', NEW.bin_id, NEW.warehouse_id;
          RETURN NULL;
        END IF;
      END;$$;


ALTER FUNCTION public.check_bin_belongs_to_wh() OWNER TO kivitendo;

--
-- Name: clean_up_acc_trans_after_ar_ap_gl_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_acc_trans_after_ar_ap_gl_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM acc_trans WHERE trans_id = OLD.id;
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_acc_trans_after_ar_ap_gl_delete() OWNER TO kivitendo;

--
-- Name: clean_up_after_customer_vendor_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_after_customer_vendor_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM contacts
    WHERE cp_cv_id = OLD.id;

    DELETE FROM shipto
    WHERE (trans_id = OLD.id)
      AND (module   = 'CT');

    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_after_customer_vendor_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_ap_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_ap_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'ap' AND from_id = OLD.id)
         OR (to_table   = 'ap' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_ap_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_ar_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_ar_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'ar' AND from_id = OLD.id)
         OR (to_table   = 'ar' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_ar_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_delivery_order_items_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_delivery_order_items_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'delivery_order_items' AND from_id = OLD.id)
         OR (to_table   = 'delivery_order_items' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_delivery_order_items_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_delivery_orders_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_delivery_orders_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'delivery_orders' AND from_id = OLD.id)
         OR (to_table   = 'delivery_orders' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_delivery_orders_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_gl_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_gl_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'gl' AND from_id = OLD.id)
         OR (to_table   = 'gl' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_gl_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_invoice_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_invoice_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'invoice' AND from_id = OLD.id)
         OR (to_table   = 'invoice' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_invoice_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_letter_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_letter_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'letter' AND from_id = OLD.id)
         OR (to_table   = 'letter' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_letter_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_oe_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_oe_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'oe' AND from_id = OLD.id)
         OR (to_table   = 'oe' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_oe_delete() OWNER TO kivitendo;

--
-- Name: clean_up_record_links_before_orderitems_delete(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.clean_up_record_links_before_orderitems_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM record_links
      WHERE (from_table = 'orderitems' AND from_id = OLD.id)
         OR (to_table   = 'orderitems' AND to_id   = OLD.id);
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.clean_up_record_links_before_orderitems_delete() OWNER TO kivitendo;

--
-- Name: comma_aggregate(text, text); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.comma_aggregate(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 <> '' THEN $1 || ', ' || $2 
                              ELSE $2 
         END; 
$_$;


ALTER FUNCTION public.comma_aggregate(text, text) OWNER TO kivitendo;

--
-- Name: delete_custom_variables_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.delete_custom_variables_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (TG_TABLE_NAME IN ('orderitems', 'delivery_order_items', 'invoice')) THEN
      PERFORM delete_custom_variables_with_sub_module('IC', TG_TABLE_NAME, old.id);
    END IF;

    IF (TG_TABLE_NAME = 'parts') THEN
      PERFORM delete_custom_variables_with_sub_module('IC', '', old.id);
    END IF;

    IF (TG_TABLE_NAME IN ('customer', 'vendor')) THEN
      PERFORM delete_custom_variables_with_sub_module('CT', '', old.id);
    END IF;

    IF (TG_TABLE_NAME = 'contacts') THEN
      PERFORM delete_custom_variables_with_sub_module('Contacts', '', old.cp_id);
    END IF;

    IF (TG_TABLE_NAME = 'project') THEN
      PERFORM delete_custom_variables_with_sub_module('Projects', '', old.id);
    END IF;

    RETURN old;
  END;
$$;


ALTER FUNCTION public.delete_custom_variables_trigger() OWNER TO kivitendo;

--
-- Name: delete_custom_variables_with_sub_module(text, text, integer); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.delete_custom_variables_with_sub_module(config_module text, cvar_sub_module text, old_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM custom_variables
    WHERE EXISTS (SELECT id FROM custom_variable_configs cfg WHERE (cfg.module = config_module) AND (custom_variables.config_id = cfg.id))
      AND (COALESCE(sub_module, '') = cvar_sub_module)
      AND (trans_id                 = old_id);

    RETURN TRUE;
  END;
$$;


ALTER FUNCTION public.delete_custom_variables_with_sub_module(config_module text, cvar_sub_module text, old_id integer) OWNER TO kivitendo;

--
-- Name: delete_requirement_spec_custom_variables_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.delete_requirement_spec_custom_variables_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM custom_variables WHERE (sub_module = '' OR sub_module IS NULL)
                                   AND trans_id = OLD.id
                                   AND (SELECT module FROM custom_variable_configs WHERE id = config_id) = 'RequirementSpecs';

    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.delete_requirement_spec_custom_variables_trigger() OWNER TO kivitendo;

--
-- Name: delivery_orders_before_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.delivery_orders_before_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          DELETE FROM status                     WHERE trans_id = OLD.id;
          DELETE FROM delivery_order_items_stock WHERE delivery_order_item_id IN (SELECT id FROM delivery_order_items WHERE delivery_order_id = OLD.id);
          DELETE FROM shipto                     WHERE (trans_id = OLD.id) AND (module = 'OE');

          RETURN OLD;
        END;
      $$;


ALTER FUNCTION public.delivery_orders_before_delete_trigger() OWNER TO kivitendo;

--
-- Name: first_agg(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.first_agg(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT $1;
$_$;


ALTER FUNCTION public.first_agg(anyelement, anyelement) OWNER TO kivitendo;

--
-- Name: follow_up_close_when_oe_closed_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.follow_up_close_when_oe_closed_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF COALESCE(NEW.closed, FALSE) AND NOT COALESCE(OLD.closed, FALSE) THEN
      UPDATE follow_ups
      SET done = TRUE
      WHERE id IN (
        SELECT follow_up_id
        FROM follow_up_links
        WHERE (trans_id   = NEW.id)
          AND (trans_type IN ('sales_quotation',   'sales_order',    'sales_delivery_order',
                              'request_quotation', 'purchase_order', 'purchase_delivery_order'))
      );
    END IF;

    RETURN NEW;
  END;
$$;


ALTER FUNCTION public.follow_up_close_when_oe_closed_trigger() OWNER TO kivitendo;

--
-- Name: follow_up_delete_notes_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.follow_up_delete_notes_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM notes
    WHERE (trans_id     = OLD.id)
      AND (trans_module = 'fu');
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.follow_up_delete_notes_trigger() OWNER TO kivitendo;

--
-- Name: follow_up_delete_when_customer_vendor_is_deleted_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.follow_up_delete_when_customer_vendor_is_deleted_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM follow_ups
    WHERE id IN (
      SELECT follow_up_id
      FROM follow_up_links
      WHERE (trans_id   = OLD.id)
        AND (trans_type IN ('customer', 'vendor'))
    );

    DELETE FROM notes
    WHERE (trans_id     = OLD.id)
      AND (trans_module = 'ct');

    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.follow_up_delete_when_customer_vendor_is_deleted_trigger() OWNER TO kivitendo;

--
-- Name: follow_up_delete_when_oe_is_deleted_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.follow_up_delete_when_oe_is_deleted_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM follow_ups
    WHERE id IN (
      SELECT follow_up_id
      FROM follow_up_links
      WHERE (trans_id   = OLD.id)
        AND (trans_type IN ('sales_quotation',   'sales_order',    'sales_delivery_order',    'sales_invoice',
                            'request_quotation', 'purchase_order', 'purchase_delivery_order', 'purchase_invoice'))
    );

    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.follow_up_delete_when_oe_is_deleted_trigger() OWNER TO kivitendo;

--
-- Name: generic_translations_delete_on_delivery_terms_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.generic_translations_delete_on_delivery_terms_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM generic_translations
      WHERE translation_id = OLD.id AND translation_type LIKE 'SL::DB::DeliveryTerm/description_long';
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.generic_translations_delete_on_delivery_terms_delete_trigger() OWNER TO kivitendo;

--
-- Name: generic_translations_delete_on_payment_terms_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.generic_translations_delete_on_payment_terms_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM generic_translations
    WHERE (translation_id = OLD.id)
      AND (translation_type IN ('SL::DB::PaymentTerm/description_long', 'SL::DB::PaymentTerm/description_long_invoice'));
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.generic_translations_delete_on_payment_terms_delete_trigger() OWNER TO kivitendo;

--
-- Name: generic_translations_delete_on_tax_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.generic_translations_delete_on_tax_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM generic_translations
      WHERE translation_id = OLD.id AND translation_type LIKE 'SL::DB::Tax/taxdescription';
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.generic_translations_delete_on_tax_delete_trigger() OWNER TO kivitendo;

--
-- Name: oe_before_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.oe_before_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          DELETE FROM status WHERE trans_id = OLD.id;
          DELETE FROM shipto WHERE (trans_id = OLD.id) AND (module = 'OE');

          RETURN OLD;
        END;
      $$;


ALTER FUNCTION public.oe_before_delete_trigger() OWNER TO kivitendo;

--
-- Name: recalculate_all_spec_item_time_estimations(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.recalculate_all_spec_item_time_estimations() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE
    rspec RECORD;
  BEGIN
    FOR rspec IN SELECT id FROM requirement_specs LOOP
      PERFORM recalculate_spec_item_time_estimation(rspec.id);
    END LOOP;

    RETURN TRUE;
  END;
$$;


ALTER FUNCTION public.recalculate_all_spec_item_time_estimations() OWNER TO kivitendo;

--
-- Name: recalculate_spec_item_time_estimation(integer); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.recalculate_spec_item_time_estimation(the_requirement_spec_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE
    item RECORD;
  BEGIN
    FOR item IN
      SELECT DISTINCT parent_id
      FROM requirement_spec_items
      WHERE (requirement_spec_id = the_requirement_spec_id)
        AND (item_type           = 'sub-function-block')
    LOOP
      RAISE DEBUG 'hmm function-block with sub: %', item.parent_id;
      PERFORM update_requirement_spec_item_time_estimation(item.parent_id, the_requirement_spec_id);
    END LOOP;

    FOR item IN
      SELECT DISTINCT parent_id
      FROM requirement_spec_items
      WHERE (requirement_spec_id = the_requirement_spec_id)
        AND (item_type           = 'function-block')
        AND (id NOT IN (
          SELECT parent_id
          FROM requirement_spec_items
          WHERE (requirement_spec_id = the_requirement_spec_id)
            AND (item_type           = 'sub-function-block')
        ))
    LOOP
      RAISE DEBUG 'hmm section with function-block: %', item.parent_id;
      PERFORM update_requirement_spec_item_time_estimation(item.parent_id, the_requirement_spec_id);
    END LOOP;

    PERFORM update_requirement_spec_item_time_estimation(NULL, the_requirement_spec_id);

    RETURN TRUE;
  END;
$$;


ALTER FUNCTION public.recalculate_spec_item_time_estimation(the_requirement_spec_id integer) OWNER TO kivitendo;

--
-- Name: requirement_spec_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.requirement_spec_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF TG_WHEN = 'AFTER' THEN
      DELETE FROM trigger_information WHERE (key = 'deleting_requirement_spec') AND (value = CAST(OLD.id AS TEXT));

      RETURN OLD;
    END IF;

    RAISE DEBUG 'before delete trigger on %', OLD.id;

    INSERT INTO trigger_information (key, value) VALUES ('deleting_requirement_spec', CAST(OLD.id AS TEXT));

    RAISE DEBUG '  Converting items into sections items for %', OLD.id;
    UPDATE requirement_spec_items SET item_type  = 'section', parent_id = NULL WHERE requirement_spec_id = OLD.id;

    RAISE DEBUG '  And we out for %', OLD.id;

    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.requirement_spec_delete_trigger() OWNER TO kivitendo;

--
-- Name: requirement_spec_item_before_delete_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.requirement_spec_item_before_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE DEBUG 'delete trig RSitem old id %', OLD.id;
    INSERT INTO trigger_information (key, value) VALUES ('deleting_requirement_spec_item', CAST(OLD.id AS TEXT));
    DELETE FROM requirement_spec_items WHERE (parent_id         = OLD.id);
    DELETE FROM trigger_information    WHERE (key = 'deleting_requirement_spec_item') AND (value = CAST(OLD.id AS TEXT));
    RAISE DEBUG 'delete trig END %', OLD.id;
    RETURN OLD;
  END;
$$;


ALTER FUNCTION public.requirement_spec_item_before_delete_trigger() OWNER TO kivitendo;

--
-- Name: requirement_spec_item_time_estimation_updater_trigger(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.requirement_spec_item_time_estimation_updater_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    do_new BOOLEAN;
  BEGIN
    RAISE DEBUG 'updateRSITE op %', TG_OP;
    IF ((TG_OP = 'UPDATE') OR (TG_OP = 'DELETE')) THEN
      RAISE DEBUG 'UPDATE trigg op % OLD.id % OLD.parent_id %', TG_OP, OLD.id, OLD.parent_id;
      PERFORM update_requirement_spec_item_time_estimation(OLD.parent_id, OLD.requirement_spec_id);
      RAISE DEBUG 'UPDATE trigg op % END %', TG_OP, OLD.id;
    END IF;
    do_new = FALSE;

    IF (TG_OP = 'UPDATE') THEN
      do_new = OLD.parent_id <> NEW.parent_id;
    END IF;

    IF (do_new OR (TG_OP = 'INSERT')) THEN
      RAISE DEBUG 'UPDATE trigg op % NEW.id % NEW.parent_id %', TG_OP, NEW.id, NEW.parent_id;
      PERFORM update_requirement_spec_item_time_estimation(NEW.parent_id, NEW.requirement_spec_id);
      RAISE DEBUG 'UPDATE trigg op % END %', TG_OP, NEW.id;
    END IF;

    RETURN NULL;
  END;
$$;


ALTER FUNCTION public.requirement_spec_item_time_estimation_updater_trigger() OWNER TO kivitendo;

--
-- Name: set_mtime(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.set_mtime() RETURNS trigger
    LANGUAGE plpgsql
    AS $$    BEGIN        NEW.mtime := 'now';        RETURN NEW;    END;$$;


ALTER FUNCTION public.set_mtime() OWNER TO kivitendo;

--
-- Name: set_priceupdate_parts(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.set_priceupdate_parts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$    BEGIN        NEW.priceupdate := 'now';        RETURN NEW;    END;$$;


ALTER FUNCTION public.set_priceupdate_parts() OWNER TO kivitendo;

--
-- Name: update_onhand(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.update_onhand() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF tg_op = 'INSERT' THEN
    UPDATE parts SET onhand = COALESCE(onhand, 0) + new.qty WHERE id = new.parts_id;
    RETURN new;
  ELSIF tg_op = 'DELETE' THEN
    UPDATE parts SET onhand = COALESCE(onhand, 0) - old.qty WHERE id = old.parts_id;
    RETURN old;
  ELSE
    UPDATE parts SET onhand = COALESCE(onhand, 0) - old.qty + new.qty WHERE id = old.parts_id;
    RETURN new;
  END IF;
END;
$$;


ALTER FUNCTION public.update_onhand() OWNER TO kivitendo;

--
-- Name: update_purchase_price(); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.update_purchase_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if tg_op = 'DELETE' THEN
    UPDATE parts SET lastcost = COALESCE((select sum ((a.qty * (p.lastcost / COALESCE(pf.factor,
    1)))) as summe from assembly a left join parts p on (p.id = a.parts_id)
    LEFT JOIN price_factors pf on (p.price_factor_id = pf.id) where a.id = parts.id),0)
    WHERE part_type = 'assembly' and id = old.id;
    return old; -- old ist eine referenz auf die geloeschte reihe
  ELSE
    UPDATE parts SET lastcost = COALESCE((select sum ((a.qty * (p.lastcost / COALESCE(pf.factor,
    1)))) as summe from assembly a left join parts p on (p.id = a.parts_id)
    LEFT JOIN price_factors pf on (p.price_factor_id = pf.id)
    WHERE a.id = parts.id),0) where part_type = 'assembly' and id = new.id;
    return new; -- entsprechend new, wird wahrscheinlich benoetigt, um den korrekten Eintrag
                -- zu filtern bzw. dann zu aktualisieren
  END IF;
END;
$$;


ALTER FUNCTION public.update_purchase_price() OWNER TO kivitendo;

--
-- Name: update_requirement_spec_item_time_estimation(integer, integer); Type: FUNCTION; Schema: public; Owner: kivitendo
--

CREATE FUNCTION public.update_requirement_spec_item_time_estimation(item_id integer, item_requirement_spec_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE
    current_row RECORD;
    new_row     RECORD;
  BEGIN
    IF EXISTS(
      SELECT *
      FROM trigger_information
      WHERE ((key = 'deleting_requirement_spec_item') AND (value = CAST(item_id                  AS TEXT)))
         OR ((key = 'deleting_requirement_spec')      AND (value = CAST(item_requirement_spec_id AS TEXT)))
      LIMIT 1
    ) THEN
      RAISE DEBUG 'updateRSIE: item_id % or requirement_spec_id % is about to be deleted; do not update', item_id, item_requirement_spec_id;
      RETURN FALSE;
    END IF;

    -- item_id IS NULL means that a section has been updated. The
    -- requirement spec itself must therefore be updated.
    IF item_id IS NULL THEN
      SELECT COALESCE(time_estimation, 0) AS time_estimation
      INTO current_row
      FROM requirement_specs
      WHERE id = item_requirement_spec_id;

      SELECT COALESCE(SUM(time_estimation), 0) AS time_estimation
      INTO new_row
      FROM requirement_spec_items
      WHERE (parent_id IS NULL)
        AND (requirement_spec_id = item_requirement_spec_id);

      IF current_row.time_estimation <> new_row.time_estimation THEN
        RAISE DEBUG 'updateRSIE: updating requirement_spec % itself: old estimation % new %.', item_requirement_spec_id, current_row.time_estimation, new_row.time_estimation;

        UPDATE requirement_specs
        SET time_estimation = new_row.time_estimation
        WHERE id = item_requirement_spec_id;
      END IF;

      RETURN TRUE;
    END IF;

    -- If we're here it means that either a sub-function-block or a
    -- function-block has been updated. item_id is the parent's ID of
    -- the updated item -- meaning the ID of the item that needs to be
    -- updated now.

    SELECT COALESCE(time_estimation, 0) AS time_estimation
    INTO current_row
    FROM requirement_spec_items
    WHERE id = item_id;

    SELECT COALESCE(SUM(time_estimation), 0) AS time_estimation
    INTO new_row
    FROM requirement_spec_items
    WHERE (parent_id = item_id);

    IF current_row.time_estimation = new_row.time_estimation THEN
      RAISE DEBUG 'updateRSIE: item %: nothing to do', item_id;
      RETURN TRUE;
    END IF;

    RAISE DEBUG 'updateRSIE: updating item %: old estimation % new %.', item_id, current_row.time_estimation, new_row.time_estimation;

    UPDATE requirement_spec_items
    SET time_estimation = new_row.time_estimation
    WHERE id = item_id;

    RETURN TRUE;
  END;
$$;


ALTER FUNCTION public.update_requirement_spec_item_time_estimation(item_id integer, item_requirement_spec_id integer) OWNER TO kivitendo;

--
-- Name: comma(text); Type: AGGREGATE; Schema: public; Owner: kivitendo
--

CREATE AGGREGATE public.comma(text) (
    SFUNC = public.comma_aggregate,
    STYPE = text,
    INITCOND = ''
);


ALTER AGGREGATE public.comma(text) OWNER TO kivitendo;

--
-- Name: first(anyelement); Type: AGGREGATE; Schema: public; Owner: kivitendo
--

CREATE AGGREGATE public.first(anyelement) (
    SFUNC = public.first_agg,
    STYPE = anyelement
);


ALTER AGGREGATE public.first(anyelement) OWNER TO kivitendo;

--
-- Name: acc_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.acc_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.acc_trans_id_seq OWNER TO kivitendo;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acc_trans; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.acc_trans (
    acc_trans_id bigint DEFAULT nextval('public.acc_trans_id_seq'::regclass) NOT NULL,
    trans_id integer NOT NULL,
    chart_id integer NOT NULL,
    amount numeric(15,5),
    transdate date DEFAULT ('now'::text)::date,
    gldate date DEFAULT ('now'::text)::date,
    source text,
    cleared boolean DEFAULT false NOT NULL,
    fx_transaction boolean DEFAULT false NOT NULL,
    ob_transaction boolean DEFAULT false NOT NULL,
    cb_transaction boolean DEFAULT false NOT NULL,
    project_id integer,
    memo text,
    taxkey integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    chart_link text NOT NULL,
    tax_id integer NOT NULL
);


ALTER TABLE public.acc_trans OWNER TO kivitendo;

--
-- Name: ap; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.ap (
    id integer DEFAULT nextval(('glid'::text)::regclass) NOT NULL,
    invnumber text NOT NULL,
    transdate date DEFAULT ('now'::text)::date,
    gldate date DEFAULT ('now'::text)::date,
    vendor_id integer,
    taxincluded boolean DEFAULT false,
    amount numeric(15,5) DEFAULT 0 NOT NULL,
    netamount numeric(15,5) DEFAULT 0 NOT NULL,
    paid numeric(15,5) DEFAULT 0 NOT NULL,
    datepaid date,
    duedate date,
    invoice boolean DEFAULT false,
    ordnumber text,
    notes text,
    employee_id integer,
    quonumber text,
    intnotes text,
    department_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    shipvia text,
    cp_id integer,
    language_id integer,
    payment_id integer,
    storno boolean DEFAULT false,
    taxzone_id integer NOT NULL,
    type text,
    orddate date,
    quodate date,
    globalproject_id integer,
    storno_id integer,
    transaction_description text,
    direct_debit boolean DEFAULT false,
    deliverydate date,
    delivery_term_id integer,
    currency_id integer NOT NULL
);


ALTER TABLE public.ap OWNER TO kivitendo;

--
-- Name: ar; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.ar (
    id integer DEFAULT nextval(('glid'::text)::regclass) NOT NULL,
    invnumber text NOT NULL,
    transdate date DEFAULT ('now'::text)::date,
    gldate date DEFAULT ('now'::text)::date,
    customer_id integer,
    taxincluded boolean,
    amount numeric(15,5) DEFAULT 0 NOT NULL,
    netamount numeric(15,5) DEFAULT 0 NOT NULL,
    paid numeric(15,5) DEFAULT 0 NOT NULL,
    datepaid date,
    duedate date,
    deliverydate date,
    invoice boolean DEFAULT false,
    shippingpoint text,
    notes text,
    ordnumber text,
    employee_id integer,
    quonumber text,
    cusordnumber text,
    intnotes text,
    department_id integer,
    shipvia text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    cp_id integer,
    language_id integer,
    payment_id integer,
    delivery_customer_id integer,
    delivery_vendor_id integer,
    storno boolean DEFAULT false,
    taxzone_id integer NOT NULL,
    shipto_id integer,
    type text,
    dunning_config_id integer,
    orddate date,
    quodate date,
    globalproject_id integer,
    salesman_id integer,
    marge_total numeric(15,5),
    marge_percent numeric(15,5),
    storno_id integer,
    transaction_description text,
    donumber text,
    invnumber_for_credit_note text,
    direct_debit boolean DEFAULT false,
    delivery_term_id integer,
    currency_id integer NOT NULL
);


ALTER TABLE public.ar OWNER TO kivitendo;

--
-- Name: assembly_assembly_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.assembly_assembly_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assembly_assembly_id_seq OWNER TO kivitendo;

SET default_with_oids = true;

--
-- Name: assembly; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.assembly (
    id integer NOT NULL,
    parts_id integer NOT NULL,
    qty real,
    bom boolean,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    assembly_id integer DEFAULT nextval('public.assembly_assembly_id_seq'::regclass) NOT NULL,
    "position" integer
);


ALTER TABLE public.assembly OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: assortment_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.assortment_items (
    assortment_id integer NOT NULL,
    parts_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    qty real NOT NULL,
    "position" integer NOT NULL,
    unit character varying(20) NOT NULL,
    charge boolean DEFAULT true
);


ALTER TABLE public.assortment_items OWNER TO kivitendo;

--
-- Name: background_job_histories; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.background_job_histories (
    id integer NOT NULL,
    package_name character varying(255),
    run_at timestamp without time zone,
    status character varying(255),
    result text,
    error text,
    data text
);


ALTER TABLE public.background_job_histories OWNER TO kivitendo;

--
-- Name: background_job_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.background_job_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.background_job_histories_id_seq OWNER TO kivitendo;

--
-- Name: background_job_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.background_job_histories_id_seq OWNED BY public.background_job_histories.id;


--
-- Name: background_jobs; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.background_jobs (
    id integer NOT NULL,
    type character varying(255),
    package_name character varying(255),
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone,
    data text,
    active boolean,
    cron_spec character varying(255)
);


ALTER TABLE public.background_jobs OWNER TO kivitendo;

--
-- Name: background_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.background_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.background_jobs_id_seq OWNER TO kivitendo;

--
-- Name: background_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.background_jobs_id_seq OWNED BY public.background_jobs.id;


--
-- Name: id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.id OWNER TO kivitendo;

--
-- Name: bank_accounts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.bank_accounts (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    account_number character varying(100),
    bank_code character varying(100),
    iban character varying(100),
    bic character varying(100),
    bank text,
    chart_id integer NOT NULL,
    name text,
    reconciliation_starting_date date,
    reconciliation_starting_balance numeric(15,5),
    obsolete boolean DEFAULT false NOT NULL,
    sortkey integer NOT NULL
);


ALTER TABLE public.bank_accounts OWNER TO kivitendo;

--
-- Name: bank_transaction_acc_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.bank_transaction_acc_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_transaction_acc_trans_id_seq OWNER TO kivitendo;

--
-- Name: bank_transaction_acc_trans; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.bank_transaction_acc_trans (
    id integer DEFAULT nextval('public.bank_transaction_acc_trans_id_seq'::regclass) NOT NULL,
    bank_transaction_id integer NOT NULL,
    acc_trans_id bigint NOT NULL,
    ar_id integer,
    ap_id integer,
    gl_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.bank_transaction_acc_trans OWNER TO kivitendo;

--
-- Name: bank_transactions; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.bank_transactions (
    id integer NOT NULL,
    transaction_id integer,
    remote_bank_code text,
    remote_account_number text,
    transdate date NOT NULL,
    valutadate date NOT NULL,
    amount numeric(15,5) NOT NULL,
    remote_name text,
    purpose text,
    invoice_amount numeric(15,5) DEFAULT 0,
    local_bank_account_id integer NOT NULL,
    currency_id integer NOT NULL,
    cleared boolean DEFAULT false NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    transaction_code text,
    transaction_text text,
    CONSTRAINT bank_transactions_check CHECK ((abs(invoice_amount) <= abs(amount)))
);


ALTER TABLE public.bank_transactions OWNER TO kivitendo;

--
-- Name: bank_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.bank_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_transactions_id_seq OWNER TO kivitendo;

--
-- Name: bank_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.bank_transactions_id_seq OWNED BY public.bank_transactions.id;


--
-- Name: bin; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.bin (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    warehouse_id integer NOT NULL,
    description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.bin OWNER TO kivitendo;

--
-- Name: buchungsgruppen; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.buchungsgruppen (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    inventory_accno_id integer NOT NULL,
    sortkey integer NOT NULL
);


ALTER TABLE public.buchungsgruppen OWNER TO kivitendo;

--
-- Name: business; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.business (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    discount real,
    customernumberinit text,
    salesman boolean DEFAULT false,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.business OWNER TO kivitendo;

--
-- Name: bwa_categories; Type: VIEW; Schema: public; Owner: kivitendo
--

CREATE VIEW public.bwa_categories AS
 SELECT "*VALUES*".column1 AS id,
    "*VALUES*".column2 AS description
   FROM (VALUES (1,'Umsatzerlöse'::text), (2,'Best.Verdg.FE/UE'::text), (3,'Aktiv.Eigenleistung'::text), (4,'Mat./Wareneinkauf'::text), (5,'So.betr.Erlöse'::text), (10,'Personalkosten'::text), (11,'Raumkosten'::text), (12,'Betriebl.Steuern'::text), (13,'Vers./Beiträge'::text), (14,'Kfz.Kosten o.St.'::text), (15,'Werbe-Reisek.'::text), (16,'Kosten Warenabgabe'::text), (17,'Abschreibungen'::text), (18,'Rep./instandhlt.'::text), (19,'Übrige Steuern'::text), (20,'Sonst.Kosten'::text), (30,'Zinsaufwand'::text), (31,'Sonst.neutr.Aufw.'::text), (32,'Zinserträge'::text), (33,'Sonst.neutr.Ertrag'::text), (34,'Verr.kalk.Kosten'::text), (35,'Steuern Eink.u.Ertr.'::text)) "*VALUES*";


ALTER TABLE public.bwa_categories OWNER TO kivitendo;

--
-- Name: chart; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.chart (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    accno text NOT NULL,
    description text,
    charttype character(1) DEFAULT 'A'::bpchar,
    category character(1),
    link text NOT NULL,
    taxkey_id integer,
    pos_bwa integer,
    pos_bilanz integer,
    pos_eur integer,
    datevautomatik boolean DEFAULT false,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    new_chart_id integer,
    valid_from date,
    pos_er integer
);


ALTER TABLE public.chart OWNER TO kivitendo;

--
-- Name: contacts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.contacts (
    cp_id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    cp_cv_id integer,
    cp_title text,
    cp_givenname text,
    cp_name text,
    cp_email text,
    cp_phone1 text,
    cp_phone2 text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    cp_fax text,
    cp_mobile1 text,
    cp_mobile2 text,
    cp_satphone text,
    cp_satfax text,
    cp_project text,
    cp_privatphone text,
    cp_privatemail text,
    cp_abteilung text,
    cp_gender character(1),
    cp_street text,
    cp_zipcode text,
    cp_city text,
    cp_birthday date,
    cp_position text,
    cp_main boolean DEFAULT false
);


ALTER TABLE public.contacts OWNER TO kivitendo;

--
-- Name: csv_import_profile_settings; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.csv_import_profile_settings (
    id integer NOT NULL,
    csv_import_profile_id integer NOT NULL,
    key text NOT NULL,
    value text
);


ALTER TABLE public.csv_import_profile_settings OWNER TO kivitendo;

--
-- Name: csv_import_profile_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.csv_import_profile_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.csv_import_profile_settings_id_seq OWNER TO kivitendo;

--
-- Name: csv_import_profile_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.csv_import_profile_settings_id_seq OWNED BY public.csv_import_profile_settings.id;


--
-- Name: csv_import_profiles; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.csv_import_profiles (
    id integer NOT NULL,
    name text NOT NULL,
    type character varying(20) NOT NULL,
    is_default boolean DEFAULT false,
    login text
);


ALTER TABLE public.csv_import_profiles OWNER TO kivitendo;

--
-- Name: csv_import_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.csv_import_profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.csv_import_profiles_id_seq OWNER TO kivitendo;

--
-- Name: csv_import_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.csv_import_profiles_id_seq OWNED BY public.csv_import_profiles.id;


--
-- Name: csv_import_report_rows; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.csv_import_report_rows (
    id integer NOT NULL,
    csv_import_report_id integer NOT NULL,
    col integer NOT NULL,
    "row" integer NOT NULL,
    value text
);


ALTER TABLE public.csv_import_report_rows OWNER TO kivitendo;

--
-- Name: csv_import_report_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.csv_import_report_rows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.csv_import_report_rows_id_seq OWNER TO kivitendo;

--
-- Name: csv_import_report_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.csv_import_report_rows_id_seq OWNED BY public.csv_import_report_rows.id;


--
-- Name: csv_import_report_status; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.csv_import_report_status (
    id integer NOT NULL,
    csv_import_report_id integer NOT NULL,
    "row" integer NOT NULL,
    type text NOT NULL,
    value text
);


ALTER TABLE public.csv_import_report_status OWNER TO kivitendo;

--
-- Name: csv_import_report_status_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.csv_import_report_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.csv_import_report_status_id_seq OWNER TO kivitendo;

--
-- Name: csv_import_report_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.csv_import_report_status_id_seq OWNED BY public.csv_import_report_status.id;


--
-- Name: csv_import_reports; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.csv_import_reports (
    id integer NOT NULL,
    session_id text NOT NULL,
    profile_id integer NOT NULL,
    type text NOT NULL,
    file text NOT NULL,
    numrows integer NOT NULL,
    numheaders integer NOT NULL,
    test_mode boolean NOT NULL
);


ALTER TABLE public.csv_import_reports OWNER TO kivitendo;

--
-- Name: csv_import_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.csv_import_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.csv_import_reports_id_seq OWNER TO kivitendo;

--
-- Name: csv_import_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.csv_import_reports_id_seq OWNED BY public.csv_import_reports.id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.currencies (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.currencies OWNER TO kivitendo;

--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.currencies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currencies_id_seq OWNER TO kivitendo;

--
-- Name: currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.currencies_id_seq OWNED BY public.currencies.id;


--
-- Name: custom_data_export_queries; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_data_export_queries (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    sql_query text NOT NULL,
    access_right text,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.custom_data_export_queries OWNER TO kivitendo;

--
-- Name: custom_data_export_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.custom_data_export_queries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_data_export_queries_id_seq OWNER TO kivitendo;

--
-- Name: custom_data_export_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.custom_data_export_queries_id_seq OWNED BY public.custom_data_export_queries.id;


--
-- Name: custom_data_export_query_parameters; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_data_export_query_parameters (
    id integer NOT NULL,
    query_id integer NOT NULL,
    name text NOT NULL,
    description text,
    parameter_type public.custom_data_export_query_parameter_type_enum NOT NULL,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL,
    default_value_type public.custom_data_export_query_parameter_default_value_type_enum NOT NULL,
    default_value text
);


ALTER TABLE public.custom_data_export_query_parameters OWNER TO kivitendo;

--
-- Name: custom_data_export_query_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.custom_data_export_query_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_data_export_query_parameters_id_seq OWNER TO kivitendo;

--
-- Name: custom_data_export_query_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.custom_data_export_query_parameters_id_seq OWNED BY public.custom_data_export_query_parameters.id;


--
-- Name: custom_variable_config_partsgroups; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_variable_config_partsgroups (
    custom_variable_config_id integer NOT NULL,
    partsgroup_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.custom_variable_config_partsgroups OWNER TO kivitendo;

--
-- Name: custom_variable_configs_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.custom_variable_configs_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_variable_configs_id OWNER TO kivitendo;

--
-- Name: custom_variable_configs; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_variable_configs (
    id integer DEFAULT nextval('public.custom_variable_configs_id'::regclass) NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    type text NOT NULL,
    module text NOT NULL,
    default_value text,
    options text,
    searchable boolean NOT NULL,
    includeable boolean NOT NULL,
    included_by_default boolean NOT NULL,
    sortkey integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    flags text,
    CONSTRAINT custom_variable_configs_name_description_type_module_not_empty CHECK (((type <> ''::text) AND (module <> ''::text) AND (name <> ''::text) AND (description <> ''::text))),
    CONSTRAINT custom_variable_configs_options_not_empty_for_select CHECK (((type <> 'select'::text) OR (COALESCE(options, ''::text) <> ''::text)))
);


ALTER TABLE public.custom_variable_configs OWNER TO kivitendo;

--
-- Name: custom_variables_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.custom_variables_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_variables_id OWNER TO kivitendo;

--
-- Name: custom_variables; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_variables (
    id integer DEFAULT nextval('public.custom_variables_id'::regclass) NOT NULL,
    config_id integer NOT NULL,
    trans_id integer NOT NULL,
    bool_value boolean,
    timestamp_value timestamp without time zone,
    text_value text,
    number_value numeric(25,5),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    sub_module text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.custom_variables OWNER TO kivitendo;

--
-- Name: custom_variables_validity; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.custom_variables_validity (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    config_id integer NOT NULL,
    trans_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.custom_variables_validity OWNER TO kivitendo;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.customer (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    name text NOT NULL,
    department_1 text,
    department_2 text,
    street text,
    zipcode text,
    city text,
    country text,
    contact text,
    phone text,
    fax text,
    homepage text,
    email text,
    notes text,
    discount real,
    taxincluded boolean,
    creditlimit numeric(15,5) DEFAULT 0,
    customernumber text,
    cc text,
    bcc text,
    business_id integer,
    taxnumber text,
    account_number text,
    bank_code text,
    bank text,
    language text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    obsolete boolean DEFAULT false,
    username text,
    user_password text,
    salesman_id integer,
    c_vendor_id text,
    language_id integer,
    payment_id integer,
    taxzone_id integer NOT NULL,
    greeting text,
    ustid text,
    iban text,
    bic text,
    direct_debit boolean DEFAULT false,
    depositor text,
    taxincluded_checked boolean,
    mandator_id text,
    mandate_date_of_signature date,
    delivery_term_id integer,
    hourly_rate numeric(8,2),
    currency_id integer NOT NULL,
    gln text,
    pricegroup_id integer,
    order_lock boolean DEFAULT false,
    commercial_court text,
    invoice_mail text,
    contact_origin text,
    delivery_order_mail text
);


ALTER TABLE public.customer OWNER TO kivitendo;

--
-- Name: datev; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.datev (
    beraternr character varying(7),
    beratername character varying(9),
    mandantennr character varying(5),
    dfvkz character varying(2),
    datentraegernr character varying(3),
    abrechnungsnr character varying(6),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    id integer NOT NULL
);


ALTER TABLE public.datev OWNER TO kivitendo;

--
-- Name: datev_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.datev_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.datev_id_seq OWNER TO kivitendo;

--
-- Name: datev_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.datev_id_seq OWNED BY public.datev.id;


--
-- Name: defaults; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.defaults (
    inventory_accno_id integer,
    income_accno_id integer,
    expense_accno_id integer,
    fxgain_accno_id integer,
    fxloss_accno_id integer,
    invnumber text,
    sonumber text,
    weightunit character varying(5),
    businessnumber text,
    version character varying(8),
    closedto date,
    revtrans boolean DEFAULT false,
    ponumber text,
    sqnumber text,
    rfqnumber text,
    customernumber text,
    vendornumber text,
    articlenumber text,
    servicenumber text,
    coa text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    rmanumber text,
    cnnumber text,
    accounting_method text,
    inventory_system text,
    profit_determination text,
    dunning_ar_amount_fee integer,
    dunning_ar_amount_interest integer,
    dunning_ar integer,
    stocktaking_warehouse_id integer,
    stocktaking_bin_id integer,
    stocktaking_cutoff_date date,
    pdonumber text,
    sdonumber text,
    stocktaking_qty_threshold numeric(25,5) DEFAULT 0,
    ar_paid_accno_id integer,
    id integer NOT NULL,
    language_id integer,
    datev_check_on_sales_invoice boolean DEFAULT true,
    datev_check_on_purchase_invoice boolean DEFAULT true,
    datev_check_on_ar_transaction boolean DEFAULT true,
    datev_check_on_ap_transaction boolean DEFAULT true,
    datev_check_on_gl_transaction boolean DEFAULT true,
    payments_changeable integer DEFAULT 0 NOT NULL,
    is_changeable integer DEFAULT 2 NOT NULL,
    ir_changeable integer DEFAULT 2 NOT NULL,
    ar_changeable integer DEFAULT 2 NOT NULL,
    ap_changeable integer DEFAULT 2 NOT NULL,
    gl_changeable integer DEFAULT 2 NOT NULL,
    show_bestbefore boolean DEFAULT false,
    sales_order_show_delete boolean DEFAULT true,
    purchase_order_show_delete boolean DEFAULT true,
    sales_delivery_order_show_delete boolean DEFAULT true,
    purchase_delivery_order_show_delete boolean DEFAULT true,
    is_show_mark_as_paid boolean DEFAULT true,
    ir_show_mark_as_paid boolean DEFAULT true,
    ar_show_mark_as_paid boolean DEFAULT true,
    ap_show_mark_as_paid boolean DEFAULT true,
    warehouse_id integer,
    bin_id integer,
    company text,
    address text,
    taxnumber text,
    co_ustid text,
    duns text,
    sepa_creditor_id text,
    templates text,
    max_future_booking_interval integer DEFAULT 360,
    "precision" numeric(15,5) DEFAULT 0.01 NOT NULL,
    webdav boolean DEFAULT false,
    webdav_documents boolean DEFAULT false,
    vertreter boolean DEFAULT false,
    parts_show_image boolean DEFAULT true,
    parts_listing_image boolean DEFAULT true,
    parts_image_css text DEFAULT 'border:0;float:left;max-width:250px;margin-top:20px:margin-right:10px;margin-left:10px;'::text,
    normalize_vc_names boolean DEFAULT true,
    normalize_part_descriptions boolean DEFAULT true,
    assemblynumber text,
    show_weight boolean DEFAULT false NOT NULL,
    transfer_default boolean DEFAULT true,
    transfer_default_use_master_default_bin boolean DEFAULT false,
    transfer_default_ignore_onhand boolean DEFAULT false,
    warehouse_id_ignore_onhand integer,
    bin_id_ignore_onhand integer,
    balance_startdate_method text,
    currency_id integer NOT NULL,
    customer_hourly_rate numeric(8,2),
    signature text,
    requirement_spec_section_order_part_id integer,
    transfer_default_services boolean DEFAULT true,
    rndgain_accno_id integer,
    rndloss_accno_id integer,
    global_bcc text DEFAULT ''::text,
    customer_projects_only_in_sales boolean DEFAULT false NOT NULL,
    reqdate_interval integer DEFAULT 0,
    require_transaction_description_ps boolean DEFAULT false NOT NULL,
    sales_purchase_order_ship_missing_column boolean DEFAULT false,
    allow_sales_invoice_from_sales_quotation boolean DEFAULT true NOT NULL,
    allow_sales_invoice_from_sales_order boolean DEFAULT true NOT NULL,
    allow_new_purchase_delivery_order boolean DEFAULT true NOT NULL,
    allow_new_purchase_invoice boolean DEFAULT true NOT NULL,
    disabled_price_sources text[],
    bcc_to_login boolean DEFAULT false NOT NULL,
    transport_cost_reminder_article_number_id integer,
    is_transfer_out boolean DEFAULT false NOT NULL,
    ap_chart_id integer,
    ar_chart_id integer,
    create_part_if_not_found boolean DEFAULT false,
    letternumber integer,
    order_always_project boolean DEFAULT false,
    project_status_id integer,
    project_type_id integer,
    feature_balance boolean DEFAULT true NOT NULL,
    feature_datev boolean DEFAULT true NOT NULL,
    feature_erfolgsrechnung boolean DEFAULT false NOT NULL,
    feature_eurechnung boolean DEFAULT true NOT NULL,
    feature_ustva boolean DEFAULT true NOT NULL,
    order_warn_duplicate_parts boolean DEFAULT true,
    show_longdescription_select_item boolean DEFAULT false,
    email_journal integer DEFAULT 2,
    quick_search_modules text[],
    transfer_default_warehouse_for_assembly boolean DEFAULT false,
    feature_experimental_order boolean DEFAULT true NOT NULL,
    fa_bufa_nr text,
    fa_dauerfrist text,
    fa_steuerberater_city text,
    fa_steuerberater_name text,
    fa_steuerberater_street text,
    fa_steuerberater_tel text,
    fa_voranmeld text,
    doc_delete_printfiles boolean DEFAULT false,
    doc_max_filesize integer DEFAULT 10000000,
    doc_storage boolean DEFAULT false,
    doc_storage_for_documents text DEFAULT 'Filesystem'::text,
    doc_storage_for_attachments text DEFAULT 'Filesystem'::text,
    doc_storage_for_images text DEFAULT 'Filesystem'::text,
    doc_files boolean DEFAULT false,
    doc_files_rootpath text DEFAULT './documents'::text,
    doc_webdav boolean DEFAULT false,
    shipped_qty_require_stock_out boolean DEFAULT false NOT NULL,
    shipped_qty_fill_up boolean DEFAULT true NOT NULL,
    shipped_qty_item_identity_fields text[] DEFAULT '{parts_id}'::text[] NOT NULL,
    sepa_reference_add_vc_vc_id boolean DEFAULT false,
    assortmentnumber text,
    feature_experimental_assortment boolean DEFAULT true NOT NULL,
    doc_storage_for_shopimages text DEFAULT 'Filesystem'::text,
    datev_export_format public.datev_export_format_enum DEFAULT 'cp1252-translit'::public.datev_export_format_enum,
    order_warn_no_deliverydate boolean DEFAULT true,
    sepa_set_duedate_as_default_exec_date boolean DEFAULT false,
    sepa_set_skonto_date_as_default_exec_date boolean DEFAULT false,
    sepa_set_skonto_date_buffer_in_days integer DEFAULT 0,
    delivery_date_interval integer DEFAULT 0,
    email_attachment_vc_files_checked boolean DEFAULT true,
    email_attachment_part_files_checked boolean DEFAULT true,
    email_attachment_record_files_checked boolean DEFAULT true,
    invoice_mail_settings public.invoice_mail_settings DEFAULT 'cp'::public.invoice_mail_settings,
    dunning_creator public.dunning_creator DEFAULT 'current_employee'::public.dunning_creator
);


ALTER TABLE public.defaults OWNER TO kivitendo;

--
-- Name: defaults_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.defaults_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.defaults_id_seq OWNER TO kivitendo;

--
-- Name: defaults_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.defaults_id_seq OWNED BY public.defaults.id;


--
-- Name: delivery_order_items_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.delivery_order_items_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_order_items_id OWNER TO kivitendo;

SET default_with_oids = true;

--
-- Name: delivery_order_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.delivery_order_items (
    id integer DEFAULT nextval('public.delivery_order_items_id'::regclass) NOT NULL,
    delivery_order_id integer NOT NULL,
    parts_id integer NOT NULL,
    description text,
    qty numeric(25,5),
    sellprice numeric(15,5),
    discount real,
    project_id integer,
    reqdate date,
    serialnumber text,
    ordnumber text,
    transdate text,
    cusordnumber text,
    unit character varying(20),
    base_qty real,
    longdescription text,
    lastcost numeric(15,5),
    price_factor_id integer,
    price_factor numeric(15,5) DEFAULT 1,
    marge_price_factor numeric(15,5) DEFAULT 1,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    pricegroup_id integer,
    "position" integer NOT NULL,
    active_price_source text DEFAULT ''::text NOT NULL,
    active_discount_source text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.delivery_order_items OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: delivery_order_items_stock; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.delivery_order_items_stock (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    delivery_order_item_id integer NOT NULL,
    qty numeric(15,5) NOT NULL,
    unit character varying(20) NOT NULL,
    warehouse_id integer NOT NULL,
    bin_id integer NOT NULL,
    chargenumber text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    bestbefore date
);


ALTER TABLE public.delivery_order_items_stock OWNER TO kivitendo;

--
-- Name: delivery_orders; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.delivery_orders (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    donumber text NOT NULL,
    ordnumber text,
    transdate date DEFAULT now(),
    vendor_id integer,
    customer_id integer,
    reqdate date,
    shippingpoint text,
    notes text,
    intnotes text,
    employee_id integer,
    closed boolean DEFAULT false,
    delivered boolean DEFAULT false,
    cusordnumber text,
    oreqnumber text,
    department_id integer,
    shipvia text,
    cp_id integer,
    language_id integer,
    shipto_id integer,
    globalproject_id integer,
    salesman_id integer,
    transaction_description text,
    is_sales boolean,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    taxzone_id integer NOT NULL,
    taxincluded boolean,
    delivery_term_id integer,
    currency_id integer NOT NULL,
    payment_id integer
);


ALTER TABLE public.delivery_orders OWNER TO kivitendo;

--
-- Name: delivery_terms; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.delivery_terms (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    description text,
    description_long text,
    sortkey integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.delivery_terms OWNER TO kivitendo;

--
-- Name: department; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.department (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.department OWNER TO kivitendo;

--
-- Name: drafts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.drafts (
    id character varying(50) NOT NULL,
    module character varying(50) NOT NULL,
    submodule character varying(50) NOT NULL,
    description text,
    itime timestamp without time zone DEFAULT now(),
    form text,
    employee_id integer
);


ALTER TABLE public.drafts OWNER TO kivitendo;

--
-- Name: dunning; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.dunning (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    trans_id integer,
    dunning_id integer,
    dunning_level integer,
    transdate date,
    duedate date,
    fee numeric(15,5),
    interest numeric(15,5),
    dunning_config_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    fee_interest_ar_id integer
);


ALTER TABLE public.dunning OWNER TO kivitendo;

--
-- Name: dunning_config; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.dunning_config (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    dunning_level integer,
    dunning_description text,
    active boolean,
    auto boolean,
    email boolean,
    terms integer,
    payment_terms integer,
    fee numeric(15,5),
    interest_rate numeric(15,5),
    email_body text,
    email_subject text,
    email_attachment boolean,
    template text,
    create_invoices_for_fees boolean DEFAULT true
);


ALTER TABLE public.dunning_config OWNER TO kivitendo;

--
-- Name: email_journal; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.email_journal (
    id integer NOT NULL,
    sender_id integer,
    "from" text NOT NULL,
    recipients text NOT NULL,
    sent_on timestamp without time zone DEFAULT now() NOT NULL,
    subject text NOT NULL,
    body text NOT NULL,
    headers text NOT NULL,
    status text NOT NULL,
    extended_status text NOT NULL,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['ok'::text, 'failed'::text])))
);


ALTER TABLE public.email_journal OWNER TO kivitendo;

--
-- Name: email_journal_attachments; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.email_journal_attachments (
    id integer NOT NULL,
    "position" integer NOT NULL,
    email_journal_id integer NOT NULL,
    name text NOT NULL,
    mime_type text NOT NULL,
    content bytea NOT NULL,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL,
    file_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.email_journal_attachments OWNER TO kivitendo;

--
-- Name: email_journal_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.email_journal_attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_journal_attachments_id_seq OWNER TO kivitendo;

--
-- Name: email_journal_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.email_journal_attachments_id_seq OWNED BY public.email_journal_attachments.id;


--
-- Name: email_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.email_journal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_journal_id_seq OWNER TO kivitendo;

--
-- Name: email_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.email_journal_id_seq OWNED BY public.email_journal.id;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.employee (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    login text,
    startdate date DEFAULT ('now'::text)::date,
    enddate date,
    sales boolean DEFAULT true,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    name text,
    deleted boolean DEFAULT false,
    deleted_email text,
    deleted_signature text,
    deleted_tel text,
    deleted_fax text
);


ALTER TABLE public.employee OWNER TO kivitendo;

--
-- Name: employee_project_invoices; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.employee_project_invoices (
    employee_id integer NOT NULL,
    project_id integer NOT NULL
);


ALTER TABLE public.employee_project_invoices OWNER TO kivitendo;

--
-- Name: eur_categories; Type: VIEW; Schema: public; Owner: kivitendo
--

CREATE VIEW public.eur_categories AS
 SELECT "*VALUES*".column1 AS id,
    "*VALUES*".column2 AS description
   FROM (VALUES (1,'Umsatzerlöse'::text), (2,'sonstige Erlöse'::text), (3,'Privatanteile'::text), (4,'Zinserträge'::text), (5,'Ausserordentliche Erträge'::text), (6,'Vereinnahmte Umsatzst.'::text), (7,'Umsatzsteuererstattungen'::text), (8,'Wareneingänge'::text), (9,'Löhne und Gehälter'::text), (10,'Gesetzl. sozialer Aufw.'::text), (11,'Mieten'::text), (12,'Gas, Strom, Wasser'::text), (13,'Instandhaltung'::text), (14,'Steuern, Versich., Beiträge'::text), (15,'Kfz-Steuern'::text), (16,'Kfz-Versicherungen'::text), (17,'Sonst. Fahrzeugkosten'::text), (18,'Werbe- und Reisekosten'::text), (19,'Instandhaltung u. Werkzeuge'::text), (20,'Fachzeitschriften, Bücher'::text), (21,'Miete für Einrichtungen'::text), (22,'Rechts- und Beratungskosten'::text), (23,'Bürobedarf, Porto, Telefon'::text), (24,'Sonstige Aufwendungen'::text), (25,'Abschreibungen auf Anlagever.'::text), (26,'Abschreibungen auf GWG'::text), (27,'Vorsteuer'::text), (28,'Umsatzsteuerzahlungen'::text), (29,'Zinsaufwand'::text), (30,'Ausserordentlicher Aufwand'::text), (31,'Betriebliche Steuern'::text)) "*VALUES*";


ALTER TABLE public.eur_categories OWNER TO kivitendo;

--
-- Name: exchangerate; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.exchangerate (
    transdate date,
    buy numeric(15,5),
    sell numeric(15,5),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    id integer NOT NULL,
    currency_id integer NOT NULL
);


ALTER TABLE public.exchangerate OWNER TO kivitendo;

--
-- Name: exchangerate_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.exchangerate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exchangerate_id_seq OWNER TO kivitendo;

--
-- Name: exchangerate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.exchangerate_id_seq OWNED BY public.exchangerate.id;


--
-- Name: files; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.files (
    id integer NOT NULL,
    object_type text NOT NULL,
    object_id integer NOT NULL,
    file_name text NOT NULL,
    file_type text NOT NULL,
    mime_type text NOT NULL,
    source text NOT NULL,
    backend text,
    backend_data text,
    title character varying(45),
    description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    CONSTRAINT valid_type CHECK (((object_type = 'credit_note'::text) OR (object_type = 'invoice'::text) OR (object_type = 'sales_order'::text) OR (object_type = 'sales_quotation'::text) OR (object_type = 'sales_delivery_order'::text) OR (object_type = 'request_quotation'::text) OR (object_type = 'purchase_order'::text) OR (object_type = 'purchase_delivery_order'::text) OR (object_type = 'purchase_invoice'::text) OR (object_type = 'vendor'::text) OR (object_type = 'customer'::text) OR (object_type = 'part'::text) OR (object_type = 'gl_transaction'::text) OR (object_type = 'dunning'::text) OR (object_type = 'dunning1'::text) OR (object_type = 'dunning2'::text) OR (object_type = 'dunning3'::text) OR (object_type = 'draft'::text) OR (object_type = 'statement'::text) OR (object_type = 'shop_image'::text)))
);


ALTER TABLE public.files OWNER TO kivitendo;

--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.files_id_seq OWNER TO kivitendo;

--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.files_id_seq OWNED BY public.files.id;


--
-- Name: finanzamt; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.finanzamt (
    fa_land_nr text,
    fa_bufa_nr text,
    fa_name text,
    fa_strasse text,
    fa_plz text,
    fa_ort text,
    fa_telefon text,
    fa_fax text,
    fa_plz_grosskunden text,
    fa_plz_postfach text,
    fa_postfach text,
    fa_blz_1 text,
    fa_kontonummer_1 text,
    fa_bankbezeichnung_1 text,
    fa_blz_2 text,
    fa_kontonummer_2 text,
    fa_bankbezeichnung_2 text,
    fa_oeffnungszeiten text,
    fa_email text,
    fa_internet text,
    id integer NOT NULL
);


ALTER TABLE public.finanzamt OWNER TO kivitendo;

--
-- Name: finanzamt_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.finanzamt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.finanzamt_id_seq OWNER TO kivitendo;

--
-- Name: finanzamt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.finanzamt_id_seq OWNED BY public.finanzamt.id;


--
-- Name: follow_up_access; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.follow_up_access (
    who integer NOT NULL,
    what integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.follow_up_access OWNER TO kivitendo;

--
-- Name: follow_up_access_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.follow_up_access_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.follow_up_access_id_seq OWNER TO kivitendo;

--
-- Name: follow_up_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.follow_up_access_id_seq OWNED BY public.follow_up_access.id;


--
-- Name: follow_up_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.follow_up_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.follow_up_id OWNER TO kivitendo;

--
-- Name: follow_up_link_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.follow_up_link_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.follow_up_link_id OWNER TO kivitendo;

--
-- Name: follow_up_links; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.follow_up_links (
    id integer DEFAULT nextval('public.follow_up_link_id'::regclass) NOT NULL,
    follow_up_id integer NOT NULL,
    trans_id integer NOT NULL,
    trans_type text NOT NULL,
    trans_info text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.follow_up_links OWNER TO kivitendo;

--
-- Name: follow_ups; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.follow_ups (
    id integer DEFAULT nextval('public.follow_up_id'::regclass) NOT NULL,
    follow_up_date date NOT NULL,
    created_for_user integer NOT NULL,
    done boolean DEFAULT false,
    note_id integer NOT NULL,
    created_by integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.follow_ups OWNER TO kivitendo;

--
-- Name: generic_translations; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.generic_translations (
    id integer NOT NULL,
    language_id integer,
    translation_type character varying(100) NOT NULL,
    translation_id integer,
    translation text
);


ALTER TABLE public.generic_translations OWNER TO kivitendo;

--
-- Name: generic_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.generic_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.generic_translations_id_seq OWNER TO kivitendo;

--
-- Name: generic_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.generic_translations_id_seq OWNED BY public.generic_translations.id;


--
-- Name: gl; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.gl (
    id integer DEFAULT nextval(('glid'::text)::regclass) NOT NULL,
    reference text,
    description text,
    transdate date DEFAULT ('now'::text)::date,
    gldate date DEFAULT ('now'::text)::date,
    employee_id integer,
    notes text,
    department_id integer,
    taxincluded boolean,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    type text,
    ob_transaction boolean,
    cb_transaction boolean,
    storno boolean DEFAULT false,
    storno_id integer
);


ALTER TABLE public.gl OWNER TO kivitendo;

--
-- Name: glid; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.glid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.glid OWNER TO kivitendo;

--
-- Name: history_erp; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.history_erp (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    trans_id integer,
    employee_id integer,
    addition text,
    what_done text,
    itime timestamp without time zone DEFAULT now(),
    snumbers text
);


ALTER TABLE public.history_erp OWNER TO kivitendo;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.inventory (
    warehouse_id integer NOT NULL,
    parts_id integer NOT NULL,
    oe_id integer,
    delivery_order_items_stock_id integer,
    shippingdate date NOT NULL,
    employee_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    bin_id integer NOT NULL,
    qty numeric(25,5),
    trans_id integer NOT NULL,
    trans_type_id integer NOT NULL,
    project_id integer,
    chargenumber text DEFAULT ''::text NOT NULL,
    comment text,
    bestbefore date,
    id integer NOT NULL,
    invoice_id integer
);


ALTER TABLE public.inventory OWNER TO kivitendo;

--
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.inventory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_id_seq OWNER TO kivitendo;

--
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;


SET default_with_oids = true;

--
-- Name: invoice; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.invoice (
    id integer DEFAULT nextval(('invoiceid'::text)::regclass) NOT NULL,
    trans_id integer,
    parts_id integer,
    description text,
    qty real,
    allocated real,
    sellprice numeric(15,5),
    fxsellprice numeric(15,5),
    discount real,
    assemblyitem boolean DEFAULT false,
    project_id integer,
    deliverydate date,
    serialnumber text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    pricegroup_id integer,
    ordnumber text,
    transdate text,
    cusordnumber text,
    unit character varying(20),
    base_qty real,
    subtotal boolean DEFAULT false,
    longdescription text,
    marge_total numeric(15,5),
    marge_percent numeric(15,5),
    lastcost numeric(15,5),
    price_factor_id integer,
    price_factor numeric(15,5) DEFAULT 1,
    marge_price_factor numeric(15,5) DEFAULT 1,
    donumber text,
    "position" integer NOT NULL,
    active_price_source text DEFAULT ''::text NOT NULL,
    active_discount_source text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.invoice OWNER TO kivitendo;

--
-- Name: invoiceid; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.invoiceid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.invoiceid OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: language; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.language (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    template_code text,
    article_code text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    output_numberformat text,
    output_dateformat text,
    output_longdates boolean
);


ALTER TABLE public.language OWNER TO kivitendo;

--
-- Name: leads; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.leads (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    lead character varying(50)
);


ALTER TABLE public.leads OWNER TO kivitendo;

--
-- Name: letter; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.letter (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    customer_id integer,
    letternumber text,
    subject text,
    greeting text,
    body text,
    employee_id integer,
    salesman_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    date date,
    reference text,
    intnotes text,
    cp_id integer,
    vendor_id integer
);


ALTER TABLE public.letter OWNER TO kivitendo;

--
-- Name: letter_draft; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.letter_draft (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    customer_id integer,
    cp_id integer,
    letternumber text,
    date date,
    intnotes text,
    reference text,
    subject text,
    greeting text,
    body text,
    employee_id integer,
    salesman_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    vendor_id integer
);


ALTER TABLE public.letter_draft OWNER TO kivitendo;

--
-- Name: makemodel_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.makemodel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.makemodel_id_seq OWNER TO kivitendo;

--
-- Name: makemodel; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.makemodel (
    parts_id integer,
    model text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    lastcost numeric(15,5),
    lastupdate date,
    sortorder integer,
    make integer,
    id integer DEFAULT nextval('public.makemodel_id_seq'::regclass) NOT NULL
);


ALTER TABLE public.makemodel OWNER TO kivitendo;

--
-- Name: note_id; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.note_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.note_id OWNER TO kivitendo;

--
-- Name: notes; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.notes (
    id integer DEFAULT nextval('public.note_id'::regclass) NOT NULL,
    subject text,
    body text,
    created_by integer NOT NULL,
    trans_id integer,
    trans_module character varying(10),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.notes OWNER TO kivitendo;

--
-- Name: oe; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.oe (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    ordnumber text NOT NULL,
    transdate date DEFAULT ('now'::text)::date,
    vendor_id integer,
    customer_id integer,
    amount numeric(15,5),
    netamount numeric(15,5),
    reqdate date,
    taxincluded boolean,
    shippingpoint text,
    notes text,
    employee_id integer,
    closed boolean DEFAULT false,
    quotation boolean DEFAULT false,
    quonumber text,
    cusordnumber text,
    intnotes text,
    department_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    shipvia text,
    cp_id integer,
    language_id integer,
    payment_id integer,
    delivery_customer_id integer,
    delivery_vendor_id integer,
    taxzone_id integer NOT NULL,
    proforma boolean DEFAULT false,
    shipto_id integer,
    order_probability integer DEFAULT 0 NOT NULL,
    expected_billing_date date,
    globalproject_id integer,
    delivered boolean DEFAULT false,
    salesman_id integer,
    marge_total numeric(15,5),
    marge_percent numeric(15,5),
    transaction_description text,
    delivery_term_id integer,
    currency_id integer NOT NULL
);


ALTER TABLE public.oe OWNER TO kivitendo;

SET default_with_oids = true;

--
-- Name: orderitems; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.orderitems (
    trans_id integer,
    parts_id integer,
    description text,
    qty real,
    sellprice numeric(15,5),
    discount real,
    project_id integer,
    reqdate date,
    ship real,
    serialnumber text,
    id integer DEFAULT nextval(('orderitemsid'::text)::regclass) NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    pricegroup_id integer,
    ordnumber text,
    transdate text,
    cusordnumber text,
    unit character varying(20),
    base_qty real,
    subtotal boolean DEFAULT false,
    longdescription text,
    marge_total numeric(15,5),
    marge_percent numeric(15,5),
    lastcost numeric(15,5),
    price_factor_id integer,
    price_factor numeric(15,5) DEFAULT 1,
    marge_price_factor numeric(15,5) DEFAULT 1,
    "position" integer NOT NULL,
    active_price_source text DEFAULT ''::text NOT NULL,
    active_discount_source text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.orderitems OWNER TO kivitendo;

--
-- Name: orderitemsid; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.orderitemsid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1
    CYCLE;


ALTER TABLE public.orderitemsid OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: part_classifications; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.part_classifications (
    id integer NOT NULL,
    description text,
    abbreviation text,
    used_for_purchase boolean DEFAULT true NOT NULL,
    used_for_sale boolean DEFAULT true NOT NULL,
    report_separate boolean DEFAULT false NOT NULL
);


ALTER TABLE public.part_classifications OWNER TO kivitendo;

--
-- Name: part_classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.part_classifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.part_classifications_id_seq OWNER TO kivitendo;

--
-- Name: part_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.part_classifications_id_seq OWNED BY public.part_classifications.id;


--
-- Name: part_customer_prices; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.part_customer_prices (
    id integer NOT NULL,
    parts_id integer NOT NULL,
    customer_id integer NOT NULL,
    customer_partnumber text DEFAULT ''::text,
    price numeric(15,5) DEFAULT 0,
    sortorder integer DEFAULT 0,
    lastupdate date DEFAULT now()
);


ALTER TABLE public.part_customer_prices OWNER TO kivitendo;

--
-- Name: part_customer_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.part_customer_prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.part_customer_prices_id_seq OWNER TO kivitendo;

--
-- Name: part_customer_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.part_customer_prices_id_seq OWNED BY public.part_customer_prices.id;


SET default_with_oids = true;

--
-- Name: parts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.parts (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    partnumber text NOT NULL,
    description text,
    listprice numeric(15,5),
    sellprice numeric(15,5),
    lastcost numeric(15,5),
    priceupdate date DEFAULT ('now'::text)::date,
    weight real,
    notes text,
    makemodel boolean DEFAULT false,
    rop real,
    shop boolean DEFAULT false,
    obsolete boolean DEFAULT false,
    bom boolean DEFAULT false,
    image text,
    drawing text,
    microfiche text,
    partsgroup_id integer,
    ve integer,
    gv numeric(15,5),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    unit character varying(20) NOT NULL,
    formel text,
    not_discountable boolean DEFAULT false,
    buchungsgruppen_id integer,
    payment_id integer,
    ean text,
    price_factor_id integer,
    onhand numeric(25,5) DEFAULT 0,
    stockable boolean DEFAULT false,
    has_sernumber boolean DEFAULT false,
    warehouse_id integer,
    bin_id integer,
    classification_id integer DEFAULT 0,
    part_type public.part_type_enum NOT NULL
);


ALTER TABLE public.parts OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: parts_price_history; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.parts_price_history (
    id integer NOT NULL,
    part_id integer NOT NULL,
    valid_from timestamp without time zone NOT NULL,
    lastcost numeric(15,5),
    listprice numeric(15,5),
    sellprice numeric(15,5)
);


ALTER TABLE public.parts_price_history OWNER TO kivitendo;

--
-- Name: parts_price_history_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.parts_price_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parts_price_history_id_seq OWNER TO kivitendo;

--
-- Name: parts_price_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.parts_price_history_id_seq OWNED BY public.parts_price_history.id;


SET default_with_oids = true;

--
-- Name: partsgroup; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.partsgroup (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    partsgroup text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    obsolete boolean DEFAULT false,
    sortkey integer NOT NULL
);


ALTER TABLE public.partsgroup OWNER TO kivitendo;

SET default_with_oids = false;

--
-- Name: payment_terms; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.payment_terms (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    description_long text,
    terms_netto integer,
    terms_skonto integer,
    percent_skonto real,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    sortkey integer NOT NULL,
    auto_calculation boolean NOT NULL,
    description_long_invoice text,
    obsolete boolean DEFAULT false
);


ALTER TABLE public.payment_terms OWNER TO kivitendo;

--
-- Name: periodic_invoices; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.periodic_invoices (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    config_id integer NOT NULL,
    ar_id integer NOT NULL,
    period_start_date date NOT NULL,
    itime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.periodic_invoices OWNER TO kivitendo;

--
-- Name: periodic_invoices_configs; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.periodic_invoices_configs (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    oe_id integer NOT NULL,
    periodicity character varying(1) NOT NULL,
    print boolean DEFAULT false,
    printer_id integer,
    copies integer,
    active boolean DEFAULT true,
    terminated boolean DEFAULT false,
    start_date date,
    end_date date,
    ar_chart_id integer NOT NULL,
    extend_automatically_by integer,
    first_billing_date date,
    order_value_periodicity character varying(1) NOT NULL,
    direct_debit boolean DEFAULT false NOT NULL,
    send_email boolean DEFAULT false NOT NULL,
    email_recipient_contact_id integer,
    email_recipient_address text,
    email_sender text,
    email_subject text,
    email_body text,
    CONSTRAINT periodic_invoices_configs_valid_order_value_periodicity CHECK (((order_value_periodicity)::text = ANY ((ARRAY['p'::character varying, 'm'::character varying, 'q'::character varying, 'b'::character varying, 'y'::character varying, '2'::character varying, '3'::character varying, '4'::character varying, '5'::character varying])::text[]))),
    CONSTRAINT periodic_invoices_configs_valid_periodicity CHECK (((periodicity)::text = ANY ((ARRAY['o'::character varying, 'm'::character varying, 'q'::character varying, 'b'::character varying, 'y'::character varying])::text[])))
);


ALTER TABLE public.periodic_invoices_configs OWNER TO kivitendo;

--
-- Name: price_factors; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.price_factors (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    factor numeric(15,5),
    sortkey integer
);


ALTER TABLE public.price_factors OWNER TO kivitendo;

--
-- Name: price_rule_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.price_rule_items (
    id integer NOT NULL,
    price_rules_id integer NOT NULL,
    type text,
    op text,
    custom_variable_configs_id integer,
    value_text text,
    value_int integer,
    value_date date,
    value_num numeric(15,5),
    itime timestamp without time zone,
    mtime timestamp without time zone
);


ALTER TABLE public.price_rule_items OWNER TO kivitendo;

--
-- Name: price_rule_items_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.price_rule_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.price_rule_items_id_seq OWNER TO kivitendo;

--
-- Name: price_rule_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.price_rule_items_id_seq OWNED BY public.price_rule_items.id;


--
-- Name: price_rules; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.price_rules (
    id integer NOT NULL,
    name text,
    type text,
    priority integer DEFAULT 3 NOT NULL,
    price numeric(15,5),
    reduction numeric(15,5),
    obsolete boolean DEFAULT false NOT NULL,
    itime timestamp without time zone,
    mtime timestamp without time zone,
    discount numeric(15,5)
);


ALTER TABLE public.price_rules OWNER TO kivitendo;

--
-- Name: price_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.price_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.price_rules_id_seq OWNER TO kivitendo;

--
-- Name: price_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.price_rules_id_seq OWNED BY public.price_rules.id;


--
-- Name: pricegroup; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.pricegroup (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    pricegroup text NOT NULL,
    obsolete boolean DEFAULT false,
    sortkey integer NOT NULL
);


ALTER TABLE public.pricegroup OWNER TO kivitendo;

--
-- Name: prices; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.prices (
    parts_id integer NOT NULL,
    pricegroup_id integer NOT NULL,
    price numeric(15,5),
    id integer NOT NULL
);


ALTER TABLE public.prices OWNER TO kivitendo;

--
-- Name: prices_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prices_id_seq OWNER TO kivitendo;

--
-- Name: prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.prices_id_seq OWNED BY public.prices.id;


--
-- Name: printers; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.printers (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    printer_description text NOT NULL,
    printer_command text,
    template_code text
);


ALTER TABLE public.printers OWNER TO kivitendo;

--
-- Name: project; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    projectnumber text,
    description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    active boolean DEFAULT true,
    customer_id integer,
    valid boolean DEFAULT true,
    project_type_id integer NOT NULL,
    start_date date,
    end_date date,
    billable_customer_id integer,
    budget_cost numeric(15,5) DEFAULT 0 NOT NULL,
    order_value numeric(15,5) DEFAULT 0 NOT NULL,
    budget_minutes integer DEFAULT 0 NOT NULL,
    timeframe boolean DEFAULT false NOT NULL,
    project_status_id integer NOT NULL
);


ALTER TABLE public.project OWNER TO kivitendo;

--
-- Name: project_participants; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_participants (
    id integer NOT NULL,
    project_id integer NOT NULL,
    employee_id integer NOT NULL,
    project_role_id integer NOT NULL,
    minutes integer DEFAULT 0 NOT NULL,
    cost_per_hour numeric(15,5),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.project_participants OWNER TO kivitendo;

--
-- Name: project_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_participants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_participants_id_seq OWNER TO kivitendo;

--
-- Name: project_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_participants_id_seq OWNED BY public.project_participants.id;


--
-- Name: project_phase_participants; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_phase_participants (
    id integer NOT NULL,
    project_phase_id integer NOT NULL,
    employee_id integer NOT NULL,
    project_role_id integer NOT NULL,
    minutes integer DEFAULT 0 NOT NULL,
    cost_per_hour numeric(15,5),
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.project_phase_participants OWNER TO kivitendo;

--
-- Name: project_phase_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_phase_participants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_phase_participants_id_seq OWNER TO kivitendo;

--
-- Name: project_phase_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_phase_participants_id_seq OWNED BY public.project_phase_participants.id;


--
-- Name: project_phases; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_phases (
    id integer NOT NULL,
    project_id integer,
    start_date date,
    end_date date,
    name text NOT NULL,
    description text NOT NULL,
    budget_minutes integer DEFAULT 0 NOT NULL,
    budget_cost numeric(15,5) DEFAULT 0 NOT NULL,
    general_minutes integer DEFAULT 0 NOT NULL,
    general_cost_per_hour numeric(15,5) DEFAULT 0 NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.project_phases OWNER TO kivitendo;

--
-- Name: project_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_phases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_phases_id_seq OWNER TO kivitendo;

--
-- Name: project_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_phases_id_seq OWNED BY public.project_phases.id;


--
-- Name: project_roles; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_roles (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.project_roles OWNER TO kivitendo;

--
-- Name: project_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_roles_id_seq OWNER TO kivitendo;

--
-- Name: project_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_roles_id_seq OWNED BY public.project_roles.id;


--
-- Name: project_statuses; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_statuses (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.project_statuses OWNER TO kivitendo;

--
-- Name: project_status_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_status_id_seq OWNER TO kivitendo;

--
-- Name: project_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_status_id_seq OWNED BY public.project_statuses.id;


--
-- Name: project_types; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.project_types (
    id integer NOT NULL,
    "position" integer NOT NULL,
    description text,
    internal boolean DEFAULT false NOT NULL
);


ALTER TABLE public.project_types OWNER TO kivitendo;

--
-- Name: project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.project_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_types_id_seq OWNER TO kivitendo;

--
-- Name: project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.project_types_id_seq OWNED BY public.project_types.id;


--
-- Name: reconciliation_links; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.reconciliation_links (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    bank_transaction_id integer NOT NULL,
    acc_trans_id bigint NOT NULL,
    rec_group integer NOT NULL
);


ALTER TABLE public.reconciliation_links OWNER TO kivitendo;

--
-- Name: record_links; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.record_links (
    from_table character varying(50) NOT NULL,
    from_id integer NOT NULL,
    to_table character varying(50) NOT NULL,
    to_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    id integer NOT NULL
);


ALTER TABLE public.record_links OWNER TO kivitendo;

--
-- Name: record_links_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.record_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_links_id_seq OWNER TO kivitendo;

--
-- Name: record_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.record_links_id_seq OWNED BY public.record_links.id;


--
-- Name: record_template_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.record_template_items (
    id integer NOT NULL,
    record_template_id integer NOT NULL,
    chart_id integer NOT NULL,
    tax_id integer NOT NULL,
    project_id integer,
    amount1 numeric(15,5) NOT NULL,
    amount2 numeric(15,5),
    source text,
    memo text
);


ALTER TABLE public.record_template_items OWNER TO kivitendo;

--
-- Name: record_template_items_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.record_template_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_template_items_id_seq OWNER TO kivitendo;

--
-- Name: record_template_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.record_template_items_id_seq OWNED BY public.record_template_items.id;


--
-- Name: record_templates; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.record_templates (
    id integer NOT NULL,
    template_name text NOT NULL,
    template_type public.record_template_type NOT NULL,
    customer_id integer,
    vendor_id integer,
    currency_id integer NOT NULL,
    department_id integer,
    project_id integer,
    employee_id integer,
    taxincluded boolean DEFAULT false NOT NULL,
    direct_debit boolean DEFAULT false NOT NULL,
    ob_transaction boolean DEFAULT false NOT NULL,
    cb_transaction boolean DEFAULT false NOT NULL,
    reference text,
    description text,
    ordnumber text,
    notes text,
    ar_ap_chart_id integer,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL,
    show_details boolean DEFAULT false NOT NULL
);


ALTER TABLE public.record_templates OWNER TO kivitendo;

--
-- Name: record_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.record_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_templates_id_seq OWNER TO kivitendo;

--
-- Name: record_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.record_templates_id_seq OWNED BY public.record_templates.id;


--
-- Name: requirement_spec_acceptance_statuses; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_acceptance_statuses (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_acceptance_statuses OWNER TO kivitendo;

--
-- Name: requirement_spec_acceptance_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_acceptance_statuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_acceptance_statuses_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_acceptance_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_acceptance_statuses_id_seq OWNED BY public.requirement_spec_acceptance_statuses.id;


--
-- Name: requirement_spec_complexities; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_complexities (
    id integer NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_complexities OWNER TO kivitendo;

--
-- Name: requirement_spec_complexities_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_complexities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_complexities_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_complexities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_complexities_id_seq OWNED BY public.requirement_spec_complexities.id;


--
-- Name: requirement_spec_item_dependencies; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_item_dependencies (
    depending_item_id integer NOT NULL,
    depended_item_id integer NOT NULL
);


ALTER TABLE public.requirement_spec_item_dependencies OWNER TO kivitendo;

--
-- Name: requirement_spec_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_items (
    id integer NOT NULL,
    requirement_spec_id integer NOT NULL,
    item_type text NOT NULL,
    parent_id integer,
    "position" integer NOT NULL,
    fb_number text NOT NULL,
    title text,
    description text,
    complexity_id integer,
    risk_id integer,
    time_estimation numeric(12,2) DEFAULT 0 NOT NULL,
    is_flagged boolean DEFAULT false NOT NULL,
    acceptance_status_id integer,
    acceptance_text text,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone,
    sellprice_factor numeric(10,5) DEFAULT 1,
    order_part_id integer,
    CONSTRAINT valid_item_type CHECK (((item_type = 'section'::text) OR (item_type = 'function-block'::text) OR (item_type = 'sub-function-block'::text))),
    CONSTRAINT valid_parent_id_for_item_type CHECK (
CASE
    WHEN (item_type = 'section'::text) THEN (parent_id IS NULL)
    ELSE (parent_id IS NOT NULL)
END)
);


ALTER TABLE public.requirement_spec_items OWNER TO kivitendo;

--
-- Name: requirement_spec_items_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_items_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_items_id_seq OWNED BY public.requirement_spec_items.id;


--
-- Name: requirement_spec_orders; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_orders (
    id integer NOT NULL,
    requirement_spec_id integer NOT NULL,
    order_id integer NOT NULL,
    version_id integer,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requirement_spec_orders OWNER TO kivitendo;

--
-- Name: requirement_spec_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_orders_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_orders_id_seq OWNED BY public.requirement_spec_orders.id;


--
-- Name: requirement_spec_parts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_parts (
    id integer NOT NULL,
    requirement_spec_id integer NOT NULL,
    part_id integer NOT NULL,
    unit_id integer NOT NULL,
    qty numeric(15,5) NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL
);


ALTER TABLE public.requirement_spec_parts OWNER TO kivitendo;

--
-- Name: requirement_spec_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_parts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_parts_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_parts_id_seq OWNED BY public.requirement_spec_parts.id;


--
-- Name: requirement_spec_pictures; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_pictures (
    id integer NOT NULL,
    requirement_spec_id integer NOT NULL,
    text_block_id integer NOT NULL,
    "position" integer NOT NULL,
    number text NOT NULL,
    description text,
    picture_file_name text NOT NULL,
    picture_content_type text NOT NULL,
    picture_mtime timestamp without time zone DEFAULT now() NOT NULL,
    picture_content bytea NOT NULL,
    picture_width integer NOT NULL,
    picture_height integer NOT NULL,
    thumbnail_content_type text NOT NULL,
    thumbnail_content bytea NOT NULL,
    thumbnail_width integer NOT NULL,
    thumbnail_height integer NOT NULL,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_pictures OWNER TO kivitendo;

--
-- Name: requirement_spec_pictures_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_pictures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_pictures_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_pictures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_pictures_id_seq OWNED BY public.requirement_spec_pictures.id;


--
-- Name: requirement_spec_predefined_texts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_predefined_texts (
    id integer NOT NULL,
    description text NOT NULL,
    title text NOT NULL,
    text text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    useable_for_text_blocks boolean DEFAULT false NOT NULL,
    useable_for_sections boolean DEFAULT false NOT NULL
);


ALTER TABLE public.requirement_spec_predefined_texts OWNER TO kivitendo;

--
-- Name: requirement_spec_predefined_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_predefined_texts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_predefined_texts_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_predefined_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_predefined_texts_id_seq OWNED BY public.requirement_spec_predefined_texts.id;


--
-- Name: requirement_spec_risks; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_risks (
    id integer NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_risks OWNER TO kivitendo;

--
-- Name: requirement_spec_risks_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_risks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_risks_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_risks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_risks_id_seq OWNED BY public.requirement_spec_risks.id;


--
-- Name: requirement_spec_statuses; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_statuses (
    id integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_statuses OWNER TO kivitendo;

--
-- Name: requirement_spec_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_statuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_statuses_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_statuses_id_seq OWNED BY public.requirement_spec_statuses.id;


--
-- Name: requirement_spec_text_blocks; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_text_blocks (
    id integer NOT NULL,
    requirement_spec_id integer NOT NULL,
    title text NOT NULL,
    text text,
    "position" integer NOT NULL,
    output_position integer DEFAULT 1 NOT NULL,
    is_flagged boolean DEFAULT false NOT NULL,
    itime timestamp without time zone DEFAULT now() NOT NULL,
    mtime timestamp without time zone
);


ALTER TABLE public.requirement_spec_text_blocks OWNER TO kivitendo;

--
-- Name: requirement_spec_text_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_text_blocks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_text_blocks_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_text_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_text_blocks_id_seq OWNED BY public.requirement_spec_text_blocks.id;


--
-- Name: requirement_spec_types; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_types (
    id integer NOT NULL,
    description text NOT NULL,
    "position" integer NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    section_number_format text DEFAULT 'A00'::text NOT NULL,
    function_block_number_format text DEFAULT 'FB000'::text NOT NULL,
    template_file_name text
);


ALTER TABLE public.requirement_spec_types OWNER TO kivitendo;

--
-- Name: requirement_spec_types_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_types_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_types_id_seq OWNED BY public.requirement_spec_types.id;


--
-- Name: requirement_spec_versions; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_spec_versions (
    id integer NOT NULL,
    version_number integer,
    description text NOT NULL,
    comment text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    requirement_spec_id integer NOT NULL,
    working_copy_id integer
);


ALTER TABLE public.requirement_spec_versions OWNER TO kivitendo;

--
-- Name: requirement_spec_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_spec_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_spec_versions_id_seq OWNER TO kivitendo;

--
-- Name: requirement_spec_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_spec_versions_id_seq OWNED BY public.requirement_spec_versions.id;


--
-- Name: requirement_specs; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.requirement_specs (
    id integer NOT NULL,
    type_id integer NOT NULL,
    status_id integer,
    customer_id integer,
    project_id integer,
    title text NOT NULL,
    hourly_rate numeric(8,2) DEFAULT 0 NOT NULL,
    working_copy_id integer,
    previous_section_number integer NOT NULL,
    previous_fb_number integer NOT NULL,
    is_template boolean DEFAULT false,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    time_estimation numeric(12,2) DEFAULT 0 NOT NULL,
    previous_picture_number integer DEFAULT 0 NOT NULL,
    CONSTRAINT requirement_specs_is_template_or_has_customer_status_type CHECK ((is_template OR ((type_id IS NOT NULL) AND (status_id IS NOT NULL) AND (customer_id IS NOT NULL))))
);


ALTER TABLE public.requirement_specs OWNER TO kivitendo;

--
-- Name: requirement_specs_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.requirement_specs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirement_specs_id_seq OWNER TO kivitendo;

--
-- Name: requirement_specs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.requirement_specs_id_seq OWNED BY public.requirement_specs.id;


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.schema_info (
    tag text NOT NULL,
    login text,
    itime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.schema_info OWNER TO kivitendo;

--
-- Name: sepa_export_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.sepa_export_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sepa_export_id_seq OWNER TO kivitendo;

--
-- Name: sepa_export; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.sepa_export (
    id integer DEFAULT nextval('public.sepa_export_id_seq'::regclass) NOT NULL,
    employee_id integer NOT NULL,
    executed boolean DEFAULT false,
    closed boolean DEFAULT false,
    itime timestamp without time zone DEFAULT now(),
    vc character varying(10)
);


ALTER TABLE public.sepa_export OWNER TO kivitendo;

--
-- Name: sepa_export_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.sepa_export_items (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    sepa_export_id integer NOT NULL,
    ap_id integer,
    chart_id integer NOT NULL,
    amount numeric(25,5),
    reference character varying(140),
    requested_execution_date date,
    executed boolean DEFAULT false,
    execution_date date,
    our_iban character varying(100),
    our_bic character varying(100),
    vc_iban character varying(100),
    vc_bic character varying(100),
    end_to_end_id character varying(35),
    our_depositor text,
    vc_depositor text,
    ar_id integer,
    vc_mandator_id text,
    vc_mandate_date_of_signature date,
    payment_type text DEFAULT 'without_skonto'::text,
    skonto_amount numeric(25,5)
);


ALTER TABLE public.sepa_export_items OWNER TO kivitendo;

--
-- Name: sepa_export_message_ids; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.sepa_export_message_ids (
    id integer NOT NULL,
    sepa_export_id integer NOT NULL,
    message_id text NOT NULL
);


ALTER TABLE public.sepa_export_message_ids OWNER TO kivitendo;

--
-- Name: sepa_export_message_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.sepa_export_message_ids_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sepa_export_message_ids_id_seq OWNER TO kivitendo;

--
-- Name: sepa_export_message_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.sepa_export_message_ids_id_seq OWNED BY public.sepa_export_message_ids.id;


--
-- Name: shipto; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shipto (
    trans_id integer,
    shiptoname text,
    shiptodepartment_1 text,
    shiptodepartment_2 text,
    shiptostreet text,
    shiptozipcode text,
    shiptocity text,
    shiptocountry text,
    shiptocontact text,
    shiptophone text,
    shiptofax text,
    shiptoemail text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    module text,
    shipto_id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    shiptocp_gender text,
    shiptogln text
);


ALTER TABLE public.shipto OWNER TO kivitendo;

--
-- Name: shop_images; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shop_images (
    id integer NOT NULL,
    file_id integer,
    "position" integer,
    thumbnail_content bytea,
    org_file_width integer,
    org_file_height integer,
    thumbnail_content_type text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    object_id text NOT NULL
);


ALTER TABLE public.shop_images OWNER TO kivitendo;

--
-- Name: shop_images_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.shop_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_images_id_seq OWNER TO kivitendo;

--
-- Name: shop_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.shop_images_id_seq OWNED BY public.shop_images.id;


--
-- Name: shop_order_items; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shop_order_items (
    id integer NOT NULL,
    shop_trans_id integer NOT NULL,
    shop_order_id integer,
    description text,
    partnumber text,
    "position" integer,
    tax_rate numeric(15,2),
    quantity numeric(25,5),
    price numeric(15,5),
    active_price_source text
);


ALTER TABLE public.shop_order_items OWNER TO kivitendo;

--
-- Name: shop_order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.shop_order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_order_items_id_seq OWNER TO kivitendo;

--
-- Name: shop_order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.shop_order_items_id_seq OWNED BY public.shop_order_items.id;


--
-- Name: shop_orders; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shop_orders (
    id integer NOT NULL,
    shop_trans_id integer NOT NULL,
    shop_ordernumber text,
    shop_customer_comment text,
    amount numeric(15,5),
    netamount numeric(15,5),
    order_date timestamp without time zone,
    shipping_costs numeric(15,5),
    shipping_costs_net numeric(15,5),
    shipping_costs_id integer,
    tax_included boolean,
    payment_id integer,
    payment_description text,
    shop_id integer,
    host text,
    remote_ip text,
    transferred boolean DEFAULT false,
    transfer_date date,
    kivi_customer_id integer,
    shop_customer_id integer,
    shop_customer_number text,
    customer_lastname text,
    customer_firstname text,
    customer_company text,
    customer_street text,
    customer_zipcode text,
    customer_city text,
    customer_country text,
    customer_greeting text,
    customer_department text,
    customer_vat text,
    customer_phone text,
    customer_fax text,
    customer_email text,
    customer_newsletter boolean,
    shop_c_billing_id integer,
    shop_c_billing_number text,
    billing_lastname text,
    billing_firstname text,
    billing_company text,
    billing_street text,
    billing_zipcode text,
    billing_city text,
    billing_country text,
    billing_greeting text,
    billing_department text,
    billing_vat text,
    billing_phone text,
    billing_fax text,
    billing_email text,
    sepa_account_holder text,
    sepa_iban text,
    sepa_bic text,
    shop_c_delivery_id integer,
    shop_c_delivery_number text,
    delivery_lastname text,
    delivery_firstname text,
    delivery_company text,
    delivery_street text,
    delivery_zipcode text,
    delivery_city text,
    delivery_country text,
    delivery_greeting text,
    delivery_department text,
    delivery_vat text,
    delivery_phone text,
    delivery_fax text,
    delivery_email text,
    obsolete boolean DEFAULT false NOT NULL,
    positions integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.shop_orders OWNER TO kivitendo;

--
-- Name: shop_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.shop_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_orders_id_seq OWNER TO kivitendo;

--
-- Name: shop_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.shop_orders_id_seq OWNED BY public.shop_orders.id;


--
-- Name: shop_parts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shop_parts (
    id integer NOT NULL,
    shop_id integer NOT NULL,
    part_id integer NOT NULL,
    shop_description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    last_update timestamp without time zone,
    show_date date,
    sortorder integer,
    front_page boolean DEFAULT false NOT NULL,
    active boolean DEFAULT false NOT NULL,
    shop_category text[],
    active_price_source text,
    metatag_keywords text,
    metatag_description text,
    metatag_title text
);


ALTER TABLE public.shop_parts OWNER TO kivitendo;

--
-- Name: shop_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.shop_parts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_parts_id_seq OWNER TO kivitendo;

--
-- Name: shop_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.shop_parts_id_seq OWNED BY public.shop_parts.id;


--
-- Name: shops; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.shops (
    id integer NOT NULL,
    description text,
    obsolete boolean DEFAULT false NOT NULL,
    sortkey integer,
    connector text,
    pricetype text,
    price_source text,
    taxzone_id integer,
    last_order_number integer,
    orders_to_fetch integer,
    server text,
    port integer,
    login text,
    password text,
    protocol text DEFAULT 'http'::text NOT NULL,
    path text DEFAULT '/'::text NOT NULL,
    realm text,
    transaction_description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.shops OWNER TO kivitendo;

--
-- Name: shops_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.shops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shops_id_seq OWNER TO kivitendo;

--
-- Name: shops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.shops_id_seq OWNED BY public.shops.id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.status (
    trans_id integer,
    formname text,
    printed boolean DEFAULT false,
    emailed boolean DEFAULT false,
    spoolfile text,
    chart_id integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    id integer NOT NULL
);


ALTER TABLE public.status OWNER TO kivitendo;

--
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_id_seq OWNER TO kivitendo;

--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.status_id_seq OWNED BY public.status.id;


--
-- Name: stocktakings; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.stocktakings (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    inventory_id integer,
    warehouse_id integer NOT NULL,
    bin_id integer NOT NULL,
    parts_id integer NOT NULL,
    employee_id integer NOT NULL,
    qty numeric(25,5) NOT NULL,
    comment text,
    chargenumber text DEFAULT ''::text NOT NULL,
    bestbefore date,
    cutoff_date date NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.stocktakings OWNER TO kivitendo;

--
-- Name: tax; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.tax (
    chart_id integer,
    rate numeric(15,5) DEFAULT 0 NOT NULL,
    taxnumber text,
    taxkey integer NOT NULL,
    taxdescription text NOT NULL,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    chart_categories text NOT NULL,
    skonto_sales_chart_id integer,
    skonto_purchase_chart_id integer
);


ALTER TABLE public.tax OWNER TO kivitendo;

--
-- Name: tax_zones; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.tax_zones (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    sortkey integer NOT NULL,
    obsolete boolean DEFAULT false
);


ALTER TABLE public.tax_zones OWNER TO kivitendo;

--
-- Name: taxkeys; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.taxkeys (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    chart_id integer NOT NULL,
    tax_id integer NOT NULL,
    taxkey_id integer NOT NULL,
    pos_ustva integer,
    startdate date NOT NULL
);


ALTER TABLE public.taxkeys OWNER TO kivitendo;

--
-- Name: taxzone_charts; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.taxzone_charts (
    id integer NOT NULL,
    taxzone_id integer NOT NULL,
    buchungsgruppen_id integer NOT NULL,
    income_accno_id integer NOT NULL,
    expense_accno_id integer NOT NULL,
    itime timestamp without time zone DEFAULT now()
);


ALTER TABLE public.taxzone_charts OWNER TO kivitendo;

--
-- Name: taxzone_charts_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.taxzone_charts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.taxzone_charts_id_seq OWNER TO kivitendo;

--
-- Name: taxzone_charts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.taxzone_charts_id_seq OWNED BY public.taxzone_charts.id;


--
-- Name: todo_user_config; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.todo_user_config (
    employee_id integer NOT NULL,
    show_after_login boolean DEFAULT true,
    show_follow_ups boolean DEFAULT true,
    show_follow_ups_login boolean DEFAULT true,
    show_overdue_sales_quotations boolean DEFAULT true,
    show_overdue_sales_quotations_login boolean DEFAULT true,
    id integer NOT NULL
);


ALTER TABLE public.todo_user_config OWNER TO kivitendo;

--
-- Name: todo_user_config_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.todo_user_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.todo_user_config_id_seq OWNER TO kivitendo;

--
-- Name: todo_user_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.todo_user_config_id_seq OWNED BY public.todo_user_config.id;


--
-- Name: transfer_type; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.transfer_type (
    id integer DEFAULT nextval('public.id'::regclass) NOT NULL,
    direction character varying(10) NOT NULL,
    description text,
    sortkey integer,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone
);


ALTER TABLE public.transfer_type OWNER TO kivitendo;

--
-- Name: translation; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.translation (
    parts_id integer,
    language_id integer,
    translation text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    longdescription text,
    id integer NOT NULL
);


ALTER TABLE public.translation OWNER TO kivitendo;

--
-- Name: translation_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.translation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.translation_id_seq OWNER TO kivitendo;

--
-- Name: translation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.translation_id_seq OWNED BY public.translation.id;


--
-- Name: trigger_information; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.trigger_information (
    id integer NOT NULL,
    key text NOT NULL,
    value text
);


ALTER TABLE public.trigger_information OWNER TO kivitendo;

--
-- Name: trigger_information_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.trigger_information_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trigger_information_id_seq OWNER TO kivitendo;

--
-- Name: trigger_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.trigger_information_id_seq OWNED BY public.trigger_information.id;


--
-- Name: units; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.units (
    name character varying(20) NOT NULL,
    base_unit character varying(20),
    factor numeric(20,5),
    type character varying(20),
    sortkey integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.units OWNER TO kivitendo;

--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.units_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.units_id_seq OWNER TO kivitendo;

--
-- Name: units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.units_id_seq OWNED BY public.units.id;


--
-- Name: units_language; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.units_language (
    unit character varying(20) NOT NULL,
    language_id integer NOT NULL,
    localized character varying(20),
    localized_plural character varying(20),
    id integer NOT NULL
);


ALTER TABLE public.units_language OWNER TO kivitendo;

--
-- Name: units_language_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.units_language_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.units_language_id_seq OWNER TO kivitendo;

--
-- Name: units_language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.units_language_id_seq OWNED BY public.units_language.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.user_preferences (
    id integer NOT NULL,
    login text NOT NULL,
    namespace text NOT NULL,
    version numeric(15,5),
    key text NOT NULL,
    value text
);


ALTER TABLE public.user_preferences OWNER TO kivitendo;

--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: kivitendo
--

CREATE SEQUENCE public.user_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_preferences_id_seq OWNER TO kivitendo;

--
-- Name: user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kivitendo
--

ALTER SEQUENCE public.user_preferences_id_seq OWNED BY public.user_preferences.id;


--
-- Name: vendor; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.vendor (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    name text NOT NULL,
    department_1 text,
    department_2 text,
    street text,
    zipcode text,
    city text,
    country text,
    contact text,
    phone text,
    fax text,
    homepage text,
    email text,
    notes text,
    taxincluded boolean,
    vendornumber text,
    cc text,
    bcc text,
    business_id integer,
    taxnumber text,
    discount real,
    creditlimit numeric(15,5),
    account_number text,
    bank_code text,
    bank text,
    language text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    obsolete boolean DEFAULT false,
    username text,
    user_password text,
    salesman_id integer,
    v_customer_id text,
    language_id integer,
    payment_id integer,
    taxzone_id integer NOT NULL,
    greeting text,
    ustid text,
    iban text,
    bic text,
    direct_debit boolean DEFAULT false,
    depositor text,
    delivery_term_id integer,
    currency_id integer NOT NULL,
    gln text
);


ALTER TABLE public.vendor OWNER TO kivitendo;

--
-- Name: warehouse; Type: TABLE; Schema: public; Owner: kivitendo
--

CREATE TABLE public.warehouse (
    id integer DEFAULT nextval(('id'::text)::regclass) NOT NULL,
    description text,
    itime timestamp without time zone DEFAULT now(),
    mtime timestamp without time zone,
    sortkey integer,
    invalid boolean
);


ALTER TABLE public.warehouse OWNER TO kivitendo;

--
-- Name: report_categories; Type: TABLE; Schema: tax; Owner: kivitendo
--

CREATE TABLE tax.report_categories (
    id integer NOT NULL,
    description text,
    subdescription text
);


ALTER TABLE tax.report_categories OWNER TO kivitendo;

--
-- Name: report_headings; Type: TABLE; Schema: tax; Owner: kivitendo
--

CREATE TABLE tax.report_headings (
    id integer NOT NULL,
    category_id integer NOT NULL,
    type text,
    description text,
    subdescription text
);


ALTER TABLE tax.report_headings OWNER TO kivitendo;

--
-- Name: report_variables; Type: TABLE; Schema: tax; Owner: kivitendo
--

CREATE TABLE tax.report_variables (
    id integer NOT NULL,
    "position" text NOT NULL,
    heading_id integer,
    description text,
    taxbase text,
    dec_places text,
    valid_from date
);


ALTER TABLE tax.report_variables OWNER TO kivitendo;

--
-- Name: background_job_histories id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.background_job_histories ALTER COLUMN id SET DEFAULT nextval('public.background_job_histories_id_seq'::regclass);


--
-- Name: background_jobs id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.background_jobs ALTER COLUMN id SET DEFAULT nextval('public.background_jobs_id_seq'::regclass);


--
-- Name: bank_transactions id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transactions ALTER COLUMN id SET DEFAULT nextval('public.bank_transactions_id_seq'::regclass);


--
-- Name: csv_import_profile_settings id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profile_settings ALTER COLUMN id SET DEFAULT nextval('public.csv_import_profile_settings_id_seq'::regclass);


--
-- Name: csv_import_profiles id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profiles ALTER COLUMN id SET DEFAULT nextval('public.csv_import_profiles_id_seq'::regclass);


--
-- Name: csv_import_report_rows id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_rows ALTER COLUMN id SET DEFAULT nextval('public.csv_import_report_rows_id_seq'::regclass);


--
-- Name: csv_import_report_status id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_status ALTER COLUMN id SET DEFAULT nextval('public.csv_import_report_status_id_seq'::regclass);


--
-- Name: csv_import_reports id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_reports ALTER COLUMN id SET DEFAULT nextval('public.csv_import_reports_id_seq'::regclass);


--
-- Name: currencies id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.currencies ALTER COLUMN id SET DEFAULT nextval('public.currencies_id_seq'::regclass);


--
-- Name: custom_data_export_queries id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_data_export_queries ALTER COLUMN id SET DEFAULT nextval('public.custom_data_export_queries_id_seq'::regclass);


--
-- Name: custom_data_export_query_parameters id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_data_export_query_parameters ALTER COLUMN id SET DEFAULT nextval('public.custom_data_export_query_parameters_id_seq'::regclass);


--
-- Name: datev id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.datev ALTER COLUMN id SET DEFAULT nextval('public.datev_id_seq'::regclass);


--
-- Name: defaults id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults ALTER COLUMN id SET DEFAULT nextval('public.defaults_id_seq'::regclass);


--
-- Name: email_journal id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal ALTER COLUMN id SET DEFAULT nextval('public.email_journal_id_seq'::regclass);


--
-- Name: email_journal_attachments id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal_attachments ALTER COLUMN id SET DEFAULT nextval('public.email_journal_attachments_id_seq'::regclass);


--
-- Name: exchangerate id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.exchangerate ALTER COLUMN id SET DEFAULT nextval('public.exchangerate_id_seq'::regclass);


--
-- Name: files id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.files ALTER COLUMN id SET DEFAULT nextval('public.files_id_seq'::regclass);


--
-- Name: finanzamt id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.finanzamt ALTER COLUMN id SET DEFAULT nextval('public.finanzamt_id_seq'::regclass);


--
-- Name: follow_up_access id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_access ALTER COLUMN id SET DEFAULT nextval('public.follow_up_access_id_seq'::regclass);


--
-- Name: generic_translations id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.generic_translations ALTER COLUMN id SET DEFAULT nextval('public.generic_translations_id_seq'::regclass);


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: part_classifications id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_classifications ALTER COLUMN id SET DEFAULT nextval('public.part_classifications_id_seq'::regclass);


--
-- Name: part_customer_prices id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_customer_prices ALTER COLUMN id SET DEFAULT nextval('public.part_customer_prices_id_seq'::regclass);


--
-- Name: parts_price_history id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts_price_history ALTER COLUMN id SET DEFAULT nextval('public.parts_price_history_id_seq'::regclass);


--
-- Name: price_rule_items id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rule_items ALTER COLUMN id SET DEFAULT nextval('public.price_rule_items_id_seq'::regclass);


--
-- Name: price_rules id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rules ALTER COLUMN id SET DEFAULT nextval('public.price_rules_id_seq'::regclass);


--
-- Name: prices id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.prices ALTER COLUMN id SET DEFAULT nextval('public.prices_id_seq'::regclass);


--
-- Name: project_participants id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_participants ALTER COLUMN id SET DEFAULT nextval('public.project_participants_id_seq'::regclass);


--
-- Name: project_phase_participants id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phase_participants ALTER COLUMN id SET DEFAULT nextval('public.project_phase_participants_id_seq'::regclass);


--
-- Name: project_phases id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phases ALTER COLUMN id SET DEFAULT nextval('public.project_phases_id_seq'::regclass);


--
-- Name: project_roles id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_roles ALTER COLUMN id SET DEFAULT nextval('public.project_roles_id_seq'::regclass);


--
-- Name: project_statuses id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_statuses ALTER COLUMN id SET DEFAULT nextval('public.project_status_id_seq'::regclass);


--
-- Name: project_types id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_types ALTER COLUMN id SET DEFAULT nextval('public.project_types_id_seq'::regclass);


--
-- Name: record_links id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_links ALTER COLUMN id SET DEFAULT nextval('public.record_links_id_seq'::regclass);


--
-- Name: record_template_items id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items ALTER COLUMN id SET DEFAULT nextval('public.record_template_items_id_seq'::regclass);


--
-- Name: record_templates id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates ALTER COLUMN id SET DEFAULT nextval('public.record_templates_id_seq'::regclass);


--
-- Name: requirement_spec_acceptance_statuses id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_acceptance_statuses ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_acceptance_statuses_id_seq'::regclass);


--
-- Name: requirement_spec_complexities id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_complexities ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_complexities_id_seq'::regclass);


--
-- Name: requirement_spec_items id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_items_id_seq'::regclass);


--
-- Name: requirement_spec_orders id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_orders_id_seq'::regclass);


--
-- Name: requirement_spec_parts id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_parts ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_parts_id_seq'::regclass);


--
-- Name: requirement_spec_pictures id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_pictures ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_pictures_id_seq'::regclass);


--
-- Name: requirement_spec_predefined_texts id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_predefined_texts ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_predefined_texts_id_seq'::regclass);


--
-- Name: requirement_spec_risks id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_risks ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_risks_id_seq'::regclass);


--
-- Name: requirement_spec_statuses id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_statuses ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_statuses_id_seq'::regclass);


--
-- Name: requirement_spec_text_blocks id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_text_blocks ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_text_blocks_id_seq'::regclass);


--
-- Name: requirement_spec_types id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_types ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_types_id_seq'::regclass);


--
-- Name: requirement_spec_versions id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_versions ALTER COLUMN id SET DEFAULT nextval('public.requirement_spec_versions_id_seq'::regclass);


--
-- Name: requirement_specs id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs ALTER COLUMN id SET DEFAULT nextval('public.requirement_specs_id_seq'::regclass);


--
-- Name: sepa_export_message_ids id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_message_ids ALTER COLUMN id SET DEFAULT nextval('public.sepa_export_message_ids_id_seq'::regclass);


--
-- Name: shop_images id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_images ALTER COLUMN id SET DEFAULT nextval('public.shop_images_id_seq'::regclass);


--
-- Name: shop_order_items id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_order_items ALTER COLUMN id SET DEFAULT nextval('public.shop_order_items_id_seq'::regclass);


--
-- Name: shop_orders id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_orders ALTER COLUMN id SET DEFAULT nextval('public.shop_orders_id_seq'::regclass);


--
-- Name: shop_parts id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_parts ALTER COLUMN id SET DEFAULT nextval('public.shop_parts_id_seq'::regclass);


--
-- Name: shops id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shops ALTER COLUMN id SET DEFAULT nextval('public.shops_id_seq'::regclass);


--
-- Name: status id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.status ALTER COLUMN id SET DEFAULT nextval('public.status_id_seq'::regclass);


--
-- Name: taxzone_charts id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts ALTER COLUMN id SET DEFAULT nextval('public.taxzone_charts_id_seq'::regclass);


--
-- Name: todo_user_config id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.todo_user_config ALTER COLUMN id SET DEFAULT nextval('public.todo_user_config_id_seq'::regclass);


--
-- Name: translation id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.translation ALTER COLUMN id SET DEFAULT nextval('public.translation_id_seq'::regclass);


--
-- Name: trigger_information id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.trigger_information ALTER COLUMN id SET DEFAULT nextval('public.trigger_information_id_seq'::regclass);


--
-- Name: units id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units ALTER COLUMN id SET DEFAULT nextval('public.units_id_seq'::regclass);


--
-- Name: units_language id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units_language ALTER COLUMN id SET DEFAULT nextval('public.units_language_id_seq'::regclass);


--
-- Name: user_preferences id; Type: DEFAULT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.user_preferences ALTER COLUMN id SET DEFAULT nextval('public.user_preferences_id_seq'::regclass);


--
-- Data for Name: acc_trans; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.acc_trans (acc_trans_id, trans_id, chart_id, amount, transdate, gldate, source, cleared, fx_transaction, ob_transaction, cb_transaction, project_id, memo, taxkey, itime, mtime, chart_link, tax_id) FROM stdin;
2	1	5	-1000.00000	2019-10-15	2019-10-15		f	f	f	f	\N		0	2019-10-15 11:50:50.874659	\N	AR_paid:AP_paid	0
3	1	69	1000.00000	2019-10-15	2019-10-15		f	f	f	f	\N		0	2019-10-15 11:50:50.874659	\N		0
4	2	9	-150.00000	2019-10-15	2019-10-15	\N	f	f	f	f	\N	\N	0	2019-10-15 11:52:10.264198	\N	AR	0
5	2	74	150.00000	2019-10-15	2019-10-15	\N	f	f	f	f	\N	\N	0	2019-10-15 11:52:10.264198	\N	AR_amount:IC_sale	0
\.


--
-- Data for Name: ap; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.ap (id, invnumber, transdate, gldate, vendor_id, taxincluded, amount, netamount, paid, datepaid, duedate, invoice, ordnumber, notes, employee_id, quonumber, intnotes, department_id, itime, mtime, shipvia, cp_id, language_id, payment_id, storno, taxzone_id, type, orddate, quodate, globalproject_id, storno_id, transaction_description, direct_debit, deliverydate, delivery_term_id, currency_id) FROM stdin;
\.


--
-- Data for Name: ar; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.ar (id, invnumber, transdate, gldate, customer_id, taxincluded, amount, netamount, paid, datepaid, duedate, deliverydate, invoice, shippingpoint, notes, ordnumber, employee_id, quonumber, cusordnumber, intnotes, department_id, shipvia, itime, mtime, cp_id, language_id, payment_id, delivery_customer_id, delivery_vendor_id, storno, taxzone_id, shipto_id, type, dunning_config_id, orddate, quodate, globalproject_id, salesman_id, marge_total, marge_percent, storno_id, transaction_description, donumber, invnumber_for_credit_note, direct_debit, delivery_term_id, currency_id) FROM stdin;
2	1	2019-10-15	2019-10-15	410	f	150.00000	150.00000	0.00000	\N	2019-10-15	\N	t				409				\N		2019-10-15 11:52:10.264198	2019-10-15 11:52:10.264198	\N	\N	\N	\N	\N	f	4	\N	invoice	\N	\N	\N	\N	409	0.00000	0.00000	\N	Support		\N	f	\N	1
\.


--
-- Data for Name: assembly; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.assembly (id, parts_id, qty, bom, itime, mtime, assembly_id, "position") FROM stdin;
\.


--
-- Data for Name: assortment_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.assortment_items (assortment_id, parts_id, itime, mtime, qty, "position", unit, charge) FROM stdin;
\.


--
-- Data for Name: background_job_histories; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.background_job_histories (id, package_name, run_at, status, result, error, data) FROM stdin;
\.


--
-- Data for Name: background_jobs; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.background_jobs (id, type, package_name, last_run_at, next_run_at, data, active, cron_spec) FROM stdin;
1	interval	CleanBackgroundJobHistory	\N	2019-10-16 03:00:00	\N	t	0 3 * * *
3	interval	BackgroundJobCleanup	\N	2019-10-16 03:00:00	\N	t	0 3 * * *
4	interval	SelfTest	\N	2019-10-16 02:20:00	\N	t	20 2 * * *
2	interval	CreatePeriodicInvoices	\N	2019-10-16 03:00:00	\N	t	0 3 * * *
5	interval	CleanAuthSessions	\N	2019-10-16 06:30:00	\N	t	30 6 * * *
\.


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.bank_accounts (id, account_number, bank_code, iban, bic, bank, chart_id, name, reconciliation_starting_date, reconciliation_starting_balance, obsolete, sortkey) FROM stdin;
\.


--
-- Data for Name: bank_transaction_acc_trans; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.bank_transaction_acc_trans (id, bank_transaction_id, acc_trans_id, ar_id, ap_id, gl_id, itime, mtime) FROM stdin;
\.


--
-- Data for Name: bank_transactions; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.bank_transactions (id, transaction_id, remote_bank_code, remote_account_number, transdate, valutadate, amount, remote_name, purpose, invoice_amount, local_bank_account_id, currency_id, cleared, itime, transaction_code, transaction_text) FROM stdin;
\.


--
-- Data for Name: bin; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.bin (id, warehouse_id, description, itime, mtime) FROM stdin;
\.


--
-- Data for Name: buchungsgruppen; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.buchungsgruppen (id, description, inventory_accno_id, sortkey) FROM stdin;
192	Standard	16	1
\.


--
-- Data for Name: business; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.business (id, description, discount, customernumberinit, salesman, itime, mtime) FROM stdin;
\.


--
-- Data for Name: chart; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.chart (id, accno, description, charttype, category, link, taxkey_id, pos_bwa, pos_bilanz, pos_eur, datevautomatik, itime, mtime, new_chart_id, valid_from, pos_er) FROM stdin;
19	1290	Angefangene Arbeiten	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
20	130	Aktive Rechnungsabgrenzungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
21	1300	Aktive Rechnungsabgrenzungen	A	A		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
22	14	ANLAGEVERMÖGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
23	140	Finanzanlagen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
24	148	Beteiligungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
25	150	Mobile Sachanlagen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
26	1500	Maschinen und Apparate	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
27	1510	Mobiliar und Einrichtungen	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
28	1520	Büromaschinen, Informatik	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
29	1530	Fahrzeuge	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
30	1540	Werkzeuge und Geräte	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
31	160	Immobile Sachanlagen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
32	170	Immaterielle Werte	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
33	180	Nicht einbezahltes Grund- Gesellschafter- oder Stiftungskapital	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
34	2	PASSIVEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
35	20	KURZFRISTIGES FREMDKAPITAL	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
36	200	Verbindlichkeiten aus Lieferungen und Leistungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
37	2000	Verbindlichkeiten aus Lieferungen und Leistungen	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
38	2001	Übrige Kreditoren	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
39	2030	Anzahlungen von Kundinnen und Kunden	A	L	AR_paid:AP_paid	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
40	210	Kurzfristige verzinsliche Verbindlichkeiten	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
41	2100	Bankverbindlichkeiten	A	L	AR_paid:AP_paid	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
42	2140	Übrige verzinsliche Verbindlichkeiten	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
43	220	Übrige kurzfristige Verbindlichkeiten	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
44	2200	Geschuldete MWST(2,5)	A	L	AR_tax:IC_taxpart:IC_taxservice	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
45	2201	Geschuldete MWST(8,0)	A	L	AR_tax:IC_taxpart:IC_taxservice	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
46	2206	Verrechnungssteuer	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
47	2210	Geschuldete Steuern	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
48	2250	Personalaufwand	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
49	2270	Verbindlichkeiten Sozialversicherungen und Vorsorgeeinrichtungen	A	L	AP	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
50	230	Passive Rechnungsabgrenzungen und kurzfristige Rückstellungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
51	2300	Passive Rechnungsabgrenzungen	A	L		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
52	2330	Kurzfristige Rückstellungen	A	L		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
53	24	LANGFRISTIGES FREMDKAPITAL	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
54	240	Langfristige verzinsliche Verbindlichkeiten	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
55	2400	Bankverbindlichkeiten	A	L		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
56	2450	Langfristige verzinsliche Darlehen	A	L		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
57	250	Übrige langfristige Verbindlichkeiten	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
58	2500	Zinslose Darlehen	A	L		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
59	260	Rückstellungen sowie vom Gesetz vorgesehene ähnliche Positionen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
60	28	EIGENKAPITAL	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
61	280	Grund-, Gesellschafter- oder Stiftungskapital	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
62	2800	Stammkapital	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
63	290	Reserven, Jahresgewinn oder Jahresverlust	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
64	2900	Gesetzliche Kapitalreserve	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
65	2950	Gesetzliche Gewinnreserve	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
66	2960	Freiwillige Gewinnreserve	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
67	2970	Gewinn- oder Verlustvortrag	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
68	2979	Jahresgewinn oder -verlust	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
69	2980	Eigene Kapitalanteile	A	Q		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
70	3	BETRIEBLICHER ERTRAG AUS LIEFERUNGEN UND LEISTUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
71	30	PRODUKTIONSERLÖSE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
72	3000	Produktionserlöse	A	I	AR_amount:IC_sale	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
73	32	HANDELSERLÖSE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
74	3200	Handelserlöse	A	I	AR_amount:IC_sale	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
75	34	DIENSTLEISTUNGSERLÖSE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
76	3400	Dienstleistungserlöse	A	I	AR_amount:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
77	36	ÜBRIGE ERLÖSE AUS LIEFERUNGEN UND LEISTUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
78	3600	Übrige Erlöse aus Lieferungen und Leistungen	A	I	IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
79	37	EIGENLEISTUNGEN UND EIGENVERBRAUCH	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
80	3700	Eigenleistungen	A	I		0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
81	38	ERLÖSMINDERUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
82	3800	Skonti	A	E	AR_paid	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
83	3801	Rabatte, Preisnachlässe	A	E	AR_paid	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
84	3805	Verluste aus Forderungen	A	E	AR_paid	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
85	3809	MWST - nur Saldosteuersatz	A	E	AR_paid	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
86	39	BESTANDESÄNDERUNGEN AN UNFERTIGEN UND FERTIGEN ERZEUGNISSEN SOWIE AN NICHT FAKTURIERTEN DIENSTLEISTUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
87	3900	Bestandesänderungen	A	I		0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
88	4	AUFWAND FÜR MATERIAL, HANDELSWAREN, DIENSTLEISTUNGEN UND ENERGIE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
89	40	MATERIALAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
90	4000	Materialeinkauf	A	E	AP_amount:IC_cogs	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
91	42	HANDELSWARENAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
92	4200	Einkauf Handelswaren	A	E	AP_amount:IC_cogs	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
93	4208	Bestandsänderungen Handelswaren	A	E	AP_amount:IC_cogs	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
94	44	AUFWAND FÜR BEZOGENE DRITTLEISTUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
95	4400	Aufwand für Drittleistungen	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
96	45	ENERGIEAUFWAND ZUR LEISTUNGSERSTELLUNG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
97	4500	Energieaufwand zur Leistungserstellung	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
98	46	ÜBRIGER AUFWAND FÜR MATERIAL, HANDELSWAREN UND DIENSTLEISTUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
99	47	DIREKTE EINKAUFSSPESEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
100	4700	Einkaufsspesen	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
101	48	BESTANDESÄNDERUNGEN UND MATERIAL-/WARENVERLUSTE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
102	4800	Bestandesänderungen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
103	49	EINKAUFSPREISMINDERUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
104	4900	Skonti, Rabatte, Preisnachlässe	A	I	AP_paid	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
105	5	PERSONALAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
106	500	Löhne und Gehälter	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
107	5000	Löhne und Gehälter	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
108	5001	Erfolgsbeteiligungen	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
109	5005	Leistungen von Sozialversicherungen	A	I	IC_income	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
110	57	SOZIALVERSICHERUNGSAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
111	5700	AHV, IV, EO, ALV	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
112	5710	FAK	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
113	5720	Berufliche Vorsorge	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
114	5730	Unfallversicherung	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
115	5740	Krankentaggeldversicherung	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
116	5790	Quellensteuer	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
117	58	ÜBRIGER PERSONALAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
118	5800	Aufwand für Personaleinstellung	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
119	5810	Weiterbildungskosten	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
120	5830	Spesen	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
121	5880	Sonstiger Personalaufwand	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
122	59	LEISTUNGEN DRITTER	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
123	6	ÜBRIGER BETRIEBLICHER AUFWAND, ABSCHREIBUNGEN UND WERTBERICHTIGUNGEN SOWIE FINANZERGEBNIS	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
124	60	RAUMAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
125	6000	Miete	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
126	6040	Reinigung	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
127	6050	Übriger Raumaufwand	A	E	IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
128	61	UNTERHALT, REPARATUREN, ERSATZ, LEASING, MOBILE SACHANLAGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
129	6100	Unterhalt	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
130	62	FAHRZEUG- UND TRANSPORTAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
131	6200	Fahrzeugaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
132	6201	Transportaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
133	63	SACHVERSICHERUNGEN, ABGABEN, GEBÜHREN, BEWILLIGUNGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
134	6300	Betriebsversicherungen	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
135	6360	Abgaben, Gebühren und Bewilligungen	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
136	64	ENERGIE- UND ENTSORGUNGSAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
137	6400	Strom, Gas, Wasser	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
138	6460	Entsorgungsaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
139	65	VERWALTUNGS- UND INFORMATIKAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
140	6500	Büromaterial, Drucksachen	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
141	6503	Fachliteratur	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
142	6510	Telefon, Fax, Porti Internet	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
143	6520	Beiträge, Spenden	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
144	6530	Buchführungs- und Beratungsaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
145	6540	Verwaltungsrat, GV, Revision	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
146	6570	Informatikaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
147	6590	Übriger Verwaltungsaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
148	66	WERBEAUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
173	8	BETRIEBSFREMDER, AUSSERORDENTLICHER, EINMALIGER UND PERIODENFREMDER AUFWAND UND ERTRAG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
174	80	BETRIEBSFREMDER AUFWAND UND BETRIEBSFREMDER ERTRAG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
1	1	AKTIVEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
2	10	UMLAUFSVERMÖGEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
3	100	Flüssige Mittel	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
4	1000	Kasse	A	A	AR_paid:AP_paid	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
5	1020	Postfinance oder Bank1	A	A	AR_paid:AP_paid	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
6	1021	Bank2	A	A	AR_paid:AP_paid	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
7	106	Kurzfristig gehaltene Aktiven mit Börsenkurs	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
8	110	Forderungen aus Lieferungen und Leistungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
9	1100	Forderungen aus Lieferungen und Leistungen	A	A	AR	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
10	114	Übrige kurzfristige Forderungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
11	1140	Vorschüsse, kurzfristige Darlehen	A	A	AR	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
12	1170	Vorsteuer auf Aufwand	A	A	AP_tax:IC_taxpart:IC_taxservice	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
13	1171	Vorsteuer auf Investitionen	A	A	AP_tax:IC_taxpart:IC_taxservice	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
14	1176	Verrechnungssteuer	A	A		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
15	120	Vorräte und nicht fakturierte Dienstleistungen	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
16	1200	Handelswaren	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
17	1210	Rohstoffe	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
18	1280	Nicht fakturierte Dienstleistungen	A	A	IC	0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
175	8000	Betriebsfremder Aufwand	A	E	AP_amount:IC_cogs:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
176	8100	Betriebsfremder Ertrag	A	I	AR_amount:IC_sale:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
177	85	AUSSERORDENTLICHER, EINMALIGER AUFWAND UND ERTRAG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
178	8500	Ausserordentlicher Aufwand	A	E	AP_amount:IC_cogs:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
179	8510	Ausserordentlicher Ertrag	A	I	AR_amount:IC_sale:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
180	87	PERIODENFREMDER AUFWAND UND ERTRAG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
181	8700	Periodenfremder Aufwand	A	E	AP_amount:IC_cogs:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
182	8710	Periodenfremder Ertrag	A	I	AR_amount:IC_sale:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
183	89	DIREKTE STEUERN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
184	8900	Direkte Steuern	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
185	9	ABSCHLUSS	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
186	90	ERFOLGSRECHNUNG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
187	91	BILANZ	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
188	9100	Eröffnungsbilanz	A	E		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
189	92	GEWINNVERWENDUNG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
190	95	JAHRESERGEBNISSE	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
191	99	HILFSKONTEN NEBENBÜCHER	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
149	6600	Werbeaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
150	67	SONSTIGER BETRIEBLICHER AUFWAND	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
151	6720	Forschung und Entwicklung	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
152	6790	Übriger Betriebsaufwand	A	E	AP_amount:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
153	68	ABSCHREIBUNGEN UND WERTBERICHTIGUNGEN AUF POSITIONEN DES ANLAGEVERMÖGENS	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
154	6800	Abschreibungen Finanzanlagen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
155	6810	Abschreibungen Beteiligungen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
156	6820	Abschreibungen mobile Sachanlagen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
157	6840	Abschreibungen immaterielle Anlagen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
158	69	FINANZAUFWAND UND FINANZERTRAG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
159	690	Finanzaufwand	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
160	6900	Finanzaufwand	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
161	6940	Bankspesen	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
162	6942	Kursverluste	A	E		0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
163	6943	Rundungsaufwand	A	E	AP_amount:IC_cogs:IC_expense	0	\N	\N	6	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	6
164	695	Finanzertrag	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
165	6950	Finanzertrag	A	I		0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
166	6952	Kursgewinne	A	I		0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
167	6953	Rundungsertrag	A	I	AR_amount:IC_sale:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
168	6970	Mitgliederbeiträge	A	I	AR_amount:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
169	6980	Spenden	A	I	AR_amount:IC_income	0	\N	\N	1	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	1
170	7	BETRIEBLICHER NEBENERFOLG	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
171	70	ERFOLG AUS NEBENBETRIEBEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
172	75	ERFOLG AUS BETRIEBLICHEN LIEGENSCHAFTEN	H	 		0	\N	\N	\N	f	2019-10-15 11:37:00.716536	2019-10-15 11:37:11.19297	\N	2011-01-01	\N
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.contacts (cp_id, cp_cv_id, cp_title, cp_givenname, cp_name, cp_email, cp_phone1, cp_phone2, itime, mtime, cp_fax, cp_mobile1, cp_mobile2, cp_satphone, cp_satfax, cp_project, cp_privatphone, cp_privatemail, cp_abteilung, cp_gender, cp_street, cp_zipcode, cp_city, cp_birthday, cp_position, cp_main) FROM stdin;
\.


--
-- Data for Name: csv_import_profile_settings; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.csv_import_profile_settings (id, csv_import_profile_id, key, value) FROM stdin;
1	1	charset	UTF-8
2	1	full_preview	0
3	1	update_policy	skip
4	1	numberformat	1000.00
5	1	sep_char	;
6	1	quote_char	"
7	1	escape_char	"
8	1	json_mappings	[]
9	1	duplicates	no_check
10	1	dont_edit_profile	1
\.


--
-- Data for Name: csv_import_profiles; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.csv_import_profiles (id, name, type, is_default, login) FROM stdin;
1	MT940	bank_transactions	t	default
\.


--
-- Data for Name: csv_import_report_rows; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.csv_import_report_rows (id, csv_import_report_id, col, "row", value) FROM stdin;
\.


--
-- Data for Name: csv_import_report_status; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.csv_import_report_status (id, csv_import_report_id, "row", type, value) FROM stdin;
\.


--
-- Data for Name: csv_import_reports; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.csv_import_reports (id, session_id, profile_id, type, file, numrows, numheaders, test_mode) FROM stdin;
\.


--
-- Data for Name: currencies; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.currencies (id, name) FROM stdin;
1	CHF
\.


--
-- Data for Name: custom_data_export_queries; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_data_export_queries (id, name, description, sql_query, access_right, itime, mtime) FROM stdin;
\.


--
-- Data for Name: custom_data_export_query_parameters; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_data_export_query_parameters (id, query_id, name, description, parameter_type, itime, mtime, default_value_type, default_value) FROM stdin;
\.


--
-- Data for Name: custom_variable_config_partsgroups; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_variable_config_partsgroups (custom_variable_config_id, partsgroup_id, itime, mtime) FROM stdin;
\.


--
-- Data for Name: custom_variable_configs; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_variable_configs (id, name, description, type, module, default_value, options, searchable, includeable, included_by_default, sortkey, itime, mtime, flags) FROM stdin;
\.


--
-- Data for Name: custom_variables; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_variables (id, config_id, trans_id, bool_value, timestamp_value, text_value, number_value, itime, mtime, sub_module) FROM stdin;
\.


--
-- Data for Name: custom_variables_validity; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.custom_variables_validity (id, config_id, trans_id, itime) FROM stdin;
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.customer (id, name, department_1, department_2, street, zipcode, city, country, contact, phone, fax, homepage, email, notes, discount, taxincluded, creditlimit, customernumber, cc, bcc, business_id, taxnumber, account_number, bank_code, bank, language, itime, mtime, obsolete, username, user_password, salesman_id, c_vendor_id, language_id, payment_id, taxzone_id, greeting, ustid, iban, bic, direct_debit, depositor, taxincluded_checked, mandator_id, mandate_date_of_signature, delivery_term_id, hourly_rate, currency_id, gln, pricegroup_id, order_lock, commercial_court, invoice_mail, contact_origin, delivery_order_mail) FROM stdin;
410	Orbital			Orbitalstrasse 5	7890	KSP Space Center	Kerbin							0	\N	0.00000	1			\N					\N	2019-10-15 11:48:33.077443	\N	f			\N		\N	\N	4	Prof. Dr.				f		\N		\N	\N	100.00	1		\N	f				
\.


--
-- Data for Name: datev; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.datev (beraternr, beratername, mandantennr, dfvkz, datentraegernr, abrechnungsnr, itime, mtime, id) FROM stdin;
\.


--
-- Data for Name: defaults; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.defaults (inventory_accno_id, income_accno_id, expense_accno_id, fxgain_accno_id, fxloss_accno_id, invnumber, sonumber, weightunit, businessnumber, version, closedto, revtrans, ponumber, sqnumber, rfqnumber, customernumber, vendornumber, articlenumber, servicenumber, coa, itime, mtime, rmanumber, cnnumber, accounting_method, inventory_system, profit_determination, dunning_ar_amount_fee, dunning_ar_amount_interest, dunning_ar, stocktaking_warehouse_id, stocktaking_bin_id, stocktaking_cutoff_date, pdonumber, sdonumber, stocktaking_qty_threshold, ar_paid_accno_id, id, language_id, datev_check_on_sales_invoice, datev_check_on_purchase_invoice, datev_check_on_ar_transaction, datev_check_on_ap_transaction, datev_check_on_gl_transaction, payments_changeable, is_changeable, ir_changeable, ar_changeable, ap_changeable, gl_changeable, show_bestbefore, sales_order_show_delete, purchase_order_show_delete, sales_delivery_order_show_delete, purchase_delivery_order_show_delete, is_show_mark_as_paid, ir_show_mark_as_paid, ar_show_mark_as_paid, ap_show_mark_as_paid, warehouse_id, bin_id, company, address, taxnumber, co_ustid, duns, sepa_creditor_id, templates, max_future_booking_interval, "precision", webdav, webdav_documents, vertreter, parts_show_image, parts_listing_image, parts_image_css, normalize_vc_names, normalize_part_descriptions, assemblynumber, show_weight, transfer_default, transfer_default_use_master_default_bin, transfer_default_ignore_onhand, warehouse_id_ignore_onhand, bin_id_ignore_onhand, balance_startdate_method, currency_id, customer_hourly_rate, signature, requirement_spec_section_order_part_id, transfer_default_services, rndgain_accno_id, rndloss_accno_id, global_bcc, customer_projects_only_in_sales, reqdate_interval, require_transaction_description_ps, sales_purchase_order_ship_missing_column, allow_sales_invoice_from_sales_quotation, allow_sales_invoice_from_sales_order, allow_new_purchase_delivery_order, allow_new_purchase_invoice, disabled_price_sources, bcc_to_login, transport_cost_reminder_article_number_id, is_transfer_out, ap_chart_id, ar_chart_id, create_part_if_not_found, letternumber, order_always_project, project_status_id, project_type_id, feature_balance, feature_datev, feature_erfolgsrechnung, feature_eurechnung, feature_ustva, order_warn_duplicate_parts, show_longdescription_select_item, email_journal, quick_search_modules, transfer_default_warehouse_for_assembly, feature_experimental_order, fa_bufa_nr, fa_dauerfrist, fa_steuerberater_city, fa_steuerberater_name, fa_steuerberater_street, fa_steuerberater_tel, fa_voranmeld, doc_delete_printfiles, doc_max_filesize, doc_storage, doc_storage_for_documents, doc_storage_for_attachments, doc_storage_for_images, doc_files, doc_files_rootpath, doc_webdav, shipped_qty_require_stock_out, shipped_qty_fill_up, shipped_qty_item_identity_fields, sepa_reference_add_vc_vc_id, assortmentnumber, feature_experimental_assortment, doc_storage_for_shopimages, datev_export_format, order_warn_no_deliverydate, sepa_set_duedate_as_default_exec_date, sepa_set_skonto_date_as_default_exec_date, sepa_set_skonto_date_buffer_in_days, delivery_date_interval, email_attachment_vc_files_checked, email_attachment_part_files_checked, email_attachment_record_files_checked, invoice_mail_settings, dunning_creator) FROM stdin;
16	74	92	166	162	1	0	kg		3.1.0 CH	\N	f	0	0	0	1	0	0	0	Switzerland-deutsch-ohneMWST-2014	2019-10-15 11:37:00.716536	\N	0	0	cash	periodic	income	\N	\N	\N	\N	\N	\N	0	0	0.00000	\N	1	\N	t	t	t	t	t	0	2	2	2	2	2	f	t	t	t	t	t	t	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	360	0.05000	f	f	f	t	f	border:0;float:left;max-width:250px;margin-top:20px:margin-right:10px;margin-left:10px;	t	t	\N	f	t	f	f	\N	\N	closedto	1	100.00	\N	\N	t	167	163		f	0	f	f	t	t	t	t	\N	f	\N	f	\N	\N	t	\N	f	\N	\N	t	t	f	t	t	t	f	2	{contact,gl_transaction}	f	t	\N	\N	\N	\N	\N	\N	\N	f	10000000	f	Filesystem	Filesystem	Filesystem	f	./documents	f	f	t	{parts_id}	f	\N	t	Filesystem	cp1252-translit	t	f	f	0	0	t	t	t	cp	current_employee
\.


--
-- Data for Name: delivery_order_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.delivery_order_items (id, delivery_order_id, parts_id, description, qty, sellprice, discount, project_id, reqdate, serialnumber, ordnumber, transdate, cusordnumber, unit, base_qty, longdescription, lastcost, price_factor_id, price_factor, marge_price_factor, itime, mtime, pricegroup_id, "position", active_price_source, active_discount_source) FROM stdin;
\.


--
-- Data for Name: delivery_order_items_stock; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.delivery_order_items_stock (id, delivery_order_item_id, qty, unit, warehouse_id, bin_id, chargenumber, itime, mtime, bestbefore) FROM stdin;
\.


--
-- Data for Name: delivery_orders; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.delivery_orders (id, donumber, ordnumber, transdate, vendor_id, customer_id, reqdate, shippingpoint, notes, intnotes, employee_id, closed, delivered, cusordnumber, oreqnumber, department_id, shipvia, cp_id, language_id, shipto_id, globalproject_id, salesman_id, transaction_description, is_sales, itime, mtime, taxzone_id, taxincluded, delivery_term_id, currency_id, payment_id) FROM stdin;
\.


--
-- Data for Name: delivery_terms; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.delivery_terms (id, description, description_long, sortkey, itime, mtime) FROM stdin;
\.


--
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.department (id, description, itime, mtime) FROM stdin;
\.


--
-- Data for Name: drafts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.drafts (id, module, submodule, description, itime, form, employee_id) FROM stdin;
\.


--
-- Data for Name: dunning; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.dunning (id, trans_id, dunning_id, dunning_level, transdate, duedate, fee, interest, dunning_config_id, itime, mtime, fee_interest_ar_id) FROM stdin;
\.


--
-- Data for Name: dunning_config; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.dunning_config (id, dunning_level, dunning_description, active, auto, email, terms, payment_terms, fee, interest_rate, email_body, email_subject, email_attachment, template, create_invoices_for_fees) FROM stdin;
\.


--
-- Data for Name: email_journal; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.email_journal (id, sender_id, "from", recipients, sent_on, subject, body, headers, status, extended_status, itime, mtime) FROM stdin;
\.


--
-- Data for Name: email_journal_attachments; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.email_journal_attachments (id, "position", email_journal_id, name, mime_type, content, itime, mtime, file_id) FROM stdin;
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.employee (id, login, startdate, enddate, sales, itime, mtime, name, deleted, deleted_email, deleted_signature, deleted_tel, deleted_fax) FROM stdin;
409	cem	2019-10-15	\N	t	2019-10-15 11:47:33.50358	\N		f	\N	\N	\N	\N
\.


--
-- Data for Name: employee_project_invoices; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.employee_project_invoices (employee_id, project_id) FROM stdin;
\.


--
-- Data for Name: exchangerate; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.exchangerate (transdate, buy, sell, itime, mtime, id, currency_id) FROM stdin;
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.files (id, object_type, object_id, file_name, file_type, mime_type, source, backend, backend_data, title, description, itime, mtime) FROM stdin;
\.


--
-- Data for Name: finanzamt; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.finanzamt (fa_land_nr, fa_bufa_nr, fa_name, fa_strasse, fa_plz, fa_ort, fa_telefon, fa_fax, fa_plz_grosskunden, fa_plz_postfach, fa_postfach, fa_blz_1, fa_kontonummer_1, fa_bankbezeichnung_1, fa_blz_2, fa_kontonummer_2, fa_bankbezeichnung_2, fa_oeffnungszeiten, fa_email, fa_internet, id) FROM stdin;
10	1010	Saarlouis 	Gaswerkweg 25	66740	Saarlouis	06831/4490	06831/449397		66714	1440	59000000	59301502	BBK SAARBRUECKEN	59010066	7761668	POSTBANK SAARBRUECKEN	Mo,Di,Do 7.30-15.30, Mi 7.30-18,Fr 7.30-12			1
10	1020	Merzig 	Am Gaswerk	66663	Merzig	06861/7030	06861/703133		66653	100232	59000000	59301502	BBK SAARBRUECKEN	59010066	7761668	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 7.30-12.00			2
10	1030	Neunkirchen 	Uhlandstr.	66538	Neunkirchen	06821/1090	06821/109275		66512	1234	59000000	59001508	BBK SAARBRUECKEN	59010066	2988669	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 07.30-12.00			3
10	1040	Saarbrücken Am Stadtgr 	Am Stadtgraben 2-4	66111	Saarbrücken	0681/30000	0681/3000329		66009	100952	59000000	59001502	BBK SAARBRUECKEN	59010066	7766663	POSTBANK SAARBRUECKEN	Mo,Di,Do 7.30-15.30, Mi 7.30-18,Fr 7.30-12			4
10	1055	Saarbrücken MainzerStr 	Mainzer Str.109-111	66121	Saarbrücken	0681/30000	0681/3000762		66009	100944	59000000	59001502	BBK SAARBRUECKEN	59010066	7766663	POSTBANK SAARBRUECKEN	Mo,Mi,Fr 8.30-12.00, zus. Mi 13.30 - 15.30			5
10	1060	St. Wendel 	Marienstr. 27	66606	St. Wendel	06851/8040	06851/804189		66592	1240	59000000	59001508	BBK SAARBRUECKEN	59010066	2988669	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 07.30-12.00			6
10	1070	Sulzbach 	Vopeliusstr. 8	66280	Sulzbach	06897/9082-0	06897/9082110		66272	1164	59000000	59001502	BBK SAARBRUECKEN	59010066	7766663	POSTBANK SAARBRUECKEN	Mo,Mi,Fr 08.30-12.00, zus. Mi 13.30-18.00			7
10	1075	Homburg 	Schillerstr. 15	66424	Homburg	06841/6970	06841/697199		66406	1551	59000000	59001508	BBK SAARBRUECKEN	59010066	2988669	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 07.30-12.00			8
10	1085	St. Ingbert 	Rentamtstr. 39	66386	St. Ingbert	06894/984-01	06894/984159		66364	1420	59000000	59001508	BBK SAARBRUECKEN	59010066	2988669	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 7.30-12.00			9
10	1090	Völklingen 	Marktstr.	66333	Völklingen	06898/20301	06898/203133		66304	101440	59000000	59001502	BBK SAARBRUECKEN	59010066	7766663	POSTBANK SAARBRUECKEN	Mo-Do 7.30-15.30,Mi bis 18.00,Fr 07.30-12.00			10
11	1113	Berlin Charlottenburg	Bismarckstraße 48	10627	Berlin	030 9024-13-0	030 9024-13-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	facharlottenburg@berlin.de	http://www.berlin.de/ofd	11
11	1114	Berlin Kreuzberg	Mehringdamm 22	10961	Berlin	030 9024-14-0	030 9024-14-900	10958			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fakreuzberg@berlin.de	http://www.berlin.de/oberfinanzdirektion	12
11	1115	Berlin Neukölln																faneukoelln@berlin.de		13
11	1116	Berlin Neukölln	Thiemannstr. 1	12059	Berlin	030 9024-16-0	030 9024-16-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	faneukoelln@berlin.de	http://www.berlin.de/oberfinanzdirektion	14
11	1117	Berlin Reinickendorf	Eichborndamm 208	13403	Berlin	030 9024-17-0	030 9024-17-900	13400			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fareinickendorf@berlin.de	http://www.berlin.de/oberfinanzdirektion	15
11	1118	Berlin Schöneberg	Bülowstraße 85/88	10783	Berlin	030/9024-18-0	030/9024-18-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Montag und Freitag: 8:00 - 13:00 Uhr Donnerstag: 11:00 - 18:00 Uhr	faschoeneberg@berlin.de	http://www.berlin.de/oberfinanzdirektion	16
11	1119	Berlin Spandau	Nonnendammallee 15-21	13599	Berlin	030/9024-19-0	030/9024-19-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	faspandau@berlin.de	http://www.berlin.de/oberfinanzdirektion	17
11	1120	Berlin Steglitz	Schloßstr. 58/59	12165	Berlin	030/9024-20-0	030/9024-20-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fasteglitz@berlin.de	http://www.berlin.de/oberfinanzdirektion	18
11	1121	Berlin Tempelhof	Tempelhofer Damm 234/236	12099	Berlin	030 9024-21-0	030 9024-21-900	12096			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fatempelhof@berlin.de	http://www.berlin.de/oberfinanzdirektion	19
11	1123	Berlin Wedding	Osloer Straße 37	13359	Berlin	030 9024-23-0	030 9024-23-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fawedding@berlin.de	http://www.berlin.de/oberfinanzdirektion	20
11	1124	Berlin Wilmersdorf	Blissestr. 5	10713	Berlin	030/9024-24-0	030/9024-24-900	10702			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fawilmersdorf@berlin.de	http://www.berlin.de/oberfinanzdirektion	21
11	1125	Berlin Zehlendorf	Martin-Buber-Str. 20/21	14163	Berlin	030 9024-25-0	030 9024-25-900	14160			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fazehlendorf@berlin.de	http://www.berlin.de/oberfinanzdirektion	22
11	1127	Berlin für Körperschaften I	Gerichtstr. 27	13347	Berlin	030 9024-27-0	030 9024-27-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fakoerperschaften1@berlin.de	http://www.berlin.de/oberfinanzdirektion	23
11	1128	Berlin Pankow/Weißennsee - nur KFZ-Steuer -	Berliner Straße 32	13089	Berlin	030/4704-0	030/94704-1777	13083			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	pankow.weissensee@berlin.de	http://www.berlin.de/oberfinanzdirektion	24
11	1129	Berlin für Körperschaften III	Volkmarstr. 13	12099	Berlin	030/70102-0	030/70102-100		12068	420844	10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fakoeperschaften3@berlin.de	http://www.berlin.de/oberfinanzdirektion	25
11	1130	Berlin für Körperschaften IV	Magdalenenstr. 25	10365	Berlin	030 9024-30-0	030 9024-30-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fakoeperschaften4@berlin.de	http://www.berlin.de/oberfinanzdirektion	26
11	1131	Berlin Friedrichsh./Prenzb.	Pappelallee 78/79	10437	Berlin	030 9024-28-0	030 9024-28-900	10431			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fafriedrichshain.prenzlauerberg@berlin.de	http://www.berlin.de/oberfinanzdirektion	27
11	1132	Berlin Lichtenb./Hohenschh.	Josef-Orlopp-Str. 62	10365	Berlin	030/5501-0	030/55012222	10358			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	falichtenberg.hohenschoenhausen@berlin.de	http://www.berlin.de/oberfinanzdirektion	28
11	1133	Berlin Hellersdorf/Marzahn	Allee der Kosmonauten 29	12681	Berlin	030 9024-26-0	030 9024-26-900	12677			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fahellersdorf.marzahn@berlin.de	http://www.berlin.de/oberfinanzdirektion	29
11	1134	Berlin Mitte/Tiergarten	Neue Jakobstr. 6-7	10179	Berlin	030 9024-22-0	030 9024-22-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	famitte.tiergarten@berlin.de	http://www.berlin.de/oberfinanzdirektion	30
11	1135	Berlin Pankow/Weißensee	Berliner Straße 32	13089	Berlin	030/4704-0	030/47041777	13083			10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	pankow.weissensee@berlin.de	http://www.berlin.de/oberfinanzdirektion	31
11	1136	Berlin Treptow/Köpenick	Seelenbinderstr. 99	12555	Berlin	030 9024-12-0	030 9024-12-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fatreptow.koepenick@berlin.de	http://www.berlin.de/oberfinanzdirektion	32
11	1137	Berlin für Körperschaften II	Magdalenenstr. 25	10365	Berlin	030 9024-29-0	030 9024-29-900				10010010	691555100	POSTBANK BERLIN	10050000	6600046463	LBB GZ - BERLINER SPARKASSE	Mo und Fr 8:00 - 13:00, Do 11:00 - 18:00 Uhr und nach Vereinbarung	fakoeperschaften2@berlin.de	http://www.berlin.de/oberfinanzdirektion	33
11	1138	Berlin für Fahndung und Strafsachen	Colditzstr. 41	12099	Berlin	030/70102-777	030/70102-700										Mo - Mi 10:00 - 14:00, Do 10:00 - 18:00, Fr 10:00 - 14:00 Uhr	fafahndung.strafsachen@berlin.de	http://www.berlin.de/oberfinanzdirektion	34
1	2111	Bad Segeberg 	Theodor-Storm-Str. 4-10	23795	Bad Segeberg	04551 54-0	04551 54-303	23792			23000000	23001502	BBK LUEBECK	23051030	744	KR SPK SUEDHOLSTEIN BAD SEG	0830-1200 MO, DI, DO, FR, 1330-1630 DO			35
1	2112	Eckernförde 	Bergstr. 50	24340	Eckernförde	04351 756-0	04351 83379		24331	1180	21000000	21001500	BBK KIEL	21092023	11511260	ECKERNFOERDER BANK VRB	0800-1200 MO-FR			36
1	2113	Elmshorn 	Friedensallee 7-9	25335	Elmshorn	04121 481-0	04121 481-460	25333			22200000	22201502	BBK KIEL EH ITZEHOE				0800-1200 MO-FR			37
1	2114	Eutin 	Robert-Schade-Str. 22	23701	Eutin	04521 704-0	04521 704-406		23691	160	23000000	23001505	BBK LUEBECK	21352240	4283	SPK OSTHOLSTEIN EUTIN	0830-1200 MO-FR, Nebenstelle Janusstr. 5 am Mo., Di, Do und Fr. 0830-1200, Do. 1330-1700			38
1	2115	Flensburg 	Duburger Str. 58-64	24939	Flensburg	0461 813-0	0461 813-254		24905	1552	21500000	21501500	BBK FLENSBURG				0800-1200 MO-FR			39
1	2116	Heide 	Ernst-Mohr-Str. 34	25746	Heide	0481 92-1	0481 92-690	25734			21500000	21701502	BBK FLENSBURG	22250020	60000123	SPK WESTHOLSTEIN	0800-1200 MO, DI, DO, FR, 1400-1700 DO			40
1	2117	Husum 	Herzog-Adolf-Str. 18	25813	Husum	04841 8949-0	04841 8949-200		25802	1230	21500000	21701500	BBK FLENSBURG				0800-1200 MO-FR			41
1	2118	Itzehoe 	Fehrsstr. 5	25524	Itzehoe	04821 66-0	04821 661-499		25503	1344	22200000	22201500	BBK KIEL EH ITZEHOE				0800-1200 MO, DI, DO, FR, 1400-1730 DO			42
1	2119	Kiel-Nord 	Holtenauer Str. 183	24118	Kiel	0431 8819-0	0431 8819-1200	24094			21000000	21001501	BBK KIEL	21050000	52001500	HSH NORDBANK KIEL	0800-1200 MO-FR 1430-1600 DI			43
1	2120	Kiel-Süd 	Hopfenstr. 2a	24114	Kiel	0431 602-0	0431 602-1009	24095			21000000	21001502	BBK KIEL	21050000	52001510	HSH NORDBANK KIEL	0800-1200 MO, DI, DO, FR, 1430-1730 DI			44
1	2121	Leck 	Eesacker Str. 11 a	25917	Leck	04662 85-0	04662 85-266		25912	1240	21700000	21701501	BBK FLENSBURG EH HUSUM	21750000	80003569	NORD-OSTSEE SPK SCHLESWIG	0800-1200 MO-FR			45
1	2122	Lübeck 	Possehlstr. 4	23560	Lübeck	0451 132-0	0451 132-501	23540			23000000	23001500	BBK LUEBECK	21050000	7052000200	HSH NORDBANK KIEL	0730-1300 MO+DI 0730-1700 Do 0730-1200 Fr			46
1	2123	Meldorf 	Jungfernstieg 1	25704	Meldorf	04832 87-0	04832 87-2508		25697	850	21500000	21701503	BBK FLENSBURG	21851830	106747	VERB SPK MELDORF	0800-1200 MO, DI, DO, FR, 1400-1700 MO			47
1	2124	Neumünster 	Bahnhofstr. 9	24534	Neumünster	04321 496 0	04321 496-189	24531			21000000	21001507	BBK KIEL				0800-1200 MO-MI, FR 1400-1700 DO			48
1	2125	Oldenburg 	Lankenstr. 1	23758	Oldenburg	04361 497-0	04361 497-125		23751	1155	23000000	23001504	BBK LUEBECK	21352240	51000396	SPK OSTHOLSTEIN EUTIN	0900-1200 MO-FR 1400-1600 MI			49
1	2126	Plön 	Fünf-Seen-Allee 1	24306	Plön	04522 506-0	04522 506-2149		24301	108	21000000	21001503	BBK KIEL	21051580	2600	SPK KREIS PLOEN	0800-1200 MO, Di, Do, Fr, 1400-1700 Di			50
1	2127	Ratzeburg 	Bahnhofsallee 20	23909	Ratzeburg	04541 882-01	04541 882-200	23903			23000000	23001503	BBK LUEBECK	23052750	100188	KR SPK LAUENBURG RATZEBURG	0830-1230 MO, DI, DO, FR, 1430-1730 DO			51
1	2128	Rendsburg 	Ritterstr. 10	24768	Rendsburg	04331 598-0	04331 598-2770		24752	640	21000000	21001504	BBK KIEL	21450000	1113	SPK MITTELHOLSTEIN RENDSBG	0730-1200 MO-FR			52
1	2129	Schleswig 	Suadicanistr. 26-28	24837	Schleswig	04621 805-0	04621 805-290		24821	1180	21500000	21501501	BBK FLENSBURG	21690020	91111	VOLKSBANK RAIFFEISENBANK	0800-1200 MO, DI, DO, FR, 1430-1700 DO			53
1	2130	Stormarn 	Berliner Ring 25	23843	Bad Oldesloe	04531 507-0	04531 507-399	23840			23000000	23001501	BBK LUEBECK	23051610	20503	SPK BAD OLDESLOE	0830-1200 MO-FR			54
1	2131	Pinneberg 	Friedrich-Ebert-Str. 29	25421	Pinneberg	04101 5472-0	04101 5472-680		25404	1451	22200000	22201503	BBK KIEL EH ITZEHOE				0800-1200 MO-FR			55
1	2132	Bad Segeberg / Außenst.Norderstedt	Europaallee 22	22850	Norderstedt	040 523068-0	040 523068-70				23000000	23001502	BBK LUEBECK	23051030	744	KR SPK SUEDHOLSTEIN BAD SEG	0830-1200 MO, DI, DO, FR, 1330-1630 DO			56
2	2201	Hamburg Steuerkasse	Steinstraße 10	20095	Hamburg	040/42853-03	040/42853-2159		20041	106026	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerSteuererhebung@finanzamt.hamburg.de		57
2	2210	Hamburg f.VerkSt.u.Grundbes-10	Gorch-Fock-Wall 11	20355	Hamburg	040/42843-60	040/42843-6199		20306	301721	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerVerkehrsteuern@finanzamt.hamburg.de		63
2	2216	Hamburg f.VerkSt.u.Grundbes-16	Gorch-Fock-Wall 11	20355	Hamburg	040/42843-60	040/42843-6199		20306	301721	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerVerkehrsteuern@finanzamt.hamburg.de		65
2	2217	Hamburg-Mitte-Altstadt 17 	Wendenstraße 35 b	20097	Hamburg	040/42853-06	040/42853-6671		20503	261338	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgMitteAltstadt@finanzamt.hamburg.de		66
2	2220	Hamburg f.VerkSt.u.Grundbes-20	Gorch-Fock-Wall 11	20355	Hamburg	040/42843-60	040/42843-6599		20306	301721	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerVerkehrsteuern@finanzamt.hamburg.de		67
2	2224	Hamburg-Mitte-Altstadt 	Wendenstr. 35 b	20097	Hamburg	040/42853-06	040/42853-6671		20503	261338	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgMitteAltstadt@finanzamt.hamburg.de		69
2	2225	Hamburg-Neustadt-St.Pauli 	Steinstraße 10	20095	Hamburg	040/42853-02	040/42853-2106		20015	102246	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgNeustadt@finanzamt.hamburg.de		70
2	2227	Hamburg für Großunternehmen	Amsinckstr. 40	20097	Hamburg	040/42853-05	040/42853-5559		20015	102205	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerGroßunternehmen@finanzamt.hamburg.de		72
2	2228	Hamburg Neust.-St.Pauli-28	Steinstr. 10	20095	Hamburg	040/42853-3589	040/42853-2106		20015	102246	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgNeustadt@finanzamt.hamburg.de		73
2	2230	Hamburg f.Verkehrst.u.Grundbes	Gorch-Fock-Wall 11	20355	Hamburg	040/42843-60	040/42843-6799		20306	301721	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerVerkehrsteuern@finanzamt.hamburg.de		74
2	2235	Hamburg f.VerkSt.u.Grundbes-35	Gorch-Fock-Wall 11	20355	Hamburg	040/42843-60	040/42843-6199		20306	301721	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAfuerVerkehrsteuern@finanzamt.hamburg.de		75
3	2311	Alfeld (Leine) 	Ravenstr.10	31061	Alfeld	05181/7050	05181/705240		31042	1244	25000000	25901505	BBK HANNOVER	25950130	10011102	KR SPK HILDESHEIM	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-alf.niedersachsen.de	www.ofd.niedersachsen.de	79
3	2312	Bad Gandersheim 	Alte Gasse 24	37581	Bad Gandersheim	05382/760	(05382) 76-213 + 204		37575	1180	26000000	26001501	BBK GOETTINGEN	25050000	22801005	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-gan.niedersachsen.de	www.ofd.niedersachsen.de	80
3	2313	Braunschweig-Altewiekring 	Altewiekring 20	38102	Braunschweig	0531/7050	0531/705309		38022	3229	27000000	27001501	BBK BRAUNSCHWEIG	25050000	2498020	NORD LB HANNOVER	Mo. - Fr. 8.00 - 12.00 Uhr, Mo. 14.00 - 17.00 Uhr	Poststelle@fa-bs-a.niedersachsen.de	www.ofd.niedersachsen.de	81
3	2314	Braunschweig-Wilhelmstr. 	Wilhelmstr. 4	38100	Braunschweig	0531/4890	0531/489224		38022	3249	27000000	27001502	BBK BRAUNSCHWEIG	25050000	811422	NORD LB HANNOVER	Mo. - Fr. 8.00 - 12.00 Uhr, Mo. 14.00 - 17.00 Uhr	Poststelle@fa-bs-w.niedersachsen.de	www.ofd.niedersachsen.de	82
3	2315	Buchholz in der Nordheide 	Bgm.-A.-Meyer-Str. 5	21244	Buchholz	04181/2030	(04181) 203-4444		21232	1262	20000000	20001520	BBK HAMBURG	20750000	3005063	SPK HARBURG-BUXTEHUDE	Mo. - Fr. 8.00 - 12.00 Uhr , Do. 14.00 - 17.00 Uhr	Poststelle@fa-buc.niedersachsen.de	www.ofd.niedersachsen.de	83
3	2316	Burgdorf 	V.d.Hannov. Tor 30	31303	Burgdorf	05136/8060	05136/806144	31300			25000000	25001515	BBK HANNOVER	25050180	1040400010	SPARKASSE HANNOVER	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-bu.niedersachsen.de	www.ofd.niedersachsen.de	84
3	2317	Celle 	Sägemühlenstr. 5	29221	Celle	(05141) 915-0	05141/915666		29201	1107	25000000	25701511	BBK HANNOVER	25750001	59	SPARKASSE CELLE	Mo. - Fr. 8.00 - 12.00 Uhr , Do. 14.00 - 17.00 Uhr	Poststelle@fa-ce.niedersachsen.de	www.ofd.niedersachsen.de	85
3	2318	Cuxhaven 	Poststr. 81	27474	Cuxhaven	(04721) 563-0	04721/563313		27452	280	29000000	24101501	BBK BREMEN	24150001	100503	ST SPK CUXHAVEN	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-cux.niedersachsen.de	www.ofd.niedersachsen.de	86
3	2319	Gifhorn 	Braunschw. Str. 6-8	38518	Gifhorn	05371/8000	05371/800241		38516	1249	27000000	27001503	BBK BRAUNSCHWEIG	26951311	11009958	SPK GIFHORN-WOLFSBURG	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00	Poststelle@fa-gf.niedersachsen.de	www.ofd.niedersachsen.de	87
3	2320	Göttingen 	Godehardstr. 6	37073	Göttingen	0551/4070	0551/407449	37070			26000000	26001500	BBK GOETTINGEN	26050001	91	SPARKASSE GOETTINGEN	Servicecenter: Mo., Di., Mi. und Fr. 8.00 - 12.00 u. Do. 8.00 - 17.00 Uhr,	Poststelle@fa-goe.niedersachsen.de	www.ofd.niedersachsen.de	88
3	2321	Goslar 	Wachtelpforte 40	38644	Goslar	05321/5590	05321/559200		38604	1440	27000000	27001505	BBK BRAUNSCHWEIG	26850001	2220	SPARKASSE GOSLAR/HARZ	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-gs.niedersachsen.de	www.ofd.niedersachsen.de	89
2	2242	Hamburg-Am Tierpark 	Hugh-Greene-Weg 6	22529	Hamburg				22520		20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgAmTierpark@finanzamt.hamburg.de		77
3	2322	Hameln 	Süntelstraße 2	31785	Hameln	05151/2040	05151/204200		31763	101325	25000000	25401511	BBK HANNOVER	25450001	430	ST SPK HAMELN	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-hm.niedersachsen.de	www.ofd.niedersachsen.de	90
3	2323	Hannover-Land I 	Göttinger Chaus. 83A	30459	Hannover	(0511) 419-1	0511/4192269		30423	910320	25000000	25001512	BBK HANNOVER	25050000	101342434	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-h-l1.niedersachsen.de	www.ofd.niedersachsen.de	91
3	2324	Hannover-Mitte 	Lavesallee 10	30169	Hannover	0511/16750	0511/1675277		30001	143	25000000	25001516	BBK HANNOVER	25050000	101341816	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhrund nach Vereinbarung	Poststelle@fa-h-mi.niedersachsen.de	www.ofd.niedersachsen.de	92
3	2325	Hannover-Nord 	Vahrenwalder Str.206	30165	Hannover	0511/67900	(0511) 6790-6090		30001	167	25000000	25001514	BBK HANNOVER	25050000	101342426	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-h-no.niedersachsen.de	www.ofd.niedersachsen.de	93
3	2326	Hannover-Süd 	Göttinger Chaus. 83B	30459	Hannover	0511/4191	0511/4192575		30423	910355	25000000	25001517	BBK HANNOVER	25050000	101342400	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-h-su.niedersachsen.de	www.ofd.niedersachsen.de	94
3	2327	Hannover-Land II 	Vahrenwalder Str.208	30165	Hannover	0511/67900	(0511) 6790-6633		30001	165	25000000	25001520	BBK HANNOVER	25050000	101342517	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-h-l2.niedersachsen.de	www.ofd.niedersachsen.de	95
3	2328	Helmstedt 	Ernst-Koch-Str.3	38350	Helmstedt	05351/1220	(05351) 122-299		38333	1320	27000000	27101500	BBK BRAUNSCHWEIG	25050000	5801006	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-he.niedersachsen.de	www.ofd.niedersachsen.de	96
3	2329	Herzberg am Harz 	Sieberstr. 1	37412	Herzberg	05521/8570	05521/857220		37401	1153	26000000	26001502	BBK GOETTINGEN	26351015	1229327	SPARKASSE IM KREIS OSTERODE	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-hz.niedersachsen.de	www.ofd.niedersachsen.de	97
3	2330	Hildesheim 	Kaiserstrasse 47	31134	Hildesheim	05121/3020	05121/302480		31104	100455	25000000	25901500	BBK HANNOVER	25950130	5555	KR SPK HILDESHEIM	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-hi.niedersachsen.de	www.ofd.niedersachsen.de	98
3	2331	Holzminden 	Ernst-August-Str.30	37603	Holzminden	05531/1220	05531/122100		37601	1251	25000000	25401512	BBK HANNOVER	25050000	27811140	NORD LB HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-hol.niedersachsen.de	www.ofd.niedersachsen.de	99
3	2332	Lüchow 	Mittelstr.5	29439	Lüchow	(05841) 963-0	05841/963170		29431	1144	24000000	25801503	BBK LUENEBURG	25851335	2080000	KR SPK LUECHOW-DANNENBERG	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-luw.niedersachsen.de	www.ofd.niedersachsen.de	100
3	2333	Lüneburg 	Am Alt. Eisenwerk 4a	21339	Lüneburg	04131/3050	04131/305915	21332			24000000	24001500	BBK LUENEBURG	24050110	18	SPK LUENEBURG	Mo. - Fr. 8.00-12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-lg.niedersachsen.de	www.ofd.niedersachsen.de	101
3	2334	Nienburg/Weser 	Schloßplatz 10	31582	Nienburg	05021/8011	05021/801300		31580	2000	25000000	25601500	BBK HANNOVER	25650106	302224	SPARKASSE NIENBURG	Mo. - Fr. 7.30 - 12.00 Uhr und nach Vereinbarung, zusätzl. Arbeitnehmerbereich: Do. 14 -	Poststelle@fa-ni.niedersachsen.de	www.ofd.niedersachsen.de	102
3	2335	Northeim 	Graf-Otto-Str. 31	37154	Northeim	05551/7040	05551/704221		37142	1261	26000000	26201500	BBK GOETTINGEN	26250001	208	KR SPK NORTHEIM	Mo. - Fr. 8.30 - 12.30 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-nom.niedersachsen.de	www.ofd.niedersachsen.de	103
3	2336	Osterholz-Scharmbeck 	Pappstraße 2	27711	Osterholz-Scharmbeck	04791/3020	04791/302101		27701	1120	29000000	29001523	BBK BREMEN	29152300	202622	KR SPK OSTERHOLZ	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-ohz.niedersachsen.de	www.ofd.niedersachsen.de	104
3	2338	Peine 	Duttenstedt.Str. 106	31224	Peine	05171/4070	05171/407199	31221			27000000	27001507	BBK BRAUNSCHWEIG	25250001	75003210	KR SPK PEINE	Mo. - Mi. Fr. 9.00 - 12.00, Do. 13.30 - 16.00 UhrDo. (Infothek) 13.30 -	Poststelle@fa-pe.niedersachsen.de	www.ofd.niedersachsen.de	105
3	2340	Rotenburg (Wümme) 	Hoffeldstr. 5	27356	Rotenburg	04261/740	04261/74108		27342	1260	29000000	29001522	BBK BREMEN	24151235	26106377	SPK ROTENBURG-BREMERVOERDE	Mo. - Mi., Fr. 8.00 - 12.00 Uhr, Do. 8.00 - 17.30	Poststelle@fa-row.niedersachsen.de	www.ofd.niedersachsen.de	106
3	2341	Soltau 	Rühberg 16 - 20	29614	Soltau	05191/8070	05191/807144		29602	1243	24000000	25801502	BBK LUENEBURG	25851660	100016	KR SPK SOLTAU	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-sol.niedersachsen.de	www.ofd.niedersachsen.de	107
3	2342	Hannover-Land I Außenstelle Springe	Bahnhofstr. 28	31832	Springe	05041/7730	05041/77363		31814	100255	25000000	25001512	BBK HANNOVER	25050180	3001000037	SPARKASSE HANNOVER	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-ast-spr.niedersachsen.de	www.ofd.niedersachsen.de	108
3	2343	Stade 	Harburger Str. 113	21680	Stade	(04141) 536-0	(04141) 536-499	21677			24000000	24001560	BBK LUENEBURG	24151005	42507	SPK STADE-ALTES LAND	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-std.niedersachsen.de	www.ofd.niedersachsen.de	109
3	2344	Stadthagen 	Schloß	31655	Stadthagen	05721/7050	05721/705250	31653			49000000	49001502	BBK MINDEN, WESTF	25551480	470140401	SPARKASSE SCHAUMBURG	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-shg.niedersachsen.de	www.ofd.niedersachsen.de	110
3	2345	Sulingen 	Hindenburgstr. 16	27232	Sulingen	04271/870	04271/87289		27226	1520	29000000	29001516	BBK BREMEN	25651325	30101430	KR SPK DIEPHOLZ	Mo., Mi., Do. und Fr. 8.00 - 12.00 Uhr, Di. 8.00 - 17.00 Uhr	Poststelle@fa-su.niedersachsen.de	www.ofd.niedersachsen.de	111
3	2346	Syke 	Bürgerm.-Mävers-Str. 15	28857	Syke	04242/1620	04242/162423		28845	1164	29000000	29001515	BBK BREMEN	29151700	1110044557	KREISSPARKASSE SYKE	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-sy.niedersachsen.de	www.ofd.niedersachsen.de	112
3	2347	Uelzen 	Am Königsberg 3	29525	Uelzen	0581/8030	0581/803404		29504	1462	24000000	25801501	BBK LUENEBURG	25850110	26	SPARKASSE UELZEN	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-ue.niedersachsen.de	www.ofd.niedersachsen.de	113
3	2348	Verden (Aller) 	Bremer Straße 4	27283	Verden	04231/9190	04231/919310		27263	1340	29000000	29001517	BBK BREMEN	29152670	10000776	KR SPK VERDEN	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-ver.niedersachsen.de	www.ofd.niedersachsen.de	114
3	2349	Wesermünde 	Borriesstr. 50	27570	Bremerhaven	0471/1830	0471/183119		27503	100369	29000000	29201501	BBK BREMEN	29250150	100103200	KR SPK WESERMUENDE-HADELN	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-wem.niedersachsen.de	www.ofd.niedersachsen.de	115
3	2350	Winsen (Luhe) 	Von-Somnitz-Ring 6	21423	Winsen	04171/6560	(04171) 656-115		21413	1329	24000000	24001550	BBK LUENEBURG	20750000	7051519	SPK HARBURG-BUXTEHUDE	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 18.00 Uhr und nach Vereinbarung	Poststelle@fa-wl.niedersachsen.de	www.ofd.niedersachsen.de	116
3	2351	Wolfenbüttel 	Jägerstr. 19	38304	Wolfenbüttel	05331/8030	(05331) 803-113/266 	38299			27000000	27001504	BBK BRAUNSCHWEIG	25050000	9801002	NORD LB HANNOVER	Mo. - Fr. 8.00 - 12.00 Uhr, Mi. 14.00 - 17.00 Uhr	Poststelle@fa-wf.niedersachsen.de	www.ofd.niedersachsen.de	117
3	2352	Zeven 	Kastanienweg 1	27404	Zeven	04281/7530	04281/753290		27392	1259	29000000	29201503	BBK BREMEN	24151235	404350	SPK ROTENBURG-BREMERVOERDE	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-zev.niedersachsen.de	www.ofd.niedersachsen.de	118
3	2353	Papenburg 	Große Straße 32	26871	Aschendorf	04962/5030	04962/503222		26883	2264	28000000	28501512	BBK OLDENBURG (OLDB)	26650001	1020007	SPK EMSLAND	Mo. - Fr. 9.00 - 12.00 Uhr, Mi. 14.00 - 17.00 Uhr	Poststelle@fa-pap.niedersachsen.de	www.ofd.niedersachsen.de	119
3	2354	Aurich 	Hasseburger Str. 3	26603	Aurich	04941/1750	04941/175152		26582	1260	28000000	28501514	BBK OLDENBURG (OLDB)	28350000	90001	SPK AURICH-NORDEN	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-aur.niedersachsen.de	www.ofd.niedersachsen.de	120
3	2355	Bad Bentheim 	Heinrich-Böll-Str. 2	48455	Bad Bentheim	05922/970-0	05922/970-2000		48443	1262	26500000	26601501	BBK OSNABRUECK	26750001	1000066	KR SPK NORDHORN	Mo. - Fr. 9.00 - 12.00 Uhr, Do 14.00 - 15.30 Uhr	Poststelle@fa-ben.niedersachsen.de	www.ofd.niedersachsen.de	121
3	2356	Cloppenburg 	Bahnhofstr. 57	49661	Cloppenburg	04471/8870	04471/887477		49646	1680	28000000	28001501	BBK OLDENBURG (OLDB)	28050100	80402100	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-clp.niedersachsen.de	www.ofd.niedersachsen.de	122
3	2357	Delmenhorst 	Fr.-Ebert-Allee 15	27749	Delmenhorst	04221/1530	04221/153126	27747			29000000	29001521	BBK BREMEN	28050100	30475669	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 9.00 - 12.00 Uhr, Di. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-del.niedersachsen.de	www.ofd.niedersachsen.de	123
3	2358	Emden 	Ringstr. 5	26721	Emden	(04921) 934-0	(04921) 934-499		26695	1553	28000000	28401500	BBK OLDENBURG (OLDB)	28450000	26	SPARKASSE EMDEN	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-emd.niedersachsen.de	www.ofd.niedersachsen.de	124
3	2360	Leer (Ostfriesland) 	Edzardstr. 12/16	26789	Leer	(0491) 9870-0	0491/9870209	26787			28000000	28501511	BBK OLDENBURG (OLDB)	28550000	849000	SPARKASSE LEER-WEENER	Mo. - Fr. 8.00 - 12.00 Uhr, nur Infothek: Mo., Do. 14.00 - 17.30 Uhr	Poststelle@fa-ler.niedersachsen.de	www.ofd.niedersachsen.de	125
3	2361	Lingen (Ems) 	Mühlentorstr. 14	49808	Lingen	0591/91490	0591/9149468		49784	1440	26500000	26601500	BBK OSNABRUECK	26650001	2402	SPK EMSLAND	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr und nach Vereinbarung	Poststelle@fa-lin.niedersachsen.de	www.ofd.niedersachsen.de	126
3	2362	Norden 	Mühlenweg 20	26506	Norden	04931/1880	04931/188196		26493	100360	28000000	28501515	BBK OLDENBURG (OLDB)	28350000	1115	SPK AURICH-NORDEN	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-nor.niedersachsen.de	www.ofd.niedersachsen.de	127
3	2363	Nordenham 	Plaatweg 1	26954	Nordenham	04731/8700	04731/870100		26942	1264	28000000	28001504	BBK OLDENBURG (OLDB)	28050100	63417000	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 8.30 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-nhm.niedersachsen.de	www.ofd.niedersachsen.de	128
3	2364	Oldenburg (Oldenburg) 	91er Straße 4	26121	Oldenburg	0441/2381	(0441) 238-201/2/3		26014	2445	28000000	28001500	BBK OLDENBURG (OLDB)	28050100	423301	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-ol.niedersachsen.de	www.ofd.niedersachsen.de	129
3	2365	Osnabrück-Land 	Hannoversche Str. 12	49084	Osnabrück	0541/58420	0541/5842450		49002	1280	26500000	26501501	BBK OSNABRUECK	26552286	110007	KREISSPARKASSE MELLE	Mo., Mi., Do. u. Fr. 8.00 - 12.00 Uhr, Di. 12.00 - 17.00 Uhr	Poststelle@fa-os-l.niedersachsen.de	www.ofd.niedersachsen.de	130
3	2366	Osnabrück-Stadt 	Süsterstr. 46/48	49074	Osnabrück	0541/3540	(0541) 354-312		49009	1920	26500000	26501500	BBK OSNABRUECK	26550105	19000	SPARKASSE OSNABRUECK	Mo. - Mi., Fr. 8.00 - 12.00 Uhr, nur Infothek: Do. 12.00 - 17.00 Uhr	Poststelle@fa-os-s.niedersachsen.de	www.ofd.niedersachsen.de	131
3	2367	Quakenbrück 	Lange Straße 37	49610	Quakenbrück	05431/1840	05431/184101		49602	1261	26500000	26501503	BBK OSNABRUECK	26551540	18837179	KR SPK BERSENBRUECK	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-qua.niedersachsen.de	www.ofd.niedersachsen.de	132
3	2368	Vechta 	Rombergstr. 49	49377	Vechta	04441/180	(04441) 18-100	49375			28000000	28001502	BBK OLDENBURG (OLDB)	28050100	70400049	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 8.30 - 12.00 Uhr, Mo. 14.00 - 16.00 Uhr,Mi. 14.00 - 17.00	Poststelle@fa-vec.niedersachsen.de	www.ofd.niedersachsen.de	133
3	2369	Westerstede 	Ammerlandallee 14	26655	Westerstede	04488/5150	04488/515444	26653			28000000	28001503	BBK OLDENBURG (OLDB)	28050100	40465007	LANDESSPARKASSE OLDENBURG	Mo. - Fr. 9.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-wst.niedersachsen.de	www.ofd.niedersachsen.de	134
3	2370	Wilhelmshaven 	Rathausplatz 3	26382	Wilhelmshaven	04421/1830	04421/183111		26354	1462	28000000	28201500	BBK OLDENBURG (OLDB)	28250110	2117000	SPARKASSE WILHELMSHAVEN	Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-whv.niedersachsen.de	www.ofd.niedersachsen.de	135
3	2371	Wittmund 	Harpertshausen.Str.2	26409	Wittmund	04462/840	04462/84195		26398	1153	28000000	28201502	BBK OLDENBURG (OLDB)				Mo. - Fr. 8.00 - 12.00 Uhr, Do. 14.00 - 17.00 Uhr	Poststelle@fa-wtm.niedersachsen.de	www.ofd.niedersachsen.de	136
3	2380	Braunschweig für Großbetriebsprüfung	Theodor-Heuss-Str.4a	38122	Braunschweig	0531/80970	(0531) 8097-333		38009	1937							nach Vereinbarung	Poststelle@fa-gbp-bs.niedersachsen.de	www.ofd.niedersachsen.de	137
3	2381	Göttingen für Großbetriebsprüfung	Godehardstr. 6	37073	Göttingen	0551/4070	(0551) 407-448											Poststelle@fa-gbp-goe.niedersachsen.de	www.ofd.niedersachsen.de	138
3	2382	Hannover I für Großbetriebsprüfung	Bischofsholer Damm 15	30173	Hannover	(0511) 8563-01	(0511) 8563-195											Poststelle@fa-gbp-h1.niedersachsen.de	www.ofd.niedersachsen.de	139
3	2383	Hannover II für Großbetriebsprüfung	Bischofsholer Damm 15	30173	Hannover	(0511) 8563-02	(0511) 8563-250		30019	1927								Poststelle@fa-gbp-h2.niedersachsen.de	www.ofd.niedersachsen.de	140
3	2384	Stade für Großbetriebsprüfung	Am Ärztehaus 12	21680	Stade	(04141) 602-0	(04141) 602-60											Poststelle@fa-gbp-std.niedersachsen.de	www.ofd.niedersachsen.de	141
3	2385	Oldenburg für Großbetriebsprüfung	Georgstr. 36	26121	Oldenburg	0441/2381	(0441) 238-522		26014	2445								Poststelle@fa-gbp-ol.niedersachsen.de	www.ofd.niedersachsen.de	142
3	2386	Osnabrück für Großbetriebsprüfung	Johann-Domann-Str. 6	49080	Osnabrück	(0541) 503 800	(0541) 503 888											Poststelle@fa-gbp-os.niedersachsen.de	www.ofd.niedersachsen.de	143
3	2390	Braunschweig für Fahndung und Strafsachen	Rudolf-Steiner-Str. 1	38120	Braunschweig	0531/28510	(0531) 2851-150		38009	1931							nach Vereinbarung	Poststelle@fa-fust-bs.niedersachsen.de	www.ofd.niedersachsen.de	144
3	2391	Hannover für Fahndung und Strafsachen	Göttinger Chaus. 83B	30459	Hannover	(0511) 419-1	(0511) 419-2988		30430	911007								Poststelle@fa-fust-h.niedersachsen.de	www.ofd.niedersachsen.de	145
3	2392	Lüneburg für Fahndung und Strafsachen	Horst-Nickel-Str. 6	21337	Lüneburg	(04131) 8545-600	(04131) 8545-698		21305	1570								Poststelle@fa-fust-lg.niedersachsen.de	www.ofd.niedersachsen.de	146
3	2393	Oldenburg für Fahndung und Strafsachen	Cloppenburger Str. 320	26133	Oldenburg	(0441) 9401-0	(0441) 9401-200		26014	2442								Poststelle@fa-fust-ol.niedersachsen.de	www.ofd.niedersachsen.de	147
4	2457	Bremen-Mitte Bewertung 	Rudolf-Hilferding-Platz 1	28195	Bremen	0421 322-2725	0421 322-2878		28079	10 79 67	29050000	1070110002	BREMER LANDESBANK BREMEN	29050101	109 0901	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtMitte.bremen.de		148
4	2471	Bremen-Mitte 	Rudolf-Hilferding-Platz 1	28195	Bremen	0421 322-2725	0421 322-2878	28187	28079	10 79 67	29000000	29001512	BBK BREMEN	29050101	1090646	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtMitte.bremen.de		149
4	2472	Bremen-Ost 	Rudolf-Hilferding-Platz 1	28195	Bremen	0421 322-3005	0421 322-3178		28057	10 57 09	29000000	29001513	BBK BREMEN	29050101	1090612	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtOst.bremen.de		150
4	2473	Bremen-West 	Rudolf-Hilferding-Platz 1	28195	Bremen	0421 322-3422	0421 322-3478		28057	10 57 29	29000000	29001514	BBK BREMEN	29050101	1090638	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtWest.bremen.de		151
4	2474	Bremen-Nord 	Gerhard-Rohlfs-Str. 32	28757	Bremen	0421 6607-1	0421 6607-300		28734	76 04 34	29000000	29001518	BBK BREMEN	29050101	5016001	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-14:00	office@FinanzamtNord.bremen.de		152
4	2475	Bremerhaven 	Schifferstr. 2-8	27568	Bremerhaven	0471 486-1	0471 486-370		27516	12 02 42	29200000	29201500	BBK BREMEN EH BREMERHAVEN	29250000	1100068	STE SPK BREMERHAVEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtBremerhaven.bremen.de		153
4	2476	Bremen-Mitte KraftfahrzeugSt 	Schillerstr. 22	28195	Bremen	0421 322-2725	0421 322-2878		28079	107967	29000000	29001512	BBK BREMEN	29050101	 109 0646	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtMitte.bremen.de		154
4	2477	Bremerhaven Bewertung 	Schifferstr. 2 - 8	27568	Bremerhaven	0471 486-1	0471 486-370		27516	12 02 42	29200000	29201500	BBK BREMEN EH BREMERHAVEN	29250000	1100068	STE SPK BREMERHAVEN	Zentrale Informations- und Annahmestelle Mo+Do 08.00-18.00/Di+Mi 08.00-16.00/Fr 08.00-15.00	office@FinanzamtBremerhaven.bremen.de		155
4	2478	Bremen für Großbetriebsprüfung	Schillerstr. 6-7	28195	Bremen	0421 322-4019	0421 322-4078		28057	10 57 69							nach Vereinbarung			156
4	2482	Bremen-Ost Arbeitnehmerbereich 	Rudolf-Hilferding-Platz 1	28195	Bremen	0421 322-3005	0421 322-3178		28057	10 57 09	29000000	29001513	BBK BREMEN	29050101	1090612	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtOst.bremen.de		157
4	2484	Bremen-Nord Arbeitnehmerbereic 	Gerhard-Rohlfs-Str. 32	28757	Bremen	0421 6607-1	0421 6607-300		28734	76 04 34	29000000	29001518	BBK BREMEN	29050101	5016001	SPK BREMEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-14:00	office@FinanzamtNord.bremen.de		158
4	2485	Bremerhaven Arbeitnehmerbereic 	Schifferstr. 2-8	27568	Bremerhaven	0471 486-1	0471 486-370		27516	12 02 42	29200000	29201500	BBK BREMEN EH BREMERHAVEN	29250000	1100068	STE SPK BREMERHAVEN	Zentrale Informations- und Annahmestelle Mo+Do 08:00-18:00,Di+Mi 08:00-16:00,Fr 08:00-15:00	office@FinanzamtBremerhaven.bremen.de		159
6	2601	Alsfeld-Lauterbach Verwaltungsstelle Alsfeld	In der Rambach 11	36304	Alsfeld	06631/790-0	06631/790-555		36292	1263	51300000	51301504	BBK GIESSEN	53051130	1022003	SPARKASSE VOGELSBERGKREIS	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Alsfeld-Lauterbach.de	www.Finanzamt-Alsfeld-Lauterbach.de	160
6	2602	Hersfeld-Rotenburg Verwaltungsstelle Bad Hersfeld	Im Stift 7	36251	Bad Hersfeld	06621/933-0	06621/933-333		36224	1451	53200000	53201500	BBK KASSEL EH BAD HERSFELD	53250000	1000016	SPK BAD HERSFELD-ROTENBURG	Mo u. Do 8:00-12:00, Di 14:00-18:00 Uhr	poststelle@Finanzamt-Hersfeld-Rotenburg.de	www.Finanzamt-Hersfeld-Rotenburg.de	161
6	2604	Rheingau-Taunus Verwaltungsst. Bad Schwalbach 	Emser Str.27a	65307	Bad Schwalbach	06124/705-0	06124/705-400		65301	1165	51000000	51001502	BBK WIESBADEN	51050015	393000643	NASS SPK WIESBADEN	Mo-Mi 8:00-15:30, Do 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Rheingau-Taunus.de	www.Finanzamt-Rheingau-Taunus.de	163
6	2605	Bensheim 	Berliner Ring 35	64625	Bensheim	06251/15-0	06251/15-267		64603	1351	50800000	50801510	BBK DARMSTADT	50950068	1040005	SPARKASSE BENSHEIM	Mo-Mi 8:00-15:30, Do 13:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Bensheim.de	www.Finanzamt-Bensheim.de	164
6	2606	Marburg-Biedenkopf Verwaltungsstelle Biedenkopf	Im Feldchen 2	35216	Biedenkopf	06421/698-0	06421/698-109				51300000	51301514	BBK GIESSEN	53350000	110027303	SPK MARBURG-BIEDENKOPF	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr Telefon Verwaltungsstelle: 06461/709-0	poststelle@Finanzamt-Marburg-Biedenkopf.de	www.Finanzamt-Marburg-Biedenkopf.de	165
6	2607	Darmstadt 	Soderstraße 30	64283	Darmstadt	06151/102-0	06151/102-1262	64287	64219	110465	50800000	50801500	BBK DARMSTADT	50850049	5093005006	LD BK GZ DARMSTADT	Mo-Mi 8:00-15:30, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Darmstadt.de	www.Finanzamt-Darmstadt.de	166
6	2608	Dieburg 	Marienstraße 19	64807	Dieburg	06071/2006-0	06071/2006-100		64802	1209	50800000	50801501	BBK DARMSTADT	50852651	33211004	SPARKASSE DIEBURG	Mo-Mi 7:30-15:30, Do 13:30-18:00, Fr 7:30-12:00 Uhr	poststelle@Finanzamt-Dieburg.de	www.Finanzamt-Dieburg.de	167
6	2609	Dillenburg 	Wilhelmstraße 9	35683	Dillenburg	02771/908-0	02771/908-100		35663	1362	51300000	51301509	BBK GIESSEN	51650045	18	BEZ SPK DILLENBURG	Mo-Mi 8:00-15:30, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Dillenburg.de	www.Finanzamt-Dillenburg.de	168
6	2610	Eschwege-Witzenhausen Verwaltungsstelle Eschwege	Schlesienstraße 2	37269	Eschwege	05651/926-5	05651/926-720	37267	37252	1280	52000000	52001510	BBK KASSEL	52250030	18	SPARKASSE WERRA-MEISSNER	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Eschwege-Witzenhausen.de	www.Finanzamt-Eschwege-Witzenhausen.de	169
8	2807	Freiburg-Land 	Stefan-Meier-Str. 133	79104	Freiburg	0761/2040	0761/2043424	79095			68000000	680 015 00	BBK FREIBURG IM BREISGAU	68090000	12222300	VOLKSBANK FREIBURG	ZIA: MO,DI,DO 8-16, MI 8-17:30, FR 8-12 UHR	poststelle@fa-freiburg-land.fv.bwl.de		170
6	2611	Korbach-Frankenberg Verwaltungsstelle Frankenberg 	Geismarer Straße 16	35066	Frankenberg	05631/563-0	05631/563-888				51300000	51301513	BBK GIESSEN	52350005	5001557	SPK WALDECK-FRANKENBERG	Mo, Di u. Do 8:00-15:30, Mi 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Korbach-Frankenberg.de	www.Finanzamt-Korbach-Frankenberg.de	171
6	2612	Frankfurt am Main II 	Gutleutstraße 122	60327	Frankfurt	069/2545-02	069/2545-2999		60305	110862	50000000	50001504	BBK FILIALE FRANKFURT MAIN	50050000	1600006	LD BK HESS-THUER GZ FFM	Mo-Mi 8:00-15:30, Do 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Frankfurt-2.de	www.Finanzamt-Frankfurt-am-Main.de	172
6	2613	Frankfurt am Main I 	Gutleutstraße 124	60327	Frankfurt	069/2545-01	069/2545-1999		60305	110861	50000000	50001504	BBK FILIALE FRANKFURT MAIN	50050000	1600006	LD BK HESS-THUER GZ FFM	Mo-Mi 8:00-15:30, Do 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Frankfurt-1.de	www.Finanzamt-Frankfurt-am-Main.de	173
6	2614	Frankfurt am Main IV 	Gutleutstraße 118	60327	Frankfurt	069/2545-04	069/2545-4999		60305	110864	50000000	50001504	BBK FILIALE FRANKFURT MAIN	50050000	1600006	LD BK HESS-THUER GZ FFM	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Frankfurt-4.de	www.Finanzamt-Frankfurt-am-Main.de	174
6	2615	Frankfurt/M. V-Höchst Verwaltungsstelle Höchst	Hospitalstraße 16 a	65929	Frankfurt	069/2545-05	069/2545-5999				50000000	50001502	BBK FILIALE FRANKFURT MAIN	50050201	608604	FRANKFURTER SPK FRANKFURT	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr Telefon Verwaltungsstelle: 069/30830-0	poststelle@Finanzamt-Frankfurt-5-Hoechst.de	www.Finanzamt-Frankfurt-am-Main.de	175
6	2616	Friedberg (Hessen) 	Leonhardstraße 10 - 12	61169	Friedberg	06031/49-1	06031/49-333		61143	100362	51300000	51301506	BBK GIESSEN	51850079	50000400	SPARKASSE WETTERAU	Di 8:00-12:00, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Friedberg.de	www.Finanzamt-Friedberg.de	176
6	2617	Bensheim Außenstelle Fürth	Erbacher Straße 23	64658	Fürth	06253/206-0	06253/206-10		64654	1154	50800000	50801510	BBK DARMSTADT	50950068	1040005	SPARKASSE BENSHEIM		poststelle@Finanzamt-Bensheim.de	www.Finanzamt-Bensheim.de	177
6	2618	Fulda 	Königstraße 2	36037	Fulda	0661/924-01	0661/924-1606		36003	1346	53000000	53001500	BBK KASSEL EH FULDA	53050180	49009	SPARKASSE FULDA	Mo-Mi 8:00-15:30, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Fulda.de	www.Finanzamt-Fulda.de	178
6	2619	Gelnhausen 	Frankfurter Straße 14	63571	Gelnhausen	06051/86-0	06051/86-299	63569	63552	1262	50600000	50601502	BBK FRANKFURT EH HANAU	50750094	2008	KREISSPARKASSE GELNHAUSEN	Mo u. Mi 8:00-12:00, Do 14:30-18:00 Uhr	poststelle@Finanzamt-Gelnhausen.de	www.Finanzamt-Gelnhausen.de	179
6	2620	Gießen 	Schubertstraße 60	35392	Gießen	0641/4800-100	0641/4800-1590	35387	35349	110440				51300000	51301500	BBK GIESSEN	Mo-Mi 8:00-15:30,Do 14:00-18:00, Fr 8:00-12:00 Uhr	info@Finanzamt-Giessen.de	www.Finanzamt-Giessen.de	180
6	2621	Groß-Gerau 	Europaring 11-13	64521	Groß-Gerau	06152/170-01	06152/170-601	64518	64502	1262	50800000	50801502	BBK DARMSTADT	50852553	1685	KR SPK GROSS-GERAU	Mo-Mi 8:00-15.30, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Gross-Gerau.de	www.Finanzamt-Gross-Gerau.de	181
6	2622	Hanau 	Am Freiheitsplatz 2	63450	Hanau	06181/101-1	06181/101-501	63446	63404	1452	50600000	50601500	BBK FRANKFURT EH HANAU	50650023	50104	SPARKASSE HANAU	Mo u. Mi 7:30-12:00, Do 14:30-18:00 Uhr	poststelle@Finanzamt-Hanau.de	www.Finanzamt-Hanau.de	182
6	2623	Kassel-Hofgeismar Verwaltungsstelle Hofgeismar	Altstädter Kirchplatz 10	34369	Hofgeismar	0561/7207-0	0561/7207-2500				52000000	52001501	BBK KASSEL	52050353	100009202	KASSELER SPARKASSE	Di, Mi u. Fr 8:00-12:00, Do 15:00-18:00 Uhr Telefon Verwaltungsstelle: 05671/8004-0	poststelle@Finanzamt-Kassel-Hofgeismar.de	www.Finanzamt-Kassel.de	183
6	2624	Schwalm-Eder Verwaltungsstelle Fritzlar	Georgengasse 5	34560	Fritzlar	05622/805-0	05622/805-111		34551	1161	52000000	52001502	BBK KASSEL	52052154	110007507	KREISSPARKASSE SCHWALM-EDER	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr	poststelle@Finanzamt-Schwalm-Eder.de	www.Finanzamt-Schwalm-Eder.de	184
6	2625	Kassel-Spohrstraße 	Spohrstraße 7	34117	Kassel	0561/7208-0	0561/7208-408	34111	34012	101249	52000000	52001500	BBK KASSEL	52050000	4091300006	LANDESKREDITKASSE KASSEL	Mo u. Fr 7:30-12:00, Mi 14:00-18:00 Uhr	poststelle@Finanzamt-Kassel-Spohrstrasse.de	www.Finanzamt-Kassel.de	185
6	2626	Kassel-Hofgeismar Verwaltungsstelle Kassel	Goethestraße 43	34119	Kassel	0561/7207-0	0561/7207-2500	34111	34012	101229	52000000	52001500	BBK KASSEL	52050000	4091300006	LANDESKREDITKASSE KASSEL	Mo, Mi u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr	poststelle@Finanzamt-Kassel-Hofgeismar.de	www.Finanzamt-Kassel.de	186
6	2627	Korbach-Frankenberg Verwaltungsstelle Korbach	Medebacher Landstraße 29	34497	Korbach	05631/563-0	05631/563-888	34495	34482	1240	52000000	52001509	BBK KASSEL	52350005	19588	SPK WALDECK-FRANKENBERG	Mo, Mi u. Fr 8:00-12:00, Do 15:30-18:00 Uhr	poststelle@Finanzamt-Korbach-Frankenberg.de	www.Finanzamt-Korbach-Frankenberg.de	187
6	2628	Langen 	Zimmerstraße 27	63225	Langen	06103/591-01	06103/591-285	63222	63202	1280	50000000	50001511	BBK FILIALE FRANKFURT MAIN	50592200	31500	VB DREIEICH	Mo, Mi u. Do 8:00-15:30, Di 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Langen.de	www.Finanzamt-Langen.de	188
6	2629	Alsfeld-Lauterbach Verwaltungsstelle Lauterbach	Bahnhofstraße 69	36341	Lauterbach	06631/790-0	06631/790-555	36339			53000000	53001501	BBK KASSEL EH FULDA	53051130	60100509	SPARKASSE VOGELSBERGKREIS	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr Telefon Verwaltungsstelle: 06641/188-0	poststelle@Finanzamt-Alsfeld-Lauterbach.de	www.Finanzamt-Alsfeld-Lauterbach.de	189
6	2630	Limburg-Weilburg Verwaltungsstelle Limburg	Walderdorffstraße 11	65549	Limburg	06431/208-1	06431/208-294	65547	65534	1465	51000000	51001507	BBK WIESBADEN	51050015	535054800	NASS SPK WIESBADEN	Mo-Mi 8:00-15:30, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Limburg-Weilburg.de	www.Finanzamt-Limburg-Weilburg.de	190
6	2631	Marburg-Biedenkopf Verwaltungsstelle Marburg	Robert-Koch-Straße 7	35037	Marburg	06421/698-0	06421/698-109	35034	35004	1469	51300000	51301512	BBK GIESSEN	53350000	11517	SPK MARBURG-BIEDENKOPF	Mo-Mi 8:00-15:30, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Marburg-Biedenkopf.de	www.Finanzamt-Marburg-Biedenkopf.de	191
6	2632	Schwalm-Eder Verwaltungsstelle Melsungen	Kasseler Straße 31 (Schloß)	34212	Melsungen	05622/805-0	05622/805-111				52000000	52001503	BBK KASSEL	52052154	10060002	KREISSPARKASSE SCHWALM-EDER	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr Telefon Verwaltungsstelle: 05661/706-0	poststelle@Finanzamt-Schwalm-Eder.de	www.Finanzamt-Schwalm-Eder.de	192
6	2633	Michelstadt 	Erbacher Straße 48	64720	Michelstadt	06061/78-0	06061/78-100		64712	3180	50800000	50801503	BBK DARMSTADT	50851952	40041451	SPK ODENWALDKREIS ERBACH	Mo, Di u. Do 8:00-15:30, Mi 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Michelstadt.de	www.Finanzamt-Michelstadt.de	193
6	2634	Nidda 	Schillerstraße 38	63667	Nidda	06043/805-0	06043/805-159		63658	1180	50600000	50601501	BBK FRANKFURT EH HANAU	51850079	150003652	SPARKASSE WETTERAU	Mo, Di u. Do 7:30-16:00, Mi 13:30-18:00, Fr 7:00-12:00 Uhr	poststelle@Finanzamt-Nidda.de	www.Finanzamt-Nidda.de	194
6	2635	Offenbach am Main-Stadt 	Bieberer Straße 59	63065	Offenbach	069/8091-1	069/8091-2400	63063	63005	100563	50000000	50001500	BBK FILIALE FRANKFURT MAIN	50550020	493	STE SPK OFFENBACH	Mo, Di u. Do 7:30-15:30, Mi 13:00-18:00, Fr 7:30-12:00 Uhr	poststelle@Finanzamt-Offenbach-Stadt.de	www.Finanzamt-Offenbach.de	195
6	2636	Hersfeld-Rotenburg Verwaltungsstelle Rotenburg	Dickenrücker Straße 12	36199	Rotenburg	06621/933-0	06621/933-333				52000000	52001504	BBK KASSEL	53250000	50000012	SPK BAD HERSFELD-ROTENBURG	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr Telefon Verwaltungsstelle: 06623/816-0	poststelle@Finanzamt-Hersfeld-Rotenburg.de	www.Finanzamt-Hersfeld-Rotenburg.de	196
6	2637	Rheingau-Taunus Verwaltungsstelle Rüdesheim	Hugo-Asbach-Straße 3 - 7	65385	Rüdesheim	06124/705-0	06124/705-400				51000000	51001501	BBK WIESBADEN	51050015	455022800	NASS SPK WIESBADEN	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr Telefon Verwaltungsstelle: 06722/405-0	poststelle@Finanzamt-Rheingau-Taunus.de	www.Finanzamt-Rheingau-Taunus.de	197
6	2638	Limburg-Weilburg Verwaltungsstelle Weilburg	Kruppstraße 1	35781	Weilburg	06431/208-1	06431/208-294	35779			51000000	51001511	BBK WIESBADEN	51151919	100000843	KR SPK WEILBURG	Mo-Mi 8:00-16:00, Do 14:00-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Limburg-Weilburg.de	www.Finanzamt-Limburg-Weilburg.de	198
6	2639	Wetzlar 	Frankfurter Straße 59	35578	Wetzlar	06441/202-0	06441/202-6810	35573	35525	1520	51300000	51301508	BBK GIESSEN	51550035	46003	SPARKASSE WETZLAR	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Wetzlar.de	www.Finanzamt-Wetzlar.de	199
6	2640	Wiesbaden I 	Dostojewskistraße 8	65187	Wiesbaden	0611/813-0	0611/813-1000	65173	65014	2469	51000000	51001500	BBK WIESBADEN	51050015	100061600	NASS SPK WIESBADEN	Mo, Di u. Do 8:00-15:30, Mi 13:30-18:00, Fr 7:00-12:00 Uhr	poststelle@Finanzamt-Wiesbaden-1.de	www.Finanzamt-Wiesbaden.de	200
6	2641	Eschwege-Witzenhausen Verwaltungsstelle Witzenhausen	Südbahnhofstraße 37	37213	Witzenhausen	05651/926-5	05651/926-720				52000000	52001505	BBK KASSEL	52250030	50000991	SPARKASSE WERRA-MEISSNER	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr Telefon Verwaltungsstelle: 05542/602-0	poststelle@Finanzamt-Eschwege-Witzenhausen.de	www.Finanzamt-Eschwege-Witzenhausen.de	201
6	2642	Schwalm-Eder Verwaltungsstelle Schwalmstadt	Landgraf-Philipp-Straße 15	34613	Schwalmstadt	05622/805-0	05622/805-111				52000000	52001506	BBK KASSEL	52052154	200006641	KREISSPARKASSE SCHWALM-EDER	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr Telefon Verwaltungsstelle: 06691/738-0	poststelle@Finanzamt-Schwalm-Eder.de	www.Finanzamt-Schwalm-Eder.de	202
6	2643	Wiesbaden II 	Dostojewskistraße 8	65187	Wiesbaden	0611/813-0	0611/813-2000	65173	65014	2469	51000000	51001500	BBK WIESBADEN	51050015	100061600	NASS SPK WIESBADEN	Mo, Di u. Do 8:00-15:30, Mi 13:30-18:00, Fr 7:00-12:00 Uhr	poststelle@Finanzamt-Wiesbaden-2.de	www.Finanzamt-Wiesbaden.de	203
6	2644	Offenbach am Main-Land 	Bieberer Straße 59	63065	Offenbach	069/8091-1	069/8091-3400	63063	63005	100552	50000000	50001500	BBK FILIALE FRANKFURT MAIN	50550020	493	STE SPK OFFENBACH	Mo, Di u. Do 7:30-15:30, Mi 13:00-18:00, Fr 7:30-12:00 Uhr	poststelle@Finanzamt-Offenbach-Land.de	www.Finanzamt-Offenbach.de	204
6	2645	Frankfurt am Main III 	Gutleutstraße 120	60327	Frankfurt	069/2545-03	069/2545-3999		60305	110863	50000000	50001504	BBK FILIALE FRANKFURT MAIN	50050000	1600006	LD BK HESS-THUER GZ FFM	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Frankfurt-3.de	wwww.Finanzamt-Frankfurt-am-Main.de	205
6	2646	Hofheim am Taunus 	Nordring 4 - 10	65719	Hofheim	06192/960-0	06192/960-412	65717	65703	1380	50000000	50001503	BBK FILIALE FRANKFURT MAIN	51250000	2000008	TAUNUS-SPARKASSE BAD HOMBG	Mo-Mi 8:00-15:30, Do 13:30-18:00, Fr 8:00-12:00 Uhr	poststelle@Finanzamt-Hofheim-am-Taunus.de	www.Finanzamt-Hofheim-am-Taunus.de	206
6	2647	Frankfurt/M. V-Höchst Verwaltungsstelle Frankfurt	Gutleutstraße 116	60327	Frankfurt	069/2545-05	069/2545-5999		60305	110865	50000000	50001504	BBK FILIALE FRANKFURT MAIN	50050000	1600006	LD BK HESS-THUER GZ FFM	Mo u. Mi 8:00-12:00, Do 14:00-18:00 Uhr	poststelle@Finanzamt-Frankfurt-5-Hoechst.de	www.Finanzamt-Frankfurt-am-Main.de	207
7	2701	Bad Neuenahr-Ahrweiler 	Römerstr. 5	53474	Bad Neuenahr-Ahrweiler	02641/3820	02641/38212000		53457	1209	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-aw.fin-rlp.de		208
7	2702	Altenkirchen-Hachenburg 	Frankfurter Str. 21	57610	Altenkirchen	02681/860	02681/8610090	57609	57602	1260	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ak.fin-rlp.de	www.finanzamt-altenkirchen-hachenburg.de	209
7	2703	Bingen-Alzey Aussenstelle Alzey	Rochusallee 10	55411	Bingen	06721/7060	06721/70614080	55409	55382		55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06731/4000	Poststelle@fa-bi.fin-rlp.de	www.finanzamt-bingen-alzey.de	210
7	2706	Bad Kreuznach 	Ringstr. 10	55543	Bad Kreuznach	0671/7000	0671/70011702	55541	55505	1552	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-kh.fin-rlp.de	www.finanzamt-bad-kreuznach.de	211
7	2707	Bernkastel-Wittlich Aussenstelle Bernkastel-Kues	Unterer Sehlemet 15	54516	Wittlich	06571/95360	06571/953613400		54502	1240	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06531/5060	Poststelle@fa-wi.fin-rlp.de	www.finanzamt-bernkastel-wittlich.de	212
7	2708	Bingen-Alzey 	Rochusallee 10	55411	Bingen	06721/7060	06721/70614080	55409	55382		55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-bi.fin-rlp.de	www.finanzamt-bingen-alzey.de	213
7	2709	Idar-Oberstein 	Hauptstraße 199	55743	Idar-Oberstein	06781/680	06781/6818333		55708	11820	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-io.fin-rlp.de	www.finanzamt-idar-oberstein.de	214
7	2710	Bitburg-Prüm 	Kölner Straße 20	54634	Bitburg	06561/6030	06561/60315090		54622	1252	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-bt.fin-rlp.de	www.finanzamt-bitburg-pruem.de	215
7	2713	Daun 	Berliner Straße 1	54550	Daun	06592/95790	06592/957916175		54542	1160	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-da.fin-rlp.de	www.finanzamt-daun.de	216
7	2714	Montabaur-Diez Aussenstelle Diez	Koblenzer Str. 15	56410	Montabaur	02602/1210	02602/12127099	56409	56404	1461	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06432/5040	Poststelle@fa-mt.fin-rlp.de	www.finanzamt-montabaur-diez.de	217
7	2715	Frankenthal 	Friedrich-Ebert-Straße 6	67227	Frankenthal	06233/49030	06233/490317082	67225	67203	1324	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ft.fin-rlp.de	www.finanzamt-frankenthal.de	218
7	2716	Speyer-Germersheim Aussenstelle Germersheim	Johannesstr. 9-12	67346	Speyer	06232/60170	06232/601733431	67343	67323	1309	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 07274/9500	Poststelle@fa-sp.fin-rlp.de	www.finanzamt-speyer-germersheim.de	219
7	2718	Altenkirchen-Hachenburg Aussenstelle Hachenburg	Frankfurter Str. 21	57610	Altenkirchen	02681/860	02681/8610090	57609	57602	1260	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 02662/94520	Poststelle@fa-ak.fin-rlp.de	www.finanzamt-altenkirchen-hachenburg.de	220
7	2719	Kaiserslautern 	Eisenbahnstr. 56	67655	Kaiserslautern	0631/36760	0631/367619500	67653	67621	3360	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-kl.fin-rlp.de	www.finanzamt-kaiserslautern.de	221
7	2721	Worms-Kirchheimbolanden Aussenstelle Kirchheimbolanden	Karlsplatz 6	67549	Worms	06241/30460	06241/304635060	67545			55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06352/4070	Poststelle@fa-wo.fin-rlp.de	www.finanzamt-worms-kirchheimbolanden.de	222
7	2722	Koblenz 	Ferdinand-Sauerbruch-Str. 19	56073	Koblenz	0261/49310	0261/493120090	56060	56007	709	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ko.fin-rlp.de	www.finanzamt-koblenz.de	223
7	2723	Kusel-Landstuhl 	Trierer Str. 46	66869	Kusel	06381/99670	06381/996721060		66864	1251	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ku.fin-rlp.de	www.finanzamt-kusel-landstuhl.de	224
7	2724	Landau 	Weißquartierstr. 13	76829	Landau	06341/9130	06341/91322100	76825	76807	1760u.1780	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ld.fin-rlp.de		225
7	2725	Kusel-Landstuhl Aussenstelle Landstuhl	Trierer Str. 46	66869	Kusel	06381/99670	06381/996721060		66864	1251	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06371/61730	Poststelle@fa-ku.fin-rlp.de	www.finanzamt-kusel-landstuhl.de	226
7	2726	Mainz-Mitte 	Schillerstr. 13	55116	Mainz	06131/2510	06131/25124090		55009	1980	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-mz.fin-rlp.de	www.finanzamt-mainz-mitte.de	227
7	2727	Ludwigshafen 	Bayernstr. 39	67061	Ludwigshafen	0621/56140	0621/561423051		67005	210507	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-lu.fin-rlp.de	www.finanzamt-ludwigshafen.de	228
7	2728	Mainz-Süd 	Emy-Roeder-Str. 3	55129	Mainz	06131/5520	06131/55225272		55071	421365	55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ms.fin-rlp.de	www.finanzamt-mainz-sued.de	229
7	2729	Mayen 	Westbahnhofstr. 11	56727	Mayen	02651/70260	02651/702626090		56703	1363	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-my.fin-rlp.de	www.finanzamt-mayen.de	230
7	2730	Montabaur-Diez 	Koblenzer Str. 15	56410	Montabaur	02602/1210	02602/12127099	56409	56404	1461	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-mt.fin-rlp.de	www.finanzamt-montabaur-diez.de	231
7	2731	Neustadt 	Konrad-Adenauer-Str. 26	67433	Neustadt	06321/9300	06321/93028600	67429	67404	100 465	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-nw.fin-rlp.de		232
7	2732	Neuwied 	Augustastr. 54	56564	Neuwied	02631/9100	02631/91029906	56562	56505	1561	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-nr.fin-rlp.de		233
7	2735	Pirmasens-Zweibrücken 	Kaiserstr. 2	66955	Pirmasens	06331/7110	06331/71130950	66950	66925	1662	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-ps.fin-rlp.de	www.finanzamt-pirmasens-zweibruecken.de	234
7	2736	Bitburg-Prüm Aussenstelle Prüm	Kölner Str. 20	54634	Bitburg	06561/6030	06561/60315093		54622	1252	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06551/9400	Poststelle@fa-bt.fin-rlp.de	www.finanzamt-bitburg-pruem.de	235
7	2738	Sankt Goarshausen-Sankt Goar Aussenstelle Sankt Goar	Wellmicher Str. 79	56346	St. Goarshausen	06771/95900	06771/959031090		56342		55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06741/98100	Poststelle@fa-gh.fin-rlp.de	www.finanzamt-sankt-goarshausen-sankt-goar.de	236
7	2739	Sankt Goarshausen-Sankt Goar 	Wellmicher Str. 79	56346	St. Goarshausen	06771/95900	06771/959031090		56342		55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-gh.fin-rlp.de	www.finanzamt-sankt-goarshausen-sankt-goar.de	237
7	2740	Simmern-Zell 	Brühlstraße 3	55469	Simmern	06761/8550	06761/85532053		55464	440	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-si.fin-rlp.de		238
7	2741	Speyer-Germersheim 	Johannesstr. 9-12	67346	Speyer	06232/60170	06232/601733431	67343	67323	1309	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-sp.fin-rlp.de	www.finanzamt-speyer-germersheim.de	239
7	2742	Trier 	Hubert-Neuerburg-Str. 1	54290	Trier	0651/93600	0651/936034900		54207	1750u.1760	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-tr.fin-rlp.de	www.finanzamt-trier.de	240
7	2743	Bernkastel-Wittlich 	Unterer Sehlemet 15	54516	Wittlich	06571/95360	06571/953613400		54502	1240	55050000	902	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-wi.fin-rlp.de	www.finanzamt-bernkastel-wittlich.de	241
7	2744	Worms-Kirchheimbolanden 	Karlsplatz 6	67549	Worms	06241/30460	06241/304635060	67545			55050000	901	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR	Poststelle@fa-wo.fin-rlp.de	www.finanzamt-worms-kirchheimbolanden.de	242
7	2745	Simmern-Zell Aussenstelle Zell	Brühlstr. 3	55469	Simmern	06761/8550	06761/85532053		55464	440	55050000	908	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06542/7090	Poststelle@fa-si.fin-rlp.de		243
7	2746	Pirmasens-Zweibrücken Aussenstelle Zweibrücken	Kaiserstr. 2	66955	Pirmasens	06331/7110	06331/71130950	66950	66925	1662	55050000	910	LRP GZ MAINZ				8.00-17.00 MO-MI 8.00-18.00 DO 8.00-13.00 FR Telefon-Nr. Aussenstelle: 06332/80680	Poststelle@fa-ps.fin-rlp.de	www.finanzamt-pirmasens-zweibruecken.de	244
8	2801	Achern 	Allerheiligenstr. 10	77855	Achern	07841/6940	07841/694136	77843	77843	1260	66000000	66001518	BBK KARLSRUHE	66450050	88013009	SPARKASSE OFFENBURG-ORTENAU	MO-DO 8-12.30+13.30-15.30,DO-17.30,FR 8-12 H	poststelle@fa-achern.fv.bwl.de		245
8	2804	Donaueschingen 	Käferstr. 25	78166	Donaueschingen	0771/8080	0771/808359	78153	78153	1269	69400000	694 01501	BBK VILLINGEN-SCHWENNINGEN	69421020	6204700600	BW BANK DONAUESCHINGEN	MO-MI 8-16 UHR, DO 8-17.30 UHR, FR 8-12 UHR	poststelle@fa-donaueschingen.fv.bwl.de		246
8	2805	Emmendingen 	Bahnhofstr. 3	79312	Emmendingen	07641/4500	07641/450350	79305	79305	1520	68000000	680 01507	BBK FREIBURG IM BREISGAU	68050101	20066684	SPK FREIBURG-NOERDL BREISGA	MO-MI 7:30-15:30,DO 7:30-17:00,FR 7:30-12:00	poststelle@fa-emmendingen.fv.bwl.de		247
8	2806	Freiburg-Stadt 	Sautierstr. 24	79104	Freiburg	0761/2040	0761/2043295	79079			68000000	680 01501	BBK FREIBURG IM BREISGAU	68020020	4402818100	BW BANK FREIBURG BREISGAU	MO, DI, DO 7.30-16,MI 7.30-17.30, FR 7.30-12	poststelle@fa-freiburg-stadt.fv.bwl.de		248
8	2808	Kehl 	Ludwig-Trick-Str. 1	77694	Kehl	07851/8640	07851/864108	77676	77676	1640	66400000	664 01501	BBK FREIBURG EH OFFENBURG	66451862	-6008	SPK HANAUERLAND KEHL	MO,DI,MI 7.45-15.30, DO -17.30, FR -12.00UHR	poststelle@fa-kehl.fv.bwl.de		249
8	2809	Konstanz 	Bahnhofplatz 12	78462	Konstanz	07531/2890	07531/289312	78459			69400000	69001500	BBK VILLINGEN-SCHWENNINGEN	69020020	6604947900	BW BANK KONSTANZ	MO,DI,DO 7.30-15.30,MI 7.30-17.00,FR 7.30-12	poststelle@fa-konstanz.fv.bwl.de		250
8	2810	Lahr 	Gerichtstr. 5	77933	Lahr	07821/2830	07821/283100		77904	1466	66000000	66001527	BBK KARLSRUHE	66450050	76103333	SPARKASSE OFFENBURG-ORTENAU	MO,DI,DO 7:30-16:00, MI 7:30-17:30, FR 7:30-12:00	poststelle@fa-lahr.fv.bwl.de		251
8	2811	Lörrach 	Luisenstr. 10 a	79539	Lörrach	07621/1730	07621/173245	79537			68000000	68301500	BBK FREIBURG IM BREISGAU	68320020	4602600100	BW BANK LOERRACH	MO-MI 7.00-15.30/DO 7.00-17.30/FR 7.00-12.00	poststelle@fa-loerrach.fv.bwl.de		252
8	2812	Müllheim 	Goethestr. 11	79379	Müllheim	07631/18900	(07631)189-190	79374	79374	1461	68000000	680 01511	BBK FREIBURG IM BREISGAU	68351865	802 888 8	SPARKASSE MARKGRAEFLERLAND	MO-MI 7,30-15,30 DO 7,30-17,30 FR 7,30-12,00	poststelle@fa-muellheim.fv.bwl.de		253
8	2813	Titisee-Neustadt 	Goethestr. 5	79812	Titisee-Neustadt	07651/2030	07651/203110		79812	12 69	68000000	680 015 10	BBK FREIBURG IM BREISGAU	68051004	4040408	SPK HOCHSCHWARZWALD T-NEUST	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.30	poststelle@fa-titisee-neustadt.fv.bwl.de		254
8	2814	Offenburg 	Zeller Str. 1- 3	77654	Offenburg	0781/9330	0781/9332444	77604	77604	1440	68000000	664 01500	BBK FREIBURG IM BREISGAU	66420020	4500000700	BW BANK OFFENBURG	MO-DO 7.30-15.30 DURCHGEHEND,MI -18.00,FR-12	poststelle@fa-offenburg.fv.bwl.de		255
8	2815	Oberndorf 	Brandeckerstr. 4	78727	Oberndorf	07423/8150	07423/815107	78721	78721	1240	69400000	694 01506	BBK VILLINGEN-SCHWENNINGEN	64250040	813 015	KR SPK ROTTWEIL	ZIA:MO,DI,DO 8-16,MI 8-17:30,FR 8-12 UHR	poststelle@fa-oberndorf.fv.bwl.de		256
8	2816	Bad Säckingen 	Werderstr. 5	79713	Bad Säckingen	07761/5660	07761/566126	79702	79702	1148	68000000	683 015 02	BBK FREIBURG IM BREISGAU				MO,DI,DO 8-15.30, MI 8-17.30, FR 8-12 UHR	poststelle@fa-badsaeckingen.fv.bwl.de		257
8	2818	Singen 	Alpenstr. 9	78224	Singen	07731/8230	07731/823650		78221	380	69000000	69001507	BBK VILL-SCHWEN EH KONSTANZ	69220020	6402000100	BW BANK SINGEN	MO-DO 7:30-15:30, MI bis 17:30, FR 7:30-12:00	poststelle@fa-singen.fv.bwl.de		258
8	2819	Rottweil 	Körnerstr. 28	78628	Rottweil	0741/2430	0741/2432194	78612	78612	1252	69400000	69401505	BBK VILLINGEN-SCHWENNINGEN	64250040	136503	KR SPK ROTTWEIL	MO-MI 8-16, DO 8-18, FR 8-12 UHR	poststelle@fa-rottweil.fv.bwl.de		259
8	2820	Waldshut-Tiengen 	Bahnhofstr. 11	79761	Waldshut-Tiengen	07741/6030	07741/603213	79753	79753	201360	68000000	68301501	BBK FREIBURG IM BREISGAU	68452290	14449	SPARKASSE HOCHRHEIN	MO-MI 8-15.30,DO 8-17.30,FR 8-12 UHR	poststelle@fa-waldshut-tiengen.fv.bwl.de		260
8	2821	Tuttlingen 	Zeughausstr. 91	78532	Tuttlingen	07461/980	07461/98303		78502	180	69400000	69401502	BBK VILLINGEN-SCHWENNINGEN	64350070	251	KR SPK TUTTLINGEN	MO-MI8-15.30,DO8-17.30,FR8-12.00UHR	poststelle@fa-tuttlingen.fv.bwl.de		261
8	2822	Villingen-Schwenningen 	Weiherstr. 7	78050	Villingen-Schwenningen	07721/923-0	07721/923-100	78045			69400000	69401500	BBK VILLINGEN-SCHWENNINGEN				MO-MI 8-16UHR,DO 8-17.30UHR,FR 8-12UHR	poststelle@fa-villingen-schwenningen.fv.bwl.de		262
8	2823	Wolfach 	Hauptstr. 55	77709	Wolfach	07834/9770	07834/977-169	77705	77705	1160	66400000	664 01502	BBK FREIBURG EH OFFENBURG	66452776	-31956	SPK WOLFACH	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.00	poststelle@fa-wolfach.fv.bwl.de		263
8	2830	Bruchsal 	Schönbornstr. 1-5	76646	Bruchsal	07251/740	07251/742111	76643	76643	3021	66000000	66001512	BBK KARLSRUHE	66350036	50	SPK KRAICHGAU	SERVICEZENTRUM:MO-MI8-15:30DO8-17:30FR8-1200	poststelle@fa-bruchsal.fv.bwl.de		264
8	2831	Ettlingen 	Pforzheimer Str. 16	76275	Ettlingen	07243/5080	07243/508295	76257	76257	363	66000000	66001502	BBK KARLSRUHE	66051220	1043009	SPARKASSE ETTLINGEN	MO+DI 8-15.30,MI 7-15.30,DO 8-17.30,FR 8-12	poststelle@fa-ettlingen.fv.bwl.de		265
8	2832	Heidelberg 	Kurfürsten-Anlage 15-17	69115	Heidelberg	06221/590	06221/592355	69111			67000000	67001510	BBK MANNHEIM	67220020	5302059000	BW BANK HEIDELBERG	ZIA:MO-DO 7.30-15.30, MI - 17.30, FR - 12.00	poststelle@fa-heidelberg.fv.bwl.de		266
8	2833	Baden-Baden 	Stephanienstr. 13 + 15	76530	Baden-Baden	07221/3590	07221/359320	76520			66000000	66001516	BBK KARLSRUHE	66220020	4301111300	BW BANK BADEN-BADEN	MO,DI,DO 8-16 UHR,MI 8-17.30 UHR,FR 8-12 UHR	poststelle@fa-baden-baden.fv.bwl.de		267
8	2834	Karlsruhe-Durlach 	Prinzessenstr. 2	76227	Karlsruhe	0721/9940	0721/9941235	76225	76203	410326	66000000	66001503	BBK KARLSRUHE				MO-DO 8-15.30,MI 8-17.30,FR 8-12	poststelle@fa-karlsruhe-durlach.fv.bwl.de		268
8	2835	Karlsruhe-Stadt 	Schlossplatz 14	76131	Karlsruhe	0721/1560	(0721) 156-1000				66000000	66001501	BBK KARLSRUHE	66020020	4002020800	BW BANK KARLSRUHE	MO-DO 7.30-15.30 MI -17.30 FR 7.30-12.00	poststelle@fa-karlsruhe-stadt.fv.bwl.de		269
8	2836	Bühl 	Alban-Stolz-Str. 8	77815	Bühl	07223/8030	07223/3625	77815			66000000	66001525	BBK KARLSRUHE	66220020	4301111300	BW BANK BADEN-BADEN	MO,DI,DO=8-16UHR, MI=8-17.30UHR,FR=8-12UHR	poststelle@fa-buehl.fv.bwl.de		270
8	2837	Mannheim-Neckarstadt 	L3, 10	68161	Mannheim	0621/2920	0621/292-1010	68150			67000000	67001500	BBK MANNHEIM	67020020	5104719900	BW BANK MANNHEIM	MO,DI,DO7.30-15.30,MI7.30-17.30,FR7.30-12.00	poststelle@fa-mannheim-neckarstadt.fv.bwl.de		271
8	2838	Mannheim-Stadt 	L3, 10	68161	Mannheim	0621/2920	2923640	68150			67000000	670 01500	BBK MANNHEIM	67020020	5104719900	BW BANK MANNHEIM	MO,DI,DO7.30-15.30,MI7.30.17.30,FR7.30-12.00	poststelle@fa-mannheim-stadt.fv.bwl.de		272
8	2839	Rastatt 	An der Ludwigsfeste 3	76437	Rastatt	07222/9780	07222/978330	76404	76404	1465	66000000	66001519	BBK KARLSRUHE	66020020	4150199000	BW BANK KARLSRUHE	MO-MI 8-15:30 UHR,DO 8-17:30 UHR,FR 8-12 UHR	poststelle@fa-rastatt.fv.bwl.de		273
8	2840	Mosbach 	Pfalzgraf-Otto-Str. 5	74821	Mosbach	06261/8070	06261/807200	74819			62000000	62001502	BBK HEILBRONN, NECKAR	62030050	5501964000	BW BANK HEILBRONN	MO-DO 08.00-16.00 UHR, DO-17.30,FR-12.00 UHR	poststelle@fa-mosbach.fv.bwl.de		274
8	2841	Pforzheim 	Moltkestr. 8	75179	Pforzheim	07231/1830	(07231)183-1111	75090			66000000	66001520	BBK KARLSRUHE	66620020	4812000000	BW BANK PFORZHEIM	MO-DO 7:30-15:30, DO bis 17:30, FR 7:30-12:00	poststelle@fa-pforzheim.fv.bwl.de		275
8	2842	Freudenstadt 	Musbacher Str. 33	72250	Freudenstadt	07441/560	07441/561011				66000000	66001510	BBK KARLSRUHE	64251060	19565	KR SPK FREUDENSTADT	MO-MI 8.00-16.00,DO 8.00-17.30,FR 8.00-12.00	poststelle@fa-freudenstadt.fv.bwl.de		276
8	2843	Schwetzingen 	Schloss	68723	Schwetzingen	06202/810	(06202) 81298	68721			67000000	67001501	BBK MANNHEIM	67250020	25008111	SPK HEIDELBERG	ZIA:MO-DO 7.30-15.30,MI-17.30,FR.7.30-12.00	poststelle@fa-schwetzingen.fv.bwl.de		277
8	2844	Sinsheim 	Bahnhofstr. 27	74889	Sinsheim	07261/6960	07261/696444	74887			67000000	67001511	BBK MANNHEIM				MO-DO 7:30-15:30, MI bis 17:30, FR 7:30-12 UHR	poststelle@fa-sinsheim.fv.bwl.de		278
8	2845	Calw 	Klosterhof 1	75365	Calw	07051/5870	07051/587111	75363			66000000	66001521	BBK KARLSRUHE	60651070	1996	SPARKASSE PFORZHEIM CALW	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.00	poststelle@fa-calw.fv.bwl.de		279
8	2846	Walldürn 	Albert-Schneider-Str. 1	74731	Walldürn	06282/7050	06282/705101	74723	74723	1162	62000000	62001509	BBK HEILBRONN, NECKAR	67450048	8102204	SPK NECKARTAL-ODENWALD	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.00	poststelle@fa-wallduern.fv.bwl.de		280
8	2847	Weinheim 	Weschnitzstr. 2	69469	Weinheim	06201/6050	(06201) 605-220/299 	69443	69443	100353	67000000	67001502	BBK MANNHEIM	67050505	63034444	SPK RHEIN NECKAR NORD	MO-MI 7.30-15.30 DO 7.30-17.30 FR 7.30-12	poststelle@fa-weinheim.fv.bwl.de		281
8	2848	Mühlacker 	Konrad-Adenauer-Platz 6	75417	Mühlacker	07041/8930	07041/893999		75415	1153	66000000	660 015 22	BBK KARLSRUHE	66650085	961 000	SPARKASSE PFORZHEIM CALW	ZIA:MO-DO 8-12:30 13:30-15:30 DO bis 17:30 FR 8-12	poststelle@fa-muehlacker.fv.bwl.de		282
8	2849	Neuenbürg 	Wildbader Str. 107	75305	Neuenbürg	07082/7990	07082/799166	75301	75301	1165	66600000	66601503	BBK PFORZHEIM	66650085	998400	SPARKASSE PFORZHEIM CALW	MO-FR 7.30-12UHR,MO-MI 13-16UHR,DO 13-18UHR	poststelle@fa-neuenbuerg.fv.bwl.de		283
8	2850	Aalen / Württemberg 	Bleichgartenstr. 17	73431	Aalen	(07361) 9578-0	(07361)9578-440	73428			63000000	614 01500	BBK ULM, DONAU	61450050	110036902	KREISSPARKASSE OSTALB	MO-MI 7.30-16.00,DO 7.30-18.00,FR 7.30-12.00	poststelle@fa-aalen.fv.bwl.de		284
8	2851	Backnang 	Stiftshof 20	71522	Backnang	07191/120	07191/12221	71522			60000000	60201501	BBK STUTTGART	60250010	244	KR SPK WAIBLINGEN	MO,DI,DO7.30-16.00MI7.30-18.00FR7.30-12.00	poststelle@fa-backnang.fv.bwl.de		285
8	2852	Bad Mergentheim 	Schloss 7	97980	Bad Mergentheim	07931/5300	07931/530228	97962	97962	1233	62000000	620 01508	BBK HEILBRONN, NECKAR	67352565	25866	SPK TAUBERFRANKEN	MO-DO 7.30-15.30,MI-17.30 UHR,FR 7.30-12 UHR	poststelle@fa-badmergentheim.fv.bwl.de		286
8	2853	Balingen 	Jakob-Beutter-Str. 4	72336	Balingen	07433/970	07433/972099	72334			64000000	653 01500	BBK REUTLINGEN	65351260	24000110	SPK ZOLLERNALB	Mo-Mi 7:45-16:00,Do 7:45-17:30,Fr 7:45-12:30	poststelle@fa-balingen.fv.bwl.de		287
8	2854	Biberach 	Bahnhofstr. 11	88400	Biberach	07351/590	07351/59202	88396			63000000	63001508	BBK ULM, DONAU	65450070	17	KR SPK BIBERACH	MO,DI,DO 8-15.30, MI 8-17.30, FR 8-12 UHR	poststelle@fa-biberach.fv.bwl.de		288
8	2855	Bietigheim-Bissingen 	Kronenbergstr. 13	74321	Bietigheim-Bissingen	07142/5900	07142/590199	74319			60000000	604 01501	BBK STUTTGART	60490150	427500001	VOLKSBANK LUDWIGSBURG	MO-MI(DO)7.30-15.30(17.30),FR 7.30-12.00 UHR	poststelle@fa-bietigheim-bissingen.fv.bwl.de		289
8	2856	Böblingen 	Talstr. 46	71034	Böblingen	(07031)13-01	07031/13-3200	71003	71003	1307	60300000	603 01500	BBK STUTTGART EH SINDELFING	60350130	220	KR SPK BOEBLINGEN	MO-MI 7.30-15.30,DO7.30-17.30,FR7.30-12.30	poststelle@fa-boeblingen.fv.bwl.de		290
8	2857	Crailsheim 	Schillerstr. 1	74564	Crailsheim	07951/4010	07951/401220	74552	74552	1252	62000000	620 01506	BBK HEILBRONN, NECKAR	62250030	282	SPARKASSE SCHWAEBISCH HALL	MO-DO:7.45-16.00,MI:-17.30,FR:7.45-12.30	poststelle@fa-crailsheim.fv.bwl.de		291
8	2858	Ehingen 	Hehlestr. 19	89584	Ehingen	07391/5080	07391/508260	89572	89572	1251	63000000	630 01502	BBK ULM, DONAU	63050000	9 300 691	SPARKASSE ULM	Mo-Mi 7.30-15.30,Do 7.30-17.30,Fr 7.30-12.00	poststelle@fa-ehingen.fv.bwl.de		292
8	2859	Esslingen 	Entengrabenstr. 11	73728	Esslingen	0711/39721	0711/3972400	73726			61100000	61101500	BBK STUTTGART EH ESSLINGEN	61150020	902139	KR SPK ESSLINGEN-NUERTINGEN	Infothek Mo-Mi 7-15.30,Do-17.30, Fr 7-12 Uhr	poststelle@fa-esslingen.fv.bwl.de		293
8	2861	Friedrichshafen 	Ehlersstr. 13	88046	Friedrichshafen	07541/7060	07541/706111	88041			63000000	65001504	BBK ULM, DONAU				MO-MI 8-15.30, DO 8-17.30, FR 8-12.30 Uhr	poststelle@fa-friedrichshafen.fv.bwl.de		294
8	2862	Geislingen 	Schillerstr. 2	73312	Geislingen	07331/220	07331/22200	73302	73302	1253	60000000	61101504	BBK STUTTGART	61050000	6007203	KR SPK GOEPPINGEN	Mo-Mi 7-15:30, Do 7-17:30,Fr 7-12	poststelle@fa-geislingen.fv.bwl.de		295
8	2863	Göppingen 	Gartenstr. 42	73033	Göppingen	07161/63-0	07161/632935		73004	420	60000000	61101503	BBK STUTTGART	61050000	1 023	KR SPK GOEPPINGEN	MO-MI.7-15.30 Uhr,DO.7-17.30 Uhr,FR.7-12 Uhr	poststelle@fa-goeppingen.fv.bwl.de		296
8	2864	Heidenheim 	Marienstr. 15	89518	Heidenheim	07321/380	07321/381528	89503	89503	1320	63000000	61401505	BBK ULM, DONAU	63250030	880433	KR SPK HEIDENHEIM	Mo-Mi 7.30-15.30 Do 7.30-17.30 Fr 7.30-12.30	poststelle@fa-heidenheim.fv.bwl.de		297
8	2865	Heilbronn 	Moltkestr. 91	74076	Heilbronn	07131/1041	07131/1043000	74064			62000000	620 01500	BBK HEILBRONN, NECKAR	62050000	123925	KR SPK HEILBRONN	Mo,Di,Do7:30-15:30,Mi7:30-17:30,Fr7:30-12:00	poststelle@fa-heilbronn.fv.bwl.de		298
8	2869	Kirchheim 	Alleenstr. 120	73230	Kirchheim	07021/5750	575258	73220	73220	1241	61100000	61101501	BBK STUTTGART EH ESSLINGEN	61150020	48317054	KR SPK ESSLINGEN-NUERTINGEN	KUNDENCENTER MO-MI 8-15.30,DO 8-17.30,FR8-12	poststelle@fa-kirchheim.fv.bwl.de		299
8	2871	Ludwigsburg 	Alt-Württ.-Allee 40 (Neubau)	71638	Ludwigsburg	07141/180	07141/182105	71631			60000000	604 01500	BBK STUTTGART	60450050	7 759	KREISSPARKASSE LUDWIGSBURG	MO-MI 8-15.30,DO 8-18.00,FR 8-12.00	poststelle@fa-ludwigsburg.fv.bwl.de		301
8	2874	Nürtingen 	Sigmaringer Str. 15	72622	Nürtingen	07022/7090	07022/709-120	72603	72603	1309	60000000	61101502	BBK STUTTGART				MO-Mi 7.30-15.30 Do 7.30-17.30 Fr 7.30-12.00	poststelle@fa-nuertingen.fv.bwl.de		302
8	2876	Öhringen 	Haagweg 39	74613	Öhringen	07941/6040	07941/604400	74611			62000000	62001501	BBK HEILBRONN, NECKAR	62251550	40008	SPARKASSE HOHENLOHEKREIS	MO-DO 7.30-16.00UhrFR 7.30-12.00 Uhr	poststelle@fa-oehringen.fv.bwl.de		303
8	2877	Ravensburg 	Broner Platz 12	88250	Weingarten	0751/4030	403-303	88248			65000000	650 015 00	BBK ULM EH RAVENSBURG	65050110	86 500 500	KR SPK RAVENSBURG	Mo,Di,Do 8-15.30Uhr,ZIA Mi 8-17.30,Fr8-12Uhr	poststelle@fa-ravensburg.fv.bwl.de		304
8	2878	Reutlingen 	Leonhardsplatz 1	72764	Reutlingen	07121/9400	07121/9401002	72705	72705	1543	64000000	64001500	BBK REUTLINGEN	64050000	64 905	KR SPK REUTLINGEN	Mo-Mi 7-15.30, Do 7-17.30, Fr 7-12.00 Uhr	poststelle@fa-reutlingen.fv.bwl.de		305
8	2879	Riedlingen 	Kirchstr. 30	88499	Riedlingen	07371/1870	07371/1871000	88491	88491	1164	63000000	63001509	BBK ULM, DONAU	65450070	400 600	KR SPK BIBERACH	INFOST. MO-MI 7.30-15.30,DO-17.30,FR-12 UHR	poststelle@fa-riedlingen.fv.bwl.de		306
8	2880	Tauberbischofsheim 	Dr.-Burger-Str. 1	97941	Tauberbischofsheim	09341/8040	09341/804244	97933	97933	1340	62000000	620 01507	BBK HEILBRONN, NECKAR	67332551	8282661100	BW BANK TAUBERBISCHOFSHEIM	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.00	poststelle@fa-tauberbischofsheim.fv.bwl.de		307
8	2881	Bad Saulgau 	Schulstr. 5	88348	Bad Saulgau	07581/504-0	07581/504499	88341	88341	1255	65000000	650 01501	BBK ULM EH RAVENSBURG	65351050	210058	LD BK KR SPK SIGMARINGEN	MO,DO,FR 8-12,DO 13.30-15.30UHR	poststelle@fa-badsaulgau.fv.bwl.de		308
8	2882	Schorndorf 	Johann-Philipp-Palm-Str. 28	73614	Schorndorf	07181/6010	07181/601499	73603	73603	1320	60000000	60201502	BBK STUTTGART	60250010	5014008	KR SPK WAIBLINGEN	MO,DI,DO 8-15.30,MI 8-17.30,FR 8-12.00	poststelle@fa-schorndorf.fv.bwl.de		309
8	2883	Schwäbisch Gmünd 	Augustinerstr. 6	73525	Schwäbisch Gmünd	(07171) 602-0	07171/602266	73522			63000000	61401501	BBK ULM, DONAU	61450050	440066604	KREISSPARKASSE OSTALB	MO,DI,DO 8-15.30 MI 8-17.30 FR 8-12.00 UHR	poststelle@fa-schwaebischgmuend.fv.bwl.de		310
8	2884	Schwäbisch Hall 	Bahnhofstr. 25	74523	Schwäbisch Hall	0791/752-0	0791/7521115	74502	74502	100260	62000000	62001503	BBK HEILBRONN, NECKAR	62250030	5070 011	SPARKASSE SCHWAEBISCH HALL	MO-MI 7.30-16.00 DO 7.30-17.30 FR 7.30-12.00	poststelle@fa-schwaebischhall.fv.bwl.de		311
8	2885	Sigmaringen 	Karlstr. 31	72488	Sigmaringen	07571/1010	07571/101300	72481	72481	1250	65300000	653 01501	BBK REUTLINGEN EH ALBSTADT	65351050	808 408	LD BK KR SPK SIGMARINGEN	MO-MI 7.45-15.30,DO 7.45-17.30,FR 7.45-12.00	poststelle@fa-sigmaringen.fv.bwl.de		312
8	2886	Tübingen 	Steinlachallee 6 - 8	72072	Tübingen	07071/7570	07071/7574500	72005	72005	1520	64000000	64001505	BBK REUTLINGEN				Mo-Do 7.30-15.30,Mi -17.30,Fr 7.30-13.00 Uhr	poststelle@fa-tuebingen.fv.bwl.de		313
8	2887	Überlingen (Bodensee) 	Mühlenstr. 28	88662	Überlingen	07551/8360	07551/836299	88660			69400000	69001501	BBK VILLINGEN-SCHWENNINGEN	69220020	6426155500	BW BANK SINGEN	Mo-Mi 8.00-15.30,Do 8.00-17.30,Fr 8.00-12.00	poststelle@fa-ueberlingen.fv.bwl.de		314
8	2888	Ulm 	Wagnerstr. 2	89077	Ulm	0731/1030	0731/103800		89008	1860	63000000	63001500	BBK ULM, DONAU	63050000	30001	SPARKASSE ULM	MO-MI 7.30-15.30,DO 7.30-17.30,FR 7.30-12.00	poststelle@fa-ulm.fv.bwl.de		315
8	2889	Bad Urach 	Graf-Eberhard-Platz 7	72574	Bad Urach	07125/1580	(07125)158-300	72562	72562	1149	64000000	640 01501	BBK REUTLINGEN	64050000	300 346	KR SPK REUTLINGEN	MO-MI 7.30-15.30 DO 7.30-17.30 FR 7.30-12.00	poststelle@fa-badurach.fv.bwl.de		316
8	2890	Waiblingen 	Fronackerstr. 77	71332	Waiblingen	07151/9550	07151/955200	71328			60000000	602 01500	BBK STUTTGART	60250010	200 398	KR SPK WAIBLINGEN	INFOTHEK MO-DO 7.30-15.30,MI-17.30,FR-12.00	poststelle@fa-waiblingen.fv.bwl.de		317
8	2891	Wangen 	Lindauer Str.37	88239	Wangen	07522/710	07522(714000)	88228	88228	1262	63000000	650 01502	BBK ULM, DONAU	65050110	218 153	KR SPK RAVENSBURG	MO-MI 8-15.30, DO 8-17.30, FR 8-12 UHR	poststelle@fa-wangen.fv.bwl.de		318
8	2892	Stuttgart IV 	Seidenstr.23	70174	Stuttgart	0711/66730	0711/66736060	70049	70049	106052	60000000	600 01503	BBK STUTTGART	60050101	2 065 854	LANDESBANK BADEN-WUERTT	MO,MI,FR 8-12,MI 13.30-16 UHR	poststelle@fa-stuttgart4.fv.bwl.de		319
8	2893	Stuttgart I 	Rotebühlplatz 30	70173	Stuttgart	0711/66730	6673 - 5010	70049	70049	106055	60000000	600 01503	BBK STUTTGART	60050101	2 065 854	LANDESBANK BADEN-WUERTT	Mo,Die,Do: 8-15.30, Mi: 8-17.30, Fr: 8-12.00	poststelle@fa-stuttgart1.fv.bwl.de		320
8	2895	Stuttgart II 	Rotebühlstr. 40	70178	Stuttgart	0711/66730	0711/66735610				60000000	60001503	BBK STUTTGART	60050101	2065854	LANDESBANK BADEN-WUERTT	MO-DO:8-15.30 FR:8-12 MI:15.30-17.30	poststelle@fa-stuttgart2.fv.bwl.de		321
8	2896	Stuttgart Zentrales Konzernprüfungsamt	Hackstr. 86	70190	Stuttgart	0711/9251-6	0711/9251706											poststelle@zbp-stuttgart.fv.bwl.de		322
8	2897	Stuttgart III 	Rotebühlplatz 30	70173	Stuttgart	0711/66730	0711/66735710		70049	106053	60000000	600 01503	BBK STUTTGART	60050101	2 065 854	LANDESBANK BADEN-WUERTT	Mo-Do:8-15.30 Mi:8-17.30 Fr:8-12.00 Uhr	poststelle@fa-stuttgart3.fv.bwl.de		323
8	2899	Stuttgart-Körpersch. 	Paulinenstr. 44	70178	Stuttgart	0711/66730	0711/66736525	70049	70049	106051	60000000	600 01503	BBK STUTTGART	60050101	2 065 854	LANDESBANK BADEN-WUERTT	MO-FR 8:00-12:00, MO-DO 13:00-15:30 Uhr	poststelle@fa-stuttgart-koerperschaften.fv.bwl.de		324
12	3046	Potsdam-Stadt 	Am Bürohochhaus 2	14478	Potsdam	0331 287-0	0331 287-1515		14429	80 03 22	16000000	16001501	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Potsdam-Stadt@fa.brandenburg.de		325
12	3047	Potsdam-Land 	Steinstr. 104 - 106	14480	Potsdam	0331 6469-0	0331 6469-200		14437	90 01 45	16000000	16001502	BBK POTSDAM				täglich außer Mi: 08:00-12:30 Uhr, zusätzlich Di: 14:00-17:00 Uhr	poststelle.FA-Potsdam-Land@fa.brandenburg.de		326
12	3048	Brandenburg 	Magdeburger Straße 46	14770	Brandenburg	03381 397-100	03381 397-200				16000000	16001503	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Brandenburg@fa.brandenburg.de		327
12	3049	Königs Wusterhausen 	Weg am Kreisgericht 9	15711	Königs Wusterhausen	03375 275-0	03375 275-103				16000000	16001505	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Koenigs-Wusterhausen@fa.brandenburg.de		328
12	3050	Luckenwalde 	Industriestraße 2	14943	Luckenwalde	03371 606-0	03371 606-200				16000000	16001504	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Luckenwalde@fa.brandenburg.de		329
12	3051	Nauen 	Ketziner Straße 3	14641	Nauen	03321 412-0	03321 412-888		14631	11 61	16000000	16001509	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Nauen@fa.brandenburg.de		330
12	3052	Kyritz 	Perleberger Straße 1 - 2	16866	Kyritz	033971 65-0	033971 65-200				16000000	16001507	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Kyritz@fa.brandenburg.de		331
12	3053	Oranienburg 	Heinrich-Grüber-Platz 3	16515	Oranienburg	03301 857-0	03301 857-334				16000000	16001508	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Oranienburg@fa.brandenburg.de		332
12	3054	Pritzwalk 	Freyensteiner Chaussee 10	16928	Pritzwalk	03395 757-0	03395 302110				16000000	16001506	BBK POTSDAM				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Pritzwalk@fa.brandenburg.de		333
12	3056	Cottbus 	Vom-Stein-Straße 29	3050	Cottbus	0355 4991-4100	0355 4991-4150		3004	10 04 53	18000000	18001501	BBK COTTBUS				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Cottbus@fa.brandenburg.de		334
12	3057	Calau 	Springteichallee 25	3205	Calau	03541 83-0	03541 83-100		3201	11 71	18000000	18001502	BBK COTTBUS				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Calau@fa.brandenburg.de		335
12	3058	Finsterwalde 	Leipziger Straße 61 - 67	3238	Finsterwalde	03531 54-0	03531 54-180		3231	11 50	18000000	18001503	BBK COTTBUS				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Finsterwalde@fa.brandenburg.de		336
12	3061	Frankfurt (Oder) 	Müllroser Chaussee 53	15236	Frankfurt (Oder)	0335 560-1399	0335 560-1202				17000000	17001502	BBK FRANKFURT (ODER)				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Frankfurt-Oder@fa.brandenburg.de		337
12	3062	Angermünde 	Jahnstraße 49	16278	Angermünde	03331 267-0	03331 267-200				17000000	17001500	BBK FRANKFURT (ODER)				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Angermuende@fa.brandenburg.de		338
12	3063	Fürstenwalde 	Beeskower Chaussee 12	15517	Fürstenwalde	03361 595-0	03361 2198				17000000	17001503	BBK FRANKFURT (ODER)				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Fuerstenwalde@fa.brandenburg.de		339
12	3064	Strausberg 	Prötzeler Chaussee 12 A	15344	Strausberg	03341 342-0	03341 342-127				17000000	17001504	BBK FRANKFURT (ODER)				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Strausberg@fa.brandenburg.de		340
12	3065	Eberswalde 	Tramper Chaussee 5	16225	Eberswalde	03334 66-2000	03334 66-2001				17000000	17001501	BBK FRANKFURT (ODER)				Mo, Mi, Do: 08:00-15:00 Uhr, Di: 08:00-17:00 Uhr, Fr: 08:00-13:30 Uhr	poststelle.FA-Eberswalde@fa.brandenburg.de		341
15	3101	Magdeburg I 	Tessenowstraße 10	39114	Magdeburg	0391 885-29	0391 885-1400		39014	39 62	81000000	810 015 06	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-md1.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	342
15	3102	Magdeburg II 	Tessenowstraße 6	39114	Magdeburg	0391 885-12	0391 885-1000		39006	16 63	81000000	810 015 07	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-md2.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	343
15	3103	Genthin 	Berliner Chaussee 29 b	39307	Genthin	03933 908-0	03933 908-499		39302	13 41	81000000	810 015 08	BBK MAGDEBURG				Mo., Di., Do., Fr.: 09.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-gtn.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	344
15	3104	Halberstadt 	R.-Wagner-Straße 51	38820	Halberstadt	03941 33-0	03941 33-199		38805	15 26	81000000	268 015 01	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-hbs.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	345
15	3105	Haldensleben 	Jungfernstieg 37	39340	Haldensleben	03904 482-0	03904 482-200		39332	10 02 09	81000000	810 015 10	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-hdl.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	346
15	3106	Salzwedel 	Buchenallee 2	29410	Salzwedel	03901 857-0	03901 857-100		29403	21 51	81000000	810 015 05	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-saw.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	347
15	3107	Staßfurt 	Atzendorfer Straße 20	39418	Staßfurt	03925 980-0	03925 980-101		39404	13 55	81000000	810 015 12	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.30 - 18.00 Uhr	poststelle@fa-sft.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	348
15	3108	Stendal 	Scharnhorststraße 87	39576	Stendal	03931 57-1000	03931 57-2000		39551	10 11 31	81000000	810 015 13	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-sdl.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	349
15	3109	Wernigerode 	Gustav-Petri-Straße 14	38855	Wernigerode	03943 657-0	03943 657-150		38842	10 12 51	81000000	268 015 03	BBK MAGDEBURG				Mo., Di., Do., Fr.: 09.00 - 12.00 Uhr, Do.: 14.00 - 18.00 Uhr	poststelle@fa-wrg.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	350
15	3110	Halle-Süd 	Blücherstraße 1	6122	Halle	0345 6923-5	0345 6923-600	6103			80000000	800 015 02	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr, Do.: 14.00	poststelle@fa-ha-s.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	351
15	3111	Halle-Nord 	Blücherstraße 1	6122	Halle	0345 6924-0	0345 6924-400	6103			80000000	800 015 01	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr, Do.: 14.00	poststelle@fa-ha-n.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	352
15	3112	Merseburg 	Bahnhofstraße 10	6217	Merseburg	03461 282-0	03461 282-199		6203	13 51	80000000	800 015 09	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-msb.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	353
15	3113	Bitterfeld 	Röhrenstraße 33	6749	Bitterfeld	03493 347-0	03493 347-247		6732	12 64	80000000	805 015 05	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-btf.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	354
15	3114	Dessau 	Kühnauer Straße 166	6846	Dessau	0340 6513-0	0340 6513-403		6815	18 25	80000000	805 015 26	BBK HALLE				Mo. - Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-des.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	355
15	3115	Wittenberg 	Dresdener Straße 40	6886	Wittenberg	03491 430-0	03491 430-113		6872	10 02 54	80000000	805 015 07	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-wbg.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	356
15	3116	Köthen 	Zeppelinstraße 15	6366	Köthen	03496 44-0	03496 44-2900		6354	14 52	80000000	805 015 06	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr	poststelle@fa-kot.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	357
15	3117	Quedlinburg 	Adelheidstraße 2	6484	Quedlinburg	03946 976-0	03946 976-400		6472	14 20	81000000	268 015 02	BBK MAGDEBURG				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 17.30 Uhr	poststelle@fa-qlb.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	358
15	3118	Eisleben 	Bahnhofsring 10 a	6295	Eisleben	03475 725-0	03475 725-109	6291			80000000	800 015 08	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-eil.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	359
15	3119	Naumburg 	Oststraße 26/26 a	6618	Naumburg	03445 753-0	03445 753-999		6602	12 51	80000000	800 015 27	BBK HALLE				Mo., Di., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 13.00 - 18.00 Uhr	poststelle@fa-nbg.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	360
15	3120	Zeitz 	Friedensstraße 80	6712	Zeitz	03441 864-0	03441 864-480		6692	12 08	80000000	800 015 04	BBK HALLE				Mo., Do., Fr.: 08.00 - 12.00 Uhr, Di.: 08.00 - 18.00 Uhr	poststelle@fa-ztz.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	361
15	3121	Sangerhausen 	Alte Promenade 27	6526	Sangerhausen	03464 539-0	03464 539-539		6512	10 12 24	80000000	800 015 25	BBK HALLE				Di., Do., Fr.: 09.00 - 12.00 Uhr, Di.: 14.00 - 18.00 Uhr, Do.: 14.00 -	poststelle@fa-sgh.ofd.mf.lsa-net.de	http://www.finanzamt.sachsen-anhalt.de	362
14	3201	Dresden I 	Lauensteiner Str. 37	1277	Dresden	0351 2567-0	0351 2567-111	1264			85000000	85001502	BBK DRESDEN				Mo 8:00-15:00, Di 8:00-18:00, Mi 8:00-15:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-dresden1.smf.sachsen.de	http://www.Finanzamt-Dresden-I.de	363
14	3202	Dresden II 	Gutzkowstraße 10	1069	Dresden	0351 4655-0	0351 4655-269	1056			85000000	85001503	BBK DRESDEN				Mo - Fr 8:00-12:00 Uhr, Di 14:00-18:00, Do 14:00-18:00 Uhr	poststelle@fa-dresden2.smf.sachsen.de	http://www.Finanzamt-Dresden-II.de	364
14	3203	Dresden III 	Rabenerstr.1	1069	Dresden	0351 4691-0	0351 4717 369		1007	120641	85000000	85001504	BBK DRESDEN				Mo 8:00-15:00, Di 8:00-18:00, Mi 8:00-15:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-dresden3.smf.sachsen.de	http://www.Finanzamt-Dresden-III.de	365
14	3204	Bautzen 	Wendischer Graben 3	2625	Bautzen	03591 488-0	03591 488-888	2621			85000000	85001505	BBK DRESDEN				Mo 8:00-15:30, Di 8:00-17:00, Mi 8:00-15:30, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-bautzen.smf.sachsen.de	http://www.Finanzamt-Bautzen.de	366
14	3205	Bischofswerda 	Kirchstraße 25	1877	Bischofswerda	03594 754-0	03594 754-444		1871	1111	85000000	85001506	BBK DRESDEN				Mo 8:00-15:30, Di 8:00-17:00, Mi 8:00-15:30, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-bischofswerda.smf.sachsen.de	http://www.Finanzamt-Bischofswerda.de	367
14	3206	Freital 	Coschützer Straße 8-10	1705	Freital	0351 6478-0	0351 6478-428		1691	1560	85000000	85001507	BBK DRESDEN				Mo 8:00-15:00, Di 8:00-18:00, Mi 8:00-15:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-freital.smf.sachsen.de	http://www.Finanzamt-Freital.de	368
14	3207	Görlitz 	Sonnenstraße 7	2826	Görlitz	03581 875-0	03581 875-100		2807	300235	85000000	85001512	BBK DRESDEN				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00, Fr 8:00-12:00 Uhr	poststelle@fa-goerlitz.smf.sachsen.de	http://www.Finanzamt-Goerlitz.de	369
14	3208	Löbau 	Georgewitzer Str.40	2708	Löbau	03585 455-0	03585 455-100		2701	1165	85000000	85001509	BBK DRESDEN				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00, Fr 8:00-12:00 Uhr	poststelle@fa-loebau.smf.sachsen.de	http://www.Finanzamt-Loebau.de	370
14	3209	Meißen 	Hermann-Grafe-Str.30	1662	Meißen	03521 745-30	03521 745-450		1651	100151	85000000	85001508	BBK DRESDEN				Mo - Fr 8:00-12:00 Uhr Di 13:00-18:00, Do 13:00-17:00 Uhr	poststelle@fa-meissen.smf.sachsen.de	http://www.Finanzamt-Meissen.de	371
14	3210	Pirna 	Emil-Schlegel-Str. 11	1796	Pirna	03501 551-0	03501 551-201		1781	100143	85000000	85001510	BBK DRESDEN				Mo - Fr 8:00-12:00 Uhr, Di 13:30-18:00, Do 13:30-17:00 Uhr	poststelle@fa-pirna.smf.sachsen.de	http://www.Finanzamt-Pirna.de	372
14	3211	Riesa 	Stahlwerkerstr.3	1591	Riesa	03525 714-0	03525 714-133		1571	24	85000000	85001511	BBK DRESDEN				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00 , Fr 8:00-12:00 Uhr	poststelle@fa-riesa.smf.sachsen.de	http://www.Finanzamt-Riesa.de	373
14	3213	Hoyerswerda 	Pforzheimer Platz 1	2977	Hoyerswerda	03571 460-0	03571 460-115		2961	1161/1162 	85000000	85001527	BBK DRESDEN				Mo 7:30-15:30, Di 7:30-17:00, Mi 7:30-13:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-hoyerswerda.smf.sachsen.de	http://www.Finanzamt-Hoyerswerda.de	374
14	3214	Chemnitz-Süd 	Paul-Bertz-Str. 1	9120	Chemnitz	0371 279-0	0371 227065	9097			87000000	87001501	BBK CHEMNITZ				Mo 8:00-16:00, Di 8:00-18:00, Mi 8:00-13:00, Do 8:00-18:00, Fr 8:00-13:00 Uhr	poststelle@fa-chemnitz-sued.smf.sachsen.de	http://www.Finanzamt-Chemnitz-Sued.de	375
14	3215	Chemnitz-Mitte 	August-Bebel-Str. 11/13	9113	Chemnitz	0371 467-0	0371 415830	9097			87000000	87001502	BBK CHEMNITZ				Mo 8:00-16:00, Di 8:00-18:00, Mi 8:00-14:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-chemnitz-mitte.smf.sachsen.de	http://www.Finanzamt-Chemnitz-Mitte.de	376
14	3216	Chemnitz-Land 	Reichenhainer Str. 31-33	9126	Chemnitz	0371 5360-0	0371 5360-317	9097			87000000	87001503	BBK CHEMNITZ				täglich 8:00-12:00, Di 13:30-17.00, Do 13:30-18:00 Uhr	poststelle@fa-chemnitz-land.smf.sachsen.de	http://www.Finanzamt-Chemnitz-Land.de	377
14	3217	Annaberg 	Magazingasse 16	9456	Annaberg-B.	03733 4270	03733 427-217		9453	100631	87000000	87001504	BBK CHEMNITZ				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00, Fr 8:00-12:00 Uhr	poststelle@fa-annaberg.smf.sachsen.de	http://www.Finanzamt-Annaberg.de	378
14	3218	Schwarzenberg 	Karlsbader Str.23	8340	Schwarzenberg	03774 161-0	03774 161-100		8332	1209	87000000	87001505	BBK CHEMNITZ				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00, Fr 8:00-12:00 Uhr	poststelle@fa-schwarzenberg.smf.sachsen.de	http://www.Finanzamt-Schwarzenberg.de	379
14	3219	Auerbach 	Schulstraße 3, Haus 1	8209	Auerbach	03744 824-0	03744 824-200		8202	10132	87000000	87001506	BBK CHEMNITZ				Mo 7:30-15:30, Di 7:30-18:00, Mi 7:30-12:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-aucherbach.smf.sachsen.de	http://www.Finanzamt-Auerbach.de	380
14	3220	Freiberg 	Brückenstr.1	9599	Freiberg	03731 379-0	03731 379-999	9596			87000000	87001507	BBK CHEMNITZ				Mo - Fr 7:30-12:30, Mo 13:30-15:30, Di 13:00-18:00, Mi 13:30-15:30, Do 13:00-17:00 Uhr	poststelle@fa-freiberg.smf.sachsen.de	http://www.Finanzamt-Freiberg.de	381
14	3221	Hohenstein-Ernstthal 	Schulstraße 34	9337	Hohenstein-E.	03723 745-0	03723 745-399		9332	1246	87000000	87001510	BBK CHEMNITZ				Mo - Fr 8:00-12:00, Mo 12:30-15:30, Di 12:30-18:00, Do 12:30-17:00	poststelle@fa-hohenstein-ernstthal.smf.sachsen.de	http://www.Finanzamt-Hohenstein-Ernstthal.de	382
14	3222	Mittweida 	Robert-Koch-Str. 17	9648	Mittweida	03727 987-0	03727 987-333		9641	1157	87000000	87001509	BBK CHEMNITZ				Mo 7:30-15:00, Di 7:30-18:00, Mi 7:30-13:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-mittweida.smf.sachsen.de	http://www.Finanzamt-Mittweida.de	383
14	3223	Plauen 	Europaratstraße 17	8523	Plauen	03741 10-0	03741 10-2000		8507	100384	87000000	87001512	BBK CHEMNITZ				Mo 7:30-14:00, Di 7:30-18:00, Mi 7:30-14:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-plauen.smf.sachsen.de	http://www.Finanzamt-Plauen.de	384
14	3224	Stollberg 	HOHENSTEINER STRASSE 54	9366	Stollberg	037296 522-0	037296 522-199		9361	1107	87000000	87001508	BBK CHEMNITZ				Mo 7:30-15:30, Di 7:30-17:00, Mi 7:30-13:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-stollberg.smf.sachsen.de	http://www.Finanzamt-Stollberg.de	385
14	3226	Zwickau-Stadt 	Dr.-Friedrichs-Ring 21	8056	Zwickau	0375 3529-0	0375 3529-444		8070	100452	87000000	87001513	BBK CHEMNITZ				Mo 7:30-15:30, Di 7:30-18:00, Mi 7:30-12:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-zwickau-stadt.smf.sachsen.de	http://www.Finanzamt-Zwickau-Stadt.de	386
14	3227	Zwickau-Land 	Äußere Schneeberger Str. 62	8056	Zwickau	0375 4440-0	0375 4440-222		8067	100150	87000000	87001514	BBK CHEMNITZ				Mo 8:00-15:30, Di 8:00-18:00, Mi 8:00-15:30, Do 8:00-17:00, Fr 8:00-12:00 Uhr	poststelle@fa-zwickau-land.smf.sachsen.de	http://www.Finanzamt-Zwickau-Land.de	387
14	3228	Zschopau 	August-Bebel-Str.17	9405	Zschopau	03725 293-0	03725 293-111		9402	58	87000000	87001515	BBK CHEMNITZ				Mo7:30-12:00/13:00-16:30,Di 7:30-12:00/13:00-18:00Mi u. Fr 7:30-13:00, Do 7:30-12:00/13:00-18:00 Uhr	poststelle@fa-zschopau.smf.sachsen.de	http://www.Finanzamt-Zschopau.de	388
14	3230	Leipzig I 	Wilhelm-Liebknecht-Platz 3/4	4105	Leipzig	0341 559-0	0341 559-1540		4001	100105	86000000	86001501	BBK LEIPZIG				Mo 7:30-14:00, Di 7:30-18:00, Mi 7:30-14:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-leipzig1.smf.sachsen.de	http://www.Finanzamt-Leipzig-I.de	389
14	3231	Leipzig II 	Erich-Weinert-Str. 20	4105	Leipzig	0341 559-0	0341 559-2505		4001	100145	86000000	86001502	BBK LEIPZIG				Mo 7:30-14:00, Di 7:30-18:00, Mi 7:30-14:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-leipzig2.smf.sachsen.de	http://www.Finanzamt-Leipzig-II.de	390
14	3232	Leipzig III 	Wilhelm-Liebknecht-Platz 3/4	4105	Leipzig	0341 559-0	0341 559-3640		4002	100226	86000000	86001503	BBK LEIPZIG				Mo 7:30-14:00, Di 7:30-18:00, Mi 7:30-14:00, Do 7:30-18:00, Fr 7:30-12:00 Uhr	poststelle@fa-leipzig3.smf.sachsen.de	http://www.Finanzamt-Leipzig-III.de	391
14	3235	Borna 	Brauhausstr.8	4552	Borna	03433 872-0	03433 872-255		4541	1325	86000000	86001509	BBK LEIPZIG				Mo 8:00-15:00, Di 8:00-18:00, Mi 8:00-15:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-borna.smf.sachsen.de	http://www.Finanzamt-Borna.de	392
14	3236	Döbeln 	Burgstr.31	4720	Döbeln	03431 653-30	03431 653-444		4713	2346	86000000	86001507	BBK LEIPZIG				Mo 7:30-15:30, Di 7:30-18:00, Mi 7:30-13:00, Do 7:30-17:00, Fr 7:30-12:00 Uhr	poststelle@fa-doebeln.smf.sachsen.de	http://www.Finanzamt-Doebeln.de	393
14	3237	Eilenburg 	Walther-Rathenau-Straße 8	4838	Eilenburg	03423 660-0	03423 660-460		4831	1133	86000000	86001506	BBK LEIPZIG				Mo 8:00-16:00, Di 8:00-18:00, Mi 8:00-14:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-eilenburg.smf.sachsen.de	http://www.Finanzamt-Eilenburg.de	394
14	3238	Grimma 	Lausicker Straße 2	4668	Grimma	03437 940-0	03437 940-500		4661	1126	86000000	86001508	BBK LEIPZIG				Mo 7:30-15:00, Di 7:30-18:00, Mi 7:30-13:30, Do 7:30-17:00, Fr 7:30-12:00 Uhr	poststelle@fa-grimma.smf.sachsen.de	http://www.Finanzamt-Grimma.de	395
14	3239	Oschatz 	Dresdener Str.77	4758	Oschatz	03435 978-0	03435 978-366		4752	1265	86000000	86001511	BBK LEIPZIG				Mo 8:00-16:00, Di 8:00-17:00, Mi 8:00-15:00, Do 8:00-18:00, Fr 8:00-12:00 Uhr	poststelle@fa-oschatz.smf.sachsen.de	http://www.Finanzamt-Oschatz.de	396
13	4071	Malchin 	Schratweg 33	17139	Malchin	03994/6340	03994/634322		17131	1101	15000000	15001511	BBK NEUBRANDENBURG				Mo Di Fr 08-12 Uhr Di 13-17 Uhr und Do 13-16 UhrMittwoch geschlossen	poststelle@fa-mc.ofd-hro.de		397
13	4072	Neubrandenburg 	Neustrelitzer Str. 120	17033	Neubrandenburg	0395/380 1000	0395/3801059		17041	110164	15000000	15001518	BBK NEUBRANDENBURG				Mo Di Do Fr 08-12 Uhr und Di 13.00-17.30 Uhr Mittwoch geschlossen	poststelle@fa-nb.ofd-hro.de		398
13	4074	Pasewalk 	Torgelower Str. 32	17309	Pasewalk	(03973) 224-0	03973/2241199		17301	1102	15000000	15001512	BBK NEUBRANDENBURG				Mo bis Fr 09.00-12.00 Uhr Di 14.00-18.00 Uhr	poststelle@fa-pw.ofd-hro.de		399
13	4075	Waren 	Einsteinstr. 15	17192	Waren (Müritz)	03991/1740	(03991)174499		17183	3154	15000000	15001515	BBK NEUBRANDENBURG				Mo-Mi 08.00-16.00 Uhr Do 08.00-18.00 Uhr Fr 08.-13.00 Uhr	poststelle@fa-wrn.ofd-hro.de		400
13	4079	Rostock 	Möllner Str. 13	18109	Rostock	(0381)7000-0	(0381)7000444		18071	201062	13000000	13001508	BBK ROSTOCK				Mo Di Fr 8.30-12.00 Di 13.30-17.00 Do 13.30-16.00	poststelle@fa-hro.ofd-hro.de		401
13	4080	Wismar 	Philosophenweg 1	23970	Wismar	03841444-0	03841/444222				14000000	14001516	BBK SCHWERIN				Mo Di Fr 08.00-12.00 Uhr Di Do 14.00-17.00 Uhr Mittwoch geschlossen	poststelle@fa-wis.ofd-hro.de		402
13	4081	Ribnitz-Damgarten 	Sandhufe 3	18311	Ribnitz-Damgarten	(03821)884-0	(03821)884140		18301	1061	13000000	13001510	BBK ROSTOCK				MO Di Mi DO 08.30-12.00 UHR DI 13.00-17.00 UHR Freitag geschlossen	poststelle@fa-rdg.ofd-hro.de		403
13	4082	Stralsund 	Lindenstraße 136	18435	Stralsund	03831/3660	(03831)366245 / 188 		18409	2241	13000000	13001513	BBK ROSTOCK				Mo Di Do Fr 08.00-12.00 Uhr Di 14.00 - 18.00 UhrMittwoch geschlossen	poststelle@fa-hst.ofd-hro.de		404
13	4083	Bergen 	Wasserstr. 15 d	18528	Bergen (Rügen)	03838/4000	03838/22217	18522	18522	1242	13000000	13001512	BBK ROSTOCK				Mo Di Do Fr 8.30-12.00 Di 13.00-18.00 Mittwoch geschlossen	poststelle@fa-brg.ofd-hro.de		405
13	4084	Greifswald 	Am Gorzberg Haus 11	17489	Greifswald	03834/5590	03834-559315/316	17462	17462	3254	15000000	15001528	BBK NEUBRANDENBURG				Mo Di Do Fr 8.30-12.00 Uhr Di 13.00-17.30 Uhr Mittwoch geschlossen	poststelle@fa-hgw.ofd-hro.de		406
13	4085	Wolgast 	Pestalozzistr. 45	17438	Wolgast	03836/254-0	03836/254300 /254100		17431	1139	15000000	15001529	BBK NEUBRANDENBURG				Mo Di Mi Do Fr 08.00-12.00 Uhr	poststelle@fa-wlg.ofd-hro.de		407
13	4086	Güstrow 	Klosterhof 1	18273	Güstrow	03843/2620	03843/262111	18271			13000000	13001501	BBK ROSTOCK				Mo-Do 09.00-12.00 Uhr Do 13.00-18.00 Uhr Freitag geschlossen	poststelle@fa-gue.ofd-hro.de		408
13	4087	Hagenow 	Steegener Chaussee 8	19230	Hagenow	03883/6700	03883 670216 /670217		19222	1242	14000000	14001504	BBK SCHWERIN				Mo Di Do Fr 08.30-12.00 Di 13.00-17.30 Mittwoch geschlossen	poststelle@fa-hgn.ofd-hro.de		409
13	4089	Parchim 	Ludwigsluster Chaussee 5	19370	Parchim	03871/4650	03871/443131		19363	1351	14000000	14001506	BBK SCHWERIN				Mo Di Mi 08.30-15.00 Uhr Do 08.30-18.00 Uhr Fr 08.30-13.00 Uhr	poststelle@fa-pch.ofd-hro.de		410
13	4090	Schwerin 	Johannes-Stelling-Str.9-11	19053	Schwerin	0385/54000	0385/5400300		19091	160131	14000000	14001502	BBK SCHWERIN				 Di Do Fr 08.30 - 12.00 Uhr Mo 13.00 - 16.00 Uhr Do 14.00	poststelle@fa-sn.ofd-hro.de		411
16	4151	Erfurt 	Mittelhäuser Str. 64f	99091	Erfurt	(0361)378-00	0361/3782800		99001	100121	82050000	3001111586	LD BK HESS-THUER GZ ERFURT				DI. 8- 12/ 13.30 -18 MI./FR. 8 - 12 UHR	poststelle@finanzamt-erfurt.thueringen.de		412
16	4152	Sömmerda 	Uhlandstrasse 3	99610	Sömmerda	03634/363-0	03634/363200		99609	100	82050000	3001111628	LD BK HESS-THUER GZ ERFURT				MO/MI/DO 8-16 UHR DI 8-18,FR 8-12 UHR	poststelle@finanzamt-soemmerda.thueringen.de		413
16	4153	Weimar 	Jenaer Str.2a	99425	Weimar	03643/5500	(03643)903811		99421	3676	82050000	3001111586	LD BK HESS-THUER GZ ERFURT				MO,MI,DO 8-15.30 UHR DI 8-18,FR 8-12 UHR	poststelle@finanzamt-weimar.thueringen.de		414
16	4154	Ilmenau 	Wallgraben 1	98693	Ilmenau	(03677) 861-0	03677/861111		98686	100754	82050000	3001111685	LD BK HESS-THUER GZ ERFURT				MO,MI 8-15.30 UHR, DI 8-18 UHR DO 8-16 UHR, FR 8-12 UHR	poststelle@finanzamt-ilmenau.thueringen.de		415
16	4155	Eisenach 	Ernst-Thaelmann-Str. 70	99817	Eisenach	03691/687-0	03691/687250		99804	101454	82050000	3001111586	LD BK HESS-THUER GZ ERFURT				MO-FR: 8-12 UHR, MO-MI: 13-16 UHR, DO: 13-18 UHR	poststelle@finanzamt-eisenach.thueringen.de		416
16	4156	Gotha 	Reuterstr. 2a	99867	Gotha	(03621)33-0	03621/332000		99853	100301	82050000	3001111586	LD BK HESS-THUER GZ ERFURT				MO - MI 8-15.30 UHR DO 8-18,FR 8-12 UHR	poststelle@finanzamt-gotha.thueringen.de		417
16	4157	Mühlhausen 	Martinistr. 22	99974	Mühlhausen	(03601)456-0	03601/456100		99961	1155	82050000	3001111628	LD BK HESS-THUER GZ ERFURT				MO/MI/DO 7.30-15 UHR DI.7.30-18,FR.7.30-12	poststelle@finanzamt-muehlhausen.thueringen.de		418
16	4158	Nordhausen 	Gerhart-Hauptmann-Str. 3	99734	Nordhausen	03631/427-0	03631/427174		99729	1120	82050000	3001111628	LD BK HESS-THUER GZ ERFURT				MO,DI,MI 8-12, 13.30-16 UHR DO 8-12,14-18 FR 8-12 UHR	poststelle@finanzamt-nordhausen.thueringen.de		419
16	4159	Sondershausen 	Schillerstraße 6	99706	Sondershausen	(03632)742-0	03632/742555		99702	1265	82050000	3001111628	LD BK HESS-THUER GZ ERFURT				MO/MI/DO 8-15.30 UHR DI 8-18, FR 8-12 UHR	poststelle@finanzamt-sondershausen.thueringen.de		420
16	4160	Worbis 	Bahnhofstr. 18	37339	Worbis	036074/37-0	036074/37219		37334	173	82050000	3001111628	LD BK HESS-THUER GZ ERFURT				MO-MI 7.30-15 UHR DO 7.30-18,FR 7.30-12	poststelle@finanzamt-worbis.thueringen.de		421
16	4161	Gera 	Hermann-Drechsler-Str.1	7548	Gera	0365/639-0	0365/6391491		7490	3044	82050000	3001111578	LD BK HESS-THUER GZ ERFURT				MO,MI 7.30-15 DI,DO 7.30- 18 UHR FR 7.30-12 UHR	poststelle@finanzamt-gera.thueringen.de		422
16	4162	Jena 	Leutragraben 8	7743	Jena	(03641)378-0	03641/378653		7740	500	82050000	3001111602	LD BK HESS-THUER GZ ERFURT				MO-MI 8-15.30 DO 8-18 FR 8-12.00UHR	poststelle@finanzamt-jena.thueringen.de		423
16	4163	Rudolstadt 	Mörlaer Str. 2	7407	Rudolstadt	(03672)443-0	(03672)443100		7391	100155	82050000	3001111578	LD BK HESS-THUER GZ ERFURT				MO-MI 7.30-12, 13-15 DO 7.30-12, 13-18 UHR FR 7.30-12 UHR	poststelle@finanzamt-rudolstadt.thueringen.de		424
16	4164	Greiz 	Rosa-Luxemburg-Str. 23	7973	Greiz	03661/700-0	03661/700300		7962	1365	82050000	3001111578	LD BK HESS-THUER GZ ERFURT				MO/DI/MI 8-16UHR DO 8-18,FR 8-12UHR	poststelle@finanzamt-greiz.thueringen.de		425
16	4165	Pößneck 	Gerberstr. 65	7381	Pößneck	(03647)446-0	(03647)446430		7372	1253	82050000	3001111578	LD BK HESS-THUER GZ ERFURT				MO-FR 8-12 MO,MI,DO 13-15 UHR DI 13-18 UHR	poststelle@finanzamt-poessneck.thueringen.de		426
16	4166	Altenburg 	Wenzelstr. 45	4600	Altenburg	03447/593-0	03447/593200		4582	1251	82050000	3001111511	LD BK HESS-THUER GZ ERFURT				MO,MI,DO 7.30-15.30 DI 7.30-18 UHR FR 7.30-12 UHR	poststelle@finanzamt-altenburg.thueringen.de		427
16	4168	Bad Salzungen 	August-Bebel-Str.2	36433	Bad Salzungen	(03695)668-0	03695/622496		36421	1153	82050000	3001111586	LD BK HESS-THUER GZ ERFURT				MO-MI 7.30-15 UHR DO 7.30-18,FR 7.30-12	poststelle@finanzamt-badsalzungen.thueringen.de		428
16	4169	Meiningen 	Charlottenstr. 2	98617	Meiningen	03693/461-0	(03693)461322		98606	100661	82050000	3001111610	LD BK HESS-THUER GZ ERFURT				MO-MI 7.30-15 UHR DO 7.30-18,FR 7.30-12	poststelle@finanzamt-meiningen.thueringen.de		429
16	4170	Sonneberg 	Köppelsdorfer Str.86	96515	Sonneberg	03675/884-0	03675/884254		96502	100241	82050000	3001111685	LD BK HESS-THUER GZ ERFURT				MO-MI 7.30-15.00 UHR DO 7.30-18 FR 7.30-12	poststelle@finanzamt-sonneberg.thueringen.de		430
16	4171	Suhl 	Karl-Liebknecht-Str. 4	98527	Suhl	03681/73-0	03681/733512		98490	100153	82050000	3001111685	LD BK HESS-THUER GZ ERFURT				MO - MI 8-16 UHR, DO 8-13 u. 14-18 UHR , FR 8-12 UHR	poststelle@finanzamt-suhl.thueringen.de		431
5	5101	Dinslaken 	Schillerstr. 71	46535	Dinslaken	02064/445-0	0800 10092675101		46522	100220	35000000	35201501	BBK DUISBURG	35251000	100123	SPK DINSLAKEN-VOERDE-HUENXE	Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5101.fin-nrw.de	www.finanzamt-Dinslaken.de	432
5	5102	Viersen 	Eindhovener Str. 71	41751	Viersen	02162/955-0	0800 10092675102		41726	110263	31000000	31001503	BBK MOENCHENGLADBACH	32050000	59203406	SPARKASSE KREFELD	Mo-Fr 8:30 bis 12:00 Uhr,Di auch 13:30 bis 15:00 Uhr,und nach Vereinbarung	Service@FA-5102.fin-nrw.de	www.finanzamt-Viersen.de	433
5	5103	Düsseldorf-Altstadt 	Kaiserstr. 52	40479	Düsseldorf	0211/4974-0	0800 10092675103		40001	101021	30000000	30001504	BBK DUESSELDORF	30050110	10124006	ST SPK DUESSELDORF	Mo-Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5103.fin-nrw.de	www.finanzamt-Duesseldorf-Altstadt.de	434
5	5105	Düsseldorf-Nord 	Roßstr. 68	40476	Düsseldorf	0211/4496-0	0800 10092675105		40403	300314	30000000	30001501	BBK DUESSELDORF	30050110	10124501	ST SPK DUESSELDORF	Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5105.fin-nrw.de	www.finanzamt-Duesseldorf-Nord.de	435
5	5106	Düsseldorf-Süd 	Kruppstr.110- 112	40227	Düsseldorf	0211/779-9	0800 10092675106		40001	101025	30000000	30001502	BBK DUESSELDORF	30050110	10125003	ST SPK DUESSELDORF	Mo-Fr 8.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5106.fin-nrw.de	www.finanzamt-Duesseldorf-Sued.de	436
5	5107	Duisburg-Hamborn 	Hufstr. 25	47166	Duisburg	0203/5445-0	0800 10092675107		47142	110264	35000000	35001502	BBK DUISBURG				Mo-Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5107.fin-nrw.de	www.finanzamt-Duisburg-Hamborn.de	437
5	5109	Duisburg-Süd 	Landfermannstr 25	47051	Duisburg	0203/3001-0	0800 10092675109		47015	101502	35000000	35001500	BBK DUISBURG	35050000	200403020	SPK DUISBURG	Mo-Fr 08:30 Uhr - 12:00 Uhr,Di auch 13:30 Uhr - 15:00 Uhr	Service@FA-5109.fin-nrw.de	www.finanzamt-Duisburg-Sued.de	438
5	5110	Essen-Nord 	Altendorfer Str. 129	45143	Essen	0201/1894-0	0800 10092675110		45011	101155	36000000	36001500	BBK ESSEN	36050105	275008	SPARKASSE ESSEN	Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5110.fin-nrw.de	www.finanzamt-Essen-Nord.de	439
5	5111	Essen-Ost 	Altendorfer Str. 129	45143	Essen	0201/1894-0	0800 10092675111	45116	45012	101262	36000000	36001501	BBK ESSEN	36050105	261800	SPARKASSE ESSEN	Mo-Fr,Di	Service@FA-5111.fin-nrw.de	www.finanzamt-Essen-Ost.de	440
5	5112	Essen-Süd 	Altendorfer Str. 129	45143	Essen	0201/1894-0	0800 10092675112		45011	101145	36000000	36001502	BBK ESSEN	36050105	203000	SPARKASSE ESSEN	Mo-Fr 08.30-12.00 Uhr, Di auch 13.30-15.00 Uhr, und nach Vereinbarung	Service@FA-5112.fin-nrw.de	www.finanzamt-Essen-Sued.de	441
5	5113	Geldern 	Gelderstr 32	47608	Geldern	02831/127-0	0800 10092675113		47591	1163	32000000	32001502	BBK MOENCHENGLADBACH EH KRE	32051370	112011	SPARKASSE GELDERN	Montag - Freitag 8:30 - 12:00,Uhr,Dienstag auch 13:00 - 15:00 U,hr und nach Vereinbarung	Service@FA-5113.fin-nrw.de	www.finanzamt-Geldern.de	442
5	5114	Grevenbroich 	Erckensstr. 2	41515	Grevenbroich	02181/607-0	0800 10092675114		41486	100264	30000000	30001507	BBK DUESSELDORF	30550000	101683	SPARKASSE NEUSS	Mo-Fr 8:30-12:00 Uhr,Di auch 13:30-15:00 Uhr,und nach Vereinbarung	Service@FA-5114.fin-nrw.de	www.finanzamt-Grevenbroich.de	443
5	5115	Kempen 	Arnoldstr 13	47906	Kempen	02152/919-0	0800 10092675115		47880	100329	31000000	32001501	BBK MOENCHENGLADBACH				MO.-DO. 8.30-12.00 UHR,FREITAGS GESCHLOSSEN	Service@FA-5115.fin-nrw.de	www.finanzamt-Kempen.de	444
5	5116	Kleve 	Emmericher Str. 182	47533	Kleve	02821/803-1	0800 10092675116		47512	1251	35000000	32401501	BBK DUISBURG	32450000	5013628	SPARKASSE KLEVE	Mo - Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr	Service@FA-5116.fin-nrw.de	www.finanzamt-Kleve.de	445
5	5117	Krefeld 	Grenzstr 100	47799	Krefeld	02151/854-0	0800 10092675117		47706	100665	31000000	32001500	BBK MOENCHENGLADBACH				Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5117.fin-nrw.de	www.finanzamt-Krefeld.de	446
5	5119	Moers 	Unterwallstr 1	47441	Moers	02841/208-0	0800 10092675119	47439	47405	101520	35000000	35001505	BBK DUISBURG	35450000	1101000121	SPARKASSE MOERS	Montag-Freitag von 8.30-12.00,Dienstag von 13.30-15.00	Service@FA-5119.fin-nrw.de	www.finanzamt-Moers.de	447
5	5120	Mülheim an der Ruhr 	Wilhelmstr 7	45468	Mülheim an der Ruhr	0208/3001-1	0800 10092675120		45405	100551	36000000	36201500	BBK ESSEN	36250000	300007007	SPK MUELHEIM AN DER RUHR	Mo-Fr,Di auch 13:30-15:00 Uhr,und nach Vereinbarung	Service@FA-5120.fin-nrw.de	www.finanzamt-Muelheim-Ruhr.de	448
5	5121	Mönchengladbach-Mitte 	Kleiststr. 1	41061	Mönchengladbach	02161/189-0	0800 10092675121		41008	100813	31000000	31001500	BBK MOENCHENGLADBACH	31050000	8888	ST SPK MOENCHENGLADBACH	Mo - Fr,Di auch,und nach Vereinbarung	Service@FA-5121.fin-nrw.de	www.finanzamt-Moenchengladbach-Mitte.de	449
5	5122	Neuss II 	Hammfelddamm 9	41460	Neuss	02131/6656-0	0800 10092675122		41405	100502	30000000	30001509	BBK DUESSELDORF	30550000	123000	SPARKASSE NEUSS	Mo,Di,Do,Fr von 8.30-12.00,Di von 13.30-15.00	Service@FA-5122.fin-nrw.de	www.finanzamt-Neuss2.de	450
5	5123	Oberhausen-Nord 	Gymnasialstr. 16	46145	Oberhausen	0208/6499-0	0800 10092675123		46122	110220	36000000	36501501	BBK ESSEN	36550000	260125	ST SPK OBERHAUSEN	Mo-Fr 08:30-12:00 Uhr,Di auch 13:30-15:00 Uhr,und nach Vereinbarung	Service@FA-5123.fin-nrw.de	www.finanzamt-Oberhausen-Nord.de	451
5	5124	Oberhausen-Süd 	Schwartzstr. 7-9	46045	Oberhausen	0208/8504-0	0800 10092675124		46004	100447	36000000	36501500	BBK ESSEN	36550000	138156	ST SPK OBERHAUSEN	Mo - Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5124.fin-nrw.de	www.finanzamt-Oberhausen-Sued.de	452
5	5125	Neuss I 	Schillerstr 80	41464	Neuss	02131/943-0	0800 10092675125	41456	41405	100501	30000000	30001508	BBK DUESSELDORF	30550000	129999	SPARKASSE NEUSS	Mo-Fr 08.30-12.00 Uhr,Mo auch 13.30-15.00 Uhr	Service@FA-5125.fin-nrw.de	www.finanzamt-Neuss1.de	453
5	5126	Remscheid 	Wupperstr 10	42897	Remscheid	02191/961-0	0800 10092675126		42862	110269	33000000	33001505	BBK WUPPERTAL	34050000	113001	ST SPK REMSCHEID	Mo-Fr 08.30-12.00Uhr,Di auch 13.30-15.00Uhr,und nach Vereinbarung	Service@FA-5126.fin-nrw.de	www.finanzamt-Remscheid.de	454
5	5127	Mönchengladbach-Rheydt 	Wilhelm-Strauß-Str. 50	41236	Mönchengladbach	02166/450-0	0800 10092675127		41204	200442	31000000	31001502	BBK MOENCHENGLADBACH	31050000	295600	ST SPK MOENCHENGLADBACH	MO - FR 08.30 - 12.00 Uhr,DI auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5127.fin-nrw.de	www.finanzamt-Moenchengladbach-Rheydt.de	455
5	5128	Solingen-Ost 	Goerdelerstr.24- 26	42651	Solingen	0212/282-1	0800 10092675128	42648	42609	100984	33000000	33001503	BBK WUPPERTAL	34250000	22707	ST SPK SOLINGEN	Mo.-Fr.,Mo. auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5128.fin-nrw.de	www.finanzamt-Solingen-Ost.de	456
5	5129	Solingen-West 	Merscheider Busch 23	42699	Solingen	0212/2351-0	0800 10092675129		42663	110340	33000000	33001501	BBK WUPPERTAL	34250000	130005	ST SPK SOLINGEN	MO-FR 08.30 - 12.00 Uhr,und nach Vereinbarung	Service@FA-5129.fin-nrw.de	www.finanzamt-Solingen-West.de	457
5	5130	Wesel 	Poppelbaumstr. 5-7	46483	Wesel	0281/105-0	0800 10092675130		46461	100136	35000000	35601500	BBK DUISBURG	35650000	208660	VERB SPK WESEL	Mo-Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5130.fin-nrw.de	www.finanzamt-Wesel.de	458
5	5131	Wuppertal-Barmen 	Unterdörnen 96	42283	Wuppertal	0202/9543-0	0800 10092675131	42271	42208	200853	33000000	33001502	BBK WUPPERTAL				Mo - Fr,Do auch,und nach Vereinbarung	Service@FA-5131.fin-nrw.de	www.finanzamt-Wuppertal-Barmen.de	459
5	5132	Wuppertal-Elberfeld 	Kasinostr. 12	42103	Wuppertal	0202/489-0	0800 10092675132		42002	100209	33000000	33001500	BBK WUPPERTAL				Mo-Fr 08.30-12.00 Uhr,Do auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5132.fin-nrw.de	www.finanzamt-Wuppertal-Elberfeld.de	460
5	5133	Düsseldorf-Mitte 	Kruppstr. 110	40227	Düsseldorf	0211/779-9	0800 10092675133		40001	101024	30000000	30001505	BBK DUESSELDORF	30050110	10123008	ST SPK DUESSELDORF		Service@FA-5133.fin-nrw.de	www.finanzamt-Duesseldorf-Mitte.de	461
5	5134	Duisburg-West 	Friedrich-Ebert-Str 133	47226	Duisburg	02065/307-0	0800 10092675134		47203	141355	35000000	35001503	BBK DUISBURG				Mo - Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5134.fin-nrw.de	www.finanzamt-Duisburg-West.de	462
5	5135	Hilden 	Neustr. 60	40721	Hilden	02103/917-0	0800 10092675135		40710	101046	30000000	30001506	BBK DUESSELDORF				Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5135.fin-nrw.de	www.finanzamt-Hilden.de	463
5	5139	Velbert 	Nedderstraße 38	42549	Velbert	02051/47-0	0800 10092675139		42513	101310	33000000	33001504	BBK WUPPERTAL	33450000	26205500	SPARKASSE HRV	Mo-Fr 08.30-12.00 Uhr,Mo auch 13.30-15.00 Uhr	Service@FA-5139.fin-nrw.de	www.finanzamt-Velbert.de	464
5	5147	Düsseldorf-Mettmann 	Harkortstr. 2-4	40210	Düsseldorf	0211/3804-0	0800 10092675147		40001	101023	30000000	30001500	BBK DUESSELDORF	30050000	4051017	WESTLB DUESSELDORF	Montag bis Freitag,08.30 bis 12.00 Uhr,und nach Vereinbarung	Service@FA-5147.fin-nrw.de	www.finanzamt-Duesseldorf-Mettmann.de	465
5	5149	Rechenzentrum d. FinVew NRW 	Roßstraße 131	40476	Düsseldorf	0211/4572-0	0211/4572-302		40408	300864								Service@FA-5149.fin-nrw.de		466
5	5170	Düsseldorf I für Groß- und Konzernbetriebsprüfung	Werftstr. 16	40549	Düsseldorf	0211/56354-01	0800 10092675170		40525	270264								Service@FA-5170.fin-nrw.de		467
5	5171	Düsseldorf II für Groß- und Konzernbetriebsprüfung	Werftstr. 16	40549	Düsseldorf	0211/56354-0	0800 10092675171		40525	270264								Service@FA-5171.fin-nrw.de		468
5	5172	Essen für Groß- und Konzernbetriebsprüfung	In der Hagenbeck 64	45143	Essen	0201/6300-1	0800 10092675172		45011	101155								Service@FA-5172.fin-nrw.de		469
5	5173	Krefeld für Groß- und Konzernbetriebsprüfung	Steinstr. 137	47798	Krefeld	02151/8418-0	0800 10092675173											Service@FA-5173.fin-nrw.de		470
5	5174	Berg. Land für Groß- und Konzernbetriebsprüfung	Bendahler Str. 29	42285	Wuppertal	0202/2832-0	0800 10092675174	42271										Service@FA-5174.fin-nrw.de		471
5	5176	Mönchengladbach für Groß- und  Konzernbetriebsprüfung	Aachener Str. 114	41061	Mönchengladbach	02161/3535-0	0800 10092675176		41017	101715								Service@FA-5176.fin-nrw.de		472
5	5181	Düsseldorf f. Steuerfahndung und Steuerstrafsachen	Kruppstr.110 -112	40227	Düsseldorf	0211/779-9	0800 10092675181		40001	101024	30000000	30001502	BBK DUESSELDORF	30050110	10125003	ST SPK DUESSELDORF	Mo - Di 07.30 - 16.30 Uhr,Mi - Fr 07.30 - 16.00 Uhr	Service@FA-5181.fin-nrw.de		473
5	5182	Essen f. Steuerfahndung und Steuerstrafsachen	In der Hagenbeck 64	45143	Essen	0201/6300-1	0800 10092675182		45011	101155	36000000	36001502	BBK ESSEN	36050105	203000	SPARKASSE ESSEN		Service@FA-5182.fin-nrw.de		474
5	5183	Wuppertal f. Steuerfahndung und Steuerstrafsachen	Unterdörnen 96	42283	Wuppertal	0202/9543-0	0800 10092675183		42205	200553	33000000	33001502	BBK WUPPERTAL	33050000	135004	ST SPK WUPPERTAL		Service@FA-5183.fin-nrw.de		475
5	5201	Aachen-Innenstadt 	Mozartstr 2-10	52064	Aachen	0241/469-0	0800 10092675201		52018	101833	39000000	39001501	BBK AACHEN	39050000	26	SPARKASSE AACHEN	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 -15.00 Uhr,und nach Vereinbarung	Service@FA-5201.fin-nrw.de	www.finanzamt-Aachen-Innenstadt.de	476
5	5202	Aachen-Kreis 	Beverstr 17	52066	Aachen	0241/940-0	0800 10092675202		52018	101829	39000000	39001500	BBK AACHEN	39050000	311118	SPARKASSE AACHEN	Mo.-Fr. 08.30 - 12.00 Uhr,Mo.,und nach Vereinbarung	Service@FA-5202.fin-nrw.de	www.finanzamt-Aachen-Kreis.de	477
5	5203	Bergheim 	Rathausstrasse 3	50126	Bergheim	02271/82-0	0800 10092675203		50101	1120	39500000	39501501	BBK AACHEN EH DUEREN				Mo-Fr 08:30-12:00 Uhr,Di 13:30-15:00 Uhr,und nach Vereinbarung	Service@FA-5203.fin-nrw.de	www.finanzamt-Bergheim.de	478
5	5204	Bergisch Gladbach 	Refrather Weg 35	51469	Bergisch Gladbach	02202/9342-0	0800 10092675204		51433	200380	37000000	37001508	BBK KOELN				Mo.-Fr. 8.30-12.00 Uhr	Service@FA-5204.fin-nrw.de	www.finanzamt-Bergisch-Gladbach.de	479
5	5302	Altena 	Winkelsen 11	58762	Altena	02352/917-0	0800 10092675302		58742	1253	45000000	45001501	BBK HAGEN	45851020	80020001	VER SPK PLETTENBERG	Mo,Di-Do,und nach Vereinbarung	Service@FA-5302.fin-nrw.de	www.finanzamt-Altena.de	480
5	5205	Bonn-Innenstadt 	Welschnonnenstr. 15	53111	Bonn	0228/718-0	0800 10092675205		53031	180120	38000000	38001500	BBK BONN	38050000	17079	SPARKASSE BONN	Mo-Mi 08.30-12.00 Uhr,Do 07.00-17.00 Uhr,Freitag geschlossen	Service@FA-5205.fin-nrw.de	www.finanzamt-Bonn-Innenstadt.de	481
5	5206	Bonn-Außenstadt 	Bachstr. 36	53115	Bonn	0228/7268-0	0800 10092675206		53005	1580	38000000	38001501	BBK BONN	38050000	22004	SPARKASSE BONN	Mo-Do,Do auch 13:30 bis 17:30 Uhr,Freitags geschlossen	Service@FA-5206.fin-nrw.de	www.finanzamt-Bonn-Aussenstadt.de	482
5	5207	Düren 	Goethestrasse 7	52349	Düren	02421/947-0	0800 10092675207		52306	100646	39500000	39501500	BBK AACHEN EH DUEREN	39550110	188300	SPARKASSE DUEREN	Mo-Fr 08:30 - 12:00 Uhr,Di auch 13:30 - 15:00 Uhr,und nach Vereinbarung	Service@FA-5207.fin-nrw.de	www.finanzamt-Dueren.de	483
5	5208	Erkelenz 	Südpromenade 37	41812	Erkelenz	02431/801-0	0800 10092675208		41806	1651	31000000	31001501	BBK MOENCHENGLADBACH	31251220	402800	KR SPK HEINSBERG ERKELENZ	Mo - Fr 8.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5208.fin-nrw.de	www.finanzamt-Erkelenz.de	484
5	5209	Euskirchen 	Thomas-Mann-Str. 2	53879	Euskirchen	02251/982-0	0800 10092675209		53864	1487	38000000	38001505	BBK BONN	38250110	1000330	KREISSPARKASSE EUSKIRCHEN	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5209.fin-nrw.de	www.finanzamt-Euskirchen.de	485
5	5210	Geilenkirchen 	H.-Wilh.-Str 45	52511	Geilenkirchen	02451/623-0	0800 10092675210		52501	1193	39000000	39001502	BBK AACHEN	31251220	5397	KR SPK HEINSBERG ERKELENZ	Mo.-Fr. 8.30 - 12.00 Uhr,nachmittags nur tel. von,13.30 - 15.00 Uhr	Service@FA-5210.fin-nrw.de	www.finanzamt-Geilenkirchen.de	486
5	5211	Schleiden 	Kurhausstr. 7	53937	Schleiden	02444/85-0	0800 10092675211		53929	1140	38000000	38001506	BBK BONN	38250110	3200235	KREISSPARKASSE EUSKIRCHEN	Mo-Fr 08.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,sowie nach Vereinbarung	Service@FA-5211.fin-nrw.de	www.finanzamt-Schleiden.de	487
5	5212	Gummersbach 	Mühlenbergweg 5	51645	Gummersbach	02261/86-0	0800 10092675212	51641			37000000	37001506	BBK KOELN				Mo - Fr 08.30-12.00 Uhr,Mo auch 13.30-15.00 Uhr	Service@FA-5212.fin-nrw.de	www.finanzamt-Gummersbach.de	488
5	5213	Jülich 	Wilhelmstr 5	52428	Jülich	02461/685-0	0800 10092675213		52403	2180	39000000	39701500	BBK AACHEN	39550110	25023	SPARKASSE DUEREN	Mo.-Fr. 08.00-12.00 Uhr,Di. 13.30-15.00 Uhr	Service@FA-5213.fin-nrw.de	www.finanzamt-Juelich.de	489
5	5214	Köln-Altstadt 	Am Weidenbach 2-4	50676	Köln	0221/2026-0	0800 10092675214		50517	250140	37000000	37001501	BBK KOELN	37050198	70052964	STADTSPARKASSE KOELN	Mo - Fr 8.30 - 12.00 Uhr,Di auch 13.00 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5214.fin-nrw.de	www.finanzamt-Koeln-Altstadt.de	490
5	5215	Köln-Mitte 	Blaubach 7	50676	Köln	0221/92400-0	0800 10092675215		50524	290208	37000000	37001505	BBK KOELN	37050198	70062963	STADTSPARKASSE KOELN	MO-FR 08.30 - 12.00 UHR	Service@FA-5215.fin-nrw.de	www.finanzamt-Koeln-Mitte.de	491
5	5216	Köln-Porz 	Klingerstr. 2-6	51143	Köln	02203/598-0	0800 10092675216		51114	900469	37000000	37001524	BBK KOELN				Mo-Fr08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5216.fin-nrw.de	www.finanzamt-Koeln-Porz.de	492
5	5217	Köln-Nord 	Innere Kanalstr. 214	50670	Köln	0221/97344-0	0800 10092675217		50495	130164	37000000	37001502	BBK KOELN	37050198	70102967	STADTSPARKASSE KOELN	Mo - Fr 8.30 - 12.00 Uhr,und nach Vereinbarung	Service@FA-5217.fin-nrw.de	www.finanzamt-Koeln-Nord.de	493
5	5218	Köln-Ost 	Siegesstrasse 1	50679	Köln	0221/9805-0	0800 10092675218		50529	210340	37000000	37001503	BBK KOELN	37050198	70082961	STADTSPARKASSE KOELN	Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5218.fin-nrw.de	www.finanzamt-Koeln-Ost.de	494
5	5219	Köln-Süd 	Am Weidenbach 6	50676	Köln	0221/2026-0	0800 10092675219		50517	250160	37000000	37001504	BBK KOELN	37050198	70032966	STADTSPARKASSE KOELN	Mo-Fr,Di auch 13.00-15.00 Uhr	Service@FA-5219.fin-nrw.de	www.finanzamt-Koeln-Sued.de	495
5	5220	Siegburg 	Mühlenstr 19	53721	Siegburg	02241/105-0	0800 10092675220		53703	1351	38000000	38001503	BBK BONN				Mo.-Fr. 08.30-12.00 Uhr,Mo. auch 13.30-17.00 Uhr,und nach Vereinbarung	Service@FA-5220.fin-nrw.de	www.finanzamt-Siegburg.de	496
5	5221	Wipperfürth 	Am Stauweiher 3	51688	Wipperfürth	02267/870-0	0800 10092675221		51676	1240	37000000	37001513	BBK KOELN				Mo-Fr 08.30-12.00 Uhr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5221.fin-nrw.de	www.finanzamt-Wipperfuerth.de	497
5	5222	Sankt Augustin 	Hubert-Minz-Str 10	53757	Sankt Augustin	02241/242-1	0800 10092675222		53730	1229	38000000	38001504	BBK BONN				Mo - Fr 8.30-12.00 Uhr,Di auch 13.30-15.00 Uhr	Service@FA-5222.fin-nrw.de	www.finanzamt-Sankt-Augustin.de	498
5	5223	Köln-West 	Haselbergstr 20	50931	Köln	0221/5734-0	0800 10092675223		50864	410469	37000000	37001523	BBK KOELN	37050198	70022967	STADTSPARKASSE KOELN		Service@FA-5223.fin-nrw.de	www.finanzamt-Koeln-West.de	499
5	5224	Brühl 	Kölnstr. 104	50321	Brühl	02232/703-0	0800 10092675224	50319			37000000	37001507	BBK KOELN				Mo-Fr 08.30 - 12.00,Die zusätzlich 13.30 - 15.00 ,und nach Vereinbarung	Service@FA-5224.fin-nrw.de	www.finanzamt-Bruehl.de	500
5	5225	Aachen-Außenstadt 	Beverstraße	52066	Aachen	0241/940-0	0800 10092675225		52018	101825	39000000	39001503	BBK AACHEN	39050000	1099	SPARKASSE AACHEN	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5225.fin-nrw.de	www.finanzamt-Aachen-Aussenstadt.de	501
5	5230	Leverkusen 	Haus-Vorster-Str 12	51379	Leverkusen	02171/407-0	0800 10092675230	51367			37000000	37001511	BBK KOELN	37551440	118318500	SPARKASSE LEVERKUSEN	Mo-Do 8.30 - 12.00 Uhr,Di.: 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5230.fin-nrw.de	www.finanzamt-Leverkusen.de	502
5	5270	KonzBP Köln für Groß- und Konzernbetriebsprüfung	Riehler Platz 2	50668	Köln	0221/2021-0	0800 10092675270											Service@FA-5270.fin-nrw.de		503
5	5271	Aachen für Groß- und Konzernbetriebsprüfung	Beverstr. 17	52066	Aachen	0241/940-0	0800 10092675271		52017	101744								Service@FA-5271.fin-nrw.de		504
5	5272	Bonn für Groß- und Konzernbetriebsprüfung	Am Propsthof 17	53121	Bonn	0228/7223-0	0800 10092675272											Service@FA-5272.fin-nrw.de		505
5	5281	Aachen f. Steuerfahndung und Steuerstrafsachen	Beverstr 17	52066	Aachen	0241/940-0	0800 10092675281		52017	101722	39000000	39001500	BBK AACHEN	39050000	311118	SPARKASSE AACHEN		Service@FA-5281.fin-nrw.de		506
5	5282	Bonn f. Steuerfahndung und Steuerstrafsachen	Theaterstr. 1	53111	Bonn	0228/718-0	0800 10092675282				38000000	38001500	BBK BONN	38050000	17079	SPARKASSE BONN		Service@FA-5282.fin-nrw.de		507
5	5283	Köln f. Steuerfahndung und Steuerstrafsachen	Am Gleisdreieck 7- 9	50823	Köln	0221/5772-0	0800 10092675283		50774	300451	37000000	37001502	BBK KOELN	37050198	70102967	STADTSPARKASSE KOELN		Service@FA-5283.fin-nrw.de		508
5	5301	Ahaus 	Vredener Dyk 2	48683	Ahaus	02561/929-0	0800 10092675301		48662	1251	40000000	40001503	BBK MUENSTER, WESTF	40154530	51027902	SPARKASSE WESTMUENSTERLAND	Mo - Fr 08.30 - 12.00 Uhr,zudem Mo 13.30 - 15.00 Uhr,sowie Do 13.30 -	Service@FA-5301.fin-nrw.de	www.finanzamt-Ahaus.de	509
5	5303	Arnsberg 	Rumbecker Straße 36	59821	Arnsberg	02931/875-0	0800 10092675303	59818	59802	5245	41000000	46401501	BBK HAMM, WESTF	46650005	1020007	SPK ARNSBERG-SUNDERN	Mo-Mi 08.30 - 12.00 Uhr,Fr,und nach Vereinbarung	Service@FA-5303.fin-nrw.de	www.finanzamt-Arnsberg.de	510
5	5304	Beckum 	Elisabethstraße 19	59269	Beckum	02521/25-0	0800 10092675304	59267	59244	1452	41000000	41001501	BBK HAMM, WESTF	41250035	1000223	SPK BECKUM-WADERSLOH	MO-FR 08.30-12.00 UHR,MO AUCH 13.30-15.00 UHR,UND NACH VEREINBARUNG	Service@FA-5304.fin-nrw.de	www.finanzamt-Beckum.de	511
5	5305	Bielefeld-Innenstadt 	Ravensberger Straße 90	33607	Bielefeld	0521/548-0	0800 10092675305		33503	100371	48000000	48001500	BBK BIELEFELD	48050161	109	SPK BIELEFELD	Mo - Fr 8.30 - 12.00 Uhr,Di auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5305.fin-nrw.de	www.finanzamt-Bielefeld-Innenstadt.de	512
5	5306	Bochum-Mitte 	Castroper Str. 40 - 42	44791	Bochum	0234/514-0	0800 10092675306		44707	100729	43000000	43001500	BBK BOCHUM	43050001	1300011	SPARKASSE BOCHUM	Mo-Fr 08:30 - 12:00 Uhr,Di auch 13:30 - 15:00 Uhr,Individuelle Terminver-,einbarungen sind möglich	Service@FA-5306.fin-nrw.de	www.finanzamt-Bochum-Mitte.de	513
5	5307	Borken 	Nordring 184	46325	Borken	02861/938-0	0800 10092675307	46322	46302	1240	40000000	40001514	BBK MUENSTER, WESTF	40154530	51021137	SPARKASSE WESTMUENSTERLAND	Mo-Fr 8.30 - 12.00 Uhr,Mo 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5307.fin-nrw.de	www.finanzamt-Borken.de	514
5	5308	Bottrop 	Scharnhölzstraße 32	46236	Bottrop	02041/691-0	0800 10092675308		46205	100553	43000000	42401501	BBK BOCHUM	42451220	10009	SPK BOTTROP	Mo-Mi 08.00-12.00 Uhr,Do 07.30-12.00 u 13.30-15.00 ,Freitags geschlossen	Service@FA-5308.fin-nrw.de	www.finanzamt-Bottrop.de	515
5	5309	Brilon 	Steinweg 30	59929	Brilon	02961/788-0	0800 10092675309		59915	1260	48000000	47201502	BBK BIELEFELD	41651770	17004	SPK HOCHSAUERLAND BRILON	Mo - Fr 08:30 - 12:00 Uhr,Di auch 13:30 - 15:00 Uhr,und nach Vereinbarung	Service@FA-5309.fin-nrw.de	www.finanzamt-Brilon.de	516
5	5310	Bünde 	Lettow-Vorbeck-Str 2-10	32257	Bünde	05223/169-0	0800 10092675310		32216	1649	48000000	48001502	BBK BIELEFELD	49450120	210003000	SPARKASSE HERFORD		Service@FA-5310.fin-nrw.de	www.finanzamt-Buende.de	517
5	5311	Steinfurt 	Ochtruper Straße 2	48565	Steinfurt	02551/17-0	0800 10092675311	48563	48542	1260	40000000	40301500	BBK MUENSTER, WESTF				Mo-Fr 08.00-12.00 Uhr,Mo auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5311.fin-nrw.de	www.finanzamt-Steinfurt.de	518
5	5312	Coesfeld 	Friedrich-Ebert-Str. 8	48653	Coesfeld	02541/732-0	0800 10092675312		48633	1344	40000000	40001505	BBK MUENSTER, WESTF	40154530	59001644	SPARKASSE WESTMUENSTERLAND	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5312.fin-nrw.de	www.finanzamt-Coesfeld.de	519
5	5313	Detmold 	Wotanstraße 8	32756	Detmold	05231/972-0	0800 10092675313	32754	32706	1664	48000000	48001504	BBK BIELEFELD	47650130	4002	SPK DETMOLD	Mo. bis Fr.,Montags,und nach Vereinbarung	Service@FA-5313.fin-nrw.de	www.finanzamt-Detmold.de	520
5	5314	Dortmund-West 	Märkische Straße 124	44141	Dortmund	0231/9581-0	0800 10092675314		44047	105041	44000000	44001500	BBK DORTMUND	44050199	301001886	SPARKASSE DORTMUND	Montags geschlossen,Di - Fr 8.30 - 12.00,Do zusätzlich 13.30 - 15.00	Service@FA-5314.fin-nrw.de	www.finanzamt-Dortmund-West.de	521
5	5315	Dortmund-Hörde 	Niederhofener Str 3	44263	Dortmund	0231/4103-0	0800 10092675315		44232	300255	44000000	44001503	BBK DORTMUND	44050199	21003468	SPARKASSE DORTMUND	Mo-Do 8.30-12.00 Uhr,und nach Vereinbarung	Service@FA-5315.fin-nrw.de	www.finanzamt-Dortmund-Hoerde.de	522
5	5316	Dortmund-Unna 	Rennweg 1	44143	Dortmund	0231/5188-1	0800 10092675316		44047	105020	44000000	44001501	BBK DORTMUND	44050199	1060600	SPARKASSE DORTMUND	Mo-Fr 08.30-12.00 Uhr,und nach Vereinbarung	Service@FA-5316.fin-nrw.de	www.finanzamt-Dortmund-Unna.de	523
5	5317	Dortmund-Ost 	Nußbaumweg 210	44143	Dortmund	0231/5188-1	0800 10092675317		44047	105039	44000000	44001502	BBK DORTMUND	44050199	301001827	SPARKASSE DORTMUND	Mo - Fr 8.30 - 12.00 Uhr,und nach Vereinbarung	Service@FA-5317.fin-nrw.de	www.finanzamt-Dortmund-Ost.de	524
5	5318	Gelsenkirchen-Nord 	Rathausplatz 1	45894	Gelsenkirchen	0209/368-1	0800 10092675318		45838	200351	43000000	42001501	BBK BOCHUM	42050001	160012007	SPARKASSE GELSENKIRCHEN	Mo-Fr 08.30-12.00 Uhr,Mo auch 13.30-15.00Uhr	Service@FA-5318.fin-nrw.de	www.finanzamt-Gelsenkirchen-Nord.de	525
5	5319	Gelsenkirchen-Süd 	Zeppelinallee 9-13	45879	Gelsenkirchen	0209/173-1	0800 10092675319		45807	100753	43000000	42001500	BBK BOCHUM	42050001	101050003	SPARKASSE GELSENKIRCHEN	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr	Service@FA-5319.fin-nrw.de	www.finanzamt-Gelsenkirchen-Sued.de	526
5	5320	Gladbeck 	Jovyplatz 4	45964	Gladbeck	02043/270-1	0800 10092675320		45952	240	43000000	42401500	BBK BOCHUM	42450040	91	ST SPK GLADBECK	MO-FR 08.30-12.00 UHR,DO AUCH 13.30-15.00 UHR,UND NACH VEREINBARUNG	Service@FA-5320.fin-nrw.de	www.finanzamt-Gladbeck.de	527
5	5321	Hagen 	Schürmannstraße 7	58097	Hagen	02331/180-0	0800 10092675321		58041	4145	45000000	45001500	BBK HAGEN	45050001	100001580	SPARKASSE HAGEN	Mo-Fr,Mo auch 13.30-15.00 Uhr	Service@FA-5321.fin-nrw.de	www.finanzamt-Hagen.de	528
5	5322	Hamm 	Grünstraße 2	59065	Hamm	02381/918-0	0800 10092675322	59061	59004	1449	41000000	41001500	BBK HAMM, WESTF	41050095	90001	SPARKASSE HAMM	Mo-Do 8.30-12.00 Uhr,Mi auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5322.fin-nrw.de	www.finanzamt-Hamm.de	529
5	5323	Hattingen 	Rathausplatz 19	45525	Hattingen	02324/208-0	0800 10092675323		45502	800257	43000000	43001501	BBK BOCHUM				Mo-Fr,Di auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5323.fin-nrw.de	www.finanzamt-Hattingen.de	530
5	5324	Herford 	Wittekindstraße 5	32051	Herford	05221/188-0	0800 10092675324		32006	1642	48000000	48001503	BBK BIELEFELD	49450120	36004	SPARKASSE HERFORD	Mo,Di,Fr 7.30-12.00 Uhr,Do 7.30-17.00 Uhr,Mi geschlossen,und nach Vereinbarung	Service@FA-5324.fin-nrw.de	www.finanzamt-Herford.de	531
5	5325	Herne-Ost 	Markgrafenstraße 12	44623	Herne	02323/598-0	0800 10092675325		44602	101220	43000000	43001502	BBK BOCHUM	43250030	1012004	HERNER SPARKASSE	Rückfragen bitte nur,telefonisch oder nach,vorheriger Rücksprache mit,dem Bearbeiter	Service@FA-5325.fin-nrw.de	www.finanzamt-Herne-Ost.de	532
5	5326	Höxter 	Bismarckstraße 11	37671	Höxter	05271/969-0	0800 10092675326	37669	37652	100239	48000000	47201501	BBK BIELEFELD	47251550	3008521	SPK HOEXTER BRAKEL	Mo - Do,Do auch,und nach Vereinbarung	Service@FA-5326.fin-nrw.de	www.finanzamt-Hoexter.de	533
5	5327	Ibbenbüren 	Uphof 10	49477	Ibbenbüren	05451/920-0	0800 10092675327		49462	1263	40000000	40301501	BBK MUENSTER, WESTF	40351060	2469	KR SPK STEINFURT	Mo - Fr,Di auch	Service@FA-5327.fin-nrw.de	www.finanzamt-Ibbenbueren.de	534
5	5328	Iserlohn 	Zollernstraße 16	58636	Iserlohn	02371/969-0	0800 10092675328	58634	58585	1554	45000000	45001503	BBK HAGEN	44550045	44008	SPK DER STADT ISERLOHN	Mo - Do 08.30 - 12.00 Uhr,Do auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5328.fin-nrw.de	www.finanzamt-Iserlohn.de	535
5	5376	Münster für Groß- und Konzernbetriebsprüfung	Andreas-Hofer-Straße 50	48145	Münster	0251/934-2115	0800 10092675376											Service@FA-5376.fin-nrw.de		536
5	5329	Lemgo 	Engelb.-Kämpfer Str. 18	32657	Lemgo	05261/253-1	0800 10092675329		32632	240	48000000	48001505	BBK BIELEFELD	48250110	45005	SPARKASSE LEMGO	Mo - Fr,Do auch,und nach Vereinbarung	Service@FA-5329.fin-nrw.de	www.finanzamt-Lemgo.de	537
5	5330	Lippstadt 	Im Grünen Winkel 3	59555	Lippstadt	02941/982-0	0800 10092675330		59525	1580	41000000	46401505	BBK HAMM, WESTF	41650001	15008	ST SPK LIPPSTADT	Mo - Fr 08.30 - 12.00,Do zusätzlich 13.30 - 15.00	Service@FA-5330.fin-nrw.de	www.finanzamt-Lippstadt.de	538
5	5331	Lübbecke 	Bohlenstraße 102	32312	Lübbecke	05741/334-0	0800 10092675331		32292	1244	49000000	49001501	BBK MINDEN, WESTF	49050101	141	SPARKASSE MINDEN-LUEBBECKE	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5331.fin-nrw.de	www.finanzamt-Luebbecke.de	539
5	5332	Lüdenscheid 	Bahnhofsallee 16	58507	Lüdenscheid	02351/155-0	0800 10092675332	58505	58465	1589	45000000	45001502	BBK HAGEN	45850005	18	SPK LUEDENSCHEID	Mo-Fr 08.30-12.00 Uhr,Do auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5332.fin-nrw.de	www.finanzamt-Luedenscheid.de	540
5	5333	Lüdinghausen 	Bahnhofstraße 32	59348	Lüdinghausen	02591/930-0	0800 10092675333		59332	1243	40000000	40001506	BBK MUENSTER, WESTF	40154530	1008	SPARKASSE WESTMUENSTERLAND	vormittags: Mo.-Fr.8.30-12.00,nachmittags: Di. 13.30-15.00	Service@FA-5333.fin-nrw.de	www.finanzamt-Luedinghausen.de	541
5	5334	Meschede 	Fritz-Honsel-Straße 4	59872	Meschede	0291/950-0	0800 10092675334		59852	1265	41000000	46401502	BBK HAMM, WESTF	46451012	13003	SPK MESCHEDE	Mo-Fr 08:30 - 12:00,und nach Vereinbarung	Service@FA-5334.fin-nrw.de	www.finanzamt-Meschede.de	542
5	5335	Minden 	Heidestraße 10	32427	Minden	0571/804-1	0800 10092675335		32380	2340	49000000	49001500	BBK MINDEN, WESTF	49050101	40018145	SPARKASSE MINDEN-LUEBBECKE	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5335.fin-nrw.de	www.finanzamt-Minden.de	543
5	5336	Münster-Außenstadt 	Friedrich-Ebert-Str. 46	48153	Münster	0251/9729-0	0800 10092675336		48136	6129	40000000	40001501	BBK MUENSTER, WESTF	40050150	95031001	SPK MUENSTERLAND OST	Mo-Fr 08.30-12.00 Uhr,Mo auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5336.fin-nrw.de	www.finanzamt-Muenster-Aussenstadt.de	544
5	5337	Münster-Innenstadt 	Münzstr. 10	48143	Münster	0251/416-1	0800 10092675337		48136	6103	40000000	40001502	BBK MUENSTER, WESTF	40050150	300004	SPK MUENSTERLAND OST		Service@FA-5337.fin-nrw.de	www.finanzamt-Muenster-Innenstadt.de	545
5	5338	Olpe 	Am Gallenberg 20	57462	Olpe	02761/963-0	0800 10092675338		57443	1320	45000000	46001501	BBK HAGEN				Mo-Do 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,Freitag keine Sprechzeit	Service@FA-5338.fin-nrw.de	www.finanzamt-Olpe.de	546
5	5339	Paderborn 	Bahnhofstraße 28	33102	Paderborn	05251/100-0	0800 10092675339		33045	1520	48000000	47201500	BBK BIELEFELD	47250101	1001353	SPARKASSE PADERBORN		Service@FA-5339.fin-nrw.de	www.finanzamt-Paderborn.de	547
5	5340	Recklinghausen 	Westerholter Weg 2	45657	Recklinghausen	02361/583-0	0800 10092675340		45605	100553	43000000	42601500	BBK BOCHUM	42650150	90034158	SPK RECKLINGHAUSEN	Mo - Fr 08:30 bis 12:00,Mi auch 13:30 bis 15:00,und nach Vereinbarung	Service@FA-5340.fin-nrw.de	www.finanzamt-Recklinghausen.de	548
5	5341	Schwelm 	Bahnhofplatz 6	58332	Schwelm	02336/803-0	0800 10092675341		58316	340	45000000	45001520	BBK HAGEN	45451555	80002	ST SPK SCHWELM	Mo-Fr 8.30-12.00 Uhr,Mo,und nach Vereinbarung	Service@FA-5341.fin-nrw.de	www.finanzamt-Schwelm.de	549
5	5342	Siegen 	Weidenauer Straße 207	57076	Siegen	0271/4890-0	0800 10092675342		57025	210148	45000000	46001500	BBK HAGEN	46050001	1100114	SPK SIEGEN	Mo-Fr,Do auch 13:30 - 17:00 Uhr,und nach Vereinbarung	Service@FA-5342.fin-nrw.de	www.finanzamt-Siegen.de	550
5	5343	Soest 	Waisenhausstraße 11	59494	Soest	02921/351-0	0800 10092675343	59491	59473	1364	41000000	46401504	BBK HAMM, WESTF	41450075	208	SPARKASSE SOEST	Mo-Fr 0830-1200Uhr,und nach Vereinbarung	Service@FA-5343.fin-nrw.de	www.finanzamt-Soest.de	551
5	5344	Herne-West 	Edmund-Weber-Str. 210	44651	Herne	02325/696-0	0800 10092675344		44632	200262	43000000	43001503	BBK BOCHUM	43250030	17004	HERNER SPARKASSE	Mo-Fr 08.30-12.00 Uhr,Mo 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5344.fin-nrw.de	www.finanzamt-Herne-West.de	552
5	5345	Warburg 	Sternstraße 33	34414	Warburg	05641/771-0	0800 10092675345		34402	1226	48000000	47201503	BBK BIELEFELD	47251550	25005521	SPK HOEXTER BRAKEL		Service@FA-5345.fin-nrw.de	www.finanzamt-Warburg.de	553
5	5346	Warendorf 	Düsternstraße 43	48231	Warendorf	02581/924-0	0800 10092675346		48205	110361	40000000	40001504	BBK MUENSTER, WESTF	40050150	182	SPK MUENSTERLAND OST	Mo-Fr 08.30-12.00 Uhr,Do auch 13.30-15.00 Uhr,und nach Vereinbarung	Service@FA-5346.fin-nrw.de	www.finanzamt-Warendorf.de	554
5	5347	Wiedenbrück 	Hauptstraße 34	33378	Rheda-Wiedenbrück	05242/934-0	0800 10092675347	33372	33342	1429	48000000	47801500	BBK BIELEFELD	47853520	5231	KREISSPARKASSE WIEDENBRUECK	Mo - Fr 08.30 - 12.00 Uhr,Do auch 13.30 - 14.30 Uhr	Service@FA-5347.fin-nrw.de	www.finanzamt-Wiedenbrueck.de	555
5	5348	Witten 	Ruhrstraße 43	58452	Witten	02302/921-0	0800 10092675348		58404	1420	43000000	43001505	BBK BOCHUM	45250035	6007	ST SPK WITTEN	Mo - Fr 08.30 - 12.00 Uhr,Mo auch 13.30 - 15.00 Uhr,und nach Vereinbarung	Service@FA-5348.fin-nrw.de	www.finanzamt-Witten.de	556
5	5349	Bielefeld-Außenstadt 	Ravensberger Straße 125	33607	Bielefeld	0521/548-0	0800 10092675349		33503	100331	48000000	48001501	BBK BIELEFELD	48050161	180000	SPK BIELEFELD	Mo - Fr 08:30 - 12:00 Uhr,Do auch 13:30 - 15:00 Uhr,und nach Vereinbarung	Service@FA-5349.fin-nrw.de	www.finanzamt-Bielefeld-Aussenstadt.de	557
5	5350	Bochum-Süd 	Königsallee 21	44789	Bochum	0234/3337-0	0800 10092675350		44707	100764	43000000	43001504	BBK BOCHUM	43050001	1307792	SPARKASSE BOCHUM	Mo-Fr 08:30-12:00 Uhr,Di auch 13:30-15:00 Uhr	Service@FA-5350.fin-nrw.de	www.finanzamt-Bochum-Sued.de	558
5	5351	Gütersloh 	Neuenkirchener Str. 86	33332	Gütersloh	05241/3071-0	0800 10092675351		33245	1565	48000000	48001506	BBK BIELEFELD				Mo - Fr 08.30 - 12.00 Uhr,Do auch 13.30 - 15.00 Uhr	Service@FA-5351.fin-nrw.de	www.finanzamt-Guetersloh.de	559
5	5359	Marl 	Brassertstraße 1	45768	Marl	02365/516-0	0800 10092675359	45765	45744	1420	43000000	42601501	BBK BOCHUM	42650150	40020000	SPK RECKLINGHAUSEN		Service@FA-5359.fin-nrw.de	www.finanzamt-Marl.de	560
5	5371	Bielefeld für Groß- und Konzernbetriebsprüfung	Ravensberger Str. 90	33607	Bielefeld	0521/548-0	0800 10092675371		33511	101150								Service@FA-5371.fin-nrw.de		561
5	5372	Herne für Groß- und Konzernbetriebsprüfung	Hauptstr. 123	44651	Herne	02325/693-0	0800 10092675372		44636	200620								Service@FA-5372.fin-nrw.de		562
5	5373	Detmold für Groß- und Konzernbetriebsprüfung	Richthofenstrasse 94	32756	Detmold	05231/974-300	0800 10092675373		32706	1664								Service@FA-5373.fin-nrw.de		563
5	5374	Dortmund für Groß- und Konzernbetriebsprüfung	Nußbaumweg 210	44143	Dortmund	0231/5188-8953	0800 10092675374		44047	105039								Service@FA-5374.fin-nrw.de		564
5	5375	Hagen für Groß- und Konzernbetriebsprüfung	Hochstr. 43 - 45	58095	Hagen	02331/3760-0	0800 10092675375											Service@FA-5375.fin-nrw.de		565
5	5381	Bielefeld f. Steuerfahndung und Steuerstrafsachen	Ravensberger Str. 90	33607	Bielefeld	0521/548-0	0800 10092675381		33511	101173	48000000	48001500	BBK BIELEFELD	48050161	109	SPK BIELEFELD		Service@FA-5381.fin-nrw.de		566
5	5382	Bochum f. Steuerfahndung und Steuerstrafsachen	Uhlandstr. 37	44791	Bochum	0234/5878-0	0800 10092675382		44707	100768	43000000	43001500	BBK BOCHUM	43050001	1300011	SPARKASSE BOCHUM		Service@FA-5382.fin-nrw.de		567
5	5383	Hagen f. Steuerfahndung und Steuerstrafsachen	Becheltestr. 32	58089	Hagen	02331/3089-0	0800 10092675383		58041	4143	45000000	145001500	BBK HAGEN	45050001	100001580	SPARKASSE HAGEN		Service@FA-5383.fin-nrw.de		568
5	5384	Münster f. Steuerfahndung und Steuerstrafsachen	Hohenzollernring 80	48145	Münster	0251/9370-0	0800 10092675384				40000000	40001501	BBK MUENSTER, WESTF	40050150	95031001	SPK MUENSTERLAND OST		Service@FA-5384.fin-nrw.de		569
9	9101	Augsburg-Stadt Arbeitnehmerbereich	Prinzregentenpl. 2	86150	Augsburg	0821 506-01	0821 506-2222		86135	10 00 65	72000000	72001500	BBK AUGSBURG	72050000	24109	ST SPK AUGSBURG	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-17:30 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-a-s.bayern.de	www.finanzamt-augsburg-stadt.de	570
9	9102	Augsburg-Land 	Peutingerstr. 25	86152	Augsburg	0821 506-02	0821 506-3270	86144	86031	11 06 69	72000000	72001501	BBK AUGSBURG	72050101	8003	KR SPK AUGSBURG	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-a-l.bayern.de	www.finanzamt-augsburg-land.de	571
9	9103	Augsburg-Stadt 	Prinzregentenpl. 2	86150	Augsburg	0821 506-01	0821 506-2222		86135	10 00 65	72000000	72001500	BBK AUGSBURG	72050000	24109	ST SPK AUGSBURG	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-17:30 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-a-s.bayern.de	www.finanzamt-augsburg-stadt.de	572
9	9104	Bad Tölz -Außenstelle des Finanzamts Wolfratshausen-	Prof.-Max-Lange-Platz 2	83646	Bad Tölz	08041 8005-0	08041 8005-185		83634	1420	70000000	70001505	BBK MUENCHEN	70054306	31054	SPK BAD TOELZ-WOLFRATSHAUSE	Servicezentrum: Mo 7:30-18:00 Uhr, Di-Do 7:30-13:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-toel.bayern.de	www.finanzamt-bad-toelz.de	573
9	9105	Berchtesgaden 	Salzburger Str. 6	83471	Berchtesgaden	08652 960-0	08652 960-100		83461	1154	71000000	71001500	BBK MUENCHEN EH B REICHENHA	71050000	350009	SPK BERCHTESGADENER LAND	Servicezentrum: Mo-Do 7:30-13:30 Uhr (Nov-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-bgd.bayern.de	www.finanzamt-berchtesgaden.de	574
9	9106	Burghausen 	Tittmoninger Str. 1	84489	Burghausen	08677 8706-0	08677 8706-100		84480	1257	71000000	71001501	BBK MUENCHEN EH B REICHENHA	71051010	250001	KR SPK ALTOETTING-BURGHAUSE	Servicezentrum: Mo-Mi 7:45-15:00 Uhr Do 7:45-17:00 Uhr, Fr 7:45-12:00 Uhr	poststelle@fa-burgh.bayern.de	www.finanzamt-burghausen.de	575
9	9107	Dachau 	Bürgermeister-Zauner-Ring 2	85221	Dachau	08131 701-0	08131 701-111	85219	85202	1280	70000000	70001507	BBK MUENCHEN	70051540	908327	SPARKASSE DACHAU	Servicezentrum: Mo, Di, Do 7:30-15:00 Uhr (Nov-Mai Do 7:30-18:00 Uhr), Mi,Fr 7:30-12:00 Uhr	poststelle@fa-dah.bayern.de	www.finanzamt-dachau.de	576
9	9108	Deggendorf 	Pfleggasse 18	94469	Deggendorf	0991 384-0	0991 384-150		94453	1355	75000000	75001506	BBK REGENSBURG	74150000	380019950	SPK DEGGENDORF	Servicezentrum: Mo, Di, Do 7:45-15:00 Uhr (Jan-Mai Do 7:45-18:00 Uhr), Mi, Fr 7:45-12:00 Uhr	poststelle@fa-deg.bayern.de	www.finanzamt-deggendorf.de	577
9	9109	Dillingen 	Schloßstr. 3	89407	Dillingen	09071 507-0	09071 507-300	89401			72000000	72001503	BBK AUGSBURG	72251520	24066	KR U ST SPK DILLINGEN	Servicezentrum: Mo, Di, Mi, Fr 7:30-13:00 Uhr, Do 7:30-13:00 Uhr u. 14:00-18:00 Uhr	poststelle@fa-dlg.bayern.de	www.finanzamt-dillingen.de	578
9	9110	Dingolfing 	Obere Stadt 44	84130	Dingolfing	08731 504-0	08731 504-190		84122	1156	74300000	74301501	BBK REGENSBURG EH LANDSHUT	74351310	100017805	SPK DINGOLFING-LANDAU	Servicezentrum: Mo-Di 7:30-15:00 Uhr, Mi, Fr 7:30-12:00 Uhr, Do 7:30-17:00 Uhr	poststelle@fa-dgf.bayern.de	www.finanzamt-dingolfing.de	579
9	9111	Donauwörth -Außenstelle des Finanzamts Nördlingen-	Sallingerstr. 2	86609	Donauwörth	0906 77-0	0906 77-150	86607			72000000	72001502	BBK AUGSBURG	70010080	1632-809	POSTBANK -GIRO- MUENCHEN	Servicezentrum: Mo-Mi 7:30-13:30 Uhr, Do 7:30-18:00 Uhr, Fr 7:30 -13:00 Uhr	poststelle@fa-don.bayern.de	www.finanzamt-donauwoerth.de	580
9	9112	Ebersberg 	Schloßplatz 1-3	85560	Ebersberg	08092 267-0	08092 267-102				70000000	70001508	BBK MUENCHEN	70051805	75	KR SPK EBERSBERG	Servicezentrum: Mo-Do 7:30-13:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-ebe.bayern.de	www.finanzamt-ebersberg.de	581
9	9113	Eggenfelden 	Pfarrkirchner Str. 71	84307	Eggenfelden	08721 981-0	08721 981-200		84301	1160	74300000	74301502	BBK REGENSBURG EH LANDSHUT	74351430	5603	SPK ROTTAL-INN EGGENFELDEN	Servicezentrum: Mo, Di, Do 7:45-15:00 Uhr (Jan-Mai Do 7:45-17:00 Uhr), Mi, Fr 7:30-12:00 Uhr	poststelle@fa-eg.bayern.de	www.finanzamt-eggenfelden.de	582
9	9114	Erding 	Münchener Str. 31	85435	Erding	08122 188-0	08122 188-150		85422	1262	70000000	70001509	BBK MUENCHEN	70051995	8003	SPK ERDING-DORFEN	Servicezentrum: Mo-Mi 7:30-14:00 Uhr Do 7:30-18:00 Uhr, Fr 7:30 -12:00 Uhr	poststelle@fa-ed.bayern.de	www.finanzamt-erding.de	583
9	9115	Freising 	Prinz-Ludwig-Str. 26	85354	Freising	08161 493-0	08161 493-106	85350	85313	1343	70000000	70001510	BBK MUENCHEN	70021180	4001010	HYPOVEREINSBK FREISING	Servicezentrum: Mo-Di 7:30-15:00 Uhr, Mi, Fr 7:30-12:00 Uhr, Do 7:30-18:00 Uhr	poststelle@fa-fs.bayern.de	www.finanzamt-freising.de	584
9	9117	Fürstenfeldbruck 	Münchner Str.36	82256	Fürstenfeldbruck	08141 60-0	08141 60-150		82242	1261	70000000	70001511	BBK MUENCHEN	70053070	8007221	SPK FUERSTENFELDBRUCK	Servicezentrum: Mo-Mi 7:30-14:30 Uhr, Do 7:30-17:30 Uhr, Fr 7:30 -12:30 Uhr	poststelle@fa-ffb.bayern.de	www.finanzamt-fuerstenfeldbruck.de	585
9	9118	Füssen -Außenstelle des Finanzamts Kaufbeuren-	Rupprechtstr. 1	87629	Füssen	08362 5056-0	08362 5056-290		87620	1460	73300000	73301510	BBK AUGSBURG EH KEMPTEN	73350000	310500525	SPARKASSE ALLGAEU	Servicezentrum: Mo-Mi 8:00-15:00 Uhr, Do 8:00-18:00 Uhr, Fr 8:00-13:00 Uhr	poststelle@fa-fues.bayern.de	www.finanzamt-fuessen.de	586
9	9119	Garmisch-Partenkirchen 	Von-Brug-Str. 5	82467	Garmisch-Partenkirchen	08821 700-0	08821 700-111		82453	1363	70000000	70001520	BBK MUENCHEN	70350000	505	KR SPK GARMISCH-PARTENKIRCH	Servicezentrum: Mo-Mi 7:30-14:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-gap.bayern.de	www.finanzamt-garmisch-partenkirchen.de	587
9	9120	Bad Griesbach -Außenstelle des Finanzamts Passau-	Schloßhof 5-6	94086	Bad Griesbach	0851 504-0	0851 504-2222		94083	1222	74000000	74001500	BBK REGENSBURG EH PASSAU	74050000	16170	SPK PASSAU	Servicezentrum: Mo-Mi 7:30-14:00 Uhr, Do 7:30-17:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-griesb.bayern.de	www.finanzamt-bad-griesbach.de	588
9	9121	Günzburg 	Schloßpl. 4	89312	Günzburg	08221 902-0	08221 902-209		89302	1241	72000000	72001505	BBK AUGSBURG	72051840	18	SPK GUENZBURG-KRUMBACH	Servicezentrum: Mo-Di 7:45-12:30 u. 13:30-15:30, Mi, Fr 7:45-12:30, Do 7:45-12:30 u. 13:30-18:00	poststelle@fa-gz.bayern.de	www.finanzamt-guenzburg.de	589
9	9153	Passau mit Außenstellen 	Innstr. 36	94032	Passau	0851 504-0	0851 504-1410		94030	1450	74000000	740 01500	BBK REGENSBURG EH PASSAU	74050000	16170	SPK PASSAU	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-17:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-pa.bayern.de	www.finanzamt-passau.de	590
9	9123	Immenstadt -Außenstelle des Finanzamts Kempten-	Rothenfelsstr. 18	87509	Immenstadt	08323 801-0	08323 801-235		87502	1251	73300000	73301520	BBK AUGSBURG EH KEMPTEN	73350000	113464	SPARKASSE ALLGAEU	Servicezentrum: Mo-Do 7:30-14:00 Uhr (Okt-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-immen.bayern.de	www.finanzamt-immenstadt.de	591
9	9124	Ingolstadt 	Esplanade 38	85049	Ingolstadt	0841 311-0	0841 311-133		85019	210451	72100000	72101500	BBK MUENCHEN EH INGOLSTADT	72150000	25 080	SPARKASSE INGOLSTADT	Servicezentrum: Mo-Di 7:15-13:30, Mi 7:15-12:30, Do 7:15-17:30, Fr 7:15-12:00	poststelle@fa-in.bayern.de	www.finanzamt-ingolstadt.de	592
9	9125	Kaufbeuren 	Remboldstr. 21	87600	Kaufbeuren	08341 802-0	08341 802-221		87572	1260	73300000	73401500	BBK AUGSBURG EH KEMPTEN	73450000	25700	KR U ST SPK KAUFBEUREN	Servicezentrum: Mo-Mi 7:30-14:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-kf.bayern.de	www.finanzamt-kaufbeuren.de	593
9	9126	Kelheim 	Klosterstr. 1	93309	Kelheim	09441 201-0	09441 201-201		93302	1252	75000000	75001501	BBK REGENSBURG	75051565	190201301	KREISSPARKASSE KELHEIM	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-17:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-keh.bayern.de	www.finanzamt-kelheim.de	594
9	9127	Kempten (Allgäu) 	Am Stadtpark 3	87435	Kempten	0831 256-0	0831 256-260		87405	1520	73300000	73301500	BBK AUGSBURG EH KEMPTEN	73350000	117	SPARKASSE ALLGAEU	Servicezentrum: Mo-Do 7:30-14:30 Uhr (Nov-Mai Do 7:20-17:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-ke.bayern.de	www.finanzamt-kempten.de	595
9	9131	Landsberg 	Israel-Beker-Str. 20	86899	Landsberg	08191 332-0	08191 332-108	86896			72000000	72001504	BBK AUGSBURG	70052060	158	SPK LANDSBERG-DIESSEN	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-16:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-ll.bayern.de	www.finanzamt-landsberg.de	596
9	9132	Landshut 	Maximilianstr. 21	84028	Landshut	0871 8529-000	0871 8529-360				74300000	74301500	BBK REGENSBURG EH LANDSHUT	74350000	10111	SPK LANDSHUT	Servicezentrum: Mo-Di 8:00-15:00 Uhr, Mi, Fr 8:00-12:00 Uhr, Do 8:00-18:00 Uhr	poststelle@fa-la.bayern.de	www.finanzamt-landshut.de	597
9	9133	Laufen - Außenstelle des Finanzamts Berchtesgaden-	Rottmayrstr. 13	83410	Laufen	08682 918-0	08682 918-100		83406	1251	71000000	71001502	BBK MUENCHEN EH B REICHENHA	71050000	59998	SPK BERCHTESGADENER LAND	Servicezentrum: Mo-Do 7:30-13:30 Uhr (Nov-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-lauf.bayern.de	www.finanzamt-laufen.de	598
9	9134	Lindau 	Brettermarkt 4	88131	Lindau	08382 916-0	08382 916-100		88103	1320	73300000	73501500	BBK AUGSBURG EH KEMPTEN	73150000	620018333	SPK MEMMINGEN-LINDAU-MINDEL	Servicezentrum: Mo-Do 7:30-14:00 Uhr (Nov-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-li.bayern.de	www.finanzamt-lindau.de	599
9	9138	Memmingen 	Bodenseestr. 6	87700	Memmingen	08331 608-0	08331 608-165		87683	1345	73100000	73101500	BBK AUGSBURG EH MEMMINGEN	73150000	210005	SPK MEMMINGEN-LINDAU-MINDEL	Servicezentrum: Mo-Do 7:30-14:00 Uhr, (Nov-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-mm.bayern.de	www.finanzamt-memmingen.de	600
9	9139	Miesbach 	Schlierseer Str. 5	83714	Miesbach	08025 709-0	08025 709-500		83711	302	70000000	70001512	BBK MUENCHEN	71152570	4002	KR SPK MIESBACH-TEGERNSEE	Servicezentrum: Mo, Di, Mi, Fr 7:30-14:00 Uhr, Do 7:30-18:00 Uhr	poststelle@fa-mb.bayern.de	www.finanzamt-miesbach.de	601
9	9140	Mindelheim -Außenstelle des Finanzamts Memmingen-	Bahnhofstr. 16	87719	Mindelheim	08261 9912-0	08261 9912-300		87711	1165	73100000	73101502	BBK AUGSBURG EH MEMMINGEN	73150000	810004788	SPK MEMMINGEN-LINDAU-MINDEL	Servicezentrum: Mo-Mi 7:30-12:00 u. 13:30-15:30, Do 7:30-12:00 u. 13:30-17:30, Fr 7:30-12:00	poststelle@fa-mn.bayern.de	www.finanzamt-mindelheim.de	602
9	9141	Mühldorf 	Katharinenplatz 16	84453	Mühldorf	08631 616-0	08631 616-100		84445	1369	71100000	71101501	BBK MUENCHEN EH ROSENHEIM	71151020	885	KR SPK MUEHLDORF	Servicezentrum: Mo-Mi 7:30-14:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-mue.bayern.de	www.finanzamt-muehldorf.de	603
9	9142	München f. Körpersch. Bewertung des Grundbesitzes	Meiserstr. 4	80333	München	089 1252-0	089 1252-7777	80275	80008	20 09 26	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-koe.bayern.de	www.finanzamt-muenchen-koerperschaften.de	604
9	9143	München f. Körpersch. Körperschaftsteuer	Meiserstr. 4	80333	München	089 1252-0	089 1252-7777	80275	80008	20 09 26	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-koe.bayern.de	www.finanzamt-muenchen-koerperschaften.de	605
9	9144	München I 	Karlstr. 9-11	80333	München	089 1252-0	089 1252-1111	80276	80008	20 09 05	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	poststelle@fa-m1.bayern.de	www.finanzamt-muenchen-I.de	606
9	9145	München III 	Deroystr. 18	80335	München	089 1252-0	089 1252-3333	80301			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	poststelle@fa-m3.bayern.de	www.finanzamt-muenchen-III.de	607
9	9146	München IV 	Deroystr. 4 Aufgang I	80335	München	089 1252-0	089 1252-4000	80302			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	poststelle@fa-m4.bayern.de	www.finanzamt-muenchen-IV.de	608
9	9147	München II 	Deroystr. 20	80335	München	089 1252-0	089 1252-2222	80269			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	poststelle@fa-m2.bayern.de	www.finanzamt-muenchen-II.de	609
9	9148	München V 	Deroystr. 4 Aufgang II	80335	München	089 1252-0	089 1252-5281	80303			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	poststelle@fa-m5.bayern.de	www.finanzamt-muenchen-V.de	610
9	9149	München-Zentral Erhebung, Vollstreckung	Winzererstr. 47a	80797	München	089 3065-0	089 3065-1900	80784			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-zfa.bayern.de	www.finanzamt-muenchen-zentral.de	611
9	9150	Neuburg -Außenstelle des Finanzamts Schrobenhausen-	Fünfzehnerstr. 7	86633	Neuburg	08252 918-0	08252 918-222		86618	1320	72100000	72101505	BBK MUENCHEN EH INGOLSTADT	72151880	104000	ST SPK SCHROBENHAUSEN	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:30 Uhr	poststelle@fa-nd.bayern.de	www.finanzamt-neuburg.de	612
9	9151	Neu-Ulm 	Nelsonallee 5	89231	Neu-Ulm	0731 7045-0	0731 7045-500	89229	89204	1460	63000000	63001501	BBK ULM, DONAU	73050000	430008425	SPK NEU-ULM ILLERTISSEN	Servicezentrum: Mo, Di, Mi, Fr 8:00-13:00 Uhr, Do 8:00-13:00 Uhr u. 14:00-18:00 Uhr	poststelle@fa-nu.bayern.de	www.finanzamt-neu-ulm.de	613
9	9152	Nördlingen 	Tändelmarkt 1	86720	Nördlingen	09081 215-0	09081 215-100		86715	1521	72000000	72001506	BBK AUGSBURG	72250000	111500	SPARKASSE NOERDLINGEN	Servicezentrum: Mo, Di, Mi, Fr 7:30-13:00 Uhr, Do 7:30-13:00 Uhr u. 14:00-18:00 Uhr	poststelle@fa-noe.bayern.de	www.finanzamt-noerdlingen.de	614
9	9154	Pfaffenhofen 	Schirmbeckstr. 5	85276	Pfaffenhofen a. d. Ilm	08441 77-0	08441 77-199		85265	1543	72100000	72101504	BBK MUENCHEN EH INGOLSTADT	72151650	7302	VER SPK PFAFFENHOFEN	Servicezentrum: Mo-Mi 7:30-14:30 Uhr, Do 7:30-17:30 Uhr, Fr 7:30-12:30 Uhr	poststelle@fa-paf.bayern.de	www.finanzamt-pfaffenhofen.de	615
9	9156	Rosenheim m. ASt Wasserburg 	Wittelsbacherstr. 25	83022	Rosenheim	08031 201-0	08031 201-222		83002	100255	71100000	71101500	BBK MUENCHEN EH ROSENHEIM	71150000	34462	SPK ROSENHEIM	Servicezentrum: Mo-Do 7:30-14:00 Uhr, (Okt-Mai Do 7:30-17:00 Uhr), Fr 7:30-12.00 Uhr	poststelle@fa-ro.bayern.de	www.finanzamt-rosenheim.de	616
9	9157	Grafenau 	Friedhofstr. 1	94481	Grafenau	08552 423-0	08552 423-170				75000000	75001507	BBK REGENSBURG	70010080	1621-806	POSTBANK -GIRO- MUENCHEN	Servicezentrum: Mo, Di 7:30-15:00 Uhr, Mi, Fr 7:30-12:00 Uhr, Do 7:30-18:00 Uhr	poststelle@fa-gra.bayern.de	www.finanzamt-grafenau.de	617
9	9158	Schongau - Außenstelle des Finanzamts Weilheim-Schongau -	Rentamtstr. 1	86956	Schongau	0881 184-0	0881 184-373		86951	1147	70000000	70001521	BBK MUENCHEN	70351030	20149	VER SPK WEILHEIM	Servicezentrum: Mo-Do 7:30-14:00 Uhr (Okt-Jun Do 7:30-17:30 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-sog.bayern.de	www.finanzamt-schongau.de	618
9	9159	Schrobenhausen m. ASt Neuburg  	Rot-Kreuz-Str. 2	86529	Schrobenhausen	08252 918-0	08252 918-430		86522	1269	72100000	72101505	BBK MUENCHEN EH INGOLSTADT	72151880	104000	ST SPK SCHROBENHAUSEN	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:30 Uhr	poststelle@fa-sob.bayern.de	www.finanzamt-schrobenhausen.de	619
9	9161	Starnberg 	Schloßbergstr.	82319	Starnberg	08151 778-0	08151 778-250		82317	1251	70000000	70001513	BBK MUENCHEN	70250150	430064295	KR SPK MUENCHEN STARNBERG	Servicezentrum: Mo-Mi 7:30-15:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-13:00 Uhr	poststelle@fa-sta.bayern.de	www.finanzamt-starnberg.de	620
9	9162	Straubing 	Fürstenstr. 9	94315	Straubing	09421 941-0	09421 941-272		94301	151	75000000	75001502	BBK REGENSBURG	74250000	240017707	SPK STRAUBING-BOGEN	Servicezentrum: Mo, Di, Mi, Fr 7:30-13:00 Uhr, Do 7:30-18:00 Uhr	poststelle@fa-sr.bayern.de	www.finanzamt-straubing.de	621
9	9163	Traunstein 	Herzog-Otto-Str. 6	83278	Traunstein	0861 701-0	0861 701-338	83276	83263	1309	71000000	71001503	BBK MUENCHEN EH B REICHENHA	71052050	7070	KR SPK TRAUNSTEIN-TROSTBERG	Servicezentrum: Mo-Do 7:30-14:00 Uhr (Okt.-Mai Do 7:30-18:00 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-ts.bayern.de	www.finanzamt-traunstein.de	622
9	9164	Viechtach -Außenstelle des Finanzamts Zwiesel-	Mönchshofstr. 27	94234	Viechtach	09922 507-0	09922 507-399		94228	1162	75000000	75001508	BBK REGENSBURG	74151450	240001008	SPARKASSE REGEN-VIECHTACH	Servicezentrum: Mo-Di 7:45-15:00 Uhr, Mi, Fr 7:45-12:00 Uhr, Do 7:45-18:00 Uhr	poststelle@fa-viech.bayern.de	www.finanzamt-viechtach.de	623
9	9166	Vilshofen -Außenstelle des Finanzamts Passau-	Kapuzinerstr. 36	94474	Vilshofen	0851 504-0	0851 504-2465				74000000	74001500	BBK REGENSBURG EH PASSAU	74050000	16170	SPK PASSAU	Servicezentrum: Mo-Mi 7:30-14:00 Uhr, Do 7:30-17:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-vof.bayern.de	www.finanzamt-vilshofen.de	624
9	9167	Wasserburg -Außenstelle des Finanzamts Rosenheim-	Rosenheimer Str. 16	83512	Wasserburg	08037 201-0	08037 201-150		83502	1280	71100000	71101500	BBK MUENCHEN EH ROSENHEIM	71150000	34462	SPK ROSENHEIM	Servicezentrum: Mo-Do 7:30-14:00 Uhr, (Okt-Mai Do 7:30-17:00 Uhr), Fr 7:30-12.00 Uhr	poststelle@fa-ws.bayern.de	www.finanzamt-wasserburg.de	625
9	9168	Weilheim-Schongau 	Hofstr. 23	82362	Weilheim	0881 184-0	0881 184-500		82352	1264	70000000	70001521	BBK MUENCHEN	70351030	20149	VER SPK WEILHEIM	Servicezentrum: Mo-Do 7:30-14:00 Uhr (Okt-Jun Do 7:30-17:30 Uhr), Fr 7:30-12:00 Uhr	poststelle@fa-wm.bayern.de	www.finanzamt-weilheim.de	626
9	9169	Wolfratshausen 	Heimgartenstr. 5	82515	Wolfratshausen	08171 25-0	08171 25-150		82504	1444	70000000	70001514	BBK MUENCHEN	70054306	505	SPK BAD TOELZ-WOLFRATSHAUSE	Servicezentrum: Mo-MI 7:30-14:00 Uhr, Do 7:30-17:00 Uhr, Fr 7:30-12:30 Uhr	poststelle@fa-wor.bayern.de	www.finanzamt-wolfratshausen.de	627
9	9170	Zwiesel m. ASt Viechtach 	Stadtplatz 16	94227	Zwiesel	09922 507-0	09922 507-200		94221	1262	75000000	75001508	BBK REGENSBURG	74151450	240001008	SPARKASSE REGEN-VIECHTACH	Servicezentrum: Mo-Di 7:45-15:00 Uhr, Mi, Fr 7:45-12:00 Uhr, Do 7:45-18:00 Uhr	poststelle@fa-zwi.bayern.de	www.finanzamt-zwiesel.de	628
9	9171	Eichstätt 	Residenzplatz 8	85072	Eichstätt	08421 6007-0	08421 6007-400	85071	85065	1163	72100000	72101501	BBK MUENCHEN EH INGOLSTADT	72151340	1214	SPARKASSE EICHSTAETT	Servicezentrum: Mo, Di, Mi 7:30-14:00 Uhr, Do 7:30-18:00 Uhr, Fr 7:30-12:00 Uhr	poststelle@fa-ei.bayern.de	www.finanzamt-eichstaett.de	629
9	9180	München f. Körpersch. 	Meiserstr. 4	80333	München	089 1252-0	089 1252-7777	80275	80008	20 09 26	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-koe.bayern.de	www.finanzamt-muenchen-koerperschaften.de	630
9	9181	München I Arbeitnehmerbereich	Karlstr. 9/11	80333	München	089 1252-0	089 1252-1111	80276	80008	20 09 05	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	Poststelle@fa-m1-BS.bayern.de	www.finanzamt-muenchen-I.de	631
9	9182	München II Arbeitnehmerbereich	Deroystr. 20	80335	München	089 1252-0	089 1252-2888	80269			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	Poststelle@fa-m2-BS.bayern.de	www.finanzamt-muenchen-II.de	632
9	9183	München III Arbeitnehmerbereich	Deroystr. 18	80335	München	089 1252-0	089 1252-3788	80301			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	Poststelle@fa-m3-BS.bayern.de	www.finanzamt-muenchen-III.de	633
9	9184	München IV Arbeitnehmerbereich	Deroystr. 4 Aufgang I	80335	München	089 1252-0	089 1252-4820	80302			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	Poststelle@fa-m4-BS.bayern.de	www.finanzamt-muenchen-IV.de	634
9	9185	München V Arbeitnehmerbereich	Deroystr. 4 Aufgang II	80335	München	089 1252-0	089 1252-5799	80303			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Servicezentrum Deroystr. 6: Mo-Mi 7:30-16:00, Do 7:30-18:00, Fr 7:30-12:30 (i. Ü. nach Vereinb.)	Poststelle@fa-m5-BS.bayern.de	www.finanzamt-muenchen-V.de	635
9	9187	München f. Körpersch. 	Meiserstr. 4	80333	München	089 1252-0	089 1252-7777	80275	80008	20 09 26	70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-koe.bayern.de	www.finanzamt-muenchen-koerperschaften.de	636
9	9189	München-Zentral Kraftfahrzeugsteuer	Winzererstr. 47a	80797	München	089 3065-0	089 3065-1900	80784			70050000	24962	BAYERNLB MUENCHEN	70000000	70001506	BBK MUENCHEN	Mo, Di, Do, Fr 8:00-12:00 Uhr, Mi geschlossen	poststelle@fa-m-zfa.bayern.de	www.finanzamt-muenchen-zentral.de	637
9	9201	Amberg 	Kirchensteig 2	92224	Amberg	09621 36-0	09621 36-413		92204	1452	75300000	75301503	BBK REGENSBURG EH WEIDEN	75250000	190011122	SPARKASSE AMBERG-SULZBACH	Servicezentrum: Mo, Die, Mi, Fr: 07:30 - 12:00 UhrDo: 07:30 - 17:30 Uhr	poststelle@fa-am.bayern.de	www.finanzamt-amberg.de	638
9	9202	Obernburg a. Main mit Außenstelle Amorbach	Schneeberger Str. 1	63916	Amorbach	09373 202-0	09373 202-100		63912	1160	79500000	79501502	BBK WUERZBURG EH ASCHAFFENB	79650000	620300111	SPK MILTENBERG-OBERNBURG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-amorb.bayern.de	www.finanzamt-amorbach.de	639
9	9203	Ansbach mit Außenstellen	Mozartstr. 25	91522	Ansbach	0981 16-0	0981 16-333		91511	608	76500000	76501500	BBK NUERNBERG EH ANSBACH	76550000	215004	VER SPK ANSBACH	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-an.bayern.de	www.finanzamt-ansbach.de	640
9	9204	Aschaffenburg 	Auhofstr. 13	63741	Aschaffenburg	06021 492-0	06021 492-1000	63736			79500000	79501500	BBK WUERZBURG EH ASCHAFFENB	79550000	8375	SPK ASCHAFFENBURG ALZENAU	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 8:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-ab.bayern.de	www.finanzamt-aschaffenburg.de	641
9	9205	Bad Kissingen 	Bibrastr. 10	97688	Bad Kissingen	0971 8021-0	0971 8021-200		97663	1360	79300000	79301501	BBK WUERZBURG EH SCHWEINFUR	79351010	10009	SPK BAD KISSINGEN	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-kg.bayern.de	/www.finanzamt-bad-kissingen.de	642
9	9206	Bad Neustadt a.d.S. 	Meininger Str. 39	97616	Bad Neustadt	09771 9104-0	09771 9104-444	97615			79300000	79301502	BBK WUERZBURG EH SCHWEINFUR	79353090	7005	SPK BAD NEUSTADT A D SAALE	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-nes.bayern.de	www.finanzamt-bad-neustadt.de	643
9	9207	Bamberg 	Martin-Luther-Str. 1	96050	Bamberg	0951 84-0	0951 84-230	96045			77000000	77001500	BBK NUERNBERG EH BAMBERG	77050000	30700	SPK BAMBERG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-ba.bayern.de	www.finanzamt-bamberg.de	644
9	9208	Bayreuth 	Maximilianstr. 12/14	95444	Bayreuth	0921 609-0	0921 609-254		95422	110361	77300000	773 01500	BBK BAYREUTH	77350110	9033333	SPARKASSE BAYREUTH	Servicezentrum: Mo - Mi: 07:30 - 14:00 Uhr, Do: 07:30 - 17:00 Uhr, Fr: 07:30	poststelle@fa-bt.bayern.de	www.finanzamt-bayreuth.de	645
9	9211	Cham mit Außenstellen 	Reberstr. 2	93413	Cham	09971 488-0	09971 488-199		93402	1253	74221170	344 755 205	HYPOVEREINSBK CHAM, OBERPF	76010085	1735-858	POSTBANK NUERNBERG	Servicezentrum: Mo - Mi: 07:30 - 15:00 Uhr, Do: 07:30 - 18:00 Uhr, Fr: 07:30	poststelle@fa-cha.bayern.de	www.finanzamt-cham.de	646
9	9212	Coburg 	Rodacher Straße 4	96450	Coburg	09561 646-0	09561 646-130		96406	1653	77000000	78301500	BBK NUERNBERG EH BAMBERG	78350000	7450	VER SPK COBURG	Servicezentrum: Mo - Fr: 08:00 - 13:00 Uhr, Do: 14:00 - 18:00 Uhr	poststelle@fa-co.bayern.de	www.finanzamt-coburg.de	647
9	9213	Dinkelsbühl - Außenstelle des  Finanzamts Ansbach -	Föhrenberggasse 30	91550	Dinkelsbühl	0981 16-0	09851 5737-607				76500000	76501500	BBK NUERNBERG EH ANSBACH	76550000	215004	VER SPK ANSBACH	Servicezentrum: Mo - Mi: 08:00 - 14:00, Do: 08:00 - 18:00 Uhr, Fr: 08:00 -	poststelle@fa-dkb.bayern.de	www.finanzamt-dinkelsbuehl.de	648
9	9214	Ebern - Außenstelle des Finanzamts Zeil -	Rittergasse 1	96104	Ebern	09524 824-0	09524 824-225				79300000	79301505	BBK WUERZBURG EH SCHWEINFUR	79351730	500900	SPK OSTUNTERFRANKEN	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-ebn.bayern.de	www.finanzamt-ebern.de	649
9	9216	Erlangen 	Schubertstr 10	91052	Erlangen	09131 121-0	09131 121-369	91051			76000000	76001507	BBK NUERNBERG	76350000	2929	ST U KR SPK ERLANGEN	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-er.bayern.de	www.finanzamt-erlangen.de	650
9	9217	Forchheim 	Dechant-Reuder-Str. 6	91301	Forchheim	09191 626-0	09191 626-200	91299			76000000	76001508	BBK NUERNBERG	76351040	91	SPARKASSE FORCHHEIM	Servicezentrum: Mo - Mi: 08:00 - 13:00 Uhr, Do: 08:00 - 17:30, Fr: 08:00 -	poststelle@fa-fo.bayern.de	www.finanzamt-forchheim.de	651
9	9218	Fürth 	Herrnstraße 69	90763	Fürth	0911 7435-0	0911 7435-350	90744			76000000	76201500	BBK NUERNBERG	76250000	18200	SPK FUERTH	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-fue.bayern.de	www.finanzamt-fuerth.de	652
9	9220	Gunzenhausen 	Hindenburgplatz 1	91710	Gunzenhausen	09831 8009-0	09831 8009-77	91709			76500000	76501502	BBK NUERNBERG EH ANSBACH	76551540	109785	VER SPK GUNZENHAUSEN	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-gun.bayern.de	www.finanzamt-gunzenhausen.de	653
9	9221	Hersbruck 	Amberger Str. 76 (Haus B)	91217	Hersbruck	09151 731-0	09151 731-200		91211	273	76000000	76001505	BBK NUERNBERG	76050101	190016618	SPARKASSE NUERNBERG	Servicezentrum: Mo - Mi: 08:00 - 15:30 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-heb.bayern.de	www.finanzamt-hersbruck.de	654
9	9222	Hilpoltstein 	Spitalwinkel 3	91161	Hilpoltstein	09174 469-0	09174 469-100		91155	1180	76000000	76401520	BBK NUERNBERG	76450000	240000026	SPK MITTELFRANKEN-SUED	Servicezentrum: Mo - Fr: 08:00 - 12:30 Uhr, Do: 14:00 - 18:00 Uhr	poststelle@fa-hip.bayern.de	www.finanzamt-hilpoltstein.de	655
9	9223	Hof mit Außenstellen 	Ernst-Reuter-Str. 60	95030	Hof	09281 929-0	09281 929-1500		95012	1368	78000000	78001500	BBK BAYREUTH EH HOF	78050000	380020750	KR U ST SPK HOF	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-ho.bayern.de	www.finanzamt-hof.de	656
9	9224	Hofheim - Außenstelle des Finanzamts Zeil -	Marktplatz 1	97457	Hofheim	09524 824-0	09524 824-250				79300000	79301505	BBK WUERZBURG EH SCHWEINFUR	79351730	500900	SPK OSTUNTERFRANKEN	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-hoh.bayern.de	www.finanzamt-hofheim.de	657
9	9225	Karlstadt - Außenstelle des Finanzamts Lohr -	Gemündener Str. 3	97753	Karlstadt	09353 949-0	09353 949-2250				79000000	79001504	BBK WUERZBURG	79050000	2246	SPK MAINFRANKEN WUERZBURG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-kar.bayern.de	www.finanzamt-karlstadt.de	658
9	9227	Kitzingen 	Moltkestr. 24	97318	Kitzingen	09321 703-0	09321 703-444		97308	660	79000000	79101500	BBK WUERZBURG	79050000	42070557	SPK MAINFRANKEN WUERZBURG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-kt.bayern.de	www.finanzamt-kitzingen.de	659
9	9228	Kronach 	Amtsgerichtsstr. 13	96317	Kronach	09261 510-0	09261 510-199		96302	1262	77300000	77101501	BBK BAYREUTH	77151640	240006007	SPK KRONACH-LUDWIGSSTADT	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08.00 - 17:30 Uhr, Fr: 08:00	poststelle@fa-kc.bayern.de	www.finanzamt-kronach.de	660
9	9229	Kulmbach 	Georg-Hagen-Str. 17	95326	Kulmbach	09221 650-0	09221 650-283		95304	1420	77300000	77101500	BBK BAYREUTH	77150000	105445	SPARKASSE KULMBACH	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08.00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-ku.bayern.de	www.finanzamt-kulmbach.de	661
9	9230	Lichtenfels 	Kronacher Str. 39	96215	Lichtenfels	09571 764-0	09571 764-420		96206	1680	77000000	77001502	BBK NUERNBERG EH BAMBERG	77051860	2345	KR SPK LICHTENFELS	Servicezentrum: Mo - Fr: 08:00 - 13:00 Uhr, Do: 14:00 - 17:00 Uhr	poststelle@fa-lif.bayern.de	www.finanzamt-lichtenfels.de	662
9	9231	Lohr a. Main mit Außenstellen  	Rexrothstr. 14	97816	Lohr	09352 850-0	09352 850-1300		97804	1465	79000000	79001504	BBK WUERZBURG	79050000	2246	SPK MAINFRANKEN WUERZBURG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-loh.bayern.de	www.finanzamt-lohr.de	663
9	9232	Marktheidenfeld - Außenstelle  des Finanzamts Lohr -	Ringstr. 24/26	97828	Marktheidenfeld	09391 506-0	09391 506-3299				79000000	79001504	BBK WUERZBURG	79050000	2246	SPK MAINFRANKEN WUERZBURG	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-mar.bayern.de	www.finanzamt-marktheidenfeld.de	664
9	9233	Münchberg - Außenstelle des Finanzamts Hof -	Hofer Str. 1	95213	Münchberg	09281 929-0	09281 929-3505				78000000	78001500	BBK BAYREUTH EH HOF	78050000	380020750	KR U ST SPK HOF	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-mueb.bayern.de	www.finanzamt-muenchberg.de	665
9	9234	Naila - Außenstelle des Finanzamts Hof -	Carl-Seyffert-Str. 3	95119	Naila	09281 929-0	09281 929-2506				78000000	78001500	BBK BAYREUTH EH HOF	78050000	380020750	KR U ST SPK HOF	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-nai.bayern.de	www.finanzamt-naila.de	666
9	9235	Neumarkt i.d.Opf. 	Ingolstädter Str. 3	92318	Neumarkt	09181 692-0	09181 692-1200				76000000	76001506	BBK NUERNBERG	76052080	6296	SPK NEUMARKT I D OPF-PARSBG	Servicezentrum: Mo - Do: 07:30 - 15:00 Uhr, Fr: 07:30 - 12:00 Uhr	poststelle@fa-nm.bayern.de	/www.finanzamt-neumarkt.de	667
9	9236	Neunburg v. W. - Außenstelle des Finanzamts Schwandorf -	Krankenhausstr. 6	92431	Neunburg vorm Wald	09431 382-0	09431 382-539		92428	1000	75300000	75301502	BBK REGENSBURG EH WEIDEN	75051040	380019000	SPK IM LANDKREIS SCHWANDORF	Servicezentrum: Mo-Mi: 07:30-12:30 u. 13:30-15:30,Do: 07:30-12:30 u. 13:30-17:00, Fr: 07:30-12:30 h 	poststelle@fa-nen.bayern.de	www.finanzamt-neunburg.de	668
9	9238	Nürnberg-Nord 	Kirchenweg 10	90419	Nürnberg	0911 3998-0	0911 3998-296	90340			76000000	76001502	BBK NUERNBERG	76050000	20161	BAYERNLB NUERNBERG	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-n-n.bayern.de	www.finanzamt-nuernberg-nord.de	669
9	9240	Nürnberg-Süd 	Sandstr. 20	90443	Nürnberg	0911 248-0	0911 248-2299/2599	90339			76000000	76001503	BBK NUERNBERG	76050101	3648043	SPARKASSE NUERNBERG	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-n-s.bayern.de	www.finanzamt-nuernberg-sued.de	670
9	9241	Nürnberg-Zentral 	Voigtländerstr. 7/9	90489	Nürnberg	0911 5393-0	0911 5393-2000				76000000	76001501	BBK NUERNBERG	76050101	1025008	SPARKASSE NUERNBERG	Servicezentrum: Mo - Do: 08:00 - 12:30 h, Di und Do: 13:30 - 15:00 h,	poststelle@fa-n-zfa.bayern.de	www.zentralfinanzamt-nuernberg.de	671
9	9242	Ochsenfurt - Außenstelle des Finanzamts Würzburg -	Völkstr.1	97199	Ochsenfurt	09331 904-0	09331 904-200		97196	1263	79000000	79001500	BBK WUERZBURG	79020076	801283	HYPOVEREINSBK WUERZBURG	Servicezentrum: Mo - Mi: 07:30 - 13:00 Uhr, Do: 07:30 - 17:00 uhr, Fr: 07:30	poststelle@fa-och.bayern.de	www.finanzamt-ochsenfurt.de	672
9	9244	Regensburg 	Landshuter Str. 4	93047	Regensburg	0941 5024-0	0941 5024-1199	93042			75000000	75001500	BBK REGENSBURG	75050000	111500	SPK REGENSBURG	Servicezentrum: Mo - Mi: 07:30 - 15:00 Uhr, Do: 07:30 - 17:00 Uhr, Fr: 07:30	poststelle@fa-r.bayern.de	www.finanzamt-regensburg.de	673
9	9246	Rothenburg - Außenstelle des Finanzamts Ansbach -	Ludwig-Siebert-Str. 31	91541	Rothenburg o.d.T.	0981 16-0	09861 706-511				76500000	76501500	BBK NUERNBERG EH ANSBACH	76550000	215004	VER SPK ANSBACH	Servicezentrum: Mo - Mi: 08:00 - 14:00 Uhr, Do: 08:00 - 18:00 Uhr, Fr: 08:00	poststelle@fa-rot.bayern.de	www.finanzamt-rothenburg.de	674
9	9247	Schwabach 	Theodor-Heuss-Str. 63	91126	Schwabach	09122 928-0	09122 928-100	91124			76000000	76401500	BBK NUERNBERG	76450000	55533	SPK MITTELFRANKEN-SUED	Servicezentrum: Mo - Mi: 08:00 - 13:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-sc.bayern.de	www.finanzamt-schwabach.de	675
9	9248	Schwandorf mit Außenstelle Neunburg v. W.	Friedrich-Ebert-Str.59	92421	Schwandorf	09431 382-0	09431 382-111	92419			75300000	75301502	BBK REGENSBURG EH WEIDEN	75051040	380019000	SPK IM LANDKREIS SCHWANDORF	Servicezentrum: Mo-Mi: 07:30-12:30 u. 13:30-15:30,Do: 07:30-12:30 u. 13:30-17:00, Fr: 07:30-12:30 h 	poststelle@fa-sad.bayern.de	www.finanzamt-schwandorf.de	676
9	9249	Schweinfurt 	Schrammstr. 3	97421	Schweinfurt	09721 2911-0	09721 2911-5070	97420			79300000	79301500	BBK WUERZBURG EH SCHWEINFUR	79350101	15800	KR SPK SCHWEINFURT	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-sw.bayern.de	www.finanzamt-schweinfurt.de	677
9	9250	Selb - Außenstelle des Finanzamts Wunsiedel -	Wittelsbacher Str. 8	95100	Selb	09232 607-0	09232 607-300				78000000	78101512	BBK BAYREUTH EH HOF	78055050	620006254	SPK FICHTELGEBIRGE	Servicezentrum: Mo-Mi: 07:30-12:30 u. 13:30-15:00,Do: 07:30-12:30 und 13:30-17:00, Fr: 07:30-12:00 h	poststelle@fa-sel.bayern.de	www.finanzamt-selb.de	678
9	9252	Uffenheim 	Schloßpl.	97215	Uffenheim	09842 200-0	09842 200-345		97211	1240	76500000	76501504	BBK NUERNBERG EH ANSBACH	76251020	620002006	SPK I LANDKREIS NEUSTADT	Servicezentrum: Mo-Mi: 08:00-12:00 u. 13:00-15:00,Do: 08:00-12:00 u. 13:00-17:00, Fr: 08:00-12:00 h 	poststelle@fa-uff.bayern.de	www.finanzamt-uffenheim.de	679
9	9253	Waldmünchen - Außenstelle des  Finanzamts Cham -	Bahnhofstr. 10	93449	Waldmünchen	09971 488-0	09971 488-550				74221170	344 755 205	HYPOVEREINSBK CHAM, OBERPF	76010085	1735-858	POSTBANK NUERNBERG	Servicezentrum: Mo - Mi: 07:30 - 15:00 Uhr, Do: 07:30 - 17:00 Uhr, Fr: 07:30	poststelle@fa-wuem.bayern.de	www.finanzamt-waldmuenchen.de	680
9	9254	Waldsassen 	Johannisplatz 13	95652	Waldsassen	09632 847-0	09632 847-199		95646	1329	75300000	75301511	BBK REGENSBURG EH WEIDEN	78151080	32367	SPK TIRSCHENREUTH	Servicezentrum: Mo - Fr: 07:30 - 12:30 Uhr, Mo - Mi: 13:30 - 15:30 Uhr,	poststelle@fa-wasa.bayern.de	www.finanzamt-waldsassen.de	681
9	9255	Weiden i.d.Opf. 	Schlörpl. 2 u. 4	92637	Weiden	0961 301-0	0961 32600		92604	1460	75300000	75301500	BBK REGENSBURG EH WEIDEN	75350000	172700	ST SPK WEIDEN	Servicezentrum: Mo - Fr: 07:30 - 12:30 Uhr, Mo - Mi: 13:30 - 15:30 Uhr,	poststelle@fa-wen.bayern.de	www.finanzamt-weiden.de	682
9	9257	Würzburg mit Außenstelle Ochsenfurt	Ludwigstr. 25	97070	Würzburg	0931 387-0	0931 387-4444	97064			79000000	79001500	BBK WUERZBURG	79020076	801283	HYPOVEREINSBK WUERZBURG	Servicezentrum: Mo - Mi: 07:30 - 15:00 Uhr, Do: 07:30 - 17:00 Uhr, Fr: 07:30	poststelle@fa-wue.bayern.de	www.finanzamt-wuerzburg.de	683
9	9258	Wunsiedel mit Außenstelle Selb	Sonnenstr. 11	95632	Wunsiedel	09232 607-0	09232 607-200	95631			78000000	78101512	BBK BAYREUTH EH HOF	78055050	620006254	SPK FICHTELGEBIRGE	Servicezentrum: Mo-Mi: 07:30-12:30 u 13:30-15:00, Do: 07:30-12:30 und 13:30-17:00, Fr: 07:30-12:00 h	poststelle@fa-wun.bayern.de	www.finanzamt-wunsiedel.de	684
9	9259	Zeil a. Main mit Außenstellen  	Obere Torstr. 9	97475	Zeil	09524 824-0	09524 824-100		97470	1160	79300000	79301505	BBK WUERZBURG EH SCHWEINFUR	79351730	500900	SPK OSTUNTERFRANKEN	Servicezentrum: Mo - Mi: 08:00 - 15:00 Uhr, Do: 08:00 - 17:00 Uhr, Fr: 08:00	poststelle@fa-zei.bayern.de	www.finanzamt-zeil.de	685
9	9260	Kötzting - Außenstelle des Finanzamts Cham -	Bahnhofstr. 3	93444	Kötzting	09971 488-0	09971 488-450				74221170	344 755 205	HYPOVEREINSBK CHAM, OBERPF	76010085	1735-858	POSTBANK NUERNBERG	Servicezentrum: Mo - Mi: 07:30 - 15:00 Uhr, Do: 07:30 - 18:00 Uhr, Fr: 07:30	poststelle@fa-koez.bayern.de	www.finanzamt-koetzting.de	686
2	2241	Hamburg-Altona 	Gr. Bergstr. 264/266	22767	Hamburg	040/42811-02	040/42811-2871		22704	500471	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgAltona@finanzamt.hamburg.de		58
2	2243	Hamburg-Barmbek-Uhlenhorst 	Lübecker Str. 101-109	22087	Hamburg	040/42860-0	040/42860-730		22053	760360	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FABarmbekUhlenhorst@finanzamt.hamburg.de		78
2	2243	Hamburg-Barmbek-Uhlenhorst 15  	Lübecker Str. 101-109	22087	Hamburg	040/42860-0	040/42860-730		22053	760360	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgBarmbekUhlenhorst@finanzamt.hamburg.de		64
2	2244	Hamburg-Bergedorf 	Ludwig-Rosenberg-Ring 41	21031	Hamburg	040/42891-0	040/42891-2243		21003	800360	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		FAHamburgBergedorf@finanzamt.hamburg.de		59
2	2245	Hamburg-Eimsbüttel 	Stresemannstraße 23	22769	Hamburg	040/42807-0	040/42807-220		22770	570110	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgEimsbuettel@finanzamt.hamburg.de		76
2	2246	Hamburg-Hansa 	Steinstraße 10	20095	Hamburg	040/42853-01	040/42853-2064		20015	102244	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		FAHamburgHansa@finanzamt.hamburg.de		68
2	2247	Hamburg-Harburg 	Harburger Ring 40	21073	Hamburg	040/42871-0	040/42871-2215		21043	900352	20000000	200 015 30	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgHarburg@finanzamt.hamburg.de		60
2	2249	Hamburg-Nord 	Borsteler Chaussee 45	22453	Hamburg	040/42806-0	040/42806-220		22207	600707	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		FAHamburgNord@finanzamt.hamburg.de		71
2	2250	Hamburg-Oberalster 	Hachmannplatz 2	20099	Hamburg	040/42854-90	040/42854-4960		20015	102248	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgOberalster@finanzamt.hamburg.de		62
2	2251	Hamburg-Wandsbek 	Schloßstr.107	22041	Hamburg	040/42881-0	040/42881-2888		22006	700660	20000000	20001530	BBK HAMBURG	21050000	101444000	HSH NORDBANK KIEL		 FAHamburgWandsbek@finanzamt.hamburg.de		61
6	2603	Bad Homburg v.d. Höhe 	Kaiser-Friedr.-Promenade 8-10 	61348	Bad Homburg	06172/107-0	06172/107-317	61343	61284	1445	50050000	1000124	Landesbank Hessen-Thüringen	50000000	50001501	DT BBK Filiale Frankfurt am Main	Mo u. Fr 8:00-12:00, Mi 14:00-18:00 Uhr	poststelle@Finanzamt-Bad-Homburg.de	www.Finanzamt-Bad-Homburg.de	162
8	2870	Leonberg 	Schlosshof 3	71229	Leonberg	(07152) 15-1	07152/15333	71226			60000000	60301501	DT BBK Filiale Stuttgart				MO-MI 7.30-12.00,DO 7.30-17.30,FR 7.30-12.30	poststelle-70@finanzamt.bwl.de	http://www.fa-leonberg.de/	300
\.


--
-- Data for Name: follow_up_access; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.follow_up_access (who, what, id) FROM stdin;
\.


--
-- Data for Name: follow_up_links; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.follow_up_links (id, follow_up_id, trans_id, trans_type, trans_info, itime, mtime) FROM stdin;
\.


--
-- Data for Name: follow_ups; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.follow_ups (id, follow_up_date, created_for_user, done, note_id, created_by, itime, mtime) FROM stdin;
\.


--
-- Data for Name: generic_translations; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.generic_translations (id, language_id, translation_type, translation_id, translation) FROM stdin;
\.


--
-- Data for Name: gl; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.gl (id, reference, description, transdate, gldate, employee_id, notes, department_id, taxincluded, itime, mtime, type, ob_transaction, cb_transaction, storno, storno_id) FROM stdin;
1	r1	Einlage Startkapital	2019-10-15	2019-10-15	409	\N	\N	f	2019-10-15 11:50:50.874659	2019-10-15 11:50:50.874659	\N	f	f	f	\N
\.


--
-- Data for Name: history_erp; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.history_erp (id, trans_id, employee_id, addition, what_done, itime, snumbers) FROM stdin;
411	410	409	SAVED	\N	2019-10-15 11:48:33.077443	customernumber_1
412	1	409	POSTED	gl transaction	2019-10-15 11:50:50.874659	gltransaction_1
414	413	409	SAVED	part	2019-10-15 11:51:58.430022	partnumber_d1
416	2	409	POSTED	invoice	2019-10-15 11:52:10.33553	invnumber_1
\.


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.inventory (warehouse_id, parts_id, oe_id, delivery_order_items_stock_id, shippingdate, employee_id, itime, mtime, bin_id, qty, trans_id, trans_type_id, project_id, chargenumber, comment, bestbefore, id, invoice_id) FROM stdin;
\.


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.invoice (id, trans_id, parts_id, description, qty, allocated, sellprice, fxsellprice, discount, assemblyitem, project_id, deliverydate, serialnumber, itime, mtime, pricegroup_id, ordnumber, transdate, cusordnumber, unit, base_qty, subtotal, longdescription, marge_total, marge_percent, lastcost, price_factor_id, price_factor, marge_price_factor, donumber, "position", active_price_source, active_discount_source) FROM stdin;
1	2	413	Support pauschal	1	0	150.00000	150.00000	0	f	\N	\N		2019-10-15 11:52:10.264198	2019-10-15 11:52:10.264198	\N	\N	\N	\N	pauschal	1	f		0.00000	0.00000	0.00000	\N	\N	\N	\N	1		
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.language (id, description, template_code, article_code, itime, mtime, output_numberformat, output_dateformat, output_longdates) FROM stdin;
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.leads (id, lead) FROM stdin;
\.


--
-- Data for Name: letter; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.letter (id, customer_id, letternumber, subject, greeting, body, employee_id, salesman_id, itime, mtime, date, reference, intnotes, cp_id, vendor_id) FROM stdin;
\.


--
-- Data for Name: letter_draft; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.letter_draft (id, customer_id, cp_id, letternumber, date, intnotes, reference, subject, greeting, body, employee_id, salesman_id, itime, mtime, vendor_id) FROM stdin;
\.


--
-- Data for Name: makemodel; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.makemodel (parts_id, model, itime, mtime, lastcost, lastupdate, sortorder, make, id) FROM stdin;
\.


--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.notes (id, subject, body, created_by, trans_id, trans_module, itime, mtime) FROM stdin;
\.


--
-- Data for Name: oe; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.oe (id, ordnumber, transdate, vendor_id, customer_id, amount, netamount, reqdate, taxincluded, shippingpoint, notes, employee_id, closed, quotation, quonumber, cusordnumber, intnotes, department_id, itime, mtime, shipvia, cp_id, language_id, payment_id, delivery_customer_id, delivery_vendor_id, taxzone_id, proforma, shipto_id, order_probability, expected_billing_date, globalproject_id, delivered, salesman_id, marge_total, marge_percent, transaction_description, delivery_term_id, currency_id) FROM stdin;
\.


--
-- Data for Name: orderitems; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.orderitems (trans_id, parts_id, description, qty, sellprice, discount, project_id, reqdate, ship, serialnumber, id, itime, mtime, pricegroup_id, ordnumber, transdate, cusordnumber, unit, base_qty, subtotal, longdescription, marge_total, marge_percent, lastcost, price_factor_id, price_factor, marge_price_factor, "position", active_price_source, active_discount_source) FROM stdin;
\.


--
-- Data for Name: part_classifications; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.part_classifications (id, description, abbreviation, used_for_purchase, used_for_sale, report_separate) FROM stdin;
0	-------	None (typeabbreviation)	t	t	f
1	Purchase	Purchase (typeabbreviation)	t	f	f
2	Sales	Sales (typeabbreviation)	f	t	f
3	Merchandise	Merchandise (typeabbreviation)	t	t	f
4	Production	Production (typeabbreviation)	f	t	f
\.


--
-- Data for Name: part_customer_prices; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.part_customer_prices (id, parts_id, customer_id, customer_partnumber, price, sortorder, lastupdate) FROM stdin;
\.


--
-- Data for Name: parts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.parts (id, partnumber, description, listprice, sellprice, lastcost, priceupdate, weight, notes, makemodel, rop, shop, obsolete, bom, image, drawing, microfiche, partsgroup_id, ve, gv, itime, mtime, unit, formel, not_discountable, buchungsgruppen_id, payment_id, ean, price_factor_id, onhand, stockable, has_sernumber, warehouse_id, bin_id, classification_id, part_type) FROM stdin;
413	d1	Support pauschal	0.00000	0.00000	0.00000	2019-10-15	\N		f	\N	f	f	f				\N	\N	0.00000	2019-10-15 11:51:58.430022	\N	pauschal		f	192	\N		\N	0.00000	f	f	\N	\N	0	service
\.


--
-- Data for Name: parts_price_history; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.parts_price_history (id, part_id, valid_from, lastcost, listprice, sellprice) FROM stdin;
1	413	2019-10-15 11:51:58.430022	0.00000	0.00000	0.00000
\.


--
-- Data for Name: partsgroup; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.partsgroup (id, partsgroup, itime, mtime, obsolete, sortkey) FROM stdin;
\.


--
-- Data for Name: payment_terms; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.payment_terms (id, description, description_long, terms_netto, terms_skonto, percent_skonto, itime, mtime, sortkey, auto_calculation, description_long_invoice, obsolete) FROM stdin;
\.


--
-- Data for Name: periodic_invoices; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.periodic_invoices (id, config_id, ar_id, period_start_date, itime) FROM stdin;
\.


--
-- Data for Name: periodic_invoices_configs; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.periodic_invoices_configs (id, oe_id, periodicity, print, printer_id, copies, active, terminated, start_date, end_date, ar_chart_id, extend_automatically_by, first_billing_date, order_value_periodicity, direct_debit, send_email, email_recipient_contact_id, email_recipient_address, email_sender, email_subject, email_body) FROM stdin;
\.


--
-- Data for Name: price_factors; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.price_factors (id, description, factor, sortkey) FROM stdin;
392	pro 10	10.00000	1
393	pro 100	100.00000	2
394	pro 1.000	1000.00000	3
\.


--
-- Data for Name: price_rule_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.price_rule_items (id, price_rules_id, type, op, custom_variable_configs_id, value_text, value_int, value_date, value_num, itime, mtime) FROM stdin;
\.


--
-- Data for Name: price_rules; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.price_rules (id, name, type, priority, price, reduction, obsolete, itime, mtime, discount) FROM stdin;
\.


--
-- Data for Name: pricegroup; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.pricegroup (id, pricegroup, obsolete, sortkey) FROM stdin;
\.


--
-- Data for Name: prices; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.prices (parts_id, pricegroup_id, price, id) FROM stdin;
\.


--
-- Data for Name: printers; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.printers (id, printer_description, printer_command, template_code) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project (id, projectnumber, description, itime, mtime, active, customer_id, valid, project_type_id, start_date, end_date, billable_customer_id, budget_cost, order_value, budget_minutes, timeframe, project_status_id) FROM stdin;
\.


--
-- Data for Name: project_participants; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_participants (id, project_id, employee_id, project_role_id, minutes, cost_per_hour, itime, mtime) FROM stdin;
\.


--
-- Data for Name: project_phase_participants; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_phase_participants (id, project_phase_id, employee_id, project_role_id, minutes, cost_per_hour, itime, mtime) FROM stdin;
\.


--
-- Data for Name: project_phases; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_phases (id, project_id, start_date, end_date, name, description, budget_minutes, budget_cost, general_minutes, general_cost_per_hour, itime, mtime) FROM stdin;
\.


--
-- Data for Name: project_roles; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_roles (id, name, description, "position", itime, mtime) FROM stdin;
\.


--
-- Data for Name: project_statuses; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_statuses (id, name, description, "position", itime, mtime) FROM stdin;
1	presales	Akquise	1	2019-10-15 11:37:10.353281	\N
2	planning	In Planung	2	2019-10-15 11:37:10.353281	\N
3	running	In Bearbeitung	3	2019-10-15 11:37:10.353281	\N
4	done	Fertiggestellt	4	2019-10-15 11:37:10.353281	\N
\.


--
-- Data for Name: project_types; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.project_types (id, "position", description, internal) FROM stdin;
1	1	Standard	f
2	2	Festpreis	f
3	3	Support	f
\.


--
-- Data for Name: reconciliation_links; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.reconciliation_links (id, bank_transaction_id, acc_trans_id, rec_group) FROM stdin;
\.


--
-- Data for Name: record_links; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.record_links (from_table, from_id, to_table, to_id, itime, id) FROM stdin;
\.


--
-- Data for Name: record_template_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.record_template_items (id, record_template_id, chart_id, tax_id, project_id, amount1, amount2, source, memo) FROM stdin;
\.


--
-- Data for Name: record_templates; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.record_templates (id, template_name, template_type, customer_id, vendor_id, currency_id, department_id, project_id, employee_id, taxincluded, direct_debit, ob_transaction, cb_transaction, reference, description, ordnumber, notes, ar_ap_chart_id, itime, mtime, show_details) FROM stdin;
\.


--
-- Data for Name: requirement_spec_acceptance_statuses; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_acceptance_statuses (id, name, description, "position", itime, mtime) FROM stdin;
1	accepted	Abgenommen	1	2019-10-15 11:37:08.302146	\N
2	accepted_with_defects	Mit Mängeln abgenommen	2	2019-10-15 11:37:08.302146	\N
3	accepted_with_defects_to_be_fixed	Mit noch zu behebenden Mängeln abgenommen	3	2019-10-15 11:37:08.302146	\N
4	not_accepted	Nicht abgenommen	4	2019-10-15 11:37:08.302146	\N
\.


--
-- Data for Name: requirement_spec_complexities; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_complexities (id, description, "position", itime, mtime) FROM stdin;
1	nicht bewertet	1	2019-10-15 11:37:08.302146	\N
2	nur Anforderung	2	2019-10-15 11:37:08.302146	\N
3	gering	3	2019-10-15 11:37:08.302146	\N
4	mittel	4	2019-10-15 11:37:08.302146	\N
5	hoch	5	2019-10-15 11:37:08.302146	\N
\.


--
-- Data for Name: requirement_spec_item_dependencies; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_item_dependencies (depending_item_id, depended_item_id) FROM stdin;
\.


--
-- Data for Name: requirement_spec_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_items (id, requirement_spec_id, item_type, parent_id, "position", fb_number, title, description, complexity_id, risk_id, time_estimation, is_flagged, acceptance_status_id, acceptance_text, itime, mtime, sellprice_factor, order_part_id) FROM stdin;
\.


--
-- Data for Name: requirement_spec_orders; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_orders (id, requirement_spec_id, order_id, version_id, itime, mtime) FROM stdin;
\.


--
-- Data for Name: requirement_spec_parts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_parts (id, requirement_spec_id, part_id, unit_id, qty, description, "position") FROM stdin;
\.


--
-- Data for Name: requirement_spec_pictures; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_pictures (id, requirement_spec_id, text_block_id, "position", number, description, picture_file_name, picture_content_type, picture_mtime, picture_content, picture_width, picture_height, thumbnail_content_type, thumbnail_content, thumbnail_width, thumbnail_height, itime, mtime) FROM stdin;
\.


--
-- Data for Name: requirement_spec_predefined_texts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_predefined_texts (id, description, title, text, "position", itime, mtime, useable_for_text_blocks, useable_for_sections) FROM stdin;
\.


--
-- Data for Name: requirement_spec_risks; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_risks (id, description, "position", itime, mtime) FROM stdin;
1	nicht bewertet	1	2019-10-15 11:37:08.302146	\N
2	nur Anforderung	2	2019-10-15 11:37:08.302146	\N
3	gering	3	2019-10-15 11:37:08.302146	\N
4	mittel	4	2019-10-15 11:37:08.302146	\N
5	hoch	5	2019-10-15 11:37:08.302146	\N
\.


--
-- Data for Name: requirement_spec_statuses; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_statuses (id, name, description, "position", itime, mtime) FROM stdin;
1	planning	In Planung	1	2019-10-15 11:37:08.302146	\N
2	running	In Bearbeitung	2	2019-10-15 11:37:08.302146	\N
3	done	Fertiggestellt	3	2019-10-15 11:37:08.302146	\N
\.


--
-- Data for Name: requirement_spec_text_blocks; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_text_blocks (id, requirement_spec_id, title, text, "position", output_position, is_flagged, itime, mtime) FROM stdin;
\.


--
-- Data for Name: requirement_spec_types; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_types (id, description, "position", itime, mtime, section_number_format, function_block_number_format, template_file_name) FROM stdin;
1	Pflichtenheft	1	2019-10-15 11:37:08.302146	2019-10-15 11:37:09.709378	A00	FB000	requirement_spec
2	Konzept	2	2019-10-15 11:37:08.302146	2019-10-15 11:37:09.709378	A00	FB000	requirement_spec
\.


--
-- Data for Name: requirement_spec_versions; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_spec_versions (id, version_number, description, comment, itime, mtime, requirement_spec_id, working_copy_id) FROM stdin;
\.


--
-- Data for Name: requirement_specs; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.requirement_specs (id, type_id, status_id, customer_id, project_id, title, hourly_rate, working_copy_id, previous_section_number, previous_fb_number, is_template, itime, mtime, time_estimation, previous_picture_number) FROM stdin;
\.


--
-- Data for Name: schema_info; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.schema_info (tag, login, itime) FROM stdin;
SKR04-3804-addition	\N	2019-10-15 11:37:00.894273
acc_trans_constraints	\N	2019-10-15 11:37:00.903203
chart_category_to_sgn	\N	2019-10-15 11:37:00.908595
chart_names	\N	2019-10-15 11:37:00.914583
chart_names2	\N	2019-10-15 11:37:00.920417
customer_vendor_ustid_length	\N	2019-10-15 11:37:00.926297
language_output_formatting	\N	2019-10-15 11:37:00.938358
remove_obsolete_trigger	\N	2019-10-15 11:37:00.944226
rename_buchungsgruppen_accounts_16_19_percent	\N	2019-10-15 11:37:00.950295
sales_quotation_order_probability_expected_billing_date	\N	2019-10-15 11:37:00.986001
tax_id_if_taxkey_is_0	\N	2019-10-15 11:37:00.991818
units_translations_and_singular_plural_distinction	\N	2019-10-15 11:37:01.004405
tax_primary_key_taxkeys_foreign_keys	\N	2019-10-15 11:37:01.057991
invalid_taxkesy	\N	2019-10-15 11:37:01.093614
release_2_4_1	\N	2019-10-15 11:37:01.099912
PgCommaAggregateFunction	\N	2019-10-15 11:37:01.106045
ap_ar_orddate_quodate	\N	2019-10-15 11:37:01.111925
buchungsgruppen_sortkey	\N	2019-10-15 11:37:01.117884
customer_vendor_taxzone_id	\N	2019-10-15 11:37:01.125377
drafts	\N	2019-10-15 11:37:01.135456
employee_no_limits	\N	2019-10-15 11:37:01.18912
globalprojectnumber_ap_ar_oe	\N	2019-10-15 11:37:01.229243
oe_delivered	\N	2019-10-15 11:37:01.244233
oe_is_salesman	\N	2019-10-15 11:37:01.250075
parts_ean	\N	2019-10-15 11:37:01.260984
payment_terms_sortkey	\N	2019-10-15 11:37:01.267956
payment_terms_translation	\N	2019-10-15 11:37:01.274559
project	\N	2019-10-15 11:37:01.30393
status_history	\N	2019-10-15 11:37:01.30984
units_sortkey	\N	2019-10-15 11:37:01.320836
history_erp	\N	2019-10-15 11:37:01.328331
marge_initial	\N	2019-10-15 11:37:01.395543
ustva_setup_2007	\N	2019-10-15 11:37:01.405711
history_erp_snumbers	\N	2019-10-15 11:37:01.411517
tax_description_without_percentage_skr04	\N	2019-10-15 11:37:01.417545
ustva_setup_2007_update_chart_taxkeys_tax	\N	2019-10-15 11:37:01.429549
fix_taxdescription	\N	2019-10-15 11:37:01.453286
ustva_setup_2007_update_chart_taxkeys_tax_add_missing_tax_accounts	\N	2019-10-15 11:37:01.465306
tax_description_without_percentage	\N	2019-10-15 11:37:01.471108
release_2_4_2	\N	2019-10-15 11:37:01.482879
COA_Account_Settings001	\N	2019-10-15 11:37:01.489042
COA_Account_Settings002	\N	2019-10-15 11:37:01.49494
USTVA_abstraction	\N	2019-10-15 11:37:01.50288
ap_storno	\N	2019-10-15 11:37:01.674307
ar_storno	\N	2019-10-15 11:37:01.680083
cb_ob_transaction	\N	2019-10-15 11:37:01.686048
dunning_config_interest_rate	\N	2019-10-15 11:37:01.691958
dunning_dunning_id	\N	2019-10-15 11:37:01.697944
dunning_invoices_for_fees	\N	2019-10-15 11:37:01.710059
gl_storno	\N	2019-10-15 11:37:01.721074
invalid_taxkeys_2	\N	2019-10-15 11:37:01.73401
transaction_description	\N	2019-10-15 11:37:01.73994
USTVA_at	\N	2019-10-15 11:37:01.748623
ar_ap_storno_id	\N	2019-10-15 11:37:01.752137
dunning_invoices_per_dunning_level	\N	2019-10-15 11:37:01.757808
tax_report_table_name	\N	2019-10-15 11:37:01.763815
release_2_4_3	\N	2019-10-15 11:37:01.769702
acc_trans_without_oid	\N	2019-10-15 11:37:01.775686
bank_accounts	\N	2019-10-15 11:37:01.951604
change_makemodel_vendor_id	\N	2019-10-15 11:37:02.009524
custom_variables	\N	2019-10-15 11:37:02.015263
direct_debit	\N	2019-10-15 11:37:02.123127
follow_ups	\N	2019-10-15 11:37:02.128856
oe_employee_id_foreignkey	\N	2019-10-15 11:37:02.273369
price_factors	\N	2019-10-15 11:37:02.278784
sic_code	\N	2019-10-15 11:37:02.339067
todo_config	\N	2019-10-15 11:37:02.346297
trigger_assembly_update_lastcost	\N	2019-10-15 11:37:02.35116
units_no_type_distinction	\N	2019-10-15 11:37:02.363098
warehouse	\N	2019-10-15 11:37:02.370155
add_stocktaking_preselects_client_config_default	\N	2019-10-15 11:37:02.515707
delivery_orders	\N	2019-10-15 11:37:02.526064
transfer_type_shipped	\N	2019-10-15 11:37:02.708607
transfer_type_stocktaking	\N	2019-10-15 11:37:02.71607
warehouse2	\N	2019-10-15 11:37:02.723318
add_stocktaking_qty_threshold_client_config_default	\N	2019-10-15 11:37:02.732197
ar_add_donumber	\N	2019-10-15 11:37:02.745791
ar_add_invnumber_for_credit_note	\N	2019-10-15 11:37:02.756146
check_bin_belongs_to_wh_trigger	\N	2019-10-15 11:37:02.76397
record_links	\N	2019-10-15 11:37:02.777102
transaction_description_not_null	\N	2019-10-15 11:37:02.866907
release_2_6_0	\N	2019-10-15 11:37:02.875273
auth_enable_sales_all_edit	\N	2019-10-15 11:37:02.883476
custom_variables_parts_services_assemblies	\N	2019-10-15 11:37:02.890437
custom_variables_valid	\N	2019-10-15 11:37:02.899325
delivery_orders_fields_for_invoices	\N	2019-10-15 11:37:02.932129
fix_acc_trans_ap_taxkey_bug	\N	2019-10-15 11:37:02.941452
fix_datepaid	\N	2019-10-15 11:37:02.97701
generic_translations	\N	2019-10-15 11:37:02.986074
has_sernumber	\N	2019-10-15 11:37:03.073515
rundungsfehler_korrigieren_BUG1328-2	\N	2019-10-15 11:37:03.082502
sepa	\N	2019-10-15 11:37:03.091952
update_date_paid	\N	2019-10-15 11:37:03.152315
warehouse3	\N	2019-10-15 11:37:03.159579
warehouse_add_bestbefore	\N	2019-10-15 11:37:03.165409
add_depositor_for_customer_vendor	\N	2019-10-15 11:37:03.171629
add_more_constraints_fibu_projekt_xplace3	\N	2019-10-15 11:37:03.207014
cp_greeting_migration	\N	2019-10-15 11:37:03.219047
release_2_6_1	\N	2019-10-15 11:37:03.225307
acc_trans_id_uniqueness	\N	2019-10-15 11:37:03.239159
add_ar_paid_defaults	\N	2019-10-15 11:37:03.247755
add_makemodel_prices	\N	2019-10-15 11:37:03.260967
csv_import_profiles	\N	2019-10-15 11:37:03.269986
customer_long_entries	\N	2019-10-15 11:37:03.432895
drop_yearend	\N	2019-10-15 11:37:03.448901
emmvee_background_jobs	\N	2019-10-15 11:37:03.456628
invalid_entries_in_custom_variables_validity	\N	2019-10-15 11:37:03.570266
payment_terms_translation2	\N	2019-10-15 11:37:03.579378
periodic_invoices	\N	2019-10-15 11:37:03.595156
schema_normalization_1	\N	2019-10-15 11:37:03.65998
sepa_in	\N	2019-10-15 11:37:03.766194
shipto_add_cp_gender	\N	2019-10-15 11:37:03.777531
skr03_04_bwa_zuordnung_konten_4250_4610	\N	2019-10-15 11:37:03.791816
skr04_fix_category_3151_3160_3170	\N	2019-10-15 11:37:03.80143
ustva_2010	\N	2019-10-15 11:37:03.809764
auto_delete_sepa_export_items_on_ap_ar_deletion	\N	2019-10-15 11:37:03.819777
csv_import_profiles_2	\N	2019-10-15 11:37:03.841116
delete_translations_on_payment_term_delete	\N	2019-10-15 11:37:03.849317
emmvee_background_jobs_2	\N	2019-10-15 11:37:04.097194
periodic_invoices_background_job	\N	2019-10-15 11:37:04.137349
periodic_invoices_first_billing_date	\N	2019-10-15 11:37:04.145151
schema_normalization_2	\N	2019-10-15 11:37:04.1528
background_jobs_3	\N	2019-10-15 11:37:05.395038
csv_import_report_cache	\N	2019-10-15 11:37:05.401439
csv_mt940_add_profile	\N	2019-10-15 11:37:05.599826
re_add_sepa_export_items_foreign_keys	\N	2019-10-15 11:37:05.611131
schema_normalization_3	\N	2019-10-15 11:37:05.621373
csv_import_reports_add_numheaders	\N	2019-10-15 11:37:05.652091
release_2_6_2	\N	2019-10-15 11:37:05.659586
chart_taxkey_id_from_taxkeys	\N	2019-10-15 11:37:05.671358
custom_variables_indices	\N	2019-10-15 11:37:05.695952
custom_variables_indices_2	\N	2019-10-15 11:37:05.753684
units_id	\N	2019-10-15 11:37:05.789817
release_2_6_3	\N	2019-10-15 11:37:05.8827
auth_enable_ct_all_edit	\N	2019-10-15 11:37:05.8884
auth_enable_edit_prices	\N	2019-10-15 11:37:05.893775
customer_add_constraints	\N	2019-10-15 11:37:05.898744
customer_vendor_add_currency	\N	2019-10-15 11:37:05.91082
defaults_add_language_id	\N	2019-10-15 11:37:05.916687
delivery_order_items_add_pricegroup_id	\N	2019-10-15 11:37:05.922659
department_drop_role	\N	2019-10-15 11:37:05.92862
drop_datevexport	\N	2019-10-15 11:37:05.934651
employee_deleted	\N	2019-10-15 11:37:05.940621
license_invoice_drop	\N	2019-10-15 11:37:05.946551
oe_customer_vendor_fkeys	\N	2019-10-15 11:37:05.957698
parts_add_unit_foreign_key	\N	2019-10-15 11:37:05.968508
umstellung_eur	\N	2019-10-15 11:37:05.980096
ustva_2010_fixes	\N	2019-10-15 11:37:05.988589
vendor_add_constraints	\N	2019-10-15 11:37:05.994478
warehouse_alter_chargenumber	\N	2019-10-15 11:37:06.006484
release_2_7_0	\N	2019-10-15 11:37:06.012432
chart_type_skonto	\N	2019-10-15 11:37:06.01847
contacts_add_street_and_zipcode_and_city	\N	2019-10-15 11:37:06.03069
contacts_convert_cp_birthday_to_date	\N	2019-10-15 11:37:06.037076
convert_curr_to_text	\N	2019-10-15 11:37:06.042313
custom_variables_sub_module_not_null	\N	2019-10-15 11:37:07.053535
customer_add_taxincluded_checked	\N	2019-10-15 11:37:07.075693
customer_vendor_phone_no_limits	\N	2019-10-15 11:37:07.087325
defaults_datev_check	\N	2019-10-15 11:37:07.095328
defaults_posting_config	\N	2019-10-15 11:37:07.106859
defaults_posting_records_config	\N	2019-10-15 11:37:07.114544
defaults_show_bestbefore	\N	2019-10-15 11:37:07.1249
defaults_show_delete_on_orders	\N	2019-10-15 11:37:07.130557
defaults_show_mark_as_paid_config	\N	2019-10-15 11:37:07.139971
finanzamt_update_fa_bufa_nr_hamburg	\N	2019-10-15 11:37:07.159803
record_links_post_delete_triggers	\N	2019-10-15 11:37:07.18542
rename_buchungsgruppe_16_19_to_19	\N	2019-10-15 11:37:07.211881
self_test_background_job	\N	2019-10-15 11:37:07.545595
ustva_setup_2007_update_chart_taxkeys_tax_skr04	\N	2019-10-15 11:37:07.554619
customer_add_taxincluded_checked_2	\N	2019-10-15 11:37:07.567334
record_links_post_delete_triggers2	\N	2019-10-15 11:37:07.581558
release_3_0_0	\N	2019-10-15 11:37:07.591242
acc_trans_booleans_not_null	\N	2019-10-15 11:37:07.597328
accounts_tax_office_bad_homburg	\N	2019-10-15 11:37:07.607031
add_chart_link_to_acc_trans	\N	2019-10-15 11:37:07.61877
add_customer_mandator_id	\N	2019-10-15 11:37:07.627099
add_fk_to_gl	\N	2019-10-15 11:37:07.642595
add_warehouse_defaults	\N	2019-10-15 11:37:07.651054
ap_add_direct_debit	\N	2019-10-15 11:37:07.663146
ap_deliverydate	\N	2019-10-15 11:37:07.671141
ar_add_direct_debit	\N	2019-10-15 11:37:07.67851
ar_ap_foreign_keys	\N	2019-10-15 11:37:07.686918
ar_ap_gl_delete_triggers_deletion_from_acc_trans	\N	2019-10-15 11:37:07.719586
background_job_change_create_periodic_invoices_to_daily	\N	2019-10-15 11:37:07.744552
charts_without_taxkey	\N	2019-10-15 11:37:07.751118
cleanup_after_customer_vendor_deletion	\N	2019-10-15 11:37:07.759434
clients	\N	2019-10-15 11:37:07.773263
contacts_add_cp_position	\N	2019-10-15 11:37:07.783285
custom_variable_configs_column_type_text	\N	2019-10-15 11:37:07.792157
custom_variables_validity_index	\N	2019-10-15 11:37:07.809678
defaults_add_max_future_booking_intervall	\N	2019-10-15 11:37:07.864614
defaults_add_precision	\N	2019-10-15 11:37:07.872603
defaults_feature	\N	2019-10-15 11:37:07.881479
defaults_feature2	\N	2019-10-15 11:37:07.900507
del_exchangerate	\N	2019-10-15 11:37:07.908657
delete_close_follow_ups_when_order_is_deleted_closed_fkey_deletion	\N	2019-10-15 11:37:07.918537
delete_customertax_vendortax_partstax	\N	2019-10-15 11:37:07.93023
delete_translations_on_tax_delete	\N	2019-10-15 11:37:07.948408
delivery_terms	\N	2019-10-15 11:37:07.956647
drop_audittrail	\N	2019-10-15 11:37:08.026182
drop_dpt_trans	\N	2019-10-15 11:37:08.035114
drop_gifi	\N	2019-10-15 11:37:08.047054
drop_rma	\N	2019-10-15 11:37:08.058594
employee_drop_columns	\N	2019-10-15 11:37:08.068894
erzeugnisnummern	\N	2019-10-15 11:37:08.081426
first_aggregator	\N	2019-10-15 11:37:08.112361
fix_datepaid_for_sepa_transfers	\N	2019-10-15 11:37:08.126469
gewichte	\N	2019-10-15 11:37:08.133716
gl_add_employee_foreign_key	\N	2019-10-15 11:37:08.142063
invoice_add_donumber	\N	2019-10-15 11:37:08.156049
oe_delivery_orders_foreign_keys	\N	2019-10-15 11:37:08.163472
orderitems_delivery_order_items_invoice_foreign_keys	\N	2019-10-15 11:37:08.193357
parts_translation_foreign_keys	\N	2019-10-15 11:37:08.214391
project_customer_type_valid	\N	2019-10-15 11:37:08.232984
project_types	\N	2019-10-15 11:37:08.241685
requirement_specs	\N	2019-10-15 11:37:08.302146
rm_whitespaces	\N	2019-10-15 11:37:09.077054
add_tax_id_to_acc_trans	\N	2019-10-15 11:37:09.085524
add_warehouse_client_config_default	\N	2019-10-15 11:37:09.095829
balance_startdate_method	\N	2019-10-15 11:37:09.107881
currencies	\N	2019-10-15 11:37:09.117238
custom_variables_delete_via_trigger	\N	2019-10-15 11:37:09.224696
default_bin_parts	\N	2019-10-15 11:37:09.238189
defaults_customer_hourly_rate	\N	2019-10-15 11:37:09.247084
defaults_signature	\N	2019-10-15 11:37:09.252997
delete_close_follow_ups_when_order_is_deleted_closed	\N	2019-10-15 11:37:09.258877
delete_cust_vend_tax	\N	2019-10-15 11:37:09.28061
delete_translations_on_delivery_term_delete	\N	2019-10-15 11:37:09.288939
drop_gifi_2	\N	2019-10-15 11:37:09.298268
oe_do_delete_via_trigger	\N	2019-10-15 11:37:09.304825
project_bob_attributes	\N	2019-10-15 11:37:09.367856
remove_role_from_employee	\N	2019-10-15 11:37:09.579645
requirement_spec_items_item_type_index	\N	2019-10-15 11:37:09.587616
requirement_spec_items_price_factor	\N	2019-10-15 11:37:09.619561
requirement_spec_items_update_trigger_fix	\N	2019-10-15 11:37:09.625436
requirement_spec_pictures	\N	2019-10-15 11:37:09.638219
requirement_spec_predefined_texts_for_sections	\N	2019-10-15 11:37:09.69007
requirement_spec_types_number_formats	\N	2019-10-15 11:37:09.697377
requirement_spec_types_template_file_name	\N	2019-10-15 11:37:09.709378
requirement_specs_print_templates	\N	2019-10-15 11:37:09.719611
requirement_specs_section_templates	\N	2019-10-15 11:37:09.727298
tax_constraints	\N	2019-10-15 11:37:09.73456
add_fkey_tax_id_to_acc_trans	\N	2019-10-15 11:37:09.787193
custom_variables_delete_via_trigger_2	\N	2019-10-15 11:37:09.79322
custom_variables_delete_via_trigger_requirement_specs	\N	2019-10-15 11:37:09.799151
project_bob_attributes_itime_default_fix	\N	2019-10-15 11:37:09.804893
requirement_spec_delete_trigger_fix	\N	2019-10-15 11:37:09.816279
requirement_spec_type_for_template_fix	\N	2019-10-15 11:37:09.834933
requirement_specs_orders	\N	2019-10-15 11:37:09.840743
steuerfilterung	\N	2019-10-15 11:37:09.909063
unit_foreign_key_for_line_items	\N	2019-10-15 11:37:09.919378
project_bob_attributes_fix_project_status_table_name	\N	2019-10-15 11:37:09.931383
release_3_1_0	\N	2019-10-15 11:37:09.937379
requirement_spec_delete_trigger_fix2	\N	2019-10-15 11:37:09.943369
requirement_spec_items_update_trigger_fix2	\N	2019-10-15 11:37:09.968243
add_warehouse_client_config_default2	\N	2019-10-15 11:37:09.980152
background_jobs_clean_auth_sessions	\N	2019-10-15 11:37:10.020839
bank_accounts_add_name	\N	2019-10-15 11:37:10.027933
column_type_text_instead_of_varchar	\N	2019-10-15 11:37:10.036138
custom_variable_partsgroups	\N	2019-10-15 11:37:10.048474
defaults_add_delivery_plan_config	\N	2019-10-15 11:37:10.082976
defaults_add_rnd_accno_ids	\N	2019-10-15 11:37:10.089876
defaults_global_bcc	\N	2019-10-15 11:37:10.098579
defaults_only_customer_projects_in_sales	\N	2019-10-15 11:37:10.105522
defaults_reqdate_interval	\N	2019-10-15 11:37:10.11423
defaults_require_transaction_description	\N	2019-10-15 11:37:10.122504
defaults_sales_purchase_order_show_ship_missing_column	\N	2019-10-15 11:37:10.131668
defaults_sales_purchase_process_limitations	\N	2019-10-15 11:37:10.140579
defaults_transport_cost_reminder	\N	2019-10-15 11:37:10.152646
delete_cvars_on_trans_deletion	\N	2019-10-15 11:37:10.160215
invoice_positions	\N	2019-10-15 11:37:10.183896
orderitems_delivery_order_items_positions	\N	2019-10-15 11:37:10.191875
periodic_invoices_order_value_periodicity	\N	2019-10-15 11:37:10.201329
price_rules	\N	2019-10-15 11:37:10.238017
price_source_client_config	\N	2019-10-15 11:37:10.347477
project_status_default_entries	\N	2019-10-15 11:37:10.353281
record_links_orderitems_delete_triggers	\N	2019-10-15 11:37:10.36305
recorditem_active_price_source	\N	2019-10-15 11:37:10.371206
remove_redundant_customer_vendor_delete_triggers	\N	2019-10-15 11:37:10.38084
requirement_spec_edit_html	\N	2019-10-15 11:37:10.389956
requirement_spec_parts	\N	2019-10-15 11:37:10.401484
taxzone_charts	\N	2019-10-15 11:37:10.455978
vendor_long_entries	\N	2019-10-15 11:37:10.491645
warehouse_add_delivery_order_items_stock_id	\N	2019-10-15 11:37:10.500758
column_type_text_instead_of_varchar2	\N	2019-10-15 11:37:10.509961
convert_taxzone	\N	2019-10-15 11:37:10.519589
defaults_bcc_to_login	\N	2019-10-15 11:37:10.530742
defaults_drop_delivery_plan_calculate_transferred_do	\N	2019-10-15 11:37:10.536621
defaults_transport_cost_reminder_id	\N	2019-10-15 11:37:10.542555
delete_cvars_on_trans_deletion_fix1	\N	2019-10-15 11:37:10.549257
oe_ar_ap_delivery_orders_edit_notes_as_html	\N	2019-10-15 11:37:10.558937
price_rules_cascade_delete	\N	2019-10-15 11:37:10.566535
recorditem_active_record_source	\N	2019-10-15 11:37:10.575376
remove_redundant_cvar_delete_triggers	\N	2019-10-15 11:37:10.587138
requirement_spec_parts_foreign_key_cascade	\N	2019-10-15 11:37:10.599267
taxzone_sortkey	\N	2019-10-15 11:37:10.608842
transfer_out_sales_invoice	\N	2019-10-15 11:37:10.617221
ar_ap_fix_notes_as_html_for_non_invoices	\N	2019-10-15 11:37:10.627069
column_type_text_instead_of_varchar3	\N	2019-10-15 11:37:10.635152
delete_cvars_on_trans_deletion_fix2	\N	2019-10-15 11:37:10.643437
price_rules_discount	\N	2019-10-15 11:37:10.650108
taxzone_default_id	\N	2019-10-15 11:37:10.656039
change_taxzone_id_0	\N	2019-10-15 11:37:10.662629
tax_zones_obsolete	\N	2019-10-15 11:37:10.679074
taxzone_id_in_oe_delivery_orders	\N	2019-10-15 11:37:10.686078
release_3_2_0	\N	2019-10-15 11:37:10.698083
ar_ap_default	\N	2019-10-15 11:37:10.703983
bank_accounts_unique_chart_constraint	\N	2019-10-15 11:37:10.715037
bank_transactions	\N	2019-10-15 11:37:10.748551
bankaccounts_reconciliation	\N	2019-10-15 11:37:10.804944
bankaccounts_sortkey_and_obsolete	\N	2019-10-15 11:37:10.81182
create_part_if_not_found	\N	2019-10-15 11:37:10.823099
defaults_drop_delivery_plan_config	\N	2019-10-15 11:37:10.829675
delete_invalidated_custom_variables_for_parts	\N	2019-10-15 11:37:10.835857
invoices_amount_paid_not_null	\N	2019-10-15 11:37:10.844582
letter	\N	2019-10-15 11:37:10.860061
payment_terms_automatic_calculation	\N	2019-10-15 11:37:10.925779
remove_terms_add_payment_id	\N	2019-10-15 11:37:10.934353
sepa_items_payment_type	\N	2019-10-15 11:37:10.95229
tax_skonto_automatic	\N	2019-10-15 11:37:10.961228
automatic_reconciliation	\N	2019-10-15 11:37:10.979402
bank_transactions_type	\N	2019-10-15 11:37:11.013722
letter_country_page	\N	2019-10-15 11:37:11.021108
letter_date_type	\N	2019-10-15 11:37:11.027037
letter_draft	\N	2019-10-15 11:37:11.036531
letter_reference	\N	2019-10-15 11:37:11.092112
auto_delete_reconciliation_links_on_acc_trans_deletion	\N	2019-10-15 11:37:11.099487
bank_transactions_type2	\N	2019-10-15 11:37:11.119971
letter_emplyee_salesman	\N	2019-10-15 11:37:11.127261
use_html_in_letter	\N	2019-10-15 11:37:11.135344
letter_notes_internal	\N	2019-10-15 11:37:11.143815
letter_cp_id	\N	2019-10-15 11:37:11.151071
release_3_3_0	\N	2019-10-15 11:37:11.164576
add_project_defaults	\N	2019-10-15 11:37:11.170659
buchungsgruppen_forein_keys	\N	2019-10-15 11:37:11.183191
chart_pos_er	\N	2019-10-15 11:37:11.19297
customer_vendor_shipto_add_gln	\N	2019-10-15 11:37:11.208053
defaults_add_features	\N	2019-10-15 11:37:11.216391
defaults_order_warn_duplicate_parts	\N	2019-10-15 11:37:11.23437
defaults_show_longdescription_select_item	\N	2019-10-15 11:37:11.241555
email_journal	\N	2019-10-15 11:37:11.253867
periodic_invoices_direct_debit_flag	\N	2019-10-15 11:37:11.363816
project_mtime_trigger	\N	2019-10-15 11:37:11.372084
remove_index	\N	2019-10-15 11:37:11.384995
sepa_contained_in_message_ids	\N	2019-10-15 11:37:11.680983
defaults_enable_email_journal	\N	2019-10-15 11:37:11.743252
release_3_4_0	\N	2019-10-15 11:37:11.75138
add_parts_price_history	\N	2019-10-15 11:37:11.757375
defaults_add_quick_search_modules	\N	2019-10-15 11:37:11.803614
delete_from_generic_translations_on_language_deletion	\N	2019-10-15 11:37:11.811952
letter_cleanup	\N	2019-10-15 11:37:11.823416
payment_terms_for_invoices	\N	2019-10-15 11:37:11.844777
periodic_invoices_send_email	\N	2019-10-15 11:37:11.853388
transfer_type_assembled	\N	2019-10-15 11:37:11.887013
add_parts_price_history2	\N	2019-10-15 11:37:11.89326
inventory_fix_shippingdate_assemblies	\N	2019-10-15 11:37:11.901289
inventory_shippingdate_not_null	\N	2019-10-15 11:37:11.913277
release_3_4_1	\N	2019-10-15 11:37:11.919082
add_test_mode_to_csv_import_report	\N	2019-10-15 11:37:11.925081
add_warehouse_for_assembly	\N	2019-10-15 11:37:11.931066
assembly_parts_foreign_key	\N	2019-10-15 11:37:11.937006
assembly_position	\N	2019-10-15 11:37:11.952172
create_record_template_tables	\N	2019-10-15 11:37:11.958344
customer_klass_rename_to_pricegroup_id_and_foreign_key	\N	2019-10-15 11:37:12.073257
defaults_add_feature_experimental	\N	2019-10-15 11:37:12.081101
defaults_add_finanzamt_data	\N	2019-10-15 11:37:12.087083
eur_bwa_category_views	\N	2019-10-15 11:37:12.097576
filemanagement_feature	\N	2019-10-15 11:37:12.109227
files	\N	2019-10-15 11:37:12.124278
get_shipped_qty_config	\N	2019-10-15 11:37:12.183166
letter_vendorletter	\N	2019-10-15 11:37:12.193062
makemodel_add_vendor_foreign_key	\N	2019-10-15 11:37:12.201041
part_classifications	\N	2019-10-15 11:37:12.207167
part_type_enum	\N	2019-10-15 11:37:12.261053
partsgroup_sortkey_obsolete	\N	2019-10-15 11:37:12.271035
payment_terms_obsolete	\N	2019-10-15 11:37:12.279527
periodic_invoices_order_value_periodicity2	\N	2019-10-15 11:37:12.284945
pricegroup_sortkey_obsolete	\N	2019-10-15 11:37:12.290926
prices_delete_cascade	\N	2019-10-15 11:37:12.302256
prices_unique	\N	2019-10-15 11:37:12.321209
remove_alternate_from_parts	\N	2019-10-15 11:37:12.348896
sepa_export_items	\N	2019-10-15 11:37:12.356567
sepa_reference_add_vc_vc_id	\N	2019-10-15 11:37:12.362529
user_preferences	\N	2019-10-15 11:37:12.368823
assembly_parts_foreign_key2	\N	2019-10-15 11:37:12.440365
assortment_items	\N	2019-10-15 11:37:12.446577
convert_drafts_to_record_templates	\N	2019-10-15 11:37:12.47915
defaults_add_feature_experimental2	\N	2019-10-15 11:37:12.488266
defaults_filemanagement_remove_doc_database	\N	2019-10-15 11:37:12.498014
displayable_name_prefs_defaults	\N	2019-10-15 11:37:12.506228
email_journal_attachments_add_fileid	\N	2019-10-15 11:37:12.515932
part_classification_report_separate	\N	2019-10-15 11:37:12.523941
part_remove_unneeded_fields	\N	2019-10-15 11:37:12.529863
assortment_charge	\N	2019-10-15 11:37:12.535837
release_3_5_0	\N	2019-10-15 11:37:12.541818
alter_record_template_tables	\N	2019-10-15 11:37:12.547789
custom_data_export	\N	2019-10-15 11:37:12.55378
shops	\N	2019-10-15 11:37:12.668759
trigram_extension	\N	2019-10-15 11:37:12.72781
custom_data_export_default_values_for_parameters	\N	2019-10-15 11:37:12.863431
customer_orderlock	\N	2019-10-15 11:37:12.871981
shop_1	\N	2019-10-15 11:37:12.878045
shop_2	\N	2019-10-15 11:37:12.886949
shop_3	\N	2019-10-15 11:37:12.894729
shop_orders	\N	2019-10-15 11:37:12.903368
shop_parts	\N	2019-10-15 11:37:13.016536
trigram_indices	\N	2019-10-15 11:37:13.098996
trigram_indices_webshop	\N	2019-10-15 11:37:13.133059
shop_orders_add_active_price_source	\N	2019-10-15 11:37:13.140856
shopimages	\N	2019-10-15 11:37:13.148348
shop_orders_update_1	\N	2019-10-15 11:37:13.208077
shopimages_2	\N	2019-10-15 11:37:13.22023
shopimages_3	\N	2019-10-15 11:37:13.22711
shop_orders_update_2	\N	2019-10-15 11:37:13.23454
shop_orders_update_3	\N	2019-10-15 11:37:13.24048
release_3_5_1	\N	2019-10-15 11:37:13.248635
create_part_customerprices	\N	2019-10-15 11:37:13.255909
datev_export_format	\N	2019-10-15 11:37:13.366192
stocktakings	\N	2019-10-15 11:37:13.374789
release_3_5_2	\N	2019-10-15 11:37:13.452097
accounts_tax_office_leonberg	\N	2019-10-15 11:37:13.460029
defaults_order_warn_no_deliverydate	\N	2019-10-15 11:37:13.467689
sepa_recommended_execution_date	\N	2019-10-15 11:37:13.475761
release_3_5_3	\N	2019-10-15 11:37:13.48556
add_emloyee_project_assignment_for_viewing_invoices	\N	2019-10-15 11:37:13.491801
bank_transactions_check_constraint_invoice_amount	\N	2019-10-15 11:37:13.52634
contacts_add_main_contact	\N	2019-10-15 11:37:13.532615
customer_add_commercial_court	\N	2019-10-15 11:37:13.538242
customer_add_fields	\N	2019-10-15 11:37:13.544106
customer_add_generic_mail_delivery	\N	2019-10-15 11:37:13.550111
defaults_delivery_date_interval	\N	2019-10-15 11:37:13.556234
defaults_doc_email_attachment	\N	2019-10-15 11:37:13.562273
defaults_invoice_mail_priority	\N	2019-10-15 11:37:13.572107
defaults_set_dunning_creator	\N	2019-10-15 11:37:13.580018
drop_payment_terms_ranking	\N	2019-10-15 11:37:13.586122
dunning_foreign_key_for_trans_id	\N	2019-10-15 11:37:13.591969
record_links_bt_acc_trans	\N	2019-10-15 11:37:13.602553
record_links_post_delete_triggers_gl2	\N	2019-10-15 11:37:13.644408
release_3_5_4	\N	2019-10-15 11:37:13.655663
\.


--
-- Data for Name: sepa_export; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.sepa_export (id, employee_id, executed, closed, itime, vc) FROM stdin;
\.


--
-- Data for Name: sepa_export_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.sepa_export_items (id, sepa_export_id, ap_id, chart_id, amount, reference, requested_execution_date, executed, execution_date, our_iban, our_bic, vc_iban, vc_bic, end_to_end_id, our_depositor, vc_depositor, ar_id, vc_mandator_id, vc_mandate_date_of_signature, payment_type, skonto_amount) FROM stdin;
\.


--
-- Data for Name: sepa_export_message_ids; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.sepa_export_message_ids (id, sepa_export_id, message_id) FROM stdin;
\.


--
-- Data for Name: shipto; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shipto (trans_id, shiptoname, shiptodepartment_1, shiptodepartment_2, shiptostreet, shiptozipcode, shiptocity, shiptocountry, shiptocontact, shiptophone, shiptofax, shiptoemail, itime, mtime, module, shipto_id, shiptocp_gender, shiptogln) FROM stdin;
2												2019-10-15 11:52:10.264198	\N	AR	415	m	
\.


--
-- Data for Name: shop_images; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shop_images (id, file_id, "position", thumbnail_content, org_file_width, org_file_height, thumbnail_content_type, itime, mtime, object_id) FROM stdin;
\.


--
-- Data for Name: shop_order_items; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shop_order_items (id, shop_trans_id, shop_order_id, description, partnumber, "position", tax_rate, quantity, price, active_price_source) FROM stdin;
\.


--
-- Data for Name: shop_orders; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shop_orders (id, shop_trans_id, shop_ordernumber, shop_customer_comment, amount, netamount, order_date, shipping_costs, shipping_costs_net, shipping_costs_id, tax_included, payment_id, payment_description, shop_id, host, remote_ip, transferred, transfer_date, kivi_customer_id, shop_customer_id, shop_customer_number, customer_lastname, customer_firstname, customer_company, customer_street, customer_zipcode, customer_city, customer_country, customer_greeting, customer_department, customer_vat, customer_phone, customer_fax, customer_email, customer_newsletter, shop_c_billing_id, shop_c_billing_number, billing_lastname, billing_firstname, billing_company, billing_street, billing_zipcode, billing_city, billing_country, billing_greeting, billing_department, billing_vat, billing_phone, billing_fax, billing_email, sepa_account_holder, sepa_iban, sepa_bic, shop_c_delivery_id, shop_c_delivery_number, delivery_lastname, delivery_firstname, delivery_company, delivery_street, delivery_zipcode, delivery_city, delivery_country, delivery_greeting, delivery_department, delivery_vat, delivery_phone, delivery_fax, delivery_email, obsolete, positions, itime, mtime) FROM stdin;
\.


--
-- Data for Name: shop_parts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shop_parts (id, shop_id, part_id, shop_description, itime, mtime, last_update, show_date, sortorder, front_page, active, shop_category, active_price_source, metatag_keywords, metatag_description, metatag_title) FROM stdin;
\.


--
-- Data for Name: shops; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.shops (id, description, obsolete, sortkey, connector, pricetype, price_source, taxzone_id, last_order_number, orders_to_fetch, server, port, login, password, protocol, path, realm, transaction_description, itime, mtime) FROM stdin;
\.


--
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.status (trans_id, formname, printed, emailed, spoolfile, chart_id, itime, mtime, id) FROM stdin;
\.


--
-- Data for Name: stocktakings; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.stocktakings (id, inventory_id, warehouse_id, bin_id, parts_id, employee_id, qty, comment, chargenumber, bestbefore, cutoff_date, itime, mtime) FROM stdin;
\.


--
-- Data for Name: tax; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.tax (chart_id, rate, taxnumber, taxkey, taxdescription, itime, mtime, id, chart_categories, skonto_sales_chart_id, skonto_purchase_chart_id) FROM stdin;
44	0.08000	2200	2	MWST	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	195	I	\N	\N
45	0.02500	2201	3	MWST	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	196	I	\N	\N
12	0.08000	1170	4	MWST Aufwand	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	197	E	\N	\N
12	0.02500	1170	5	MWST Aufwand	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	198	E	\N	\N
13	0.08000	1171	6	MWST Investitionen	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	199	E	\N	\N
13	0.02500	1171	7	MWST Investitionen	2019-10-15 11:37:00.716536	2019-10-15 11:37:09.909063	200	E	\N	\N
\N	0.00000	\N	0	Keine Steuer	2019-10-15 11:37:00.716536	2019-10-15 11:37:10.961228	0	ALQCIE	\N	\N
\N	0.00000	\N	1	Mehrwertsteuerfrei	2019-10-15 11:37:00.716536	2019-10-15 11:37:10.961228	194	ALQCIE	\N	\N
\.


--
-- Data for Name: tax_zones; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.tax_zones (id, description, sortkey, obsolete) FROM stdin;
1	EU mit USt-ID Nummer	2	f
2	EU ohne USt-ID Nummer	3	f
3	Ausserhalb EU	4	f
4	Schweiz	1	f
\.


--
-- Data for Name: taxkeys; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.taxkeys (id, chart_id, tax_id, taxkey_id, pos_ustva, startdate) FROM stdin;
201	1	0	0	\N	2011-01-01
202	2	0	0	\N	2011-01-01
203	3	0	0	\N	2011-01-01
204	4	0	0	\N	2011-01-01
205	5	0	0	\N	2011-01-01
206	6	0	0	\N	2011-01-01
207	7	0	0	\N	2011-01-01
208	8	0	0	\N	2011-01-01
209	9	0	0	\N	2011-01-01
210	10	0	0	\N	2011-01-01
211	11	0	0	\N	2011-01-01
212	12	0	0	\N	2011-01-01
213	13	0	0	\N	2011-01-01
214	14	0	0	\N	2011-01-01
215	15	0	0	\N	2011-01-01
216	16	0	0	\N	2011-01-01
217	17	0	0	\N	2011-01-01
218	18	0	0	\N	2011-01-01
219	19	0	0	\N	2011-01-01
220	20	0	0	\N	2011-01-01
221	21	0	0	\N	2011-01-01
222	22	0	0	\N	2011-01-01
223	23	0	0	\N	2011-01-01
224	24	0	0	\N	2011-01-01
225	25	0	0	\N	2011-01-01
226	26	0	0	\N	2011-01-01
227	27	0	0	\N	2011-01-01
228	28	0	0	\N	2011-01-01
229	29	0	0	\N	2011-01-01
230	30	0	0	\N	2011-01-01
231	31	0	0	\N	2011-01-01
232	32	0	0	\N	2011-01-01
233	33	0	0	\N	2011-01-01
234	34	0	0	\N	2011-01-01
235	35	0	0	\N	2011-01-01
236	36	0	0	\N	2011-01-01
237	37	0	0	\N	2011-01-01
238	38	0	0	\N	2011-01-01
239	39	0	0	\N	2011-01-01
240	40	0	0	\N	2011-01-01
241	41	0	0	\N	2011-01-01
242	42	0	0	\N	2011-01-01
243	43	0	0	\N	2011-01-01
244	44	0	0	\N	2011-01-01
245	45	0	0	\N	2011-01-01
246	46	0	0	\N	2011-01-01
247	47	0	0	\N	2011-01-01
248	48	0	0	\N	2011-01-01
249	49	0	0	\N	2011-01-01
250	50	0	0	\N	2011-01-01
251	51	0	0	\N	2011-01-01
252	52	0	0	\N	2011-01-01
253	53	0	0	\N	2011-01-01
254	54	0	0	\N	2011-01-01
255	55	0	0	\N	2011-01-01
256	56	0	0	\N	2011-01-01
257	57	0	0	\N	2011-01-01
258	58	0	0	\N	2011-01-01
259	59	0	0	\N	2011-01-01
260	60	0	0	\N	2011-01-01
261	61	0	0	\N	2011-01-01
262	62	0	0	\N	2011-01-01
263	63	0	0	\N	2011-01-01
264	64	0	0	\N	2011-01-01
265	65	0	0	\N	2011-01-01
266	66	0	0	\N	2011-01-01
267	67	0	0	\N	2011-01-01
268	68	0	0	\N	2011-01-01
269	69	0	0	\N	2011-01-01
270	70	0	0	\N	2011-01-01
271	71	0	0	\N	2011-01-01
272	72	0	0	\N	2011-01-01
273	73	0	0	\N	2011-01-01
274	74	0	0	\N	2011-01-01
275	75	0	0	\N	2011-01-01
276	76	0	0	\N	2011-01-01
277	77	0	0	\N	2011-01-01
278	78	0	0	\N	2011-01-01
279	79	0	0	\N	2011-01-01
280	80	0	0	\N	2011-01-01
281	81	0	0	\N	2011-01-01
282	82	0	0	\N	2011-01-01
283	83	0	0	\N	2011-01-01
284	84	0	0	\N	2011-01-01
285	85	0	0	\N	2011-01-01
286	86	0	0	\N	2011-01-01
287	87	0	0	\N	2011-01-01
288	88	0	0	\N	2011-01-01
289	89	0	0	\N	2011-01-01
290	90	0	0	\N	2011-01-01
291	91	0	0	\N	2011-01-01
292	92	0	0	\N	2011-01-01
293	93	0	0	\N	2011-01-01
294	94	0	0	\N	2011-01-01
295	95	0	0	\N	2011-01-01
296	96	0	0	\N	2011-01-01
297	97	0	0	\N	2011-01-01
298	98	0	0	\N	2011-01-01
299	99	0	0	\N	2011-01-01
300	100	0	0	\N	2011-01-01
301	101	0	0	\N	2011-01-01
302	102	0	0	\N	2011-01-01
303	103	0	0	\N	2011-01-01
304	104	0	0	\N	2011-01-01
305	105	0	0	\N	2011-01-01
306	106	0	0	\N	2011-01-01
307	107	0	0	\N	2011-01-01
308	108	0	0	\N	2011-01-01
309	109	0	0	\N	2011-01-01
310	110	0	0	\N	2011-01-01
311	111	0	0	\N	2011-01-01
312	112	0	0	\N	2011-01-01
313	113	0	0	\N	2011-01-01
314	114	0	0	\N	2011-01-01
315	115	0	0	\N	2011-01-01
316	116	0	0	\N	2011-01-01
317	117	0	0	\N	2011-01-01
318	118	0	0	\N	2011-01-01
319	119	0	0	\N	2011-01-01
320	120	0	0	\N	2011-01-01
321	121	0	0	\N	2011-01-01
322	122	0	0	\N	2011-01-01
323	123	0	0	\N	2011-01-01
324	124	0	0	\N	2011-01-01
325	125	0	0	\N	2011-01-01
326	126	0	0	\N	2011-01-01
327	127	0	0	\N	2011-01-01
328	128	0	0	\N	2011-01-01
329	129	0	0	\N	2011-01-01
330	130	0	0	\N	2011-01-01
331	131	0	0	\N	2011-01-01
332	132	0	0	\N	2011-01-01
333	133	0	0	\N	2011-01-01
334	134	0	0	\N	2011-01-01
335	135	0	0	\N	2011-01-01
336	136	0	0	\N	2011-01-01
337	137	0	0	\N	2011-01-01
338	138	0	0	\N	2011-01-01
339	139	0	0	\N	2011-01-01
340	140	0	0	\N	2011-01-01
341	141	0	0	\N	2011-01-01
342	142	0	0	\N	2011-01-01
343	143	0	0	\N	2011-01-01
344	144	0	0	\N	2011-01-01
345	145	0	0	\N	2011-01-01
346	146	0	0	\N	2011-01-01
347	147	0	0	\N	2011-01-01
348	148	0	0	\N	2011-01-01
349	149	0	0	\N	2011-01-01
350	150	0	0	\N	2011-01-01
351	151	0	0	\N	2011-01-01
352	152	0	0	\N	2011-01-01
353	153	0	0	\N	2011-01-01
354	154	0	0	\N	2011-01-01
355	155	0	0	\N	2011-01-01
356	156	0	0	\N	2011-01-01
357	157	0	0	\N	2011-01-01
358	158	0	0	\N	2011-01-01
359	159	0	0	\N	2011-01-01
360	160	0	0	\N	2011-01-01
361	161	0	0	\N	2011-01-01
362	162	0	0	\N	2011-01-01
363	163	0	0	\N	2011-01-01
364	164	0	0	\N	2011-01-01
365	165	0	0	\N	2011-01-01
366	166	0	0	\N	2011-01-01
367	167	0	0	\N	2011-01-01
368	168	0	0	\N	2011-01-01
369	169	0	0	\N	2011-01-01
370	170	0	0	\N	2011-01-01
371	171	0	0	\N	2011-01-01
372	172	0	0	\N	2011-01-01
373	173	0	0	\N	2011-01-01
374	174	0	0	\N	2011-01-01
375	175	0	0	\N	2011-01-01
376	176	0	0	\N	2011-01-01
377	177	0	0	\N	2011-01-01
378	178	0	0	\N	2011-01-01
379	179	0	0	\N	2011-01-01
380	180	0	0	\N	2011-01-01
381	181	0	0	\N	2011-01-01
382	182	0	0	\N	2011-01-01
383	183	0	0	\N	2011-01-01
384	184	0	0	\N	2011-01-01
385	185	0	0	\N	2011-01-01
386	186	0	0	\N	2011-01-01
387	187	0	0	\N	2011-01-01
388	188	0	0	\N	2011-01-01
389	189	0	0	\N	2011-01-01
390	190	0	0	\N	2011-01-01
391	191	0	0	\N	2011-01-01
\.


--
-- Data for Name: taxzone_charts; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.taxzone_charts (id, taxzone_id, buchungsgruppen_id, income_accno_id, expense_accno_id, itime) FROM stdin;
2	1	192	74	92	2019-10-15 11:37:10.519589
3	2	192	74	92	2019-10-15 11:37:10.519589
4	3	192	74	92	2019-10-15 11:37:10.519589
1	4	192	74	92	2019-10-15 11:37:10.519589
\.


--
-- Data for Name: todo_user_config; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.todo_user_config (employee_id, show_after_login, show_follow_ups, show_follow_ups_login, show_overdue_sales_quotations, show_overdue_sales_quotations_login, id) FROM stdin;
409	t	t	t	t	t	1
\.


--
-- Data for Name: transfer_type; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.transfer_type (id, direction, description, sortkey, itime, mtime) FROM stdin;
395	in	stock	1	2019-10-15 11:37:02.370155	\N
396	in	found	2	2019-10-15 11:37:02.370155	\N
397	in	correction	3	2019-10-15 11:37:02.370155	\N
398	out	used	4	2019-10-15 11:37:02.370155	\N
399	out	disposed	5	2019-10-15 11:37:02.370155	\N
400	out	back	6	2019-10-15 11:37:02.370155	\N
401	out	missing	7	2019-10-15 11:37:02.370155	\N
402	out	correction	9	2019-10-15 11:37:02.370155	\N
403	transfer	transfer	10	2019-10-15 11:37:02.370155	\N
404	transfer	correction	11	2019-10-15 11:37:02.370155	\N
405	out	shipped	12	2019-10-15 11:37:02.708607	\N
406	in	stocktaking	13	2019-10-15 11:37:02.71607	\N
407	out	stocktaking	14	2019-10-15 11:37:02.71607	\N
408	in	assembled	15	2019-10-15 11:37:11.887013	\N
\.


--
-- Data for Name: translation; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.translation (parts_id, language_id, translation, itime, mtime, longdescription, id) FROM stdin;
\.


--
-- Data for Name: trigger_information; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.trigger_information (id, key, value) FROM stdin;
\.


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.units (name, base_unit, factor, type, sortkey, id) FROM stdin;
Stck	\N	0.00000	dimension	1	1
mg	\N	0.00000	dimension	2	2
g	mg	1000.00000	dimension	3	3
kg	g	1000.00000	dimension	4	4
t	kg	1000.00000	dimension	5	5
ml	\N	0.00000	dimension	6	6
L	ml	1000.00000	dimension	7	7
pauschal	\N	0.00000	service	8	8
Min	\N	0.00000	service	9	9
Std	Min	60.00000	service	10	10
Tag	Std	8.00000	service	11	11
Wo	\N	0.00000	service	12	12
Mt	Wo	4.00000	service	13	13
Jahr	Mt	12.00000	service	14	14
\.


--
-- Data for Name: units_language; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.units_language (unit, language_id, localized, localized_plural, id) FROM stdin;
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.user_preferences (id, login, namespace, version, key, value) FROM stdin;
1	#default#	DisplayableName	0.00000	SL::DB::Customer	<%customernumber%> <%name%>
2	#default#	DisplayableName	0.00000	SL::DB::Vendor	<%vendornumber%> <%name%>
3	#default#	DisplayableName	0.00000	SL::DB::Part	<%partnumber%> <%description%>
4	cem	PositionsScrollbar	0.00000	height	25
\.


--
-- Data for Name: vendor; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.vendor (id, name, department_1, department_2, street, zipcode, city, country, contact, phone, fax, homepage, email, notes, taxincluded, vendornumber, cc, bcc, business_id, taxnumber, discount, creditlimit, account_number, bank_code, bank, language, itime, mtime, obsolete, username, user_password, salesman_id, v_customer_id, language_id, payment_id, taxzone_id, greeting, ustid, iban, bic, direct_debit, depositor, delivery_term_id, currency_id, gln) FROM stdin;
\.


--
-- Data for Name: warehouse; Type: TABLE DATA; Schema: public; Owner: kivitendo
--

COPY public.warehouse (id, description, itime, mtime, sortkey, invalid) FROM stdin;
\.


--
-- Data for Name: report_categories; Type: TABLE DATA; Schema: tax; Owner: kivitendo
--

COPY tax.report_categories (id, description, subdescription) FROM stdin;
0		
1	Lieferungen und sonstige Leistungen	(einschließlich unentgeltlicher Wertabgaben)
2	Innergemeinschaftliche Erwerbe	
3	Ergänzende Angaben zu Umsätzen	
99	Summe	
\.


--
-- Data for Name: report_headings; Type: TABLE DATA; Schema: tax; Owner: kivitendo
--

COPY tax.report_headings (id, category_id, type, description, subdescription) FROM stdin;
0	0			
1	1	received	Steuerfreie Umsätze mit Vorsteuerabzug	
2	1	recieved	Steuerfreie Umsätze ohne Vorsteuerabzug	
3	1	recieved	Steuerpflichtige Umsätze	(Lieferungen und sonstige Leistungen einschl. unentgeltlicher Wertabgaben)
4	2	recieved	Steuerfreie innergemeinschaftliche Erwerbe	
5	2	recieved	Steuerpflichtige innergemeinschaftliche Erwerbe	
6	3	recieved	Umsätze, für die als Leistungsempfänger die Steuer nach § 13b Abs. 2 UStG geschuldet wird	
66	3	recieved		
7	3	paied	Abziehbare Vorsteuerbeträge	
8	3	paied	Andere Steuerbeträge	
99	99		Summe	
\.


--
-- Data for Name: report_variables; Type: TABLE DATA; Schema: tax; Owner: kivitendo
--

COPY tax.report_variables (id, "position", heading_id, description, taxbase, dec_places, valid_from) FROM stdin;
0	keine	0	< < < keine UStVa Position > > >			1970-01-01
1	41	1	Innergemeinschaftliche Lieferungen (§ 4 Nr. 1 Buchst. b UStG) an Abnehmer mit USt-IdNr.	0	0	1970-01-01
2	44	1	neuer Fahrzeuge an Abnehmer ohne USt-IdNr.	0	0	1970-01-01
3	49	1	neuer Fahrzeuge außerhalb eines Unternehmens (§ 2a UStG)	0	0	1970-01-01
4	43	1	Weitere steuerfreie Umsätze mit Vorsteuerabzug	0	0	1970-01-01
5	48	2	Umsätze nach § 4 Nr. 8 bis 28 UStG	0	0	1970-01-01
6	51	3	zum Steuersatz von 16 %	0	0	1970-01-01
7	511	3		6	2	1970-01-01
8	81	3	zum Steuersatz von 19 %	0	0	1970-01-01
9	811	3		8	2	1970-01-01
10	86	3	zum Steuersatz von 7 %	0	0	1970-01-01
11	861	3		10	2	1970-01-01
12	35	3	Umsätze, die anderen Steuersätzen unterliegen	0	0	1970-01-01
13	36	3		12	2	1970-01-01
14	77	3	Lieferungen in das übrige Gemeinschaftsgebiet an Abnehmer mit USt-IdNr.	0	0	1970-01-01
15	76	3	Umsätze, für die eine Steuer nach § 24 UStG zu entrichten ist	0	0	1970-01-01
16	80	3		15	2	1970-01-01
17	91	4	Erwerbe nach § 4b UStG	0	0	1970-01-01
18	97	5	zum Steuersatz von 16 %	0	0	1970-01-01
19	971	5		18	2	1970-01-01
20	89	5	zum Steuersatz von 19 %	0	0	1970-01-01
21	891	5		20	2	1970-01-01
22	93	5	zum Steuersatz von 7 %	0	0	1970-01-01
23	931	5		22	2	1970-01-01
24	95	5	zu anderen Steuersätzen	0	0	1970-01-01
25	98	5		24	2	1970-01-01
26	94	5	neuer Fahrzeuge von Lieferern ohne USt-IdNr. zum allgemeinen Steuersatz	0	0	1970-01-01
27	96	5		26	2	1970-01-01
28	42	66	Lieferungen des ersten Abnehmers bei innergemeinschaftlichen Dreiecksgeschäften (§ 25b Abs. 2 UStG)	0	0	1970-01-01
29	60	66	Steuerpflichtige Umsätze im Sinne des § 13b Abs. 1 Satz 1 Nr. 1 bis 5 UStG, für die der Leistungsempfänger die Steuer schuldet	0	0	1970-01-01
30	45	66	Nicht steuerbare Umsätze (Leistungsort nicht im Inland)	0	0	1970-01-01
31	52	6	Leistungen eines im Ausland ansässigen Unternehmers (§ 13b Abs. 1 Satz 1 Nr. 1 und 5 UStG)	0	0	1970-01-01
32	53	6		31	2	1970-01-01
33	73	6	Lieferungen sicherungsübereigneter Gegenstände und Umsätze, die unter das GrEStG fallen (§ 13b Abs. 1 Satz 1 Nr. 2 und 3 UStG)	0	0	1970-01-01
34	74	6		33	2	1970-01-01
35	84	6	Bauleistungen eines im Inland ansässigen Unternehmers (§ 13b Abs. 1 Satz 1 Nr. 4 UStG)	0	0	1970-01-01
36	85	6		35	2	1970-01-01
37	65	6	Steuer infolge Wechsels der Besteuerungsform sowie Nachsteuer auf versteuerte Anzahlungen u. ä. wegen Steuersatzänderung		2	1970-01-01
38	66	7	Vorsteuerbeträge aus Rechnungen von anderen Unternehmern (§ 15 Abs. 1 Satz 1 Nr. 1 UStG), aus Leistungen im Sinne des § 13a Abs. 1 Nr. 6 UStG (§ 15 Abs. 1 Satz 1 Nr. 5 UStG) und aus innergemeinschaftlichen Dreiecksgeschäften (§ 25b Abs. 5 UStG)		2	1970-01-01
39	61	7	Vorsteuerbeträge aus dem innergemeinschaftlichen Erwerb von Gegenständen (§ 15 Abs. 1 Satz 1 Nr. 3 UStG)		2	1970-01-01
40	62	7	Entrichtete Einfuhrumsatzsteuer (§ 15 Abs. 1 Satz 1 Nr. 2 UStG)		2	1970-01-01
41	67	7	Vorsteuerbeträge aus Leistungen im Sinne des § 13b Abs. 1 UStG (§ 15 Abs. 1 Satz 1 Nr. 4 UStG)		2	1970-01-01
42	63	7	Vorsteuerbeträge, die nach allgemeinen Durchschnittssätzen berechnet sind (§§ 23 und 23a UStG)		2	1970-01-01
43	64	7	Berichtigung des Vorsteuerabzugs (§ 15a UStG)		2	1970-01-01
44	59	7	Vorsteuerabzug für innergemeinschaftliche Lieferungen neuer Fahrzeuge außerhalb eines Unternehmens (§ 2a UStG) sowie von Kleinunternehmern im Sinne des § 19 Abs. 1 UStG (§ 15 Abs. 4a UStG)		2	1970-01-01
45	69	8	in Rechnungen unrichtig oder unberechtigt ausgewiesene Steuerbeträge (§ 14c UStG) sowie Steuerbeträge, die nach § 4 Nr. 4a Satz 1 Buchst. a Satz 2, § 6a Abs. 4 Satz 2, § 17 Abs. 1 Satz 6 oder § 25b Abs. 2 UStG geschuldet werden		2	1970-01-01
46	39	8	Anrechnung (Abzug) der festgesetzten Sondervorauszahlung für Dauerfristverlängerung (nur auszufüllen in der letzten Voranmeldung des Besteuerungszeitraums, in der Regel Dezember)		2	1970-01-01
47	21	66	Nicht steuerbare sonstige Leistungen gem. § 18b Satz 1 Nr. 2 UStG	0	0	2010-01-01
48	46	6	Im Inland steuerpflichtige sonstige Leistungen von im übrigen Gemeinschaftsgebiet ansässigen Unternehmen (§13b Abs. 1 UStG)	0	0	2010-01-01
49	47	6		49	2	2010-01-01
50	83	8	Verbleibender Überschuss - bitte dem Betrag ein Minuszeichen voranstellen -	0	2	2010-01-01
\.


--
-- Name: acc_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.acc_trans_id_seq', 5, true);


--
-- Name: assembly_assembly_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.assembly_assembly_id_seq', 1, false);


--
-- Name: background_job_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.background_job_histories_id_seq', 1, false);


--
-- Name: background_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.background_jobs_id_seq', 5, true);


--
-- Name: bank_transaction_acc_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.bank_transaction_acc_trans_id_seq', 1, false);


--
-- Name: bank_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.bank_transactions_id_seq', 1, false);


--
-- Name: csv_import_profile_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.csv_import_profile_settings_id_seq', 10, true);


--
-- Name: csv_import_profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.csv_import_profiles_id_seq', 1, true);


--
-- Name: csv_import_report_rows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.csv_import_report_rows_id_seq', 1, false);


--
-- Name: csv_import_report_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.csv_import_report_status_id_seq', 1, false);


--
-- Name: csv_import_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.csv_import_reports_id_seq', 1, false);


--
-- Name: currencies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.currencies_id_seq', 1, true);


--
-- Name: custom_data_export_queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.custom_data_export_queries_id_seq', 1, false);


--
-- Name: custom_data_export_query_parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.custom_data_export_query_parameters_id_seq', 1, false);


--
-- Name: custom_variable_configs_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.custom_variable_configs_id', 1, false);


--
-- Name: custom_variables_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.custom_variables_id', 1, false);


--
-- Name: datev_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.datev_id_seq', 1, false);


--
-- Name: defaults_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.defaults_id_seq', 1, true);


--
-- Name: delivery_order_items_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.delivery_order_items_id', 1, false);


--
-- Name: email_journal_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.email_journal_attachments_id_seq', 1, false);


--
-- Name: email_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.email_journal_id_seq', 1, false);


--
-- Name: exchangerate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.exchangerate_id_seq', 1, false);


--
-- Name: files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.files_id_seq', 1, false);


--
-- Name: finanzamt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.finanzamt_id_seq', 686, true);


--
-- Name: follow_up_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.follow_up_access_id_seq', 1, false);


--
-- Name: follow_up_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.follow_up_id', 1, false);


--
-- Name: follow_up_link_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.follow_up_link_id', 1, false);


--
-- Name: generic_translations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.generic_translations_id_seq', 1, false);


--
-- Name: glid; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.glid', 2, true);


--
-- Name: id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.id', 416, true);


--
-- Name: inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.inventory_id_seq', 1, false);


--
-- Name: invoiceid; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.invoiceid', 1, true);


--
-- Name: makemodel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.makemodel_id_seq', 1, false);


--
-- Name: note_id; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.note_id', 1, false);


--
-- Name: orderitemsid; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.orderitemsid', 1, false);


--
-- Name: part_classifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.part_classifications_id_seq', 4, true);


--
-- Name: part_customer_prices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.part_customer_prices_id_seq', 1, false);


--
-- Name: parts_price_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.parts_price_history_id_seq', 1, true);


--
-- Name: price_rule_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.price_rule_items_id_seq', 1, false);


--
-- Name: price_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.price_rules_id_seq', 1, false);


--
-- Name: prices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.prices_id_seq', 1, false);


--
-- Name: project_participants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_participants_id_seq', 1, false);


--
-- Name: project_phase_participants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_phase_participants_id_seq', 1, false);


--
-- Name: project_phases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_phases_id_seq', 1, false);


--
-- Name: project_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_roles_id_seq', 1, false);


--
-- Name: project_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_status_id_seq', 4, true);


--
-- Name: project_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.project_types_id_seq', 3, true);


--
-- Name: record_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.record_links_id_seq', 1, false);


--
-- Name: record_template_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.record_template_items_id_seq', 1, false);


--
-- Name: record_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.record_templates_id_seq', 1, false);


--
-- Name: requirement_spec_acceptance_statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_acceptance_statuses_id_seq', 4, true);


--
-- Name: requirement_spec_complexities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_complexities_id_seq', 5, true);


--
-- Name: requirement_spec_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_items_id_seq', 1, false);


--
-- Name: requirement_spec_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_orders_id_seq', 1, false);


--
-- Name: requirement_spec_parts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_parts_id_seq', 1, false);


--
-- Name: requirement_spec_pictures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_pictures_id_seq', 1, false);


--
-- Name: requirement_spec_predefined_texts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_predefined_texts_id_seq', 1, false);


--
-- Name: requirement_spec_risks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_risks_id_seq', 5, true);


--
-- Name: requirement_spec_statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_statuses_id_seq', 3, true);


--
-- Name: requirement_spec_text_blocks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_text_blocks_id_seq', 1, false);


--
-- Name: requirement_spec_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_types_id_seq', 2, true);


--
-- Name: requirement_spec_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_spec_versions_id_seq', 1, false);


--
-- Name: requirement_specs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.requirement_specs_id_seq', 1, false);


--
-- Name: sepa_export_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.sepa_export_id_seq', 1, false);


--
-- Name: sepa_export_message_ids_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.sepa_export_message_ids_id_seq', 1, false);


--
-- Name: shop_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.shop_images_id_seq', 1, false);


--
-- Name: shop_order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.shop_order_items_id_seq', 1, false);


--
-- Name: shop_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.shop_orders_id_seq', 1, false);


--
-- Name: shop_parts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.shop_parts_id_seq', 1, false);


--
-- Name: shops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.shops_id_seq', 1, false);


--
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.status_id_seq', 1, false);


--
-- Name: taxzone_charts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.taxzone_charts_id_seq', 4, true);


--
-- Name: todo_user_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.todo_user_config_id_seq', 1, true);


--
-- Name: translation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.translation_id_seq', 1, false);


--
-- Name: trigger_information_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.trigger_information_id_seq', 1, false);


--
-- Name: units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.units_id_seq', 14, true);


--
-- Name: units_language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.units_language_id_seq', 1, false);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kivitendo
--

SELECT pg_catalog.setval('public.user_preferences_id_seq', 4, true);


--
-- Name: acc_trans acc_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.acc_trans
    ADD CONSTRAINT acc_trans_pkey PRIMARY KEY (acc_trans_id);


--
-- Name: ap ap_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_pkey PRIMARY KEY (id);


--
-- Name: ar ar_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_pkey PRIMARY KEY (id);


--
-- Name: assembly assembly_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assembly
    ADD CONSTRAINT assembly_pkey PRIMARY KEY (assembly_id);


--
-- Name: assortment_items assortment_part_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assortment_items
    ADD CONSTRAINT assortment_part_pkey PRIMARY KEY (assortment_id, parts_id);


--
-- Name: background_job_histories background_job_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.background_job_histories
    ADD CONSTRAINT background_job_histories_pkey PRIMARY KEY (id);


--
-- Name: background_jobs background_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.background_jobs
    ADD CONSTRAINT background_jobs_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_pkey PRIMARY KEY (bank_transaction_id, acc_trans_id);


--
-- Name: bank_transactions bank_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transactions
    ADD CONSTRAINT bank_transactions_pkey PRIMARY KEY (id);


--
-- Name: bin bin_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bin
    ADD CONSTRAINT bin_pkey PRIMARY KEY (id);


--
-- Name: buchungsgruppen buchungsgruppen_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.buchungsgruppen
    ADD CONSTRAINT buchungsgruppen_pkey PRIMARY KEY (id);


--
-- Name: business business_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts chart_id_unique; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_accounts
    ADD CONSTRAINT chart_id_unique UNIQUE (chart_id);


--
-- Name: chart chart_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.chart
    ADD CONSTRAINT chart_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (cp_id);


--
-- Name: csv_import_profile_settings csv_import_profile_settings_csv_import_profile_id_key_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profile_settings
    ADD CONSTRAINT csv_import_profile_settings_csv_import_profile_id_key_key UNIQUE (csv_import_profile_id, key);


--
-- Name: csv_import_profile_settings csv_import_profile_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profile_settings
    ADD CONSTRAINT csv_import_profile_settings_pkey PRIMARY KEY (id);


--
-- Name: csv_import_profiles csv_import_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profiles
    ADD CONSTRAINT csv_import_profiles_pkey PRIMARY KEY (id);


--
-- Name: csv_import_report_rows csv_import_report_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_rows
    ADD CONSTRAINT csv_import_report_rows_pkey PRIMARY KEY (id);


--
-- Name: csv_import_report_status csv_import_report_status_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_status
    ADD CONSTRAINT csv_import_report_status_pkey PRIMARY KEY (id);


--
-- Name: csv_import_reports csv_import_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_reports
    ADD CONSTRAINT csv_import_reports_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_name_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_name_key UNIQUE (name);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: custom_data_export_queries custom_data_export_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_data_export_queries
    ADD CONSTRAINT custom_data_export_queries_pkey PRIMARY KEY (id);


--
-- Name: custom_data_export_query_parameters custom_data_export_query_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_data_export_query_parameters
    ADD CONSTRAINT custom_data_export_query_parameters_pkey PRIMARY KEY (id);


--
-- Name: custom_variable_config_partsgroups custom_variable_config_partsgroups_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variable_config_partsgroups
    ADD CONSTRAINT custom_variable_config_partsgroups_pkey PRIMARY KEY (custom_variable_config_id, partsgroup_id);


--
-- Name: custom_variable_configs custom_variable_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variable_configs
    ADD CONSTRAINT custom_variable_configs_pkey PRIMARY KEY (id);


--
-- Name: custom_variables custom_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variables
    ADD CONSTRAINT custom_variables_pkey PRIMARY KEY (id);


--
-- Name: custom_variables_validity custom_variables_validity_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variables_validity
    ADD CONSTRAINT custom_variables_validity_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: datev datev_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.datev
    ADD CONSTRAINT datev_pkey PRIMARY KEY (id);


--
-- Name: defaults defaults_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_pkey PRIMARY KEY (id);


--
-- Name: delivery_order_items delivery_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_pkey PRIMARY KEY (id);


--
-- Name: delivery_order_items_stock delivery_order_items_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items_stock
    ADD CONSTRAINT delivery_order_items_stock_pkey PRIMARY KEY (id);


--
-- Name: delivery_orders delivery_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_pkey PRIMARY KEY (id);


--
-- Name: delivery_terms delivery_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_terms
    ADD CONSTRAINT delivery_terms_pkey PRIMARY KEY (id);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (id);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: dunning_config dunning_config_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.dunning_config
    ADD CONSTRAINT dunning_config_pkey PRIMARY KEY (id);


--
-- Name: dunning dunning_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.dunning
    ADD CONSTRAINT dunning_pkey PRIMARY KEY (id);


--
-- Name: email_journal_attachments email_journal_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal_attachments
    ADD CONSTRAINT email_journal_attachments_pkey PRIMARY KEY (id);


--
-- Name: email_journal email_journal_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal
    ADD CONSTRAINT email_journal_pkey PRIMARY KEY (id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- Name: employee_project_invoices employee_project_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.employee_project_invoices
    ADD CONSTRAINT employee_project_invoices_pkey PRIMARY KEY (employee_id, project_id);


--
-- Name: exchangerate exchangerate_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.exchangerate
    ADD CONSTRAINT exchangerate_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: finanzamt finanzamt_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.finanzamt
    ADD CONSTRAINT finanzamt_pkey PRIMARY KEY (id);


--
-- Name: follow_up_access follow_up_access_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_access
    ADD CONSTRAINT follow_up_access_pkey PRIMARY KEY (id);


--
-- Name: follow_up_links follow_up_links_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_links
    ADD CONSTRAINT follow_up_links_pkey PRIMARY KEY (id);


--
-- Name: follow_ups follow_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_pkey PRIMARY KEY (id);


--
-- Name: generic_translations generic_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.generic_translations
    ADD CONSTRAINT generic_translations_pkey PRIMARY KEY (id);


--
-- Name: gl gl_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.gl
    ADD CONSTRAINT gl_pkey PRIMARY KEY (id);


--
-- Name: history_erp history_erp_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.history_erp
    ADD CONSTRAINT history_erp_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: letter_draft letter_draft_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_pkey PRIMARY KEY (id);


--
-- Name: letter letter_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_pkey PRIMARY KEY (id);


--
-- Name: makemodel makemodel_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.makemodel
    ADD CONSTRAINT makemodel_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: oe oe_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_pkey PRIMARY KEY (id);


--
-- Name: orderitems orderitems_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_pkey PRIMARY KEY (id);


--
-- Name: part_classifications part_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_classifications
    ADD CONSTRAINT part_classifications_pkey PRIMARY KEY (id);


--
-- Name: part_customer_prices part_customer_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_customer_prices
    ADD CONSTRAINT part_customer_prices_pkey PRIMARY KEY (id);


--
-- Name: prices parts_id_pricegroup_id_unique; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT parts_id_pricegroup_id_unique UNIQUE (parts_id, pricegroup_id);


--
-- Name: parts parts_partnumber_key1; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_partnumber_key1 UNIQUE (partnumber);


--
-- Name: parts parts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_pkey PRIMARY KEY (id);


--
-- Name: parts_price_history parts_price_history_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts_price_history
    ADD CONSTRAINT parts_price_history_pkey PRIMARY KEY (id);


--
-- Name: partsgroup partsgroup_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.partsgroup
    ADD CONSTRAINT partsgroup_pkey PRIMARY KEY (id);


--
-- Name: payment_terms payment_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.payment_terms
    ADD CONSTRAINT payment_terms_pkey PRIMARY KEY (id);


--
-- Name: periodic_invoices_configs periodic_invoices_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices_configs
    ADD CONSTRAINT periodic_invoices_configs_pkey PRIMARY KEY (id);


--
-- Name: periodic_invoices periodic_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices
    ADD CONSTRAINT periodic_invoices_pkey PRIMARY KEY (id);


--
-- Name: price_factors price_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_factors
    ADD CONSTRAINT price_factors_pkey PRIMARY KEY (id);


--
-- Name: price_rule_items price_rule_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rule_items
    ADD CONSTRAINT price_rule_items_pkey PRIMARY KEY (id);


--
-- Name: price_rules price_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rules
    ADD CONSTRAINT price_rules_pkey PRIMARY KEY (id);


--
-- Name: pricegroup pricegroup_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.pricegroup
    ADD CONSTRAINT pricegroup_pkey PRIMARY KEY (id);


--
-- Name: prices prices_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_pkey PRIMARY KEY (id);


--
-- Name: printers printers_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.printers
    ADD CONSTRAINT printers_pkey PRIMARY KEY (id);


--
-- Name: project_participants project_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_participants
    ADD CONSTRAINT project_participants_pkey PRIMARY KEY (id);


--
-- Name: project_phase_participants project_phase_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phase_participants
    ADD CONSTRAINT project_phase_participants_pkey PRIMARY KEY (id);


--
-- Name: project_phases project_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phases
    ADD CONSTRAINT project_phases_pkey PRIMARY KEY (id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: project project_projectnumber_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_projectnumber_key UNIQUE (projectnumber);


--
-- Name: project_roles project_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_roles
    ADD CONSTRAINT project_roles_pkey PRIMARY KEY (id);


--
-- Name: project_statuses project_status_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_statuses
    ADD CONSTRAINT project_status_pkey PRIMARY KEY (id);


--
-- Name: project_types project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_types
    ADD CONSTRAINT project_types_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_links reconciliation_links_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.reconciliation_links
    ADD CONSTRAINT reconciliation_links_pkey PRIMARY KEY (id);


--
-- Name: record_links record_links_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_links
    ADD CONSTRAINT record_links_pkey PRIMARY KEY (id);


--
-- Name: record_template_items record_template_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items
    ADD CONSTRAINT record_template_items_pkey PRIMARY KEY (id);


--
-- Name: record_templates record_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_acceptance_statuses requirement_spec_acceptance_statuses_name_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_acceptance_statuses
    ADD CONSTRAINT requirement_spec_acceptance_statuses_name_description_key UNIQUE (name, description);


--
-- Name: requirement_spec_acceptance_statuses requirement_spec_acceptance_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_acceptance_statuses
    ADD CONSTRAINT requirement_spec_acceptance_statuses_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_complexities requirement_spec_complexities_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_complexities
    ADD CONSTRAINT requirement_spec_complexities_description_key UNIQUE (description);


--
-- Name: requirement_spec_complexities requirement_spec_complexities_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_complexities
    ADD CONSTRAINT requirement_spec_complexities_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_orders requirement_spec_id_order_id_unique; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders
    ADD CONSTRAINT requirement_spec_id_order_id_unique UNIQUE (requirement_spec_id, order_id);


--
-- Name: requirement_spec_item_dependencies requirement_spec_item_dependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_item_dependencies
    ADD CONSTRAINT requirement_spec_item_dependencies_pkey PRIMARY KEY (depending_item_id, depended_item_id);


--
-- Name: requirement_spec_items requirement_spec_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_orders requirement_spec_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders
    ADD CONSTRAINT requirement_spec_orders_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_parts requirement_spec_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_parts
    ADD CONSTRAINT requirement_spec_parts_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_pictures requirement_spec_pictures_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_pictures
    ADD CONSTRAINT requirement_spec_pictures_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_predefined_texts requirement_spec_predefined_texts_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_predefined_texts
    ADD CONSTRAINT requirement_spec_predefined_texts_description_key UNIQUE (description);


--
-- Name: requirement_spec_predefined_texts requirement_spec_predefined_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_predefined_texts
    ADD CONSTRAINT requirement_spec_predefined_texts_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_risks requirement_spec_risks_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_risks
    ADD CONSTRAINT requirement_spec_risks_description_key UNIQUE (description);


--
-- Name: requirement_spec_risks requirement_spec_risks_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_risks
    ADD CONSTRAINT requirement_spec_risks_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_statuses requirement_spec_statuses_name_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_statuses
    ADD CONSTRAINT requirement_spec_statuses_name_description_key UNIQUE (name, description);


--
-- Name: requirement_spec_statuses requirement_spec_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_statuses
    ADD CONSTRAINT requirement_spec_statuses_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_text_blocks requirement_spec_text_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_text_blocks
    ADD CONSTRAINT requirement_spec_text_blocks_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_types requirement_spec_types_description_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_types
    ADD CONSTRAINT requirement_spec_types_description_key UNIQUE (description);


--
-- Name: requirement_spec_types requirement_spec_types_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_types
    ADD CONSTRAINT requirement_spec_types_pkey PRIMARY KEY (id);


--
-- Name: requirement_spec_versions requirement_spec_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_versions
    ADD CONSTRAINT requirement_spec_versions_pkey PRIMARY KEY (id);


--
-- Name: requirement_specs requirement_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_pkey PRIMARY KEY (id);


--
-- Name: schema_info schema_info_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.schema_info
    ADD CONSTRAINT schema_info_pkey PRIMARY KEY (tag);


--
-- Name: sepa_export_items sepa_export_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_items
    ADD CONSTRAINT sepa_export_items_pkey PRIMARY KEY (id);


--
-- Name: sepa_export_message_ids sepa_export_message_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_message_ids
    ADD CONSTRAINT sepa_export_message_ids_pkey PRIMARY KEY (id);


--
-- Name: sepa_export sepa_export_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export
    ADD CONSTRAINT sepa_export_pkey PRIMARY KEY (id);


--
-- Name: shipto shipto_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shipto
    ADD CONSTRAINT shipto_pkey PRIMARY KEY (shipto_id);


--
-- Name: shop_images shop_images_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_images
    ADD CONSTRAINT shop_images_pkey PRIMARY KEY (id);


--
-- Name: shop_order_items shop_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_order_items
    ADD CONSTRAINT shop_order_items_pkey PRIMARY KEY (id);


--
-- Name: shop_orders shop_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_orders
    ADD CONSTRAINT shop_orders_pkey PRIMARY KEY (id);


--
-- Name: shop_parts shop_parts_part_id_shop_id_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_parts
    ADD CONSTRAINT shop_parts_part_id_shop_id_key UNIQUE (part_id, shop_id);


--
-- Name: shop_parts shop_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_parts
    ADD CONSTRAINT shop_parts_pkey PRIMARY KEY (id);


--
-- Name: shops shops_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shops
    ADD CONSTRAINT shops_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: stocktakings stocktakings_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_pkey PRIMARY KEY (id);


--
-- Name: tax tax_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- Name: tax_zones tax_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.tax_zones
    ADD CONSTRAINT tax_zones_pkey PRIMARY KEY (id);


--
-- Name: taxkeys taxkeys_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxkeys
    ADD CONSTRAINT taxkeys_pkey PRIMARY KEY (id);


--
-- Name: taxzone_charts taxzone_charts_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts
    ADD CONSTRAINT taxzone_charts_pkey PRIMARY KEY (id);


--
-- Name: todo_user_config todo_user_config_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.todo_user_config
    ADD CONSTRAINT todo_user_config_pkey PRIMARY KEY (id);


--
-- Name: transfer_type transfer_type_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.transfer_type
    ADD CONSTRAINT transfer_type_pkey PRIMARY KEY (id);


--
-- Name: translation translation_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.translation
    ADD CONSTRAINT translation_pkey PRIMARY KEY (id);


--
-- Name: trigger_information trigger_information_key_value_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.trigger_information
    ADD CONSTRAINT trigger_information_key_value_key UNIQUE (key, value);


--
-- Name: trigger_information trigger_information_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.trigger_information
    ADD CONSTRAINT trigger_information_pkey PRIMARY KEY (id);


--
-- Name: units units_id_unique; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_id_unique UNIQUE (id);


--
-- Name: units_language units_language_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units_language
    ADD CONSTRAINT units_language_pkey PRIMARY KEY (id);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (name);


--
-- Name: user_preferences user_preferences_login_namespace_version_key_key; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_login_namespace_version_key_key UNIQUE (login, namespace, version, key);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: vendor vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (id);


--
-- Name: warehouse warehouse_pkey; Type: CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.warehouse
    ADD CONSTRAINT warehouse_pkey PRIMARY KEY (id);


--
-- Name: report_categories report_categorys_pkey; Type: CONSTRAINT; Schema: tax; Owner: kivitendo
--

ALTER TABLE ONLY tax.report_categories
    ADD CONSTRAINT report_categorys_pkey PRIMARY KEY (id);


--
-- Name: report_headings report_headings_pkey; Type: CONSTRAINT; Schema: tax; Owner: kivitendo
--

ALTER TABLE ONLY tax.report_headings
    ADD CONSTRAINT report_headings_pkey PRIMARY KEY (id);


--
-- Name: report_variables report_variables_pkey; Type: CONSTRAINT; Schema: tax; Owner: kivitendo
--

ALTER TABLE ONLY tax.report_variables
    ADD CONSTRAINT report_variables_pkey PRIMARY KEY (id);


--
-- Name: acc_trans_chart_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX acc_trans_chart_id_key ON public.acc_trans USING btree (chart_id);


--
-- Name: acc_trans_source_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX acc_trans_source_key ON public.acc_trans USING btree (lower(source));


--
-- Name: acc_trans_trans_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX acc_trans_trans_id_key ON public.acc_trans USING btree (trans_id);


--
-- Name: acc_trans_transdate_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX acc_trans_transdate_key ON public.acc_trans USING btree (transdate);


--
-- Name: ap_employee_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_employee_id_key ON public.ap USING btree (employee_id);


--
-- Name: ap_invnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_invnumber_gin_trgm_idx ON public.ap USING gin (invnumber public.gin_trgm_ops);


--
-- Name: ap_invnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_invnumber_key ON public.ap USING btree (lower(invnumber));


--
-- Name: ap_ordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_ordnumber_gin_trgm_idx ON public.ap USING gin (ordnumber public.gin_trgm_ops);


--
-- Name: ap_ordnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_ordnumber_key ON public.ap USING btree (lower(ordnumber));


--
-- Name: ap_quonumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_quonumber_gin_trgm_idx ON public.ap USING gin (quonumber public.gin_trgm_ops);


--
-- Name: ap_quonumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_quonumber_key ON public.ap USING btree (lower(quonumber));


--
-- Name: ap_transaction_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_transaction_description_gin_trgm_idx ON public.ap USING gin (transaction_description public.gin_trgm_ops);


--
-- Name: ap_transdate_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_transdate_key ON public.ap USING btree (transdate);


--
-- Name: ap_vendor_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ap_vendor_id_key ON public.ap USING btree (vendor_id);


--
-- Name: ar_cusordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_cusordnumber_gin_trgm_idx ON public.ar USING gin (cusordnumber public.gin_trgm_ops);


--
-- Name: ar_customer_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_customer_id_key ON public.ar USING btree (customer_id);


--
-- Name: ar_employee_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_employee_id_key ON public.ar USING btree (employee_id);


--
-- Name: ar_invnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_invnumber_gin_trgm_idx ON public.ar USING gin (invnumber public.gin_trgm_ops);


--
-- Name: ar_invnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_invnumber_key ON public.ar USING btree (lower(invnumber));


--
-- Name: ar_ordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_ordnumber_gin_trgm_idx ON public.ar USING gin (ordnumber public.gin_trgm_ops);


--
-- Name: ar_ordnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_ordnumber_key ON public.ar USING btree (lower(ordnumber));


--
-- Name: ar_quonumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_quonumber_gin_trgm_idx ON public.ar USING gin (quonumber public.gin_trgm_ops);


--
-- Name: ar_quonumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_quonumber_key ON public.ar USING btree (lower(quonumber));


--
-- Name: ar_transaction_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_transaction_description_gin_trgm_idx ON public.ar USING gin (transaction_description public.gin_trgm_ops);


--
-- Name: ar_transdate_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX ar_transdate_key ON public.ar USING btree (transdate);


--
-- Name: assembly_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX assembly_id_key ON public.assembly USING btree (id);


--
-- Name: chart_accno_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE UNIQUE INDEX chart_accno_key ON public.chart USING btree (accno);


--
-- Name: chart_category_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX chart_category_key ON public.chart USING btree (category);


--
-- Name: chart_link_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX chart_link_key ON public.chart USING btree (link);


--
-- Name: csv_import_report_rows_index_row; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX csv_import_report_rows_index_row ON public.csv_import_report_rows USING btree ("row");


--
-- Name: custom_variables_config_id_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX custom_variables_config_id_idx ON public.custom_variables USING btree (config_id);


--
-- Name: custom_variables_sub_module_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX custom_variables_sub_module_idx ON public.custom_variables USING btree (sub_module);


--
-- Name: custom_variables_trans_config_module_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX custom_variables_trans_config_module_idx ON public.custom_variables USING btree (config_id, trans_id, sub_module);


--
-- Name: customer_contact_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_contact_key ON public.customer USING btree (contact);


--
-- Name: customer_customernumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_customernumber_gin_trgm_idx ON public.customer USING gin (customernumber public.gin_trgm_ops);


--
-- Name: customer_customernumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_customernumber_key ON public.customer USING btree (customernumber);


--
-- Name: customer_name_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_name_gin_trgm_idx ON public.customer USING gin (name public.gin_trgm_ops);


--
-- Name: customer_name_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_name_key ON public.customer USING btree (name);


--
-- Name: customer_street_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX customer_street_gin_trgm_idx ON public.customer USING gin (street public.gin_trgm_ops);


--
-- Name: do_cusordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX do_cusordnumber_gin_trgm_idx ON public.delivery_orders USING gin (cusordnumber public.gin_trgm_ops);


--
-- Name: do_donumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX do_donumber_gin_trgm_idx ON public.delivery_orders USING gin (donumber public.gin_trgm_ops);


--
-- Name: do_ordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX do_ordnumber_gin_trgm_idx ON public.delivery_orders USING gin (ordnumber public.gin_trgm_ops);


--
-- Name: do_transaction_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX do_transaction_description_gin_trgm_idx ON public.delivery_orders USING gin (transaction_description public.gin_trgm_ops);


--
-- Name: doi_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX doi_description_gin_trgm_idx ON public.delivery_order_items USING gin (description public.gin_trgm_ops);


--
-- Name: employee_login_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE UNIQUE INDEX employee_login_key ON public.employee USING btree (login);


--
-- Name: employee_name_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX employee_name_key ON public.employee USING btree (name);


--
-- Name: generic_translations_type_id_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX generic_translations_type_id_idx ON public.generic_translations USING btree (language_id, translation_type, translation_id);


--
-- Name: gl_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_description_gin_trgm_idx ON public.gl USING gin (description public.gin_trgm_ops);


--
-- Name: gl_description_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_description_key ON public.gl USING btree (lower(description));


--
-- Name: gl_employee_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_employee_id_key ON public.gl USING btree (employee_id);


--
-- Name: gl_reference_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_reference_gin_trgm_idx ON public.gl USING gin (reference public.gin_trgm_ops);


--
-- Name: gl_reference_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_reference_key ON public.gl USING btree (lower(reference));


--
-- Name: gl_transdate_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX gl_transdate_key ON public.gl USING btree (transdate);


--
-- Name: idx_custom_variables_validity_config_id_trans_id; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_custom_variables_validity_config_id_trans_id ON public.custom_variables_validity USING btree (config_id, trans_id);


--
-- Name: idx_custom_variables_validity_trans_id; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_custom_variables_validity_trans_id ON public.custom_variables_validity USING btree (trans_id);


--
-- Name: idx_record_links_from_id; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_record_links_from_id ON public.record_links USING btree (from_id);


--
-- Name: idx_record_links_from_table; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_record_links_from_table ON public.record_links USING btree (from_table);


--
-- Name: idx_record_links_to_id; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_record_links_to_id ON public.record_links USING btree (to_id);


--
-- Name: idx_record_links_to_table; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX idx_record_links_to_table ON public.record_links USING btree (to_table);


--
-- Name: invoice_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX invoice_description_gin_trgm_idx ON public.invoice USING gin (description public.gin_trgm_ops);


--
-- Name: invoice_trans_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX invoice_trans_id_key ON public.invoice USING btree (trans_id);


--
-- Name: makemodel_model_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX makemodel_model_key ON public.makemodel USING btree (lower(model));


--
-- Name: makemodel_parts_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX makemodel_parts_id_key ON public.makemodel USING btree (parts_id);


--
-- Name: oe_cusordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_cusordnumber_gin_trgm_idx ON public.oe USING gin (cusordnumber public.gin_trgm_ops);


--
-- Name: oe_employee_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_employee_id_key ON public.oe USING btree (employee_id);


--
-- Name: oe_ordnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_ordnumber_gin_trgm_idx ON public.oe USING gin (ordnumber public.gin_trgm_ops);


--
-- Name: oe_ordnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_ordnumber_key ON public.oe USING btree (lower(ordnumber));


--
-- Name: oe_quonumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_quonumber_gin_trgm_idx ON public.oe USING gin (quonumber public.gin_trgm_ops);


--
-- Name: oe_transaction_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_transaction_description_gin_trgm_idx ON public.oe USING gin (transaction_description public.gin_trgm_ops);


--
-- Name: oe_transdate_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX oe_transdate_key ON public.oe USING btree (transdate);


--
-- Name: orderitems_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX orderitems_description_gin_trgm_idx ON public.orderitems USING gin (description public.gin_trgm_ops);


--
-- Name: orderitems_trans_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX orderitems_trans_id_key ON public.orderitems USING btree (trans_id);


--
-- Name: part_customer_prices_customer_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX part_customer_prices_customer_id_key ON public.part_customer_prices USING btree (customer_id);


--
-- Name: part_customer_prices_parts_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX part_customer_prices_parts_id_key ON public.part_customer_prices USING btree (parts_id);


--
-- Name: parts_description_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX parts_description_gin_trgm_idx ON public.parts USING gin (description public.gin_trgm_ops);


--
-- Name: parts_description_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX parts_description_key ON public.parts USING btree (lower(description));


--
-- Name: parts_partnumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX parts_partnumber_gin_trgm_idx ON public.parts USING gin (partnumber public.gin_trgm_ops);


--
-- Name: parts_partnumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX parts_partnumber_key ON public.parts USING btree (lower(partnumber));


--
-- Name: requirement_spec_items_item_type_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX requirement_spec_items_item_type_key ON public.requirement_spec_items USING btree (item_type);


--
-- Name: shipto_trans_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX shipto_trans_id_key ON public.shipto USING btree (trans_id);


--
-- Name: status_trans_id_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX status_trans_id_key ON public.status USING btree (trans_id);


--
-- Name: taxkeys_chartid_startdate; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE UNIQUE INDEX taxkeys_chartid_startdate ON public.taxkeys USING btree (chart_id, startdate);


--
-- Name: units_language_unit_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX units_language_unit_idx ON public.units_language USING btree (unit);


--
-- Name: vendor_contact_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX vendor_contact_key ON public.vendor USING btree (contact);


--
-- Name: vendor_name_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX vendor_name_gin_trgm_idx ON public.vendor USING gin (name public.gin_trgm_ops);


--
-- Name: vendor_name_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX vendor_name_key ON public.vendor USING btree (name);


--
-- Name: vendor_vendornumber_gin_trgm_idx; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX vendor_vendornumber_gin_trgm_idx ON public.vendor USING gin (vendornumber public.gin_trgm_ops);


--
-- Name: vendor_vendornumber_key; Type: INDEX; Schema: public; Owner: kivitendo
--

CREATE INDEX vendor_vendornumber_key ON public.vendor USING btree (vendornumber);


--
-- Name: parts add_parts_price_history_entry_after_changes_on_parts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER add_parts_price_history_entry_after_changes_on_parts AFTER INSERT OR UPDATE ON public.parts FOR EACH ROW EXECUTE PROCEDURE public.add_parts_price_history_entry();


--
-- Name: ap after_delete_ap_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_ap_trigger AFTER DELETE ON public.ap FOR EACH ROW EXECUTE PROCEDURE public.clean_up_acc_trans_after_ar_ap_gl_delete();


--
-- Name: ar after_delete_ar_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_ar_trigger AFTER DELETE ON public.ar FOR EACH ROW EXECUTE PROCEDURE public.clean_up_acc_trans_after_ar_ap_gl_delete();


--
-- Name: customer after_delete_customer_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_customer_trigger AFTER DELETE ON public.customer FOR EACH ROW EXECUTE PROCEDURE public.clean_up_after_customer_vendor_delete();


--
-- Name: delivery_terms after_delete_delivery_term_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_delivery_term_trigger AFTER DELETE ON public.delivery_terms FOR EACH ROW EXECUTE PROCEDURE public.generic_translations_delete_on_delivery_terms_delete_trigger();


--
-- Name: gl after_delete_gl_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_gl_trigger AFTER DELETE ON public.gl FOR EACH ROW EXECUTE PROCEDURE public.clean_up_acc_trans_after_ar_ap_gl_delete();


--
-- Name: payment_terms after_delete_payment_term_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_payment_term_trigger AFTER DELETE ON public.payment_terms FOR EACH ROW EXECUTE PROCEDURE public.generic_translations_delete_on_payment_terms_delete_trigger();


--
-- Name: requirement_specs after_delete_requirement_spec_dependencies; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_requirement_spec_dependencies AFTER DELETE ON public.requirement_specs FOR EACH ROW EXECUTE PROCEDURE public.requirement_spec_delete_trigger();


--
-- Name: tax after_delete_tax_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_tax_trigger AFTER DELETE ON public.tax FOR EACH ROW EXECUTE PROCEDURE public.generic_translations_delete_on_tax_delete_trigger();


--
-- Name: vendor after_delete_vendor_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER after_delete_vendor_trigger AFTER DELETE ON public.vendor FOR EACH ROW EXECUTE PROCEDURE public.clean_up_after_customer_vendor_delete();


--
-- Name: ap before_delete_ap_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_ap_trigger BEFORE DELETE ON public.ap FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_ap_delete();


--
-- Name: ar before_delete_ar_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_ar_trigger BEFORE DELETE ON public.ar FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_ar_delete();


--
-- Name: delivery_order_items before_delete_delivery_order_items_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_delivery_order_items_trigger BEFORE DELETE ON public.delivery_order_items FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_delivery_order_items_delete();


--
-- Name: delivery_orders before_delete_delivery_orders_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_delivery_orders_trigger BEFORE DELETE ON public.delivery_orders FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_delivery_orders_delete();


--
-- Name: gl before_delete_gl_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_gl_trigger BEFORE DELETE ON public.gl FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_gl_delete();


--
-- Name: invoice before_delete_invoice_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_invoice_trigger BEFORE DELETE ON public.invoice FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_invoice_delete();


--
-- Name: letter before_delete_letter_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_letter_trigger BEFORE DELETE ON public.letter FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_letter_delete();


--
-- Name: oe before_delete_oe_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_oe_trigger BEFORE DELETE ON public.oe FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_oe_delete();


--
-- Name: orderitems before_delete_orderitems_trigger; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER before_delete_orderitems_trigger BEFORE DELETE ON public.orderitems FOR EACH ROW EXECUTE PROCEDURE public.clean_up_record_links_before_orderitems_delete();


--
-- Name: delivery_order_items_stock check_bin_wh_delivery_order_items_stock; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER check_bin_wh_delivery_order_items_stock BEFORE INSERT OR UPDATE ON public.delivery_order_items_stock FOR EACH ROW EXECUTE PROCEDURE public.check_bin_belongs_to_wh();


--
-- Name: inventory check_bin_wh_inventory; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER check_bin_wh_inventory BEFORE INSERT OR UPDATE ON public.inventory FOR EACH ROW EXECUTE PROCEDURE public.check_bin_belongs_to_wh();


--
-- Name: parts check_bin_wh_parts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER check_bin_wh_parts BEFORE INSERT OR UPDATE ON public.parts FOR EACH ROW EXECUTE PROCEDURE public.check_bin_belongs_to_wh();


--
-- Name: contacts contacts_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER contacts_delete_custom_variables_after_deletion AFTER DELETE ON public.contacts FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: customer customer_before_delete_clear_follow_ups; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER customer_before_delete_clear_follow_ups AFTER DELETE ON public.customer FOR EACH ROW EXECUTE PROCEDURE public.follow_up_delete_when_customer_vendor_is_deleted_trigger();


--
-- Name: customer customer_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER customer_delete_custom_variables_after_deletion AFTER DELETE ON public.customer FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: delivery_orders delete_delivery_orders_dependencies; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delete_delivery_orders_dependencies BEFORE DELETE ON public.delivery_orders FOR EACH ROW EXECUTE PROCEDURE public.delivery_orders_before_delete_trigger();


--
-- Name: oe delete_oe_dependencies; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delete_oe_dependencies BEFORE DELETE ON public.oe FOR EACH ROW EXECUTE PROCEDURE public.oe_before_delete_trigger();


--
-- Name: requirement_specs delete_requirement_spec_custom_variables; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delete_requirement_spec_custom_variables BEFORE DELETE ON public.requirement_specs FOR EACH ROW EXECUTE PROCEDURE public.delete_requirement_spec_custom_variables_trigger();


--
-- Name: requirement_specs delete_requirement_spec_dependencies; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delete_requirement_spec_dependencies BEFORE DELETE ON public.requirement_specs FOR EACH ROW EXECUTE PROCEDURE public.requirement_spec_delete_trigger();


--
-- Name: requirement_spec_items delete_requirement_spec_item_dependencies; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delete_requirement_spec_item_dependencies BEFORE DELETE ON public.requirement_spec_items FOR EACH ROW EXECUTE PROCEDURE public.requirement_spec_item_before_delete_trigger();


--
-- Name: delivery_order_items delivery_order_items_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delivery_order_items_delete_custom_variables_after_deletion AFTER DELETE ON public.delivery_order_items FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: delivery_orders delivery_orders_on_update_close_follow_up; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER delivery_orders_on_update_close_follow_up AFTER UPDATE ON public.delivery_orders FOR EACH ROW EXECUTE PROCEDURE public.follow_up_close_when_oe_closed_trigger();


--
-- Name: follow_ups follow_up_delete_notes; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER follow_up_delete_notes AFTER DELETE ON public.follow_ups FOR EACH ROW EXECUTE PROCEDURE public.follow_up_delete_notes_trigger();


--
-- Name: invoice invoice_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER invoice_delete_custom_variables_after_deletion AFTER DELETE ON public.invoice FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: acc_trans mtime_acc_trans; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_acc_trans BEFORE UPDATE ON public.acc_trans FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: ap mtime_ap; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_ap BEFORE UPDATE ON public.ap FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: ar mtime_ar; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_ar BEFORE UPDATE ON public.ar FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: bin mtime_bin; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_bin BEFORE UPDATE ON public.bin FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: chart mtime_chart; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_chart BEFORE UPDATE ON public.chart FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: contacts mtime_contacts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_contacts BEFORE UPDATE ON public.contacts FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: custom_data_export_queries mtime_custom_data_export_queries; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_custom_data_export_queries BEFORE UPDATE ON public.custom_data_export_queries FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: custom_data_export_query_parameters mtime_custom_data_export_query_parameters; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_custom_data_export_query_parameters BEFORE UPDATE ON public.custom_data_export_query_parameters FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: custom_variable_config_partsgroups mtime_custom_variable_config_partsgroups; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_custom_variable_config_partsgroups BEFORE UPDATE ON public.custom_variable_config_partsgroups FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: custom_variable_configs mtime_custom_variable_configs; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_custom_variable_configs BEFORE UPDATE ON public.custom_variable_configs FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: custom_variables mtime_custom_variables; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_custom_variables BEFORE UPDATE ON public.custom_variables FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: customer mtime_customer; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_customer BEFORE UPDATE ON public.customer FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: delivery_order_items mtime_delivery_order_items_id; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_delivery_order_items_id BEFORE UPDATE ON public.delivery_order_items FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: delivery_order_items_stock mtime_delivery_order_items_stock; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_delivery_order_items_stock BEFORE UPDATE ON public.delivery_order_items_stock FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: delivery_orders mtime_delivery_orders; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_delivery_orders BEFORE UPDATE ON public.delivery_orders FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: delivery_terms mtime_delivery_terms; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_delivery_terms BEFORE UPDATE ON public.delivery_terms FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: department mtime_department; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_department BEFORE UPDATE ON public.department FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: dunning mtime_dunning; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_dunning BEFORE UPDATE ON public.dunning FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: email_journal mtime_email_journal; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_email_journal BEFORE UPDATE ON public.email_journal FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: email_journal_attachments mtime_email_journal_attachments; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_email_journal_attachments BEFORE UPDATE ON public.email_journal_attachments FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: follow_up_links mtime_follow_up_links; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_follow_up_links BEFORE UPDATE ON public.follow_up_links FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: follow_ups mtime_follow_ups; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_follow_ups BEFORE UPDATE ON public.follow_ups FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: gl mtime_gl; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_gl BEFORE UPDATE ON public.gl FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: inventory mtime_inventory; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_inventory BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: invoice mtime_invoice; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_invoice BEFORE UPDATE ON public.invoice FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: notes mtime_notes; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_notes BEFORE UPDATE ON public.notes FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: oe mtime_oe; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_oe BEFORE UPDATE ON public.oe FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: orderitems mtime_orderitems; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_orderitems BEFORE UPDATE ON public.orderitems FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: parts mtime_parts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_parts BEFORE UPDATE ON public.parts FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: partsgroup mtime_partsgroup; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_partsgroup BEFORE UPDATE ON public.partsgroup FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: price_rule_items mtime_price_rule_items; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_price_rule_items BEFORE UPDATE ON public.price_rule_items FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: price_rules mtime_price_rules; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_price_rules BEFORE UPDATE ON public.price_rules FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project mtime_project; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project BEFORE UPDATE ON public.project FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project_participants mtime_project_participants; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project_participants BEFORE UPDATE ON public.project_participants FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project_phase_participants mtime_project_phase_paticipants; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project_phase_paticipants BEFORE UPDATE ON public.project_phase_participants FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project_phases mtime_project_phases; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project_phases BEFORE UPDATE ON public.project_phases FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project_roles mtime_project_roles; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project_roles BEFORE UPDATE ON public.project_roles FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: project_statuses mtime_project_status; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_project_status BEFORE UPDATE ON public.project_statuses FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: record_templates mtime_record_templates; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_record_templates BEFORE UPDATE ON public.record_templates FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_acceptance_statuses mtime_requirement_spec_acceptance_statuses; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_acceptance_statuses BEFORE UPDATE ON public.requirement_spec_acceptance_statuses FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_complexities mtime_requirement_spec_complexities; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_complexities BEFORE UPDATE ON public.requirement_spec_complexities FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_items mtime_requirement_spec_items; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_items BEFORE UPDATE ON public.requirement_spec_items FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_orders mtime_requirement_spec_orders; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_orders BEFORE UPDATE ON public.requirement_spec_orders FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_pictures mtime_requirement_spec_pictures; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_pictures BEFORE UPDATE ON public.requirement_spec_pictures FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_predefined_texts mtime_requirement_spec_predefined_texts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_predefined_texts BEFORE UPDATE ON public.requirement_spec_predefined_texts FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_risks mtime_requirement_spec_risks; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_risks BEFORE UPDATE ON public.requirement_spec_risks FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_statuses mtime_requirement_spec_statuses; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_statuses BEFORE UPDATE ON public.requirement_spec_statuses FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_text_blocks mtime_requirement_spec_text_blocks; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_text_blocks BEFORE UPDATE ON public.requirement_spec_text_blocks FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_types mtime_requirement_spec_types; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_types BEFORE UPDATE ON public.requirement_spec_types FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_spec_versions mtime_requirement_spec_versions; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_spec_versions BEFORE UPDATE ON public.requirement_spec_versions FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: requirement_specs mtime_requirement_specs; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_requirement_specs BEFORE UPDATE ON public.requirement_specs FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: shop_images mtime_shop_images; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_shop_images BEFORE UPDATE ON public.shop_images FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: shop_parts mtime_shop_parts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_shop_parts BEFORE UPDATE ON public.shop_parts FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: shops mtime_shops; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_shops BEFORE UPDATE ON public.shops FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: status mtime_status; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_status BEFORE UPDATE ON public.status FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: stocktakings mtime_stocktakings; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_stocktakings BEFORE UPDATE ON public.stocktakings FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: tax mtime_tax; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_tax BEFORE UPDATE ON public.tax FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: transfer_type mtime_transfer_type; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_transfer_type BEFORE UPDATE ON public.transfer_type FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: vendor mtime_vendor; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_vendor BEFORE UPDATE ON public.vendor FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: warehouse mtime_warehouse; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER mtime_warehouse BEFORE UPDATE ON public.warehouse FOR EACH ROW EXECUTE PROCEDURE public.set_mtime();


--
-- Name: oe oe_before_delete_clear_follow_ups; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER oe_before_delete_clear_follow_ups BEFORE DELETE ON public.oe FOR EACH ROW EXECUTE PROCEDURE public.follow_up_delete_when_oe_is_deleted_trigger();


--
-- Name: oe oe_on_update_close_follow_up; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER oe_on_update_close_follow_up AFTER UPDATE ON public.oe FOR EACH ROW EXECUTE PROCEDURE public.follow_up_close_when_oe_closed_trigger();


--
-- Name: orderitems orderitems_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER orderitems_delete_custom_variables_after_deletion AFTER DELETE ON public.orderitems FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: parts parts_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER parts_delete_custom_variables_after_deletion AFTER DELETE ON public.parts FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: parts priceupdate_parts; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER priceupdate_parts AFTER UPDATE ON public.parts FOR EACH ROW EXECUTE PROCEDURE public.set_priceupdate_parts();


--
-- Name: project project_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER project_delete_custom_variables_after_deletion AFTER DELETE ON public.project FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: assembly trig_assembly_purchase_price; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER trig_assembly_purchase_price AFTER INSERT OR DELETE OR UPDATE ON public.assembly FOR EACH ROW EXECUTE PROCEDURE public.update_purchase_price();


--
-- Name: inventory trig_update_onhand; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER trig_update_onhand AFTER INSERT OR DELETE OR UPDATE ON public.inventory FOR EACH ROW EXECUTE PROCEDURE public.update_onhand();


--
-- Name: requirement_spec_items update_requirement_spec_item_time_estimation; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER update_requirement_spec_item_time_estimation AFTER INSERT OR DELETE OR UPDATE ON public.requirement_spec_items FOR EACH ROW EXECUTE PROCEDURE public.requirement_spec_item_time_estimation_updater_trigger();


--
-- Name: vendor vendor_before_delete_clear_follow_ups; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER vendor_before_delete_clear_follow_ups AFTER DELETE ON public.vendor FOR EACH ROW EXECUTE PROCEDURE public.follow_up_delete_when_customer_vendor_is_deleted_trigger();


--
-- Name: vendor vendor_delete_custom_variables_after_deletion; Type: TRIGGER; Schema: public; Owner: kivitendo
--

CREATE TRIGGER vendor_delete_custom_variables_after_deletion AFTER DELETE ON public.vendor FOR EACH ROW EXECUTE PROCEDURE public.delete_custom_variables_trigger();


--
-- Name: invoice $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT "$1" FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: ar $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT "$1" FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: ap $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT "$1" FOREIGN KEY (vendor_id) REFERENCES public.vendor(id);


--
-- Name: units $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT "$1" FOREIGN KEY (base_unit) REFERENCES public.units(name);


--
-- Name: parts $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT "$1" FOREIGN KEY (buchungsgruppen_id) REFERENCES public.buchungsgruppen(id);


--
-- Name: acc_trans $1; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.acc_trans
    ADD CONSTRAINT "$1" FOREIGN KEY (chart_id) REFERENCES public.chart(id);


--
-- Name: acc_trans acc_trans_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.acc_trans
    ADD CONSTRAINT acc_trans_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: acc_trans acc_trans_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.acc_trans
    ADD CONSTRAINT acc_trans_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.tax(id);


--
-- Name: ap ap_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: ap ap_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: ap ap_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: ap ap_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id);


--
-- Name: ap ap_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: ap ap_globalproject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_globalproject_id_fkey FOREIGN KEY (globalproject_id) REFERENCES public.project(id);


--
-- Name: ap ap_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: ap ap_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: ap ap_storno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_storno_id_fkey FOREIGN KEY (storno_id) REFERENCES public.ap(id);


--
-- Name: ap ap_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ap
    ADD CONSTRAINT ap_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: ar ar_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: ar ar_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: ar ar_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: ar ar_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id);


--
-- Name: ar ar_dunning_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_dunning_config_id_fkey FOREIGN KEY (dunning_config_id) REFERENCES public.dunning_config(id);


--
-- Name: ar ar_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: ar ar_globalproject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_globalproject_id_fkey FOREIGN KEY (globalproject_id) REFERENCES public.project(id);


--
-- Name: ar ar_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: ar ar_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: ar ar_salesman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_salesman_id_fkey FOREIGN KEY (salesman_id) REFERENCES public.employee(id);


--
-- Name: ar ar_shipto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_shipto_id_fkey FOREIGN KEY (shipto_id) REFERENCES public.shipto(shipto_id);


--
-- Name: ar ar_storno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_storno_id_fkey FOREIGN KEY (storno_id) REFERENCES public.ar(id);


--
-- Name: ar ar_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.ar
    ADD CONSTRAINT ar_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: assembly assembly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assembly
    ADD CONSTRAINT assembly_id_fkey FOREIGN KEY (id) REFERENCES public.parts(id);


--
-- Name: assembly assembly_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assembly
    ADD CONSTRAINT assembly_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: assortment_items assortment_items_assortment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assortment_items
    ADD CONSTRAINT assortment_items_assortment_id_fkey FOREIGN KEY (assortment_id) REFERENCES public.parts(id) ON DELETE CASCADE;


--
-- Name: assortment_items assortment_items_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assortment_items
    ADD CONSTRAINT assortment_items_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: assortment_items assortment_items_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.assortment_items
    ADD CONSTRAINT assortment_items_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: bank_accounts bank_accounts_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_accounts
    ADD CONSTRAINT bank_accounts_chart_id_fkey FOREIGN KEY (chart_id) REFERENCES public.chart(id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_acc_trans_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_acc_trans_id_fkey FOREIGN KEY (acc_trans_id) REFERENCES public.acc_trans(acc_trans_id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_ap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_ap_id_fkey FOREIGN KEY (ap_id) REFERENCES public.ap(id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_ar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_ar_id_fkey FOREIGN KEY (ar_id) REFERENCES public.ar(id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_bank_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_bank_transaction_id_fkey FOREIGN KEY (bank_transaction_id) REFERENCES public.bank_transactions(id);


--
-- Name: bank_transaction_acc_trans bank_transaction_acc_trans_gl_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transaction_acc_trans
    ADD CONSTRAINT bank_transaction_acc_trans_gl_id_fkey FOREIGN KEY (gl_id) REFERENCES public.gl(id);


--
-- Name: bank_transactions bank_transactions_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transactions
    ADD CONSTRAINT bank_transactions_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: bank_transactions bank_transactions_local_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bank_transactions
    ADD CONSTRAINT bank_transactions_local_bank_account_id_fkey FOREIGN KEY (local_bank_account_id) REFERENCES public.bank_accounts(id);


--
-- Name: bin bin_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.bin
    ADD CONSTRAINT bin_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: buchungsgruppen buchungsgruppen_inventory_accno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.buchungsgruppen
    ADD CONSTRAINT buchungsgruppen_inventory_accno_id_fkey FOREIGN KEY (inventory_accno_id) REFERENCES public.chart(id);


--
-- Name: csv_import_profile_settings csv_import_profile_settings_csv_import_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_profile_settings
    ADD CONSTRAINT csv_import_profile_settings_csv_import_profile_id_fkey FOREIGN KEY (csv_import_profile_id) REFERENCES public.csv_import_profiles(id);


--
-- Name: csv_import_report_rows csv_import_report_rows_csv_import_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_rows
    ADD CONSTRAINT csv_import_report_rows_csv_import_report_id_fkey FOREIGN KEY (csv_import_report_id) REFERENCES public.csv_import_reports(id);


--
-- Name: csv_import_report_status csv_import_report_status_csv_import_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_report_status
    ADD CONSTRAINT csv_import_report_status_csv_import_report_id_fkey FOREIGN KEY (csv_import_report_id) REFERENCES public.csv_import_reports(id);


--
-- Name: csv_import_reports csv_import_reports_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.csv_import_reports
    ADD CONSTRAINT csv_import_reports_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.csv_import_profiles(id);


--
-- Name: custom_data_export_query_parameters custom_data_export_query_parameters_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_data_export_query_parameters
    ADD CONSTRAINT custom_data_export_query_parameters_query_id_fkey FOREIGN KEY (query_id) REFERENCES public.custom_data_export_queries(id) ON DELETE CASCADE;


--
-- Name: custom_variable_config_partsgroups custom_variable_config_partsgrou_custom_variable_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variable_config_partsgroups
    ADD CONSTRAINT custom_variable_config_partsgrou_custom_variable_config_id_fkey FOREIGN KEY (custom_variable_config_id) REFERENCES public.custom_variable_configs(id);


--
-- Name: custom_variable_config_partsgroups custom_variable_config_partsgroups_partsgroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variable_config_partsgroups
    ADD CONSTRAINT custom_variable_config_partsgroups_partsgroup_id_fkey FOREIGN KEY (partsgroup_id) REFERENCES public.partsgroup(id);


--
-- Name: custom_variables custom_variables_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variables
    ADD CONSTRAINT custom_variables_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.custom_variable_configs(id);


--
-- Name: custom_variables_validity custom_variables_validity_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.custom_variables_validity
    ADD CONSTRAINT custom_variables_validity_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.custom_variable_configs(id);


--
-- Name: customer customer_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- Name: customer customer_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: customer customer_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: customer customer_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: customer customer_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: customer customer_pricegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pricegroup_id_fkey FOREIGN KEY (pricegroup_id) REFERENCES public.pricegroup(id);


--
-- Name: customer customer_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: defaults defaults_ap_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_ap_chart_id_fkey FOREIGN KEY (ap_chart_id) REFERENCES public.chart(id);


--
-- Name: defaults defaults_ar_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_ar_chart_id_fkey FOREIGN KEY (ar_chart_id) REFERENCES public.chart(id);


--
-- Name: defaults defaults_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin(id);


--
-- Name: defaults defaults_bin_id_ignore_onhand_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_bin_id_ignore_onhand_fkey FOREIGN KEY (bin_id_ignore_onhand) REFERENCES public.bin(id);


--
-- Name: defaults defaults_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: defaults defaults_project_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_project_status_id_fkey FOREIGN KEY (project_status_id) REFERENCES public.project_statuses(id);


--
-- Name: defaults defaults_project_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_project_type_id_fkey FOREIGN KEY (project_type_id) REFERENCES public.project_types(id);


--
-- Name: defaults defaults_requirement_spec_section_order_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_requirement_spec_section_order_part_id_fkey FOREIGN KEY (requirement_spec_section_order_part_id) REFERENCES public.parts(id) ON DELETE SET NULL;


--
-- Name: defaults defaults_stocktaking_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_stocktaking_bin_id_fkey FOREIGN KEY (stocktaking_bin_id) REFERENCES public.bin(id);


--
-- Name: defaults defaults_stocktaking_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_stocktaking_warehouse_id_fkey FOREIGN KEY (stocktaking_warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: defaults defaults_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: defaults defaults_warehouse_id_ignore_onhand_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.defaults
    ADD CONSTRAINT defaults_warehouse_id_ignore_onhand_fkey FOREIGN KEY (warehouse_id_ignore_onhand) REFERENCES public.warehouse(id);


--
-- Name: delivery_order_items delivery_order_items_delivery_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_delivery_order_id_fkey FOREIGN KEY (delivery_order_id) REFERENCES public.delivery_orders(id) ON DELETE CASCADE;


--
-- Name: delivery_order_items delivery_order_items_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id) ON DELETE RESTRICT;


--
-- Name: delivery_order_items delivery_order_items_price_factor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_price_factor_id_fkey FOREIGN KEY (price_factor_id) REFERENCES public.price_factors(id) ON DELETE RESTRICT;


--
-- Name: delivery_order_items delivery_order_items_pricegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_pricegroup_id_fkey FOREIGN KEY (pricegroup_id) REFERENCES public.pricegroup(id) ON DELETE RESTRICT;


--
-- Name: delivery_order_items delivery_order_items_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: delivery_order_items_stock delivery_order_items_stock_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items_stock
    ADD CONSTRAINT delivery_order_items_stock_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin(id) ON DELETE RESTRICT;


--
-- Name: delivery_order_items_stock delivery_order_items_stock_delivery_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items_stock
    ADD CONSTRAINT delivery_order_items_stock_delivery_order_item_id_fkey FOREIGN KEY (delivery_order_item_id) REFERENCES public.delivery_order_items(id) ON DELETE CASCADE;


--
-- Name: inventory delivery_order_items_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT delivery_order_items_stock_id_fkey FOREIGN KEY (delivery_order_items_stock_id) REFERENCES public.delivery_order_items_stock(id);


--
-- Name: delivery_order_items_stock delivery_order_items_stock_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items_stock
    ADD CONSTRAINT delivery_order_items_stock_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id) ON DELETE RESTRICT;


--
-- Name: delivery_order_items delivery_order_items_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_order_items
    ADD CONSTRAINT delivery_order_items_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: delivery_orders delivery_orders_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: delivery_orders delivery_orders_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: delivery_orders delivery_orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: delivery_orders delivery_orders_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: delivery_orders delivery_orders_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id);


--
-- Name: delivery_orders delivery_orders_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: delivery_orders delivery_orders_globalproject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_globalproject_id_fkey FOREIGN KEY (globalproject_id) REFERENCES public.project(id);


--
-- Name: delivery_orders delivery_orders_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: delivery_orders delivery_orders_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: delivery_orders delivery_orders_salesman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_salesman_id_fkey FOREIGN KEY (salesman_id) REFERENCES public.employee(id);


--
-- Name: delivery_orders delivery_orders_shipto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_shipto_id_fkey FOREIGN KEY (shipto_id) REFERENCES public.shipto(shipto_id);


--
-- Name: delivery_orders delivery_orders_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: delivery_orders delivery_orders_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.delivery_orders
    ADD CONSTRAINT delivery_orders_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor(id);


--
-- Name: drafts drafts_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: dunning dunning_dunning_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.dunning
    ADD CONSTRAINT dunning_dunning_config_id_fkey FOREIGN KEY (dunning_config_id) REFERENCES public.dunning_config(id);


--
-- Name: dunning dunning_fee_interest_ar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.dunning
    ADD CONSTRAINT dunning_fee_interest_ar_id_fkey FOREIGN KEY (fee_interest_ar_id) REFERENCES public.ar(id);


--
-- Name: dunning dunning_trans_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.dunning
    ADD CONSTRAINT dunning_trans_id_fkey FOREIGN KEY (trans_id) REFERENCES public.ar(id) ON DELETE CASCADE;


--
-- Name: email_journal_attachments email_journal_attachments_email_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal_attachments
    ADD CONSTRAINT email_journal_attachments_email_journal_id_fkey FOREIGN KEY (email_journal_id) REFERENCES public.email_journal(id) ON DELETE CASCADE;


--
-- Name: email_journal email_journal_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.email_journal
    ADD CONSTRAINT email_journal_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.employee(id);


--
-- Name: employee_project_invoices employee_project_invoices_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.employee_project_invoices
    ADD CONSTRAINT employee_project_invoices_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id) ON DELETE CASCADE;


--
-- Name: employee_project_invoices employee_project_invoices_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.employee_project_invoices
    ADD CONSTRAINT employee_project_invoices_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: exchangerate exchangerate_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.exchangerate
    ADD CONSTRAINT exchangerate_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: follow_up_access follow_up_access_what_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_access
    ADD CONSTRAINT follow_up_access_what_fkey FOREIGN KEY (what) REFERENCES public.employee(id);


--
-- Name: follow_up_access follow_up_access_who_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_access
    ADD CONSTRAINT follow_up_access_who_fkey FOREIGN KEY (who) REFERENCES public.employee(id);


--
-- Name: follow_up_links follow_up_links_follow_up_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_up_links
    ADD CONSTRAINT follow_up_links_follow_up_id_fkey FOREIGN KEY (follow_up_id) REFERENCES public.follow_ups(id) ON DELETE CASCADE;


--
-- Name: follow_ups follow_ups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.employee(id);


--
-- Name: follow_ups follow_ups_created_for_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_created_for_user_fkey FOREIGN KEY (created_for_user) REFERENCES public.employee(id);


--
-- Name: follow_ups follow_ups_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.notes(id);


--
-- Name: generic_translations generic_translations_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.generic_translations
    ADD CONSTRAINT generic_translations_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id) ON DELETE CASCADE;


--
-- Name: gl gl_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.gl
    ADD CONSTRAINT gl_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id);


--
-- Name: gl gl_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.gl
    ADD CONSTRAINT gl_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: gl gl_storno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.gl
    ADD CONSTRAINT gl_storno_id_fkey FOREIGN KEY (storno_id) REFERENCES public.gl(id);


--
-- Name: history_erp history_erp_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.history_erp
    ADD CONSTRAINT history_erp_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: inventory inventory_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin(id);


--
-- Name: inventory inventory_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: inventory inventory_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoice(id);


--
-- Name: inventory inventory_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: inventory inventory_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: inventory inventory_trans_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_trans_type_id_fkey FOREIGN KEY (trans_type_id) REFERENCES public.transfer_type(id);


--
-- Name: inventory inventory_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: invoice invoice_price_factor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_price_factor_id_fkey FOREIGN KEY (price_factor_id) REFERENCES public.price_factors(id);


--
-- Name: invoice invoice_pricegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pricegroup_id_fkey FOREIGN KEY (pricegroup_id) REFERENCES public.pricegroup(id);


--
-- Name: invoice invoice_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: invoice invoice_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: letter letter_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: letter letter_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: letter_draft letter_draft_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: letter_draft letter_draft_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: letter_draft letter_draft_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: letter_draft letter_draft_salesman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_salesman_id_fkey FOREIGN KEY (salesman_id) REFERENCES public.employee(id);


--
-- Name: letter_draft letter_draft_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter_draft
    ADD CONSTRAINT letter_draft_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor(id);


--
-- Name: letter letter_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: letter letter_salesman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_salesman_id_fkey FOREIGN KEY (salesman_id) REFERENCES public.employee(id);


--
-- Name: letter letter_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.letter
    ADD CONSTRAINT letter_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor(id);


--
-- Name: makemodel makemodel_make_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.makemodel
    ADD CONSTRAINT makemodel_make_fkey FOREIGN KEY (make) REFERENCES public.vendor(id);


--
-- Name: notes notes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.employee(id);


--
-- Name: oe oe_cp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_cp_id_fkey FOREIGN KEY (cp_id) REFERENCES public.contacts(cp_id);


--
-- Name: oe oe_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: oe oe_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: oe oe_delivery_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_delivery_customer_id_fkey FOREIGN KEY (delivery_customer_id) REFERENCES public.customer(id);


--
-- Name: oe oe_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: oe oe_delivery_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_delivery_vendor_id_fkey FOREIGN KEY (delivery_vendor_id) REFERENCES public.vendor(id);


--
-- Name: oe oe_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id);


--
-- Name: oe oe_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: oe oe_globalproject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_globalproject_id_fkey FOREIGN KEY (globalproject_id) REFERENCES public.project(id);


--
-- Name: inventory oe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT oe_id_fkey FOREIGN KEY (oe_id) REFERENCES public.delivery_orders(id);


--
-- Name: oe oe_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: oe oe_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: oe oe_salesman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_salesman_id_fkey FOREIGN KEY (salesman_id) REFERENCES public.employee(id);


--
-- Name: oe oe_shipto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_shipto_id_fkey FOREIGN KEY (shipto_id) REFERENCES public.shipto(shipto_id);


--
-- Name: oe oe_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: oe oe_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.oe
    ADD CONSTRAINT oe_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor(id);


--
-- Name: orderitems orderitems_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id) ON DELETE RESTRICT;


--
-- Name: orderitems orderitems_price_factor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_price_factor_id_fkey FOREIGN KEY (price_factor_id) REFERENCES public.price_factors(id) ON DELETE RESTRICT;


--
-- Name: orderitems orderitems_pricegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_pricegroup_id_fkey FOREIGN KEY (pricegroup_id) REFERENCES public.pricegroup(id) ON DELETE RESTRICT;


--
-- Name: orderitems orderitems_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: orderitems orderitems_trans_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_trans_id_fkey FOREIGN KEY (trans_id) REFERENCES public.oe(id) ON DELETE CASCADE;


--
-- Name: orderitems orderitems_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: parts part_classification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT part_classification_id_fkey FOREIGN KEY (classification_id) REFERENCES public.part_classifications(id);


--
-- Name: part_customer_prices part_customer_prices_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_customer_prices
    ADD CONSTRAINT part_customer_prices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: part_customer_prices part_customer_prices_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.part_customer_prices
    ADD CONSTRAINT part_customer_prices_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: parts parts_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin(id);


--
-- Name: parts parts_partsgroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_partsgroup_id_fkey FOREIGN KEY (partsgroup_id) REFERENCES public.partsgroup(id);


--
-- Name: parts parts_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: parts parts_price_factor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_price_factor_id_fkey FOREIGN KEY (price_factor_id) REFERENCES public.price_factors(id);


--
-- Name: parts_price_history parts_price_history_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts_price_history
    ADD CONSTRAINT parts_price_history_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.parts(id) ON DELETE CASCADE;


--
-- Name: parts parts_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: parts parts_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: periodic_invoices periodic_invoices_ar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices
    ADD CONSTRAINT periodic_invoices_ar_id_fkey FOREIGN KEY (ar_id) REFERENCES public.ar(id) ON DELETE CASCADE;


--
-- Name: periodic_invoices periodic_invoices_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices
    ADD CONSTRAINT periodic_invoices_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.periodic_invoices_configs(id) ON DELETE CASCADE;


--
-- Name: periodic_invoices_configs periodic_invoices_configs_ar_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices_configs
    ADD CONSTRAINT periodic_invoices_configs_ar_chart_id_fkey FOREIGN KEY (ar_chart_id) REFERENCES public.chart(id) ON DELETE RESTRICT;


--
-- Name: periodic_invoices_configs periodic_invoices_configs_email_recipient_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices_configs
    ADD CONSTRAINT periodic_invoices_configs_email_recipient_contact_id_fkey FOREIGN KEY (email_recipient_contact_id) REFERENCES public.contacts(cp_id) ON DELETE SET NULL;


--
-- Name: periodic_invoices_configs periodic_invoices_configs_oe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices_configs
    ADD CONSTRAINT periodic_invoices_configs_oe_id_fkey FOREIGN KEY (oe_id) REFERENCES public.oe(id) ON DELETE CASCADE;


--
-- Name: periodic_invoices_configs periodic_invoices_configs_printer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.periodic_invoices_configs
    ADD CONSTRAINT periodic_invoices_configs_printer_id_fkey FOREIGN KEY (printer_id) REFERENCES public.printers(id) ON DELETE SET NULL;


--
-- Name: price_rule_items price_rule_items_custom_variable_configs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rule_items
    ADD CONSTRAINT price_rule_items_custom_variable_configs_id_fkey FOREIGN KEY (custom_variable_configs_id) REFERENCES public.custom_variable_configs(id);


--
-- Name: price_rule_items price_rule_items_price_rules_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.price_rule_items
    ADD CONSTRAINT price_rule_items_price_rules_id_fkey FOREIGN KEY (price_rules_id) REFERENCES public.price_rules(id) ON DELETE CASCADE;


--
-- Name: prices prices_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id) ON DELETE CASCADE;


--
-- Name: prices prices_pricegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_pricegroup_id_fkey FOREIGN KEY (pricegroup_id) REFERENCES public.pricegroup(id) ON DELETE CASCADE;


--
-- Name: project project_billable_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_billable_customer_id_fkey FOREIGN KEY (billable_customer_id) REFERENCES public.customer(id);


--
-- Name: project project_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: project_participants project_participants_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_participants
    ADD CONSTRAINT project_participants_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: project_participants project_participants_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_participants
    ADD CONSTRAINT project_participants_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: project_participants project_participants_project_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_participants
    ADD CONSTRAINT project_participants_project_role_id_fkey FOREIGN KEY (project_role_id) REFERENCES public.project_roles(id);


--
-- Name: project_phase_participants project_phase_participants_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phase_participants
    ADD CONSTRAINT project_phase_participants_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: project_phase_participants project_phase_participants_project_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phase_participants
    ADD CONSTRAINT project_phase_participants_project_phase_id_fkey FOREIGN KEY (project_phase_id) REFERENCES public.project_phases(id);


--
-- Name: project_phase_participants project_phase_participants_project_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phase_participants
    ADD CONSTRAINT project_phase_participants_project_role_id_fkey FOREIGN KEY (project_role_id) REFERENCES public.project_roles(id);


--
-- Name: project_phases project_phases_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project_phases
    ADD CONSTRAINT project_phases_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: project project_project_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_project_status_id_fkey FOREIGN KEY (project_status_id) REFERENCES public.project_statuses(id);


--
-- Name: project project_project_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_project_type_id_fkey FOREIGN KEY (project_type_id) REFERENCES public.project_types(id);


--
-- Name: reconciliation_links reconciliation_links_acc_trans_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.reconciliation_links
    ADD CONSTRAINT reconciliation_links_acc_trans_id_fkey FOREIGN KEY (acc_trans_id) REFERENCES public.acc_trans(acc_trans_id) ON DELETE CASCADE;


--
-- Name: reconciliation_links reconciliation_links_bank_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.reconciliation_links
    ADD CONSTRAINT reconciliation_links_bank_transaction_id FOREIGN KEY (bank_transaction_id) REFERENCES public.bank_transactions(id) ON DELETE CASCADE;


--
-- Name: record_template_items record_template_items_chart_id; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items
    ADD CONSTRAINT record_template_items_chart_id FOREIGN KEY (chart_id) REFERENCES public.chart(id) ON DELETE CASCADE;


--
-- Name: record_template_items record_template_items_project_id; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items
    ADD CONSTRAINT record_template_items_project_id FOREIGN KEY (project_id) REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: record_template_items record_template_items_record_template_id; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items
    ADD CONSTRAINT record_template_items_record_template_id FOREIGN KEY (record_template_id) REFERENCES public.record_templates(id) ON DELETE CASCADE;


--
-- Name: record_template_items record_template_items_tax_id; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_template_items
    ADD CONSTRAINT record_template_items_tax_id FOREIGN KEY (tax_id) REFERENCES public.tax(id) ON DELETE CASCADE;


--
-- Name: record_templates record_templates_ar_ap_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_ar_ap_chart_id_fkey FOREIGN KEY (ar_ap_chart_id) REFERENCES public.chart(id) ON DELETE SET NULL;


--
-- Name: record_templates record_templates_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id) ON DELETE CASCADE;


--
-- Name: record_templates record_templates_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id) ON DELETE SET NULL;


--
-- Name: record_templates record_templates_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(id) ON DELETE SET NULL;


--
-- Name: record_templates record_templates_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id) ON DELETE SET NULL;


--
-- Name: record_templates record_templates_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: record_templates record_templates_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.record_templates
    ADD CONSTRAINT record_templates_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendor(id) ON DELETE SET NULL;


--
-- Name: requirement_spec_item_dependencies requirement_spec_item_dependencies_depended_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_item_dependencies
    ADD CONSTRAINT requirement_spec_item_dependencies_depended_item_id_fkey FOREIGN KEY (depended_item_id) REFERENCES public.requirement_spec_items(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_item_dependencies requirement_spec_item_dependencies_depending_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_item_dependencies
    ADD CONSTRAINT requirement_spec_item_dependencies_depending_item_id_fkey FOREIGN KEY (depending_item_id) REFERENCES public.requirement_spec_items(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_items requirement_spec_items_acceptance_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_acceptance_status_id_fkey FOREIGN KEY (acceptance_status_id) REFERENCES public.requirement_spec_acceptance_statuses(id);


--
-- Name: requirement_spec_items requirement_spec_items_complexity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_complexity_id_fkey FOREIGN KEY (complexity_id) REFERENCES public.requirement_spec_complexities(id);


--
-- Name: requirement_spec_items requirement_spec_items_order_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_order_part_id_fkey FOREIGN KEY (order_part_id) REFERENCES public.parts(id) ON DELETE SET NULL;


--
-- Name: requirement_spec_items requirement_spec_items_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.requirement_spec_items(id);


--
-- Name: requirement_spec_items requirement_spec_items_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_items requirement_spec_items_risk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_items
    ADD CONSTRAINT requirement_spec_items_risk_id_fkey FOREIGN KEY (risk_id) REFERENCES public.requirement_spec_risks(id);


--
-- Name: requirement_spec_orders requirement_spec_orders_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders
    ADD CONSTRAINT requirement_spec_orders_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.oe(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_orders requirement_spec_orders_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders
    ADD CONSTRAINT requirement_spec_orders_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_orders requirement_spec_orders_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_orders
    ADD CONSTRAINT requirement_spec_orders_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.requirement_spec_versions(id) ON DELETE SET NULL;


--
-- Name: requirement_spec_parts requirement_spec_parts_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_parts
    ADD CONSTRAINT requirement_spec_parts_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.parts(id);


--
-- Name: requirement_spec_parts requirement_spec_parts_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_parts
    ADD CONSTRAINT requirement_spec_parts_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_parts requirement_spec_parts_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_parts
    ADD CONSTRAINT requirement_spec_parts_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: requirement_spec_pictures requirement_spec_pictures_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_pictures
    ADD CONSTRAINT requirement_spec_pictures_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_pictures requirement_spec_pictures_text_block_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_pictures
    ADD CONSTRAINT requirement_spec_pictures_text_block_id_fkey FOREIGN KEY (text_block_id) REFERENCES public.requirement_spec_text_blocks(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_text_blocks requirement_spec_text_blocks_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_text_blocks
    ADD CONSTRAINT requirement_spec_text_blocks_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_versions requirement_spec_versions_requirement_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_versions
    ADD CONSTRAINT requirement_spec_versions_requirement_spec_id_fkey FOREIGN KEY (requirement_spec_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_spec_versions requirement_spec_versions_working_copy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_spec_versions
    ADD CONSTRAINT requirement_spec_versions_working_copy_id_fkey FOREIGN KEY (working_copy_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: requirement_specs requirement_specs_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: requirement_specs requirement_specs_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.project(id);


--
-- Name: requirement_specs requirement_specs_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.requirement_spec_statuses(id);


--
-- Name: requirement_specs requirement_specs_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.requirement_spec_types(id);


--
-- Name: requirement_specs requirement_specs_working_copy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.requirement_specs
    ADD CONSTRAINT requirement_specs_working_copy_id_fkey FOREIGN KEY (working_copy_id) REFERENCES public.requirement_specs(id) ON DELETE CASCADE;


--
-- Name: sepa_export sepa_export_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export
    ADD CONSTRAINT sepa_export_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: sepa_export_items sepa_export_items_ap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_items
    ADD CONSTRAINT sepa_export_items_ap_id_fkey FOREIGN KEY (ap_id) REFERENCES public.ap(id) ON DELETE CASCADE;


--
-- Name: sepa_export_items sepa_export_items_ar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_items
    ADD CONSTRAINT sepa_export_items_ar_id_fkey FOREIGN KEY (ar_id) REFERENCES public.ar(id) ON DELETE CASCADE;


--
-- Name: sepa_export_items sepa_export_items_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_items
    ADD CONSTRAINT sepa_export_items_chart_id_fkey FOREIGN KEY (chart_id) REFERENCES public.chart(id);


--
-- Name: sepa_export_items sepa_export_items_sepa_export_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_items
    ADD CONSTRAINT sepa_export_items_sepa_export_id_fkey FOREIGN KEY (sepa_export_id) REFERENCES public.sepa_export(id) ON DELETE CASCADE;


--
-- Name: sepa_export_message_ids sepa_export_message_ids_sepa_export_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.sepa_export_message_ids
    ADD CONSTRAINT sepa_export_message_ids_sepa_export_id_fkey FOREIGN KEY (sepa_export_id) REFERENCES public.sepa_export(id) ON DELETE CASCADE;


--
-- Name: shop_images shop_images_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_images
    ADD CONSTRAINT shop_images_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: shop_order_items shop_order_items_shop_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_order_items
    ADD CONSTRAINT shop_order_items_shop_order_id_fkey FOREIGN KEY (shop_order_id) REFERENCES public.shop_orders(id) ON DELETE CASCADE;


--
-- Name: shop_orders shop_orders_kivi_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_orders
    ADD CONSTRAINT shop_orders_kivi_customer_id_fkey FOREIGN KEY (kivi_customer_id) REFERENCES public.customer(id);


--
-- Name: shop_orders shop_orders_shop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_orders
    ADD CONSTRAINT shop_orders_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: shop_parts shop_parts_part_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_parts
    ADD CONSTRAINT shop_parts_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.parts(id);


--
-- Name: shop_parts shop_parts_shop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.shop_parts
    ADD CONSTRAINT shop_parts_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: stocktakings stocktakings_bin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_bin_id_fkey FOREIGN KEY (bin_id) REFERENCES public.bin(id);


--
-- Name: stocktakings stocktakings_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: stocktakings stocktakings_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(id);


--
-- Name: stocktakings stocktakings_parts_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_parts_id_fkey FOREIGN KEY (parts_id) REFERENCES public.parts(id);


--
-- Name: stocktakings stocktakings_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.stocktakings
    ADD CONSTRAINT stocktakings_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouse(id);


--
-- Name: tax tax_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_chart_id_fkey FOREIGN KEY (chart_id) REFERENCES public.chart(id);


--
-- Name: tax tax_skonto_purchase_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_skonto_purchase_chart_id_fkey FOREIGN KEY (skonto_purchase_chart_id) REFERENCES public.chart(id);


--
-- Name: tax tax_skonto_sales_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_skonto_sales_chart_id_fkey FOREIGN KEY (skonto_sales_chart_id) REFERENCES public.chart(id);


--
-- Name: taxkeys taxkeys_chart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxkeys
    ADD CONSTRAINT taxkeys_chart_id_fkey FOREIGN KEY (chart_id) REFERENCES public.chart(id);


--
-- Name: taxkeys taxkeys_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxkeys
    ADD CONSTRAINT taxkeys_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.tax(id);


--
-- Name: taxzone_charts taxzone_charts_buchungsgruppen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts
    ADD CONSTRAINT taxzone_charts_buchungsgruppen_id_fkey FOREIGN KEY (buchungsgruppen_id) REFERENCES public.buchungsgruppen(id);


--
-- Name: taxzone_charts taxzone_charts_expense_accno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts
    ADD CONSTRAINT taxzone_charts_expense_accno_id_fkey FOREIGN KEY (expense_accno_id) REFERENCES public.chart(id);


--
-- Name: taxzone_charts taxzone_charts_income_accno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts
    ADD CONSTRAINT taxzone_charts_income_accno_id_fkey FOREIGN KEY (income_accno_id) REFERENCES public.chart(id);


--
-- Name: taxzone_charts taxzone_charts_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.taxzone_charts
    ADD CONSTRAINT taxzone_charts_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: todo_user_config todo_user_config_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.todo_user_config
    ADD CONSTRAINT todo_user_config_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: translation translation_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.translation
    ADD CONSTRAINT translation_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: units_language units_language_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units_language
    ADD CONSTRAINT units_language_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: units_language units_language_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.units_language
    ADD CONSTRAINT units_language_unit_fkey FOREIGN KEY (unit) REFERENCES public.units(name);


--
-- Name: vendor vendor_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- Name: vendor vendor_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: vendor vendor_delivery_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_delivery_term_id_fkey FOREIGN KEY (delivery_term_id) REFERENCES public.delivery_terms(id);


--
-- Name: vendor vendor_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: vendor vendor_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment_terms(id);


--
-- Name: vendor vendor_taxzone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kivitendo
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_taxzone_id_fkey FOREIGN KEY (taxzone_id) REFERENCES public.tax_zones(id);


--
-- Name: report_headings report_headings_category_id_fkey; Type: FK CONSTRAINT; Schema: tax; Owner: kivitendo
--

ALTER TABLE ONLY tax.report_headings
    ADD CONSTRAINT report_headings_category_id_fkey FOREIGN KEY (category_id) REFERENCES tax.report_categories(id);


--
-- Name: report_variables report_variables_heading_id_fkey; Type: FK CONSTRAINT; Schema: tax; Owner: kivitendo
--

ALTER TABLE ONLY tax.report_variables
    ADD CONSTRAINT report_variables_heading_id_fkey FOREIGN KEY (heading_id) REFERENCES tax.report_headings(id);


--
-- PostgreSQL database dump complete
--

