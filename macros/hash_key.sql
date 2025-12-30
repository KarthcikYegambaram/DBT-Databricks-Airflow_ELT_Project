{% macro generate_md5_hash(columns) %}
    md5(
        coalesce(
            concat_ws('|',
                {% for col in columns %}
                    coalesce(
                        upper(trim(cast({{ col }} as string))),
                        'NULL'
                    )
                    {% if not loop.last %}, {% endif %}
                {% endfor %}
            ),
            'NULL'
        )
    )
{% endmacro %}
