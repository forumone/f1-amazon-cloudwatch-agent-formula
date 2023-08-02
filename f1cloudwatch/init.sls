logs:
  group.present:
    - gid: 5647
{% if salt['grains.get']('roles:web-server') is defined  %}
php-logs:
  group.present:
    - name: logs
    - gid: 5647
    - addusers:
{% if pillar.vhosts is defined and pillar.vhosts.sites is defined  %}
{% for site, name in pillar.vhosts.sites.items() %}
  {% set user = name.user | default(site)%}
      - {{ user }}
{% endfor %}
{% endif %}
    - order: last
{% endif %}

{% if salt['grains.get']('roles:node-server') is defined  %}
node-logs:
  group.present:
    - name: logs
    - gid: 5647
    - addusers:
{% if pillar.node is defined and pillar.node.sites is defined %}
{% for site, name in pillar.node.sites.items() %}
  {% set user = name.user | default(site)%}
      - {{ user }}
  {% endfor %}
{% elif pillar.siteusers is defined %}
{% for user in pillar.siteusers %}
      - {{ user }}
{% endfor %}
{% endif %}
{% endif %}

/var/log/{{ pillar.project }}/:
  file.directory:
    - user: root
    - group: logs
    - makedirs: True
    - mode: 2774
    - require:
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