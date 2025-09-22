# Stack Copier Template

## Create

```
copier copy --answers-file=.copier-answers-stack.yml  gh:unifica-ai/stack-copier-template /path/to/project
```

## Update

```
copier copy --answers-file=.copier-answers-stack.yml update .
```


## Manual touch up:

1. Add to `smtpreal` in `common.yaml`:

```
- ./config/user-patches.sh:/tmp/docker-mailserver/user-patches.sh:ro
```

2. Append =odoo/custom/src/_repos.yml= to =odoo/custom/src/repos.yml=

 TODO replace this file with a jinja template, variable, and loop
 
3. Append _tasks.py to tasks.py

TODO find a better way to do this, maybe via a task

4. Update `smtpreal` in `common.yaml`:
 
 ENABLE_SRS: 0
 
 
5. Run the stack-post-create script
