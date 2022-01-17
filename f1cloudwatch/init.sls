logs:
  group.present:
    - gid: 5647

/var/log/{{ pillar.project }}/:
  file.directory:
    - user: root
    - group: logs
    - makedirs: True
    - mode: 2774

awslogs:
  pkg.purged

/etc/awslogs/awslogs.conf:
  file.absent

'amazon-linux-extras install collectd':
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
    - require:
      - pkg: install_cloudwatch_agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/forumone.json:
  cmd.run:
    - success_retcodes: 0
    - onchanges:
      - file: /opt/aws/amazon-cloudwatch-agent/bin/forumone.json
      - install_cloudwatch_agent
