logs:
  group.present:
    - gid: 5647
    - addusers:
{% if pillar.vhosts is defined %}
{% for site, name in pillar.vhosts.sites.items() %}
  {% if name.user is defined %}
  {% set user = name.user %}
  {% else %}
  {% set user = site %}
  {% endif %}
      - {{ user }}
{% endfor %}
{% endif %}
{% if pillar.node is defined %}
{% for site, name in pillar.node.sites.items() %}
  {% if name.user is defined %}
  {% set user = name.user %}
  {% else %}
  {% set user = site %}
  {% endif %}
      - {{ user }}
{% endfor %}
{% endif %}
{% if pillar.siteusers is defined %}
{% for user in pillar.siteusers %}
      - {{ user }}
{% endfor %}
{% endif %}

/var/log/{{ pillar.project }}/:
  file.directory:
    - user: root
    - group: logs
    - makedirs: True
    - mode: 2774
    - depends_on:
      - logs
      
awslogs:
  pkg.purged

/etc/awslogs/awslogs.conf:
  file.absent

'amazon-linux-extras install -y collectd':
  cmd.run:
    - unless: 
      - /bin/amazon-linux-extras list | grep collectd | grep -c enabled

install_cloudwatch_agent:
  pkg.installed:
    - pkgs:
      - amazon-cloudwatch-agent
      - collectd

/opt/aws/amazon-cloudwatch-agent/bin/forumone.json:
  file.managed:
    - source: salt://f1cloudwatch/files/config.json
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context: 
        retention_days: {{ pillar.get('log_retention_days', '30') }}
    - require:
      - pkg: install_cloudwatch_agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/forumone.json:
  cmd.run:
    - success_retcodes: 0
    - onchanges:
      - file: /opt/aws/amazon-cloudwatch-agent/bin/forumone.json
      - install_cloudwatch_agent
