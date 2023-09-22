/var/log/{{ pillar.project }}/:
  file.directory:
    - user: root
    - makedirs: True
    - mode: 2774

{% if pillar.vhosts is defined %}
{% for site, name in pillar.vhosts.sites.items() %}
{% set user = name.user|default(site) %}
{{ user }}_{{ pillar.project }}_logs_dir_acl:
  acl.present:
    - name: /var/log/{{ pillar.project }}/
    - acl_type: user
    - acl_name: {{ user }}
    - perms: rwx
    - onlyif:
      - grep -c {{ user }} /etc/passwd
{% endfor %}
{% endif %}


{% if pillar.node is defined and pillar.node.sites is defined %}
{% for site, name in pillar.node.sites.items() %}
{% set user = name.user|default(site) %}
{{ user }}_{{ pillar.project }}_logs_dir_acl:
  acl.present:
    - name: /var/log/{{ pillar.project }}/
    - acl_type: user
    - acl_name: {{ user }}
    - perms: rwx
    - onlyif:
      - grep -c {{ user }} /etc/passwd
{% endfor %}
{% endif %}

{% if pillar.siteusers is defined %}
{% for user in pillar.siteusers %}
{{ user }}_{{ pillar.project }}_logs_dir_acl:
  acl.present:
    - name: /var/log/{{ pillar.project }}/
    - acl_type: user
    - acl_name: {{ user }}
    - perms: rwx
    - onlyif:
      - grep -c {{ user }} /etc/passwd
{% endfor %}
{% endif %}
      
awslogs:
  pkg.purged

/etc/awslogs/awslogs.conf:
  file.absent

'amazon-linux-extras enable collectd':
  cmd.run:
    - unless: 
      - grep collectd /etc/yum.repos.d/amzn2-extras.repo

install_collectd_aws_extras:
  pkg.installed:
    - fromrepo: amzn2extra-collectd
    - pkgs:
      - collectd

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