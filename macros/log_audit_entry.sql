{% macro log_audit_entry() %}

    INSERT INTO analytics.audit_log (
        table_name,
        schema_name,
        run_completed_at      
    )
    VALUES (
        '{{ this.identifier }}',     -- model table name
        '{{ this.schema }}',         -- schema where the model is written
        current_timestamp()         -- end time of job
                           
    );

{% endmacro %}
