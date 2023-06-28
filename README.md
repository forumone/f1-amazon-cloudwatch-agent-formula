# f1-amazon-cloudwatch-agent-formula

This formula installs and configures Amazon Cloudwatch Agent.

you can set log retention in the project pillar with this yaml:

log_rentention_days: 365

Where the interget MUST be one of these numbers:
-1, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653

This is an AWS API restriction.

It lifts and shifts the source of the salt formula from its current location within <project>-infrastructure repositories into this repository, and 
the `metric_collection_interval` to 300 seconds for all non utility instances.

To replace the existing cloudwatch formulas in <project>-infrastructure repositories, do the following:
  
1. Remove the `saltstack/salt/cloudwatch` directory  
2. Edit `saltstack/salt/core/init.sls` and remove the `- cloudwatch` include at the bottom  
3. Add `- salt.cloudwatch` to `saltstack/salt/top.sls` for `'*'`
4. Create `saltstack/salt/salt/cloudwatch.sls` with the following contents:
```
cloudwatch:
  grains.present:
    - value: True

{% if 'salt-master' in grains.get('roles',[]) %}
cloudwatch_remote:
  file.append:
    - name: /etc/salt/master.d/git_remotes.conf
    - text: "  - https://github.com/forumone/f1-amazon-cloudwatch-agent-formula.git:\n    - base: main"

cloudwatch_reload_salt_master:
  service.running:
    - name: salt-master
    - watch:
      - cloudwatch_remote
{% endif %}

{% if grains.get('cloudwatch', False) %}
include:
  - f1cloudwatch
{% endif %}
```
